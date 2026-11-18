mock_provider "azurerm" {
  mock_data "azurerm_management_group" {
    defaults = {
      all_subscription_ids = ["00000000-0000-0000-0000-00000000000a", "00000000-0000-0000-0000-00000000000b"]
    }
  }
}

variables {
  deployment_id        = "5A7E2C1D-3B4F-4A6E-8C9D-0E1F2A3B4C5D"
  service_principal_id = "00000000-0000-0000-0000-000000000004"
  location             = "westus"
}

run "creates_acts_namespace_with_a_lock" {
  command = plan

  module {
    source = "./modules/activity-logs"
  }

  assert {
    condition     = azurerm_eventhub_namespace.act.name == "act-events-westus-5a7e2c1d3b4f" && azurerm_resource_group.act[0].name == "act-cloud-events-5a7e2c1d3b4f-rg"
    error_message = "The namespace and its group are named as Act's deploy command names them."
  }

  assert {
    condition     = azurerm_eventhub_namespace.act.tags["act:purpose"] == "cloud-events" && azurerm_eventhub_namespace.act.tags["act:connection-id"] == "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
    error_message = "Act finds the namespace by its act:purpose and act:connection-id tags."
  }

  assert {
    condition     = toset([for hub in azurerm_eventhub.act : hub.name]) == toset(["act-cloud-events-resource-logs", "act-cloud-events-activity-logs", "act-cloud-events-entra-logs", "act-cloud-events-vnet-flow-logs"])
    error_message = "The namespace carries the four cloud-events hubs."
  }

  assert {
    condition     = azurerm_eventhub_namespace_authorization_rule.logs_writer.send && !azurerm_eventhub_namespace_authorization_rule.logs_writer.listen && !azurerm_eventhub_namespace_authorization_rule.logs_writer.manage
    error_message = "act-logs-writer is Send-only."
  }

  assert {
    condition     = azurerm_role_assignment.receiver.role_definition_name == "Azure Event Hubs Data Receiver" && azurerm_role_assignment.receiver.principal_id == var.service_principal_id
    error_message = "Act's service principal reads the namespace as Azure Event Hubs Data Receiver."
  }

  assert {
    condition     = length(azurerm_management_lock.namespace) == 1 && azurerm_management_lock.namespace[0].lock_level == "CanNotDelete"
    error_message = "The namespace is locked by default."
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.activity_logs) == 0
    error_message = "Without subscriptions no activity log setting is created."
  }
}

run "lock_off" {
  command = plan

  module {
    source = "./modules/activity-logs"
  }

  variables {
    lock_namespace = false
  }

  assert {
    condition     = length(azurerm_management_lock.namespace) == 0 && output.lock_id == null
    error_message = "lock_namespace = false creates no lock."
  }
}

run "streams_every_subscription_under_the_management_group" {
  command = plan

  module {
    source = "./modules/activity-logs"
  }

  variables {
    management_group_id = "contoso"
    subscription_ids    = ["00000000-0000-0000-0000-00000000000C", "00000000-0000-0000-0000-00000000000a"]
  }

  assert {
    condition     = toset(keys(azurerm_monitor_diagnostic_setting.activity_logs)) == toset(["00000000-0000-0000-0000-00000000000a", "00000000-0000-0000-0000-00000000000b", "00000000-0000-0000-0000-00000000000c"])
    error_message = "Every subscription under the management group and every listed one gets one setting."
  }

  assert {
    condition = alltrue([
      for id, setting in azurerm_monitor_diagnostic_setting.activity_logs :
      setting.target_resource_id == "/subscriptions/${id}" && setting.name == "act-cloud-events-5a7e2c1d3b4f" && setting.eventhub_name == "act-cloud-events-activity-logs"
    ])
    error_message = "Each setting streams the subscription's activity log to the activity-logs hub."
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.activity_logs["00000000-0000-0000-0000-00000000000a"].enabled_log) == 8
    error_message = "Each setting streams the eight activity log categories Act reads."
  }
}

run "existing_resource_group" {
  command = plan

  module {
    source = "./modules/activity-logs"
  }

  variables {
    create_resource_group = false
    resource_group_name   = "shared-logs"
  }

  override_data {
    target = data.azurerm_resource_group.existing[0]
    values = {
      name = "shared-logs"
    }
  }

  assert {
    condition     = length(azurerm_resource_group.act) == 0 && azurerm_eventhub_namespace.act.resource_group_name == "shared-logs"
    error_message = "create_resource_group = false puts the namespace in the existing group."
  }
}
