locals {
  parsed_agents = {
    for id, content in var.agents : id => yamldecode(content)
  }

  parsed_mcps = {
    for id, content in var.mcps : id => yamldecode(content)
  }

  agent_services = {
    for agent_id, agent in local.parsed_agents :
    agent_id => {
      location        = agent.location
      display_name    = agent.display_name
      description     = lookup(agent, "description", null)
      interfaces      = []
      mcp_server_spec = null
      endpoint_spec   = null
      agent_spec = {
        type = "A2A_AGENT_CARD"
        content = jsonencode({
          name               = agent.name
          description        = agent.description
          version            = agent.version
          defaultInputModes  = ["text/plain"]
          defaultOutputModes = ["text/plain"]
          capabilities       = { streaming = false, pushNotifications = false }
          supportedInterfaces = [{
            url             = agent.url
            protocolBinding = "JSONRPC"
            protocolVersion = "1.0"
          }]
          skills = [for s in lookup(agent, "skills", []) : {
            id          = s.id
            name        = s.name
            description = s.description
            tags        = lookup(s, "tags", [])
            examples    = lookup(s, "examples", [])
            inputModes  = ["text/plain"]
            outputModes = ["text/plain"]
          }]
        })
      }
    }
  }

  mcp_services = {
    for service_id, mcp in local.parsed_mcps :
    service_id => {
      location        = mcp.location
      display_name    = mcp.display_name
      description     = lookup(mcp, "description", null)
      interfaces      = lookup(mcp, "interfaces", [])
      agent_spec      = null
      endpoint_spec   = null
      mcp_server_spec = {
        type    = mcp.mcp_server_spec.type
        content = mcp.mcp_server_spec.content
      }
    }
  }
}

module "agent_registry_service" {
  source     = "./modules/agent-registry-service"
  project_id = var.project_id
  services   = merge(local.mcp_services, local.agent_services)
}

module "agent_registry_skill" {
  source     = "./modules/agent-registry-skill"
  project_id = var.project_id
  skills     = var.skills
}
