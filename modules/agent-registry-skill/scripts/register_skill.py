#!/usr/bin/env python3
"""
Register or update a skill in the GCP Agent Registry.

Reads all inputs from environment variables:
  PROJECT_ID, LOCATION, SKILL_ID, DISPLAY_NAME, DESCRIPTION, SKILL_CONTENT

API: agentregistry.googleapis.com/v1alpha — LOCATION must be "global".

ID convention: the API prepends "private-" to every skill created without a publisher.
  Input SKILL_ID  → resource name  private-{SKILL_ID}

Flow for new skill:
  1. POST /skills?skillId=SKILL_ID  (targetState=TARGET_STATE_DRAFT, with initialRevision)
  2. Poll private-SKILL_ID until STATE_DRAFT (revision ACTIVE)
  3. GET revisions to find the active revision resource name
  4. PATCH private-SKILL_ID with defaultRevision + targetState=TARGET_STATE_ACTIVE
  5. Poll until STATE_ACTIVE

Flow for existing skill in FAILED state:
  DELETE private-SKILL_ID → wait → run new skill flow above

Flow for existing ACTIVE/DRAFT skill (content update):
  POST /skills/private-SKILL_ID/revisions with new archiveContent
  GET revisions to find the newest active revision
  PATCH private-SKILL_ID with defaultRevision pointing at the new revision
"""

import base64
import io
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zipfile

PROJECT_ID    = os.environ["PROJECT_ID"]
LOCATION      = os.environ["LOCATION"]
SKILL_ID      = os.environ["SKILL_ID"]
SKILL_CONTENT = os.environ["SKILL_CONTENT"]

PRIVATE_ID = f"private-{SKILL_ID}"
BASE_URL   = f"https://agentregistry.googleapis.com/v1alpha/projects/{PROJECT_ID}/locations/{LOCATION}/skills"


def get_token():
    candidates = [
        "python3.13", "python3.12", "python3.11", "python3.10",
        "/opt/homebrew/bin/python3",
    ]
    for py in candidates:
        try:
            result = subprocess.run(
                ["gcloud", "auth", "print-access-token"],
                env={**os.environ, "CLOUDSDK_PYTHON": py},
                capture_output=True, text=True,
            )
            token = result.stdout.strip()
            if token and not token.startswith("ERROR"):
                return token
        except FileNotFoundError:
            continue
    sys.exit("ERROR: could not obtain access token — ensure Python 3.10+ is installed and gcloud is authenticated")


def parse_frontmatter(content):
    """Extract name and description from YAML frontmatter between --- delimiters."""
    import re
    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return SKILL_ID, ""
    fm = {}
    for line in match.group(1).splitlines():
        if ":" in line and not line.startswith(" "):
            k, _, v = line.partition(":")
            fm[k.strip()] = v.strip()
    return fm.get("name", SKILL_ID), fm.get("description", "")


def make_zip(content):
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("SKILL.md", content)
    return base64.b64encode(buf.getvalue()).decode()


def api(method, url, token, body=None):
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


def is_active(state):
    return state in ("ACTIVE", "STATE_ACTIVE")


def is_failed(state):
    return state in ("FAILED", "STATE_FAILED")


def poll_skill(token, exit_states, retries=24, delay=5):
    for _ in range(retries):
        s, b = api("GET", f"{BASE_URL}/{PRIVATE_ID}", token)
        state = b.get("state", "UNKNOWN") if s == 200 else "NOT_FOUND"
        if state in exit_states or state == "NOT_FOUND":
            return state, b
        time.sleep(delay)
    return "TIMEOUT", {}


def get_active_revision(token):
    s, b = api("GET", f"{BASE_URL}/{PRIVATE_ID}/revisions", token)
    if s != 200:
        return None
    revisions = b.get("skillRevisions", [])
    active = [r for r in revisions if r.get("state") == "ACTIVE"]
    if not active:
        return None
    active.sort(key=lambda r: r.get("createTime", ""), reverse=True)
    return active[0]["name"]


def activate_skill(token):
    rev = get_active_revision(token)
    if not rev:
        sys.exit(f"ERROR: no active revision found for {PRIVATE_ID} — cannot activate")
    s, b = api("PATCH",
        f"{BASE_URL}/{PRIVATE_ID}?updateMask=defaultRevision,targetState",
        token,
        {"defaultRevision": rev, "targetState": "TARGET_STATE_ACTIVE"},
    )
    if s not in (200, 201):
        sys.exit(f"ERROR: PATCH to activate failed {s}: {json.dumps(b)}")


def create_skill(token, zip_b64, display_name, description):
    payload = {
        "displayName": display_name,
        "description": description,
        "type": "SIMPLE",
        "targetState": "TARGET_STATE_DRAFT",
        "initialRevision": {
            "archiveUploadSource": {"archiveContent": zip_b64}
        },
    }
    s, b = api("POST", f"{BASE_URL}?skillId={SKILL_ID}", token, payload)
    if s not in (200, 201):
        sys.exit(f"ERROR: POST to create skill failed {s}: {json.dumps(b)}")

    state, _ = poll_skill(token, exit_states={"STATE_DRAFT", "STATE_ACTIVE", "STATE_FAILED", "FAILED"})
    if is_failed(state):
        sys.exit(f"ERROR: skill entered FAILED state after creation — check GCP console")

    activate_skill(token)


def update_skill(token, zip_b64):
    archive = {"archiveUploadSource": {"archiveContent": zip_b64}}
    s, b = api("POST", f"{BASE_URL}/{PRIVATE_ID}/revisions", token, archive)
    if s not in (200, 201):
        sys.exit(f"ERROR: revision POST failed {s}: {json.dumps(b)}")

    time.sleep(5)
    activate_skill(token)


def main():
    token = get_token()
    zip_b64 = make_zip(SKILL_CONTENT)
    display_name, description = parse_frontmatter(SKILL_CONTENT)

    s, body = api("GET", f"{BASE_URL}/{PRIVATE_ID}", token)
    current_state = body.get("state", "") if s == 200 else ""

    if s == 404:
        print(f"Creating skill: {PRIVATE_ID}")
        create_skill(token, zip_b64, display_name, description)

    elif is_failed(current_state):
        print(f"Skill {PRIVATE_ID} is {current_state} — deleting and recreating")
        api("DELETE", f"{BASE_URL}/{PRIVATE_ID}", token)
        time.sleep(5)
        create_skill(token, zip_b64, display_name, description)

    else:
        print(f"Updating skill: {PRIVATE_ID} (current state: {current_state})")
        update_skill(token, zip_b64)

    state, _ = poll_skill(token, exit_states={"STATE_ACTIVE", "STATE_FAILED", "FAILED"})
    if not is_active(state):
        sys.exit(f"ERROR: skill ended in state {state} — check the GCP console for details")

    print(f"Skill {PRIVATE_ID} is ACTIVE")


if __name__ == "__main__":
    main()
