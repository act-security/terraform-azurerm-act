locals {
  deployment12        = substr(replace(lower(var.deployment_id), "-", ""), 0, 12)
  namespace_name      = coalesce(var.namespace_name, "act-events-${var.location}-${local.deployment12}")
  resource_group_name = coalesce(var.resource_group_name, "act-cloud-events-${local.deployment12}-rg")
  setting_name        = "act-cloud-events-${local.deployment12}"

  cloud_events_hubs = {
    resource_logs  = "act-cloud-events-resource-logs"
    activity_logs  = "act-cloud-events-activity-logs"
    entra_logs     = "act-cloud-events-entra-logs"
    vnet_flow_logs = "act-cloud-events-vnet-flow-logs"
  }
  partition_count        = 32
  message_retention_days = 7
  maximum_throughput     = 20

  activity_log_categories = ["Administrative", "Security", "ServiceHealth", "Alert", "Recommendation", "Policy", "Autoscale", "ResourceHealth"]
  subscription_ids = toset(concat(
    [for id in var.subscription_ids : lower(id)],
    [for id in try(data.azurerm_management_group.scope[0].all_subscription_ids, []) : lower(id)],
  ))

  tags = merge(var.tags, {
    "act:purpose"       = "cloud-events"
    "act:connection-id" = lower(var.deployment_id)
  })

  root_manage_rule_id = "${azurerm_eventhub_namespace.act.id}/authorizationRules/RootManageSharedAccessKey"
}

resource "azurerm_resource_group" "act" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1

  name = local.resource_group_name
}

resource "azurerm_eventhub_namespace" "act" {
  name                     = local.namespace_name
  resource_group_name      = var.create_resource_group ? azurerm_resource_group.act[0].name : data.azurerm_resource_group.existing[0].name
  location                 = var.location
  sku                      = "Standard"
  capacity                 = 1
  auto_inflate_enabled     = true
  maximum_throughput_units = local.maximum_throughput
  minimum_tls_version      = "1.2"
  tags                     = local.tags
}

resource "azurerm_eventhub" "act" {
  for_each = local.cloud_events_hubs

  name              = each.value
  namespace_id      = azurerm_eventhub_namespace.act.id
  partition_count   = local.partition_count
  message_retention = local.message_retention_days
}

resource "azurerm_eventhub_namespace_authorization_rule" "logs_writer" {
  name                = "act-logs-writer"
  namespace_name      = azurerm_eventhub_namespace.act.name
  resource_group_name = azurerm_eventhub_namespace.act.resource_group_name
  send                = true
  listen              = false
  manage              = false
}

resource "azurerm_role_assignment" "receiver" {
  scope                            = azurerm_eventhub_namespace.act.id
  role_definition_name             = "Azure Event Hubs Data Receiver"
  principal_id                     = var.service_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_management_lock" "namespace" {
  count = var.lock_namespace ? 1 : 0

  name       = "act-cloud-events"
  scope      = azurerm_eventhub_namespace.act.id
  lock_level = "CanNotDelete"
  notes      = "Act reads cloud events from this namespace."

  depends_on = [azurerm_eventhub.act, azurerm_eventhub_namespace_authorization_rule.logs_writer, azurerm_role_assignment.receiver]
}

data "azurerm_management_group" "scope" {
  count = var.management_group_id == null ? 0 : 1

  name = var.management_group_id
}

resource "azurerm_monitor_diagnostic_setting" "activity_logs" {
  for_each = local.subscription_ids

  name                           = local.setting_name
  target_resource_id             = "/subscriptions/${each.key}"
  eventhub_authorization_rule_id = local.root_manage_rule_id
  eventhub_name                  = azurerm_eventhub.act["activity_logs"].name

  dynamic "enabled_log" {
    for_each = local.activity_log_categories
    content {
      category = enabled_log.value
    }
  }

  lifecycle {
    ignore_changes = [storage_account_id, log_analytics_workspace_id, log_analytics_destination_type, partner_solution_id]
  }

  depends_on = [azurerm_role_assignment.receiver]
}
