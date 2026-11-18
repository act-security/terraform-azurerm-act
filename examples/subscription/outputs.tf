output "deployment_id" {
  description = "The deployment ID, known after the roles exist."
  value       = module.act.deployment_id
}

output "azure_tenant_id" {
  description = "The tenant of the connected subscription."
  value       = module.act.azure_tenant_id
}

output "subscription_id" {
  description = "The connected subscription."
  value       = module.act.subscription_id
}

output "service_principal_id" {
  description = "Object ID of Act's service principal."
  value       = module.act.service_principal_id
}

output "custom_role_id" {
  description = "Resource ID of the custom role."
  value       = module.act.custom_role_id
}

output "role_assignment_ids" {
  description = "Role assignment IDs by role name."
  value       = module.act.role_assignment_ids
}
