variable "storage_account_id" {
  description = "Resource ID of the storage account whose logs stream to Act. The azurerm provider must be configured for its subscription."
  type        = string

  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourceGroups/[^/]+/providers/Microsoft\\.Storage/storageAccounts/[a-z0-9]{3,24}$", var.storage_account_id))
    error_message = "storage_account_id must be a storage account resource ID."
  }
}

variable "eventhub_namespace_id" {
  description = "Resource ID of Act's Event Hub namespace in the storage account's region, the `namespace_id` output of the `activity-logs` submodule applied in that region. The settings write to its `act-cloud-events-resource-logs` hub through its Send-only `act-logs-writer` rule."
  type        = string

  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourcegroups/[^/]+/providers/microsoft\\.eventhub/namespaces/[^/]+$", var.eventhub_namespace_id))
    error_message = "eventhub_namespace_id must be an Event Hub namespace resource ID."
  }
}

variable "send_metrics" {
  description = "Also stream the account and service metrics alongside the logs."
  type        = bool
  default     = true
  nullable    = false
}
