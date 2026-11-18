# Entra ID logs

Creates the tenant's Entra ID diagnostic setting `act-cloud-events-<first 12 hex characters of deployment_id>`, which streams the `AuditLogs`, `SignInLogs`, `NonInteractiveUserSignInLogs`, `ServicePrincipalSignInLogs` and `ManagedIdentitySignInLogs` categories to the `act-cloud-events-entra-logs` hub of Act's Event Hub from the `activity-logs` submodule.

The setting writes through the namespace's `RootManageSharedAccessKey` rule, because Entra ID needs Manage, Send and Listen rights on it. The identity that applies needs the Security Administrator or Global Administrator role in Entra ID and `Microsoft.EventHub/namespaces/authorizationRules/listKeys/action` on that rule, for example Contributor on the namespace. If a setting with the same name already exists, the apply fails until you `terraform import` it.

## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.7 |
| azurerm | ~> 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| azurerm | ~> 4.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_monitor_aad_diagnostic_setting.act](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_aad_diagnostic_setting) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| deployment\_id | The deployment ID from Act's onboarding values. It names the diagnostic setting `act-cloud-events-<first 12 hex characters>`. | `string` | n/a | yes |
| eventhub\_namespace\_id | Resource ID of Act's Event Hub namespace, the `namespace_id` output of the `activity-logs` submodule. The setting writes to its `act-cloud-events-entra-logs` hub through `RootManageSharedAccessKey`. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| diagnostic\_setting\_id | Resource ID of the tenant's Entra ID diagnostic setting. |
| diagnostic\_setting\_name | Name of the tenant's Entra ID diagnostic setting. |
| log\_categories | The Entra ID log categories the setting streams. |