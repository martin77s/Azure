# ActivityLogs KQL Queries

## Subscriptions with new deployments

```kql
AzureActivity
| where OperationNameValue == "Microsoft.Resources/deployments/write"
| where ActivityStatus == "Succeeded"
| summarize Count = count() by SubscriptionId, ResourceGroup
| order by SubscriptionId, Count
```

- - -

## Subscriptions without successful write activities in the last month

```kql
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

- - -

## Policy Assignment changes

```kql
AzureActivity
| where ActivityStatusValue == "Start" and OperationNameValue contains "MICROSOFT.AUTHORIZATION/POLICYASSIGNMENTS"
| extend Operation = strcat_array(split(OperationNameValue, "/", 2),"")
| extend request = parse_json(tostring(parse_json(tostring(parse_json(Properties).requestbody)))).properties
| extend role = tostring(parse_json(Authorization).evidence.role)
| extend policyAssignmentId = parse_json(Properties).entity
| project TimeGenerated, CallerIpAddress, Caller, CallerRole = role, Operation, policyAssignmentId,
    PolicyDisplayName = request.displayName,
    PolicyDefinitionId = request.policyDefinitionId,
    PolicyParameters = request.parameters,
    PolicyScope = request.scope,
    PolicyEnforcementMode = request.enforcementMode
```
