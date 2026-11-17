provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}

module "act" {
  source = "../.."

  subscription_id      = var.subscription_id
  deployment_id        = var.deployment_id
  binding_marker       = var.binding_marker
  service_principal_id = var.service_principal_id
  permission_groups    = var.permission_groups
}
