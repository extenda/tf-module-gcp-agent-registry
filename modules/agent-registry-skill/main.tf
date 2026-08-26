/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# Skills are registered via the Agent Registry REST API (v1alpha) — no Terraform provider
# resource exists yet. Location must be "global".
resource "null_resource" "skill" {
  for_each = var.skills

  triggers = {
    skill_id   = each.key
    content    = each.value
    project_id = var.project_id
  }

  provisioner "local-exec" {
    interpreter = ["python3"]
    command     = "${path.module}/scripts/register_skill.py"
    environment = {
      PROJECT_ID    = var.project_id
      LOCATION      = "global"
      SKILL_ID      = each.key
      SKILL_CONTENT = each.value
    }
  }
}
