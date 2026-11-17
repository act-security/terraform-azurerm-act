output "service_principal_id" {
  description = "Object ID of Act's service principal in this tenant. Pass it to `service_principal_id` of the root module and the log submodules."
  value       = one(data.azuread_service_principals.act.object_ids)
}

output "graph_app_roles" {
  description = "The Microsoft Graph application permissions, by name, that approving Act's app grants when the deployment includes Entra ID. The module never grants them."
  value       = var.include_entra_id ? { for role in local.graph_app_roles : role.name => role.id } : {}
}
