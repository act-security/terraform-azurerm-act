data "azurerm_client_config" "current" {}

locals {
  account_id_parts        = split("/", var.storage_account_id)
  account_subscription_id = lower(local.account_id_parts[2])
  account_resource_group  = local.account_id_parts[4]
  account_name            = local.account_id_parts[8]

  eventhub_name  = "act-cloud-events-resource-logs"
  setting_name   = "act-cloud-events"
  writer_rule_id = "${var.eventhub_namespace_id}/authorizationRules/act-logs-writer"

  account_kind = data.azurerm_storage_account.target.account_kind
  services = (
    contains(["BlobStorage", "BlockBlobStorage"], local.account_kind) ? ["blob"]
    : local.account_kind == "FileStorage" ? ["file"]
    : ["blob", "file", "queue", "table"]
  )
  targets = merge(
    { account = var.storage_account_id },
    { for service in local.services : service => "${var.storage_account_id}/${service}Services/default" },
  )
}

data "azurerm_storage_account" "target" {
  name                = local.account_name
  resource_group_name = local.account_resource_group

  lifecycle {
    precondition {
      condition     = lower(data.azurerm_client_config.current.subscription_id) == local.account_subscription_id
      error_message = "Configure the azurerm provider for subscription ${local.account_subscription_id}, the storage account's subscription."
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "target" {
  for_each = local.targets

  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "service" {
  for_each = toset(local.services)

  name                           = local.setting_name
  target_resource_id             = local.targets[each.value]
  eventhub_name                  = local.eventhub_name
  eventhub_authorization_rule_id = local.writer_rule_id

  enabled_log {
    category_group = "allLogs"
  }

  dynamic "enabled_metric" {
    for_each = var.send_metrics ? data.azurerm_monitor_diagnostic_categories.target[each.value].metrics : []
    content {
      category = enabled_metric.value
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "account" {
  count = var.send_metrics ? 1 : 0

  name                           = local.setting_name
  target_resource_id             = var.storage_account_id
  eventhub_name                  = local.eventhub_name
  eventhub_authorization_rule_id = local.writer_rule_id

  dynamic "enabled_metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.target["account"].metrics
    content {
      category = enabled_metric.value
    }
  }
}
