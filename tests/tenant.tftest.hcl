mock_provider "azuread" {
  mock_data "azuread_service_principals" {
    defaults = {
      object_ids = ["00000000-0000-0000-0000-000000000004"]
    }
  }
}

variables {
  act_app_client_id = "00000000-0000-0000-0000-000000000005"
  consent_url       = "https://login.microsoftonline.com/organizations/adminconsent?client_id=00000000-0000-0000-0000-000000000005"
}

run "finds_acts_service_principal" {
  command = plan

  module {
    source = "./modules/tenant"
  }

  assert {
    condition     = output.service_principal_id == "00000000-0000-0000-0000-000000000004"
    error_message = "The module outputs the object ID of Act's service principal."
  }

  assert {
    condition     = data.azuread_service_principals.act.ignore_missing && data.azuread_service_principals.act.client_ids == tolist(["00000000-0000-0000-0000-000000000005"])
    error_message = "The lookup is by client ID and tolerates a missing service principal, so the postcondition can explain it."
  }

  assert {
    condition     = output.graph_app_roles["Directory.Read.All"] == "7ab1d382-f21e-4acd-a863-ba3e13f7da61" && length(output.graph_app_roles) == 5
    error_message = "With Entra ID the output lists the five Graph application permissions."
  }
}

run "without_entra_id_lists_no_graph_roles" {
  command = plan

  module {
    source = "./modules/tenant"
  }

  variables {
    include_entra_id = false
  }

  assert {
    condition     = length(output.graph_app_roles) == 0
    error_message = "Without Entra ID no Graph permission is granted."
  }
}

run "missing_service_principal_fails_at_plan" {
  command = plan

  module {
    source = "./modules/tenant"
  }

  override_data {
    target = data.azuread_service_principals.act
    values = {
      object_ids = []
    }
  }

  expect_failures = [data.azuread_service_principals.act]
}

run "consent_url_must_be_https" {
  command = plan

  module {
    source = "./modules/tenant"
  }

  variables {
    consent_url = "http://example.com"
  }

  expect_failures = [var.consent_url]
}
