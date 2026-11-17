variable "subscription_id" {
  description = "The subscription to connect, for example `00000000-0000-0000-0000-000000000000`."
  type        = string
}

variable "deployment_id" {
  description = "`deployment_id` from Act's onboarding values."
  type        = string
}

variable "binding_marker" {
  description = "`binding_marker` from Act's onboarding values, `[act:binding=<value>]`."
  type        = string
}

variable "service_principal_id" {
  description = "Object ID of Act's service principal in the tenant, the `service_principal_id` output of the `tenant` submodule."
  type        = string
}

variable "permission_groups" {
  description = "`permission_groups` from Act's onboarding values, for example `{ access_map = {}, kubernetes = {} }`. Null keeps the original role layout."
  type        = any
  default     = null
}
