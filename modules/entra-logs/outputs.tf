output "diagnostic_setting_id" {
  description = "Resource ID of the tenant's Entra ID diagnostic setting."
  value       = azurerm_monitor_aad_diagnostic_setting.act.id
}

output "diagnostic_setting_name" {
  description = "Name of the tenant's Entra ID diagnostic setting."
  value       = azurerm_monitor_aad_diagnostic_setting.act.name
}

output "log_categories" {
  description = "The Entra ID log categories the setting streams."
  value       = local.entra_log_categories
}
