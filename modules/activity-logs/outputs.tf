output "namespace_id" {
  description = "Resource ID of the Event Hub namespace, known once its hubs, rules, Act's access and the lock exist. Pass it to `eventhub_namespace_id` of the `entra-logs` and `storage-account-logs` submodules."
  value       = azurerm_eventhub_namespace.act.id

  depends_on = [
    azurerm_eventhub.act,
    azurerm_eventhub_namespace_authorization_rule.logs_writer,
    azurerm_role_assignment.receiver,
    azurerm_management_lock.namespace,
  ]
}

output "namespace_name" {
  description = "Name of the Event Hub namespace."
  value       = azurerm_eventhub_namespace.act.name
}

output "resource_group_name" {
  description = "Resource group holding the namespace."
  value       = azurerm_eventhub_namespace.act.resource_group_name
}

output "eventhub_names" {
  description = "The cloud-events hubs in the namespace, by log type."
  value       = { for log_type, hub in azurerm_eventhub.act : log_type => hub.name }
}

output "logs_writer_rule_id" {
  description = "The Send-only `act-logs-writer` rule resource diagnostic settings write through."
  value       = azurerm_eventhub_namespace_authorization_rule.logs_writer.id
}

output "root_manage_rule_id" {
  description = "The namespace's `RootManageSharedAccessKey` rule, which the activity log and Entra ID diagnostic settings write through."
  value       = local.root_manage_rule_id
}

output "activity_log_setting_ids" {
  description = "The activity log diagnostic setting on each subscription, by subscription ID."
  value       = { for subscription_id, setting in azurerm_monitor_diagnostic_setting.activity_logs : subscription_id => setting.id }
}

output "lock_id" {
  description = "Resource ID of the management lock on the namespace, null when `lock_namespace` is false."
  value       = one(azurerm_management_lock.namespace[*].id)
}
