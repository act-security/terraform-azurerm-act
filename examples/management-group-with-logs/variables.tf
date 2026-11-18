variable "management_group_id" {
  description = "The management group to connect, with every subscription under it."
  type        = string
}

variable "events_subscription_id" {
  description = "The subscription that holds Act's Event Hub namespace, for example `00000000-0000-0000-0000-000000000000`. The azurerm provider runs in it."
  type        = string
}

variable "location" {
  description = "Azure region of Act's Event Hub namespace."
  type        = string
  default     = "westus"
}

variable "deployment_id" {
  description = "`deployment_id` from Act's onboarding values."
  type        = string
}

variable "binding_marker" {
  description = "`binding_marker` from Act's onboarding values, `[act:binding=<value>]`."
  type        = string
}

variable "act_app_client_id" {
  description = "`act_app_client_id` from Act's onboarding values."
  type        = string
}

variable "consent_url" {
  description = "`consent_url` from Act's onboarding values, the link an Entra administrator opens to approve Act's app."
  type        = string
}

variable "permission_groups" {
  description = "`permission_groups` from Act's onboarding values."
  type        = any
  default = {
    access_map    = {}
    kubernetes    = {}
    activity_logs = {}
    entra_logs    = {}
  }
}
