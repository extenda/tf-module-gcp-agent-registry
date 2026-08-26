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

variable "project_id" {
  description = "The project ID to deploy to."
  type        = string
}

variable "skills" {
  description = <<-EOT
    Skills to register in the Agent Registry, keyed by skill_id.
    Value is raw .md file content with YAML frontmatter — display_name and description
    are extracted from the frontmatter by the register script.
    Skill IDs use "{clan}-{skill}" convention; the API prepends "private-" automatically.
  EOT
  type    = map(string)
  default = {}
}
