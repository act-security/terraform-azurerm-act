output "diagnostic_setting_ids" {
  description = "Diagnostic setting IDs this module manages, by target: `account`, `blob`, `file`, `queue` and `table`."
  value = merge(
    { for service, setting in azurerm_monitor_diagnostic_setting.service : service => setting.id },
    { for setting in azurerm_monitor_diagnostic_setting.account : "account" => setting.id },
  )
}

output "eventhub_namespace_id" {
  description = "Act's Event Hub namespace the logs stream to."
  value       = var.eventhub_namespace_id
}

output "region" {
  description = "Region of the storage account."
  value       = data.azurerm_storage_account.target.location
}
