data "azurerm_client_config" "current" {}

locals {
  permissions_dir = "${path.module}/permissions"
  manifest        = jsondecode(file("${local.permissions_dir}/manifest.json"))
  builtin_roles   = { for role in jsondecode(file("${local.permissions_dir}/${local.manifest.builtin_roles_file}")) : role.id => role }
  core_actions    = jsondecode(file("${local.permissions_dir}/${local.manifest.custom_role.actions_file}"))
  groups          = { for entry in local.manifest.permission_groups : entry.group => entry }

  scope_inputs = [for value in [var.subscription_id, var.management_group_id] : value if value != null]
  scope = (
    var.subscription_id != null ? "/subscriptions/${var.subscription_id}"
    : var.management_group_id != null ? "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
    : ""
  )
  builtin_role_definition_scope = var.subscription_id != null ? local.scope : ""

  group_mode       = var.permission_groups != null
  requested_groups = local.group_mode ? keys(var.permission_groups) : []
  unknown_groups   = [for group in local.requested_groups : group if !contains(keys(local.groups), group)]
  role_groups      = local.group_mode ? [for group in distinct(concat(["access_map"], local.requested_groups)) : group if contains(keys(local.groups), group)] : []

  group_actions = flatten([
    for group in local.role_groups : jsondecode(file("${local.permissions_dir}/${local.groups[group].actions_file}")) if try(local.groups[group].actions_file, null) != null
  ])
  custom_role_actions = distinct(concat(local.core_actions, local.group_actions))

  legacy_builtin_role_ids = keys(local.builtin_roles)
  group_builtin_role_ids  = flatten([for group in local.role_groups : local.groups[group].builtin_role_ids])
  group_mode_builtin_role_ids = distinct(concat(
    var.keep_legacy_builtin_roles ? local.legacy_builtin_role_ids : [],
    local.group_builtin_role_ids,
  ))
  builtin_role_ids = var.assign_builtin_roles ? (local.group_mode ? local.group_mode_builtin_role_ids : local.legacy_builtin_role_ids) : []

  custom_role_name   = coalesce(var.custom_role_name, "${local.manifest.custom_role.name_prefix}-${var.deployment_id}")
  deployment_version = local.manifest.deployment_version

  permission_files = concat(
    ["manifest.json", local.manifest.builtin_roles_file, local.manifest.graph_app_roles_file, local.manifest.custom_role.actions_file],
    [for entry in local.manifest.permission_groups : entry.actions_file if try(entry.actions_file, null) != null],
  )
  permissions_hash = sha256(join("", [for name in local.permission_files : filesha256("${local.permissions_dir}/${name}")]))
}

resource "azurerm_role_definition" "act" {
  name              = local.custom_role_name
  scope             = local.scope
  description       = "${local.manifest.custom_role.description} ${var.binding_marker} [act:deployment-version=${local.deployment_version}]"
  assignable_scopes = [local.scope]

  permissions {
    actions = local.custom_role_actions
  }

  lifecycle {
    precondition {
      condition     = length(local.scope_inputs) == 1
      error_message = "Set exactly one of subscription_id and management_group_id."
    }

    precondition {
      condition     = length(local.unknown_groups) == 0
      error_message = "permission_groups has unknown groups: ${join(", ", local.unknown_groups)}. Valid groups: ${join(", ", keys(local.groups))}."
    }
  }
}

resource "azurerm_role_assignment" "custom" {
  scope                            = azurerm_role_definition.act.scope
  role_definition_id               = azurerm_role_definition.act.role_definition_resource_id
  principal_id                     = var.service_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "builtin" {
  for_each = toset(local.builtin_role_ids)

  scope                            = azurerm_role_definition.act.scope
  role_definition_id               = "${local.builtin_role_definition_scope}/providers/Microsoft.Authorization/roleDefinitions/${each.key}"
  principal_id                     = var.service_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
