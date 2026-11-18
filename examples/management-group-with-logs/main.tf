provider "azuread" {}

provider "azurerm" {
  features {}
  subscription_id                 = var.events_subscription_id
  resource_provider_registrations = "none"
}

module "tenant" {
  source = "../../modules/tenant"

  act_app_client_id = var.act_app_client_id
  consent_url       = var.consent_url
}

module "act" {
  source = "../.."

  management_group_id  = var.management_group_id
  deployment_id        = var.deployment_id
  binding_marker       = var.binding_marker
  service_principal_id = module.tenant.service_principal_id
  permission_groups    = var.permission_groups
}

module "activity_logs" {
  source = "../../modules/activity-logs"

  deployment_id        = var.deployment_id
  service_principal_id = module.tenant.service_principal_id
  location             = var.location
  management_group_id  = var.management_group_id
}

module "entra_logs" {
  source = "../../modules/entra-logs"

  deployment_id         = var.deployment_id
  eventhub_namespace_id = module.activity_logs.namespace_id
}
