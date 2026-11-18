locals {
  graph_app_roles = jsondecode(file("${path.module}/../../permissions/graph-app-roles.json"))
  consent_admin_roles = (
    var.include_entra_id
    ? "a Global Administrator or Privileged Role Administrator"
    : "an Application Administrator or Cloud Application Administrator"
  )
}

data "azuread_service_principals" "act" {
  client_ids     = [var.act_app_client_id]
  ignore_missing = true

  lifecycle {
    postcondition {
      condition     = length(self.object_ids) == 1
      error_message = "Act's app ${var.act_app_client_id} has no service principal in this tenant yet. Ask ${local.consent_admin_roles} to approve it at ${var.consent_url}, then plan again."
    }
  }
}
