mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_data "azurerm_storage_account" {
    defaults = {
      account_kind = "StorageV2"
      location     = "westus"
    }
  }

  mock_data "azurerm_monitor_diagnostic_categories" {
    defaults = {
      metrics = ["Transaction"]
    }
  }
}

variables {
  deployment_id         = "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
  eventhub_namespace_id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/act-cloud-events-5a7e2c1d3b4f-rg/providers/Microsoft.EventHub/namespaces/act-events-westus-5a7e2c1d3b4f"
  storage_account_id    = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/data/providers/Microsoft.Storage/storageAccounts/contosodata"
}

run "entra_logs_stream_to_the_entra_hub" {
  command = plan

  module {
    source = "./modules/entra-logs"
  }

  assert {
    condition     = azurerm_monitor_aad_diagnostic_setting.act.name == "act-cloud-events-5a7e2c1d3b4f" && azurerm_monitor_aad_diagnostic_setting.act.eventhub_name == "act-cloud-events-entra-logs"
    error_message = "The Entra ID setting is named as Act's deploy command names it and writes to the entra-logs hub."
  }

  assert {
    condition     = azurerm_monitor_aad_diagnostic_setting.act.eventhub_authorization_rule_id == "${var.eventhub_namespace_id}/authorizationRules/RootManageSharedAccessKey"
    error_message = "Entra ID diagnostic settings need a rule with Manage, Send and Listen."
  }

  assert {
    condition     = length(azurerm_monitor_aad_diagnostic_setting.act.enabled_log) == 5
    error_message = "The setting streams the five Entra ID log categories Act reads."
  }
}

run "entra_logs_bad_namespace_fails" {
  command = plan

  module {
    source = "./modules/entra-logs"
  }

  variables {
    eventhub_namespace_id = "act-events-westus-5a7e2c1d3b4f"
  }

  expect_failures = [var.eventhub_namespace_id]
}

run "storage_account_logs_cover_every_service" {
  command = plan

  module {
    source = "./modules/storage-account-logs"
  }

  assert {
    condition     = toset(keys(azurerm_monitor_diagnostic_setting.service)) == toset(["blob", "file", "queue", "table"]) && length(azurerm_monitor_diagnostic_setting.account) == 1
    error_message = "A StorageV2 account gets a setting per service and one for account metrics."
  }

  assert {
    condition = alltrue([
      for setting in azurerm_monitor_diagnostic_setting.service :
      setting.eventhub_name == "act-cloud-events-resource-logs" && setting.eventhub_authorization_rule_id == "${var.eventhub_namespace_id}/authorizationRules/act-logs-writer"
    ])
    error_message = "Resource logs go to the resource-logs hub through the Send-only act-logs-writer rule."
  }
}

run "storage_account_logs_blob_only_without_metrics" {
  command = plan

  module {
    source = "./modules/storage-account-logs"
  }

  variables {
    send_metrics = false
  }

  override_data {
    target = data.azurerm_storage_account.target
    values = {
      account_kind = "BlockBlobStorage"
      location     = "westus"
    }
  }

  assert {
    condition     = keys(azurerm_monitor_diagnostic_setting.service) == ["blob"] && length(azurerm_monitor_diagnostic_setting.account) == 0
    error_message = "A BlockBlobStorage account without metrics gets only the blob setting."
  }
}

run "storage_account_logs_need_the_accounts_subscription" {
  command = plan

  module {
    source = "./modules/storage-account-logs"
  }

  override_data {
    target = data.azurerm_client_config.current
    values = {
      subscription_id = "00000000-0000-0000-0000-000000000009"
    }
  }

  expect_failures = [data.azurerm_storage_account.target]
}
