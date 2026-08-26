# Agent Registry Service

This module provides the primary resource to deploy and manage the full lifecycle of AI agent interfaces and capabilities within the Google Cloud Agent Registry. It supports the registration of first-party (1P), second-party (2P), and third-party (3P) agents and tools.

> Extenda fork note: this module registers any number of services (agents, MCP
> servers, or endpoints) from a single `services` map via `for_each`, instead of
> one service per module call. It also runs on the GA `google` provider
> (`google_agent_registry_service` graduated out of `google-nightly` in
> `hashicorp/google` v7.39.0), so no `google-nightly` provider setup is required.

## Usage

```hcl
module "agent_registry_service" {
  source     = "../../modules/agent-registry-service"
  project_id = var.project_id

  services = {
    my-mcp-server = {
      location     = "us-central1"
      display_name = "My MCP Server"
      interfaces = [
        { url = "https://example.com", protocol_binding = "JSONRPC" }
      ]
      mcp_server_spec = {
        type    = "TOOL_SPEC"
        content = jsonencode({ tools = [] })
      }
    }
    my-agent = {
      location     = "us-central1"
      display_name = "My Agent"
      agent_spec = {
        type    = "NO_SPEC"
        content = ""
      }
    }
  }
}
```

Refer to the root module for end-to-end integration examples including Agent Engine and Agent Gateway connectivity.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | The project ID to deploy to. | `string` | n/a | yes |
| services | Agent Registry services to create, keyed by service\_id. Exactly one of agent\_spec, mcp\_server\_spec, or endpoint\_spec must be set per entry. | <pre>map(object({<br>    location     = string<br>    display_name = string # max 63 characters<br>    description  = optional(string)<br>    interfaces = optional(list(object({<br>      url              = string<br>      protocol_binding = string # JSONRPC, GRPC, or HTTP_JSON<br>    })), [])<br>    agent_spec = optional(object({<br>      type    = string # NO_SPEC or A2A_AGENT_CARD<br>      content = string # JSON format content<br>    }))<br>    mcp_server_spec = optional(object({<br>      type    = string # NO_SPEC or TOOL_SPEC<br>      content = string # JSON format content<br>    }))<br>    endpoint_spec = optional(object({<br>      type = string # NO_SPEC<br>    }))<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| discovery\_filters | Map of service\_id to a pre-formatted filter string for discovery modules. |
| display\_names | Map of service\_id to the user-defined display name of the service. |
| ids | Map of service\_id to Agent Registry Service ID. |
| services | Full Agent Registry Service resource attributes, keyed by service\_id. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
