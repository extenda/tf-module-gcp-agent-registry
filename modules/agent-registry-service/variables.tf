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

variable "project_id" {
  description = "The project ID to deploy to."
  type        = string
}

variable "services" {
  description = "Agent Registry services to create, keyed by service_id. Exactly one of agent_spec, mcp_server_spec, or endpoint_spec must be set per entry."
  type = map(object({
    location     = string
    display_name = string # max 63 characters
    description  = optional(string)
    interfaces = optional(list(object({
      url              = string
      protocol_binding = string # JSONRPC, GRPC, or HTTP_JSON
    })), [])
    agent_spec = optional(object({
      type    = string # NO_SPEC or A2A_AGENT_CARD
      content = string # JSON format content
    }))
    mcp_server_spec = optional(object({
      type    = string # NO_SPEC or TOOL_SPEC
      content = string # JSON format content
    }))
    endpoint_spec = optional(object({
      type = string # NO_SPEC
    }))
  }))
}
