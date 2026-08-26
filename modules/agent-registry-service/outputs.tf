/**
 * Copyright 2021 Google LLC
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

data "google_project" "project" {
  project_id = var.project_id
}

output "ids" {
  description = "Map of service_id to Agent Registry Service ID."
  value       = { for k, v in google_agent_registry_service.this : k => v.id }
}

output "services" {
  description = "Full Agent Registry Service resource attributes, keyed by service_id."
  value       = google_agent_registry_service.this
}

output "display_names" {
  description = "Map of service_id to the user-defined display name of the service."
  value       = { for k, v in google_agent_registry_service.this : k => v.display_name }
}

output "discovery_filters" {
  description = "Map of service_id to a pre-formatted filter string for discovery modules."
  value = {
    for k, v in google_agent_registry_service.this : k => format("%s:\"urn:%s:projects-%s:projects:%s:locations:%s:agentregistry:services:%s\"",
      length(v.agent_spec) > 0 ? "agentId" : (length(v.mcp_server_spec) > 0 ? "mcpServerId" : "endpointId"),
      length(v.agent_spec) > 0 ? "agent" : (length(v.mcp_server_spec) > 0 ? "mcp" : "endpoint"),
      data.google_project.project.number,
      data.google_project.project.number,
      var.services[k].location,
      basename(v.id)
    )
  }

  depends_on = [
    google_agent_registry_service.this,
    time_sleep.wait_after_registration
  ]
}
