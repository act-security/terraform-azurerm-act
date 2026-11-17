variable "act_app_client_id" {
  description = "Client ID of Act's app, from Act's onboarding values."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.act_app_client_id))
    error_message = "act_app_client_id must be an app (client) ID."
  }
}

variable "consent_url" {
  description = "The admin consent link from Act's onboarding values. The plan prints it when Act's app is not approved in the tenant yet."
  type        = string

  validation {
    condition     = startswith(var.consent_url, "https://")
    error_message = "consent_url must be an https URL."
  }
}

variable "include_entra_id" {
  description = "Whether the deployment includes Entra ID. Approving Act's app with Entra ID grants it Microsoft Graph application permissions, which takes a Global Administrator or Privileged Role Administrator; without it an Application Administrator or Cloud Application Administrator can approve."
  type        = bool
  default     = true
  nullable    = false
}
