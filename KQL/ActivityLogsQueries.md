# ActivityLogs KQL Queries


## All Subscriptions

```
AzureActivity | summarize by SubscriptionId
```

- - - 

## Active Resource Groups

### Subscriptions with new deployments

```
AzureActivity 
| extend Name = strcat("/", SubscriptionId, "/", ResourceGroup)
| where OperationNameValue == "Microsoft.Resources/deployments/write"
| where ActivityStatus == "Succeeded"
| summarize Count = count() by SubscriptionId, ResourceGroup, Name
| order by SubscriptionId, Count
```

- - - 

## Idle Subscriptions

### Subscriptions without successful write activities in the last month

```
AzureActivity | where TimeGenerated < ago(12m) | summarize by SubscriptionId
| join kind=leftouter (
    AzureActivity | where TimeGenerated < ago(1m)
    | where OperationNameValue endswith "write" 
    | where ActivityStatus == "Succeeded" 
    | project SubscriptionId, CorrelationId
) on SubscriptionId
| where isempty(CorrelationId)
| project SubscriptionId
```