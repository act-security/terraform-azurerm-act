variable "deployment_id" {
  description = "The deployment ID from Act's onboarding values. It names the diagnostic setting `act-cloud-events-<first 12 hex characters>`."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", var.deployment_id))
    error_message = "deployment_id must be a UUIDv4."
  }
}

variable "eventhub_namespace_id" {
  description = "Resource ID of Act's Event Hub namespace, the `namespace_id` output of the `activity-logs` submodule. The setting writes to its `act-cloud-events-entra-logs` hub through `RootManageSharedAccessKey`."
  type        = string

  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourcegroups/[^/]+/providers/microsoft\\.eventhub/namespaces/[^/]+$", var.eventhub_namespace_id))
    error_message = "eventhub_namespace_id must be an Event Hub namespace resource ID."
  }
}
