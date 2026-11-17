# Act module for Azure

Creates the Azure resources [Act](https://act.security) needs to read a subscription or a management group: a custom role `ActScannerRole-<deployment_id>` assignable only at that scope, and role assignments of it and the built-in roles to Act's service principal. Submodules add Act's Event Hub for activity logs, the tenant's Entra ID diagnostic setting and storage account resource logs. The modules use only the `azurerm` and `azuread` providers and create nothing in Act; registering the deployment with Act is covered in Act's documentation.

Its inputs are the onboarding values Act issues for the deployment (deployment ID, binding marker, Act's app and, for the tenant check, the consent link). Its outputs are what you register with Act afterwards. `deployment_id`, `azure_tenant_id`, `subscription_id`, `management_group_id`, `service_principal_id`, `scope`, `custom_role_id` and `ready` depend on the custom role and every assignment, so a resource that consumes them is created after the roles and destroyed before them.

| What | Module | Run it as |
| ---- | ------ | ---------------- |
| Check that Act's app is approved and find its service principal | `act-security/act/azurerm//modules/tenant` | Any identity that reads service principals in Microsoft Graph |
| Roles at one subscription | `act-security/act/azurerm` with `subscription_id` | Owner or User Access Administrator on the subscription |
| Roles at a management group and every subscription under it | `act-security/act/azurerm` with `management_group_id` | Owner or User Access Administrator on the management group |
| Act's Event Hub and the activity log of each subscription | `act-security/act/azurerm//modules/activity-logs` | Contributor and User Access Administrator on the subscription that holds the Event Hub |
| The tenant's Entra ID logs | `act-security/act/azurerm//modules/entra-logs` | Entra Security Administrator or Global Administrator |
| One storage account's resource logs | `act-security/act/azurerm//modules/storage-account-logs` | Monitoring Contributor on the storage account |

## Usage

An Entra administrator approves Act's app once per tenant with the consent link from Act. Until then, `tenant` fails the plan and prints that link and the role to ask for.

```hcl
module "act_tenant" {
  source  = "act-security/act/azurerm//modules/tenant"
  version = "~> 0.1"

  act_app_client_id = "00000000-0000-0000-0000-000000000000"
  consent_url       = "https://login.microsoftonline.com/organizations/adminconsent?client_id=00000000-0000-0000-0000-000000000000"
}

module "act" {
  source  = "act-security/act/azurerm"
  version = "~> 0.1"

  subscription_id      = "00000000-0000-0000-0000-000000000000"
  deployment_id        = "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
  binding_marker       = "[act:binding=example]"
  service_principal_id = module.act_tenant.service_principal_id
}
```

Set `management_group_id` instead of `subscription_id` to connect a management group. Pass `permission_groups` as Act's onboarding lists them; `activity_logs` and `entra_logs` are created by their submodules. See [`examples/`](examples) for a subscription and for a management group with logs.

`assign_builtin_roles = false` is for a scope where another deployment already assigns the built-in roles to Act's service principal, because Azure refuses a second identical assignment. Set it before the first apply and never change it afterwards.

## Compatibility

Terraform 1.5.7 or later, the AzureRM provider 4.x and, for `tenant`, the AzureAD provider 3.x. The modules have no provider blocks; configure `azurerm` with `features {}` and a subscription in the tenant. The tests in `tests/` use mock providers and need Terraform 1.7 or later.

## Permissions

Act's service principal gets these roles at the subscription or management group and nothing else: exactly what Act requests when you connect Azure from the Act console. The files in [`permissions/`](permissions) are the only source; the modules and this section are built from them, and CI fails when this section drifts from them. The custom role's description carries `[act:deployment-version=20261116-91ed635f]`.

### Custom role

`ActScannerRole-<deployment_id>`, assignable only at the connected scope. It always holds these 32 actions, listed in [`permissions/custom-role-actions.json`](permissions/custom-role-actions.json):

| Resource provider | Actions |
| ----------------- | ------- |
| `Microsoft.Authorization` | `Microsoft.Authorization/roleAssignmentScheduleInstances/read`, `Microsoft.Authorization/roleEligibilityScheduleInstances/read`, `Microsoft.Authorization/roleAssignmentSchedules/read`, `Microsoft.Authorization/roleEligibilitySchedules/read` |
| `Microsoft.Compute` | `Microsoft.Compute/virtualMachines/read`, `Microsoft.Compute/disks/read`, `Microsoft.Compute/snapshots/read` |
| `Microsoft.ContainerRegistry` | `Microsoft.ContainerRegistry/registries/read` |
| `Microsoft.ContainerService` | `Microsoft.ContainerService/managedClusters/read` |
| `Microsoft.DocumentDB` | `Microsoft.DocumentDB/databaseAccounts/read` |
| `Microsoft.Insights` | `Microsoft.Insights/metrics/read` |
| `Microsoft.KeyVault` | `Microsoft.KeyVault/vaults/read` |
| `Microsoft.Kubernetes` | `Microsoft.Kubernetes/connectedclusters/read` |
| `Microsoft.Management` | `Microsoft.Management/managementGroups/read` |
| `Microsoft.Network` | `Microsoft.Network/networkInterfaces/read`, `Microsoft.Network/publicIPAddresses/read`, `Microsoft.Network/virtualNetworks/read`, `Microsoft.Network/networkSecurityGroups/read`, `Microsoft.Network/loadBalancers/read` |
| `Microsoft.Sql` | `Microsoft.Sql/locations/capabilities/read`, `Microsoft.Sql/servers/databases/usages/read`, `Microsoft.Sql/servers/read`, `Microsoft.Sql/servers/databases/read` |
| `Microsoft.Storage` | `Microsoft.Storage/storageAccounts/read`, `Microsoft.Storage/storageAccounts/privateEndpointConnections/read`, `Microsoft.Storage/storageAccounts/inventoryPolicies/read` |
| `Microsoft.Web` | `Microsoft.Web/sites/read`, `Microsoft.Web/sites/config/read`, `Microsoft.Web/sites/config/list/Action`, `Microsoft.Web/sites/slots/config/list/Action`, `Microsoft.Web/hostingenvironments/sites/read`, `Microsoft.Web/serverfarms/sites/read` |

### Built-in roles

Without `permission_groups`, the module also assigns these built-in roles at the scope, listed in [`permissions/builtin-roles.json`](permissions/builtin-roles.json). Set `assign_builtin_roles = false` when another deployment on the scope already assigns them.

| Role | ID | Why |
| ---- | -- | --- |
| [Azure Kubernetes Service Cluster User Role](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles) | `4abbcc35-e782-43d8-92c5-2d3f1bd2253f` | Lists the user kubeconfig of AKS clusters, so Act can connect to them. |
| [Azure Kubernetes Service RBAC Reader](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles) | `7f6c6a51-bcf8-42ba-9220-52d62157d7db` | Reads Kubernetes objects inside AKS clusters that use Azure RBAC, except secrets. |
| [Reader](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles) | `acdd72a7-3385-48ef-bd42-f606fba81ae7` | Reads every resource in the scope, so Act can inventory what exists. |

### Permission groups

Set `permission_groups` to the groups Act's onboarding lists, each set to `{}`. Any map switches the root module to permission groups: `access_map` is always on, and the module assigns only the built-in roles the groups need (`keep_legacy_builtin_roles` keeps the others). An unknown group fails at plan.

| Group | What it grants | Created by | Custom role actions | Built-in roles |
| ----- | -------------- | ---------- | ------------------- | -------------- |
| `access_map` | **Access map.** Puts Reader's `*/read` in the custom role, so Act reads every resource through one role. | root module | `*/read` | none |
| `kubernetes` | **Kubernetes inside AKS clusters.** Lets Act fetch the user kubeconfig of AKS clusters and read the Kubernetes objects inside them. | root module | `Microsoft.ContainerService/managedClusters/listClusterUserCredential/action` | `Azure Kubernetes Service RBAC Reader` |
| `activity_logs` | **Activity logs.** Streams the activity log of every subscription in scope to Act's Event Hub, which Act reads as Azure Event Hubs Data Receiver. | [`modules/activity-logs`](modules/activity-logs) | none | none |
| `entra_logs` | **Entra ID logs.** Streams the tenant's Entra ID audit and sign-in logs to Act's Event Hub. | [`modules/entra-logs`](modules/entra-logs) | none | none |

### Microsoft Graph application permissions

Approving Act's app with Entra ID included grants it these application permissions in the tenant, listed in [`permissions/graph-app-roles.json`](permissions/graph-app-roles.json). An Entra administrator grants them through Act's consent link; no module here creates, grants or removes them.

| Permission | App role ID | Why |
| ---------- | ----------- | --- |
| [`Directory.Read.All`](https://learn.microsoft.com/graph/permissions-reference) | `7ab1d382-f21e-4acd-a863-ba3e13f7da61` | Reads users, groups, devices and the directory structure. |
| [`Application.Read.All`](https://learn.microsoft.com/graph/permissions-reference) | `9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30` | Reads app registrations and service principals, including their credential metadata. |
| [`RoleManagement.Read.All`](https://learn.microsoft.com/graph/permissions-reference) | `c7fbd983-d9aa-4fa7-84b8-17382c103bc4` | Reads Entra ID role definitions and assignments, including Privileged Identity Management. |
| [`Policy.Read.All`](https://learn.microsoft.com/graph/permissions-reference) | `246dd0d5-5bd0-4def-940b-0421030a5b68` | Reads Conditional Access and the other tenant policies. |
| [`AuditLog.Read.All`](https://learn.microsoft.com/graph/permissions-reference) | `b0afded3-3588-46d8-8b3d-9842eff778da` | Reads Entra ID audit and sign-in activity. |

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
| [azurerm_role_assignment.builtin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.custom](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_definition.act](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| binding\_marker | The binding marker from Act's onboarding values, `[act:binding=<value>]`. The custom role's description carries it, which is how Act matches the role to the deployment. | `string` | n/a | yes |
| deployment\_id | The deployment ID from Act's onboarding values. It names the custom role `ActScannerRole-<deployment_id>`. Keep it and the Terraform state for future updates. | `string` | n/a | yes |
| service\_principal\_id | Object ID of Act's service principal in this tenant, the principal that receives the roles. The `tenant` submodule outputs it. | `string` | n/a | yes |
| assign\_builtin\_roles | Assign the built-in roles to Act's service principal at the scope. Set to false only when another deployment on the same scope already assigns them, because Azure refuses a second identical assignment. Set it before the first apply and never change it: switching to false destroys assignments every deployment on the scope relies on. | `bool` | `true` | no |
| custom\_role\_name | Name of the custom role. Null uses `ActScannerRole-<deployment_id>`, the name Act looks for. | `string` | `null` | no |
| keep\_legacy\_builtin\_roles | With `permission_groups`, keep the Reader, AKS Cluster User and AKS RBAC Reader assignments of the original layout, also when `kubernetes` is off. Set it to true when a state that used the original layout switches to permission groups while other deployments share the scope. Ignored without `permission_groups`. | `bool` | `false` | no |
| management\_group\_id | The management group to connect, with every subscription under it. Set exactly one of `subscription_id` and `management_group_id`. | `string` | `null` | no |
| permission\_groups | The deployment's full set of permission groups, each set to {}: `access_map` (always on), `kubernetes`, `activity_logs` and `entra_logs`, as Act's onboarding lists them. Null keeps the original layout: the custom role plus Reader and the AKS roles as built-in assignments. Any map switches to permission groups: the custom role holds Reader's `*/read`, and with `kubernetes` also the AKS user credential action and an AKS RBAC Reader assignment. `activity_logs` and `entra_logs` change no role here; the `activity-logs` and `entra-logs` submodules create them. | `any` | `null` | no |
| subscription\_id | The subscription to connect. Set exactly one of `subscription_id` and `management_group_id`. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| azure\_tenant\_id | The Entra ID tenant the azurerm provider runs in. |
| custom\_role\_actions | The actions the custom role holds. |
| custom\_role\_id | Resource ID of the custom role definition. |
| custom\_role\_name | Name of the custom role definition. |
| deployment\_id | The deployment ID, passed through once every role exists. |
| deployment\_version | The Act deployment version this release grants, stamped on the custom role's description as `[act:deployment-version=<version>]`. |
| management\_group\_id | The connected management group, null for a subscription. |
| permissions\_hash | SHA-256 over the permission files of this release. Compare it across versions to see whether an upgrade changes what Act can read. |
| ready | Always true, and depends on the custom role and every assignment. Reference it, or any other output, from the Act resource that registers this deployment: Terraform then creates that resource after the roles and destroys it before them. |
| role\_assignment\_ids | Role assignment IDs by role name: the custom role and each built-in role. |
| scope | The ARM scope the roles are assigned at. |
| service\_principal\_id | Object ID of Act's service principal, the principal that holds the roles. |
| subscription\_id | The connected subscription, null for a management group. |