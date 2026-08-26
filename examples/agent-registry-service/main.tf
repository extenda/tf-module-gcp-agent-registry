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

# examples/agent-registry-service/main.tf

module "agent_registry_service" {
  source     = "../../modules/agent-registry-service"
  project_id = var.project_id

  services = {
    "test-service-${var.random_string}" = {
      location     = "us-central1"
      display_name = "test-service-${var.random_string}"
      interfaces = [
        { "protocol_binding" = "HTTP_JSON", "url" = "https://api.stripe.com" }
      ]
      endpoint_spec = {
        type = "NO_SPEC"
      }
    }
    "test-mcp-server-${var.random_string}" = {
      location     = "us-central1"
      display_name = "test-mcp-server-${var.random_string}"
      interfaces = [
        { "protocol_binding" = "JSONRPC", "url" = "https://example.com" }
      ]
      mcp_server_spec = {
        type    = "TOOL_SPEC"
        content = jsonencode({ tools = [] })
      }
    }
  }
}
