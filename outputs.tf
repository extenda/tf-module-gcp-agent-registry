output "ids" {
  description = "Map of service_id to Agent Registry Service ID."
  value       = module.agent_registry_service.ids
}

output "services" {
  description = "Full Agent Registry Service resource attributes, keyed by service_id."
  value       = module.agent_registry_service.services
}

output "display_names" {
  description = "Map of service_id to the user-defined display name of the service."
  value       = module.agent_registry_service.display_names
}

output "discovery_filters" {
  description = "Map of service_id to a pre-formatted filter string for discovery modules."
  value       = module.agent_registry_service.discovery_filters
}
