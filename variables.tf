variable "deployment_id" {
  description = "The deployment ID from Act's onboarding values. It names the custom role `ActScannerRole-<deployment_id>`. Keep it and the Terraform state for future updates."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", var.deployment_id))
    error_message = "deployment_id must be a UUIDv4."
  }
}

variable "binding_marker" {
  description = "The binding marker from Act's onboarding values, `[act:binding=<value>]`. The custom role's description carries it, which is how Act matches the role to the deployment."
  type        = string

  validation {
    condition     = can(regex("^\\[act:binding=[A-Za-z0-9_-]+\\]$", var.binding_marker))
    error_message = "binding_marker must look like [act:binding=<letters, digits, _ or ->]."
  }
}

variable "service_principal_id" {
  description = "Object ID of Act's service principal in this tenant, the principal that receives the roles. The `tenant` submodule outputs it."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.service_principal_id))
    error_message = "service_principal_id must be the service principal's object ID."
  }
}

variable "subscription_id" {
  description = "The subscription to connect. Set exactly one of `subscription_id` and `management_group_id`."
  type        = string
  default     = null

  validation {
    condition     = var.subscription_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a subscription ID."
  }
}

variable "management_group_id" {
  description = "The management group to connect, with every subscription under it. Set exactly one of `subscription_id` and `management_group_id`."
  type        = string
  default     = null

  validation {
    condition     = var.management_group_id == null || can(regex("^[A-Za-z0-9_().-]{1,90}$", var.management_group_id))
    error_message = "management_group_id must be a management group ID."
  }
}

variable "permission_groups" {
  description = "The deployment's full set of permission groups, each set to {}: `access_map` (always on), `kubernetes`, `activity_logs` and `entra_logs`, as Act's onboarding lists them. Null keeps the original layout: the custom role plus Reader and the AKS roles as built-in assignments. Any map switches to permission groups: the custom role holds Reader's `*/read`, and with `kubernetes` also the AKS user credential action and an AKS RBAC Reader assignment. `activity_logs` and `entra_logs` change no role here; the `activity-logs` and `entra-logs` submodules create them."
  type        = any
  default     = null

  validation {
    condition     = var.permission_groups == null || try(alltrue([for settings in values(var.permission_groups) : length(keys(settings)) == 0]), false)
    error_message = "permission_groups must be a map of groups, each set to {}, for example { kubernetes = {} }."
  }
}

variable "assign_builtin_roles" {
  description = "Assign the built-in roles to Act's service principal at the scope. Set to false only when another deployment on the same scope already assigns them, because Azure refuses a second identical assignment. Set it before the first apply and never change it: switching to false destroys assignments every deployment on the scope relies on."
  type        = bool
  default     = true
  nullable    = false
}

variable "keep_legacy_builtin_roles" {
  description = "With `permission_groups`, keep the Reader, AKS Cluster User and AKS RBAC Reader assignments of the original layout, also when `kubernetes` is off. Set it to true when a state that used the original layout switches to permission groups while other deployments share the scope. Ignored without `permission_groups`."
  type        = bool
  default     = false
  nullable    = false
}

variable "custom_role_name" {
  description = "Name of the custom role. Null uses `ActScannerRole-<deployment_id>`, the name Act looks for."
  type        = string
  default     = null
}
