output "deployment_id" {
  description = "The deployment ID, known after the roles exist."
  value       = module.act.deployment_id
}

output "azure_tenant_id" {
  description = "The tenant of the connected management group."
  value       = module.act.azure_tenant_id
}

output "management_group_id" {
  description = "The connected management group."
  value       = module.act.management_group_id
}

output "service_principal_id" {
  description = "Object ID of Act's service principal."
  value       = module.act.service_principal_id
}

output "eventhub_namespace_id" {
  description = "Act's Event Hub namespace."
  value       = module.activity_logs.namespace_id
}

output "activity_log_setting_ids" {
  description = "The activity log diagnostic setting on each subscription under the management group."
  value       = module.activity_logs.activity_log_setting_ids
}

output "entra_diagnostic_setting_id" {
  description = "The tenant's Entra ID diagnostic setting."
  value       = module.entra_logs.diagnostic_setting_id
}
