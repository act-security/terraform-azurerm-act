mock_provider "azurerm" {}

variables {
  deployment_id        = "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
  binding_marker       = "[act:binding=b1nd]"
  service_principal_id = "00000000-0000-0000-0000-000000000004"
  management_group_id  = "contoso"
}

run "grants_the_roles_at_the_management_group" {
  command = plan

  assert {
    condition     = azurerm_role_definition.act.scope == "/providers/Microsoft.Management/managementGroups/contoso" && azurerm_role_definition.act.assignable_scopes == tolist(["/providers/Microsoft.Management/managementGroups/contoso"])
    error_message = "The custom role must be defined and assignable only at the management group."
  }

  assert {
    condition     = alltrue([for assignment in concat(values(azurerm_role_assignment.builtin), [azurerm_role_assignment.custom]) : assignment.scope == "/providers/Microsoft.Management/managementGroups/contoso"])
    error_message = "Every role is assigned at the management group."
  }

  assert {
    condition     = alltrue([for id, assignment in azurerm_role_assignment.builtin : assignment.role_definition_id == "/providers/Microsoft.Authorization/roleDefinitions/${id}"])
    error_message = "Built-in roles at a management group use tenant-level definition IDs."
  }

  assert {
    condition     = strcontains(azurerm_role_definition.act.description, "[act:binding=b1nd]") && strcontains(azurerm_role_definition.act.description, "[act:deployment-version=")
    error_message = "The custom role's description must carry the binding marker and the deployment version."
  }

  assert {
    condition     = output.management_group_id == "contoso" && output.subscription_id == null
    error_message = "The outputs identify the management group."
  }
}

run "bad_management_group_id_fails" {
  command = plan

  variables {
    management_group_id = "has spaces"
  }

  expect_failures = [var.management_group_id]
}
