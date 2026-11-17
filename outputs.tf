output "deployment_id" {
  description = "The deployment ID, passed through once every role exists."
  value       = var.deployment_id
  depends_on  = [azurerm_role_definition.act, azurerm_role_assignment.custom, azurerm_role_assignment.builtin]
}

output "azure_tenant_id" {
  description = "The Entra ID tenant the azurerm provider runs in."
  value       = data.azurerm_client_config.current.tenant_id
  depends_on  = [azurerm_role_definition.act, azurerm_role_assignment.custom, azurerm_role_assignment.builtin]
}

output "subscription_id" {
  description = "The connected subscription, null for a management group."
  value       = var.subscription_id
  depends_on  = [azurerm_role_definition.act, azurerm_role_assignment.custom, azurerm_role_assignment.builtin]
}

output "management_group_id" {
  description = "The connected management group, null for a subscription."
  value       = var.management_group_id
  depends_on  = [azurerm_role_definition.act, azurerm_role_assignment.custom, azurerm_role_assignment.builtin]
}

output "service_principal_id" {
  description = "Object ID of Act's service principal, the principal that holds the roles."
  value       = var.service_principal_id
  depends_on  = [azurerm_role_definition.act, azurerm_role_assignment.custom, azurerm_role_assignment.builtin]
}

output "scope" {
  description = "The ARM scope the roles are assigned at."
  value       = local.scope
  depends_on  = [azurerm_role_definition.act, azurerm_role_assignment.custom, azurerm_role_assignment.builtin]
}

output "custom_role_id" {
  description = "Resource ID of the custom role definition."
  value       = azurerm_role_definition.act.role_definition_resource_id
  depends_on  = [azurerm_role_assignment.custom, azurerm_role_assignment.builtin]
}

output "custom_role_name" {
  description = "Name of the custom role definition."
  value       = azurerm_role_definition.act.name
}

output "custom_role_actions" {
  description = "The actions the custom role holds."
  value       = local.custom_role_actions
}

output "role_assignment_ids" {
  description = "Role assignment IDs by role name: the custom role and each built-in role."
  value = merge(
    { (azurerm_role_definition.act.name) = azurerm_role_assignment.custom.id },
    { for id, assignment in azurerm_role_assignment.builtin : local.builtin_roles[id].name => assignment.id },
  )
}

output "ready" {
  description = "Always true, and depends on the custom role and every assignment. Reference it, or any other output, from the Act resource that registers this deployment: Terraform then creates that resource after the roles and destroys it before them."
  value       = true
  depends_on  = [azurerm_role_definition.act, azurerm_role_assignment.custom, azurerm_role_assignment.builtin]
}

output "deployment_version" {
  description = "The Act deployment version this release grants, stamped on the custom role's description as `[act:deployment-version=<version>]`."
  value       = local.deployment_version
}

output "permissions_hash" {
  description = "SHA-256 over the permission files of this release. Compare it across versions to see whether an upgrade changes what Act can read."
  value       = local.permissions_hash
}
