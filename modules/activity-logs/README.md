# Activity logs

Creates Act's Event Hub: a namespace `act-events-<location>-<first 12 hex characters of deployment_id>` tagged `act:purpose = cloud-events` and `act:connection-id = <deployment_id>`, which is how Act finds it, the four `act-cloud-events-{resource,activity,entra,vnet-flow}-logs` hubs, a Send-only `act-logs-writer` rule for resource diagnostic settings, and Azure Event Hubs Data Receiver for Act's service principal. It then streams the activity log of each subscription in `subscription_ids` and under `management_group_id` to the activity-logs hub, with a diagnostic setting `act-cloud-events-<first 12 hex characters>` on each.

The namespace goes in its own resource group, `act-cloud-events-<first 12 hex characters>-rg` unless `resource_group_name` names another; set `create_resource_group = false` to use an existing group. By default a `CanNotDelete` management lock keeps anything outside this state from deleting the namespace or its hubs; Terraform removes the lock before it destroys the namespace, so set `lock_namespace = false` only when another tool manages locks.

Configure the `azurerm` provider for the subscription that holds the namespace. The identity that applies needs Contributor and User Access Administrator (or Role Based Access Control Administrator) there, Monitoring Contributor on each streamed subscription, and read access to the management group. The module only creates its own settings: if a setting with the same name already exists on a subscription, for example from Act's deploy command, the apply fails until you `terraform import` it. Destinations added to these settings outside Terraform are left alone.

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
| [azurerm_eventhub.act](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub_namespace.act](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_eventhub_namespace_authorization_rule.logs_writer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace_authorization_rule) | resource |
| [azurerm_management_lock.namespace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_monitor_diagnostic_setting.activity_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_resource_group.act](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.receiver](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_management_group.scope](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/management_group) | data source |
| [azurerm_resource_group.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| deployment\_id | The deployment ID from Act's onboarding values. It names the namespace and its resource group, and tags the namespace `act:connection-id` so Act finds it. | `string` | n/a | yes |
| location | Azure region of the namespace, such as `westus`. Resource logs stream only to an Event Hub in the resource's own region. | `string` | n/a | yes |
| service\_principal\_id | Object ID of Act's service principal. It receives Azure Event Hubs Data Receiver on the namespace. | `string` | n/a | yes |
| create\_resource\_group | Create the resource group in `location`. Set to false to use an existing group. | `bool` | `true` | no |
| lock\_namespace | Put a CanNotDelete management lock on the namespace, so nothing outside this state deletes it or its hubs. Terraform removes the lock before it destroys the namespace. | `bool` | `true` | no |
| management\_group\_id | A management group whose subscriptions all stream their activity log to the namespace. Subscriptions added to it later are covered on the next apply. | `string` | `null` | no |
| namespace\_name | Name of the Event Hub namespace, global across Azure. Null uses `act-events-<location>-<first 12 hex characters of deployment_id>`. | `string` | `null` | no |
| resource\_group\_name | Resource group for the namespace. Null uses `act-cloud-events-<first 12 hex characters of deployment_id>-rg`. | `string` | `null` | no |
| subscription\_ids | Subscriptions whose activity log streams to the namespace. | `set(string)` | `[]` | no |
| tags | Tags for the resource group and namespace. Act's `act:purpose` and `act:connection-id` tags take precedence. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| activity\_log\_setting\_ids | The activity log diagnostic setting on each subscription, by subscription ID. |
| eventhub\_names | The cloud-events hubs in the namespace, by log type. |
| lock\_id | Resource ID of the management lock on the namespace, null when `lock_namespace` is false. |
| logs\_writer\_rule\_id | The Send-only `act-logs-writer` rule resource diagnostic settings write through. |
| namespace\_id | Resource ID of the Event Hub namespace, known once its hubs, rules, Act's access and the lock exist. Pass it to `eventhub_namespace_id` of the `entra-logs` and `storage-account-logs` submodules. |
| namespace\_name | Name of the Event Hub namespace. |
| resource\_group\_name | Resource group holding the namespace. |
| root\_manage\_rule\_id | The namespace's `RootManageSharedAccessKey` rule, which the activity log and Entra ID diagnostic settings write through. |