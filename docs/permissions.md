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
