# Tenant

Finds Act's service principal in the tenant by the client ID of Act's app and outputs its object ID for the other modules. It creates, changes and destroys nothing, and never grants Microsoft Graph permissions.

An Entra administrator approves Act's app once per tenant with the consent link from Act. With Entra ID included, that takes a Global Administrator or Privileged Role Administrator, because approval grants Microsoft Graph application permissions; without it, an Application Administrator or Cloud Application Administrator can approve. Until the app is approved, the plan fails with the consent link and the role to ask for.

The identity that runs the plan needs to read service principals in Microsoft Graph. A signed-in user can; a service principal needs `Application.Read.All`.

## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.7 |
| azuread | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| azuread | ~> 3.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [azuread_service_principals.act](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principals) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| act\_app\_client\_id | Client ID of Act's app, from Act's onboarding values. | `string` | n/a | yes |
| consent\_url | The admin consent link from Act's onboarding values. The plan prints it when Act's app is not approved in the tenant yet. | `string` | n/a | yes |
| include\_entra\_id | Whether the deployment includes Entra ID. Approving Act's app with Entra ID grants it Microsoft Graph application permissions, which takes a Global Administrator or Privileged Role Administrator; without it an Application Administrator or Cloud Application Administrator can approve. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| graph\_app\_roles | The Microsoft Graph application permissions, by name, that approving Act's app grants when the deployment includes Entra ID. The module never grants them. |
| service\_principal\_id | Object ID of Act's service principal in this tenant. Pass it to `service_principal_id` of the root module and the log submodules. |