# Storage account logs

Streams one storage account's resource logs to Act's Event Hub. It creates a diagnostic setting `act-cloud-events` on each data service the account kind has (blob, file, queue, table) with the `allLogs` category group and, when `send_metrics` is on, every metric category the target exposes, plus a metrics setting on the account itself. Every setting writes to the `act-cloud-events-resource-logs` hub through the namespace's Send-only `act-logs-writer` rule.

Azure streams a resource's logs only to an Event Hub in the same region, so pass the `namespace_id` of an `activity-logs` namespace in the storage account's region. Configure the `azurerm` provider for the storage account's subscription; the plan fails otherwise. The identity that applies needs Monitoring Contributor on the storage account and `Microsoft.EventHub/namespaces/authorizationRules/listKeys/action` on the `act-logs-writer` rule. A storage account allows at most five diagnostic settings, and Azure rejects a second setting named `act-cloud-events`.

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
| [azurerm_monitor_diagnostic_setting.account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_monitor_diagnostic_categories.target](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_diagnostic_categories) | data source |
| [azurerm_storage_account.target](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| eventhub\_namespace\_id | Resource ID of Act's Event Hub namespace in the storage account's region, the `namespace_id` output of the `activity-logs` submodule applied in that region. The settings write to its `act-cloud-events-resource-logs` hub through its Send-only `act-logs-writer` rule. | `string` | n/a | yes |
| storage\_account\_id | Resource ID of the storage account whose logs stream to Act. The azurerm provider must be configured for its subscription. | `string` | n/a | yes |
| send\_metrics | Also stream the account and service metrics alongside the logs. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| diagnostic\_setting\_ids | Diagnostic setting IDs this module manages, by target: `account`, `blob`, `file`, `queue` and `table`. |
| eventhub\_namespace\_id | Act's Event Hub namespace the logs stream to. |
| region | Region of the storage account. |