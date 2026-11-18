mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000001"
    }
  }
}

variables {
  deployment_id        = "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
  binding_marker       = "[act:binding=b1nd-ing_42]"
  service_principal_id = "00000000-0000-0000-0000-000000000004"
  subscription_id      = "00000000-0000-0000-0000-000000000002"
}

run "grants_todays_roles_at_the_subscription" {
  command = plan

  assert {
    condition     = azurerm_role_definition.act.name == "ActScannerRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
    error_message = "The custom role must be named after the deployment, as Act looks for it."
  }

  assert {
    condition     = azurerm_role_definition.act.scope == "/subscriptions/00000000-0000-0000-0000-000000000002" && azurerm_role_definition.act.assignable_scopes == tolist(["/subscriptions/00000000-0000-0000-0000-000000000002"])
    error_message = "The custom role must be defined and assignable only at the subscription."
  }

  assert {
    condition     = strcontains(azurerm_role_definition.act.description, "[act:binding=b1nd-ing_42]")
    error_message = "The custom role's description must carry the binding marker."
  }

  assert {
    condition     = strcontains(azurerm_role_definition.act.description, "[act:deployment-version=${output.deployment_version}]")
    error_message = "The custom role's description must carry the deployment version."
  }

  assert {
    condition     = toset(azurerm_role_definition.act.permissions[0].actions) == toset(jsondecode(file("permissions/custom-role-actions.json"))) && !contains(azurerm_role_definition.act.permissions[0].actions, "*/read")
    error_message = "Without permission groups the custom role holds exactly the core actions."
  }

  assert {
    condition = toset([for assignment in azurerm_role_assignment.builtin : assignment.role_definition_id]) == toset([
      "/subscriptions/00000000-0000-0000-0000-000000000002/providers/Microsoft.Authorization/roleDefinitions/4abbcc35-e782-43d8-92c5-2d3f1bd2253f",
      "/subscriptions/00000000-0000-0000-0000-000000000002/providers/Microsoft.Authorization/roleDefinitions/7f6c6a51-bcf8-42ba-9220-52d62157d7db",
      "/subscriptions/00000000-0000-0000-0000-000000000002/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7",
    ])
    error_message = "Without permission groups Reader and both AKS roles are assigned with subscription-scoped definition IDs."
  }

  assert {
    condition = alltrue([
      for assignment in concat(values(azurerm_role_assignment.builtin), [azurerm_role_assignment.custom]) :
      assignment.principal_id == var.service_principal_id && assignment.principal_type == "ServicePrincipal" && assignment.scope == "/subscriptions/00000000-0000-0000-0000-000000000002"
    ])
    error_message = "Every role goes to Act's service principal at the subscription."
  }

  assert {
    condition     = output.subscription_id == var.subscription_id && output.management_group_id == null && output.azure_tenant_id == "00000000-0000-0000-0000-000000000001"
    error_message = "The outputs identify the subscription and its tenant."
  }

  assert {
    condition     = output.ready && output.deployment_id == var.deployment_id && output.service_principal_id == var.service_principal_id
    error_message = "The outputs Act consumes pass the inputs through."
  }
}

run "permission_groups_move_reader_into_the_custom_role" {
  command = plan

  variables {
    permission_groups = { access_map = {}, kubernetes = {}, activity_logs = {}, entra_logs = {} }
  }

  assert {
    condition     = contains(azurerm_role_definition.act.permissions[0].actions, "*/read") && contains(azurerm_role_definition.act.permissions[0].actions, "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action")
    error_message = "With kubernetes the custom role holds */read and the AKS user credential action."
  }

  assert {
    condition     = keys(azurerm_role_assignment.builtin) == ["7f6c6a51-bcf8-42ba-9220-52d62157d7db"]
    error_message = "With kubernetes only AKS RBAC Reader is assigned as a built-in role."
  }
}

run "empty_permission_groups_keeps_access_map_only" {
  command = plan

  variables {
    permission_groups = {}
  }

  assert {
    condition     = contains(azurerm_role_definition.act.permissions[0].actions, "*/read") && !contains(azurerm_role_definition.act.permissions[0].actions, "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action")
    error_message = "access_map is always on; kubernetes is off when left out."
  }

  assert {
    condition     = length(azurerm_role_assignment.builtin) == 0
    error_message = "Without kubernetes no built-in role is assigned."
  }
}

run "keep_legacy_builtin_roles" {
  command = plan

  variables {
    permission_groups         = { access_map = {} }
    keep_legacy_builtin_roles = true
  }

  assert {
    condition     = length(azurerm_role_assignment.builtin) == 3
    error_message = "keep_legacy_builtin_roles keeps Reader and both AKS roles."
  }
}

run "assign_builtin_roles_off" {
  command = plan

  variables {
    assign_builtin_roles = false
  }

  assert {
    condition     = length(azurerm_role_assignment.builtin) == 0 && azurerm_role_assignment.custom.principal_id == var.service_principal_id
    error_message = "assign_builtin_roles = false assigns only the custom role."
  }
}

run "custom_role_name_override" {
  command = plan

  variables {
    custom_role_name = "act-reader"
  }

  assert {
    condition     = azurerm_role_definition.act.name == "act-reader" && output.custom_role_name == "act-reader"
    error_message = "custom_role_name names the custom role."
  }
}

run "both_scopes_fail" {
  command = plan

  variables {
    management_group_id = "contoso"
  }

  expect_failures = [azurerm_role_definition.act]
}

run "neither_scope_fails" {
  command = plan

  variables {
    subscription_id = null
  }

  expect_failures = [azurerm_role_definition.act]
}

run "bad_binding_marker_fails" {
  command = plan

  variables {
    binding_marker = "act:binding=b1nd"
  }

  expect_failures = [var.binding_marker]
}

run "binding_marker_with_spaces_fails" {
  command = plan

  variables {
    binding_marker = "[act:binding=a b]"
  }

  expect_failures = [var.binding_marker]
}

run "bad_deployment_id_fails" {
  command = plan

  variables {
    deployment_id = "not-a-uuid"
  }

  expect_failures = [var.deployment_id]
}

run "unknown_group_fails" {
  command = plan

  variables {
    permission_groups = { kubernetes = {}, network_logs = {} }
  }

  expect_failures = [azurerm_role_definition.act]
}

run "group_settings_fail" {
  command = plan

  variables {
    permission_groups = { kubernetes = { clusters = ["aks-1"] } }
  }

  expect_failures = [var.permission_groups]
}
