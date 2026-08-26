variable "project_id" {
  description = "The project ID to deploy to."
  type        = string
}

variable "agents" {
  description = <<-EOT
    A2A agents to register in the Agent Registry, keyed by agent directory name.
    Value is raw agent.yaml content — the module parses it and builds the A2A agent card.
  EOT
  type    = map(string)
  default = {}
}

variable "mcps" {
  description = <<-EOT
    MCP servers to register in the Agent Registry, keyed by service directory name.
    Value is raw mcp.yaml content — the module parses it and creates the service.
  EOT
  type    = map(string)
  default = {}
}

variable "skills" {
  description = <<-EOT
    Skills to register in the Agent Registry, keyed by skill_id.
    Value is raw .md file content (with YAML frontmatter) — the module handles zipping and registration.
    Skill IDs use "{clan}-{skill}" convention (e.g. "platform-fix-dependabot-pr");
    the API prepends "private-" automatically. Location is always "global".
  EOT
  type    = map(string)
  default = {}
}
