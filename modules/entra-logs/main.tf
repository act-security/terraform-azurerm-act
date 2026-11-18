locals {
  deployment12          = substr(replace(lower(var.deployment_id), "-", ""), 0, 12)
  entra_logs_hub        = "act-cloud-events-entra-logs"
  entra_log_categories  = ["AuditLogs", "SignInLogs", "NonInteractiveUserSignInLogs", "ServicePrincipalSignInLogs", "ManagedIdentitySignInLogs"]
  authorization_rule_id = "${var.eventhub_namespace_id}/authorizationRules/RootManageSharedAccessKey"
}

resource "azurerm_monitor_aad_diagnostic_setting" "act" {
  name                           = "act-cloud-events-${local.deployment12}"
  eventhub_authorization_rule_id = local.authorization_rule_id
  eventhub_name                  = local.entra_logs_hub

  dynamic "enabled_log" {
    for_each = local.entra_log_categories
    content {
      category = enabled_log.value
    }
  }
}
