variable "deployment_id" {
  description = "The deployment ID from Act's onboarding values. It names the namespace and its resource group, and tags the namespace `act:connection-id` so Act finds it."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", var.deployment_id))
    error_message = "deployment_id must be a UUIDv4."
  }
}

variable "service_principal_id" {
  description = "Object ID of Act's service principal. It receives Azure Event Hubs Data Receiver on the namespace."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.service_principal_id))
    error_message = "service_principal_id must be the service principal's object ID."
  }
}

variable "location" {
  description = "Azure region of the namespace, such as `westus`. Resource logs stream only to an Event Hub in the resource's own region."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location takes an Azure region name such as westus."
  }
}

variable "subscription_ids" {
  description = "Subscriptions whose activity log streams to the namespace."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for id in var.subscription_ids : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))])
    error_message = "subscription_ids takes subscription IDs."
  }
}

variable "management_group_id" {
  description = "A management group whose subscriptions all stream their activity log to the namespace. Subscriptions added to it later are covered on the next apply."
  type        = string
  default     = null

  validation {
    condition     = var.management_group_id == null || can(regex("^[A-Za-z0-9_().-]{1,90}$", var.management_group_id))
    error_message = "management_group_id must be a management group ID."
  }
}

variable "resource_group_name" {
  description = "Resource group for the namespace. Null uses `act-cloud-events-<first 12 hex characters of deployment_id>-rg`."
  type        = string
  default     = null
}

variable "create_resource_group" {
  description = "Create the resource group in `location`. Set to false to use an existing group."
  type        = bool
  default     = true
  nullable    = false
}

variable "namespace_name" {
  description = "Name of the Event Hub namespace, global across Azure. Null uses `act-events-<location>-<first 12 hex characters of deployment_id>`."
  type        = string
  default     = null

  validation {
    condition     = var.namespace_name == null || can(regex("^[a-zA-Z][a-zA-Z0-9-]{4,48}[a-zA-Z0-9]$", var.namespace_name))
    error_message = "namespace_name must be 6-50 letters, numbers and hyphens, start with a letter and end with a letter or number."
  }
}

variable "lock_namespace" {
  description = "Put a CanNotDelete management lock on the namespace, so nothing outside this state deletes it or its hubs. Terraform removes the lock before it destroys the namespace."
  type        = bool
  default     = true
  nullable    = false
}

variable "tags" {
  description = "Tags for the resource group and namespace. Act's `act:purpose` and `act:connection-id` tags take precedence."
  type        = map(string)
  default     = {}
  nullable    = false
}
