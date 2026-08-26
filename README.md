# terraform-google-agent-registry

## Description

Registers A2A agents, MCP servers, and skills in the GCP Agent Registry
(`agentregistry.googleapis.com`). Forked from the upstream Google module and
extended with skill registration support (v1alpha REST API — no provider
resource exists yet).

The module accepts raw file contents and handles all transformation internally:

- **Agents** (`agents/*/agent.yaml`) — parsed and registered as A2A agent cards.
- **MCP servers** (`mcp/*/mcp.yaml`) — parsed and registered as MCP server services.
- **Skills** (`skills/*.md`) — zipped, base64-encoded, and registered via REST.
  Skill IDs use a `{clan}-{skill}` convention; the API prepends `private-` automatically.

### PreDeploy

1. **Enable APIs**: `agentregistry.googleapis.com` must be enabled in the project.
2. **Permissions**: the identity running Terraform requires `roles/agentregistry.admin`.
3. **Python 3.10+**: required on the machine running `apply` for the skill registration script.

> **Note on skill deletion**: there is no Terraform provider resource for skills yet.
> Removing a skill `.md` file and applying will drop the state entry but will **not**
> delete the skill from the registry. Delete it manually via the GCP console or the
> `agentregistry.googleapis.com/v1alpha` REST API.

## Architecture
The Agent Registry integrates with several Google Cloud services to provide a secure management boundary for AI agents.

1. **AI Agents**: Registered via Agent Engine to assert functional capabilities.
2. **MCP Servers**: Standardized tool definitions discovered via the registry catalog.
3. **Endpoints**: Targets for secure service execution.
4. **App Hub**: Implemented as a new catalog type to provide application-centric observability.


## Documentation
- [Hosting a Static Website](https://cloud.google.com/storage/docs/hosting-static-website)

## Deployment Duration
Configuration: X mins
Deployment: Y mins

## Cost
[Blueprint cost details](https://cloud.google.com/products/calculator?id=02fb0c45-cc29-4567-8cc6-f72ac9024add)

## Usage

Each clan's `agent-registry/` directory follows this layout:

```
agent-registry/
  agents/
    my-agent/
      agent.yaml       # A2A agent metadata and skills list
  mcp/
    my-mcp-server/
      mcp.yaml         # MCP server metadata, interfaces, and tool spec
  skills/
    clan-skill-name.md # Skill instructions with YAML frontmatter
  terragrunt.hcl
```

The `terragrunt.hcl` is identical across all clans — it just reads the files:

```hcl
inputs = {
  project_id = "my-project"

  agents = {
    for f in fileset("${get_terragrunt_dir()}/agents", "*/agent.yaml") :
    dirname(f) => file("${get_terragrunt_dir()}/agents/${f}")
  }

  mcps = {
    for f in fileset("${get_terragrunt_dir()}/mcp", "*/mcp.yaml") :
    dirname(f) => file("${get_terragrunt_dir()}/mcp/${f}")
  }

  skills = {
    for f in fileset("${get_terragrunt_dir()}/skills", "*.md") :
    trimsuffix(f, ".md") => file("${get_terragrunt_dir()}/skills/${f}")
  }
}
```

### agent.yaml format

```yaml
name: my-agent                         # used in the A2A card
display_name: My Agent                 # shown in the registry UI (max 63 chars)
description: What this agent does.
url: https://my-agent.retailsvc.com
version: 0.1.0
location: europe-west1
skills:
  - id: clan-skill-name
    name: Human readable skill name
    description: What this skill does.
    tags: [tag1, tag2]
    examples:
      - Example prompt that triggers this skill
```

### mcp.yaml format

```yaml
location: europe-west1
display_name: My MCP Server            # max 63 chars
description: What this MCP server exposes.
interfaces:
  - protocol_binding: JSONRPC          # JSONRPC or GRPC (HTTP_JSON not supported by backend)
    url: https://my-mcp.retailsvc.com
mcp_server_spec:
  type: TOOL_SPEC                      # NO_SPEC or TOOL_SPEC
  content: |
    { "tools": [ ... ] }
```

### skill .md format

```markdown
---
name: clan-skill-name
metadata:
  category: DeveloperTooling
description: One-line description shown in the registry.
---

# Skill Title

Full instruction content for the agent...
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_id` | The GCP project ID to deploy to. | `string` | yes |
| `agents` | A2A agents to register, keyed by agent directory name. Value is raw `agent.yaml` content. | `map(string)` | no |
| `mcps` | MCP servers to register, keyed by service directory name. Value is raw `mcp.yaml` content. | `map(string)` | no |
| `skills` | Skills to register, keyed by skill ID. Value is raw `.md` content with YAML frontmatter. | `map(string)` | no |

## Outputs

| Name | Description |
|------|-------------|
| `ids` | Map of service ID to Agent Registry Service resource ID. |
| `services` | Full Agent Registry Service resource attributes, keyed by service ID. |
| `display_names` | Map of service ID to display name. |
| `discovery_filters` | Map of service ID to pre-formatted discovery filter string. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

These sections describe requirements for using this module.

### Software

- OpenTofu >= 1.6 or Terraform >= 1.3
- Google provider >= 6.0
- Python 3.10+ on the machine running `apply` (for skill registration)

### Service Account

A service account with the following roles must be used to provision
the resources of this module:

- `roles/agentregistry.admin` on the project

### APIs

- `agentregistry.googleapis.com`

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

[iam-module]: https://registry.terraform.io/modules/terraform-google-modules/iam/google
[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html

## Security Disclosures

Please see our [security disclosure process](./SECURITY.md).
