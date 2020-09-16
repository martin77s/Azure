# Azure AD Users Activity KQL Queries


## User SignIns blocked by Conditional Access

```
SigninLogs | where ConditionalAccessStatus == "failure" 
| extend AuthMethod = MfaDetail.authMethod
| extend AdditionalDetails = Status.additionalDetails
| extend ErrorCode = Status.errorCode
| extend Location = strcat(LocationDetails.countryOrRegion, ', ', LocationDetails.state, ', ', LocationDetails.city)
| summarize Count = dcount(Id) by UserDisplayName, AppDisplayName, tostring(AuthMethod), tostring(AdditionalDetails), tostring(ErrorCode), tostring(Location) 
| sort by Count, UserDisplayName, AppDisplayName desc
| project Count, UserDisplayName, AppDisplayName, ErrorCode, AuthMethod, AdditionalDetails, Location
```

- - - 

## User SignIns by City

```
SigninLogs | where AppDisplayName !="" | where Location !="" 
| extend Country = tostring(LocationDetails.countryOrRegion) 
| extend State = tostring(LocationDetails.state) 
| extend City = tostring(LocationDetails.city) 
| summarize LoginCount = count() by City, State, Country | sort by LoginCount desc
```

- - - 

## User SignIns by Application

```
SigninLogs | summarize LoginCount = count() by AppDisplayName| sort by LoginCount desc
```

- - - 

## User SignIns by Client

```
SigninLogs
| extend OS= DeviceDetail.operatingSystem
| extend Browser =extract("([a-zA-Z]+)",1,tostring(DeviceDetail.browser))
| where OS!=""
| where Browser !=""
| where AppDisplayName !=""
| summarize LoginCount=count() by tostring(Browser)
| sort by LoginCount desc
```

- - - 

## Users that never signed in (365 days)

```
AuditLogs | where TimeGenerated > ago(365d)
| where OperationName == "Add user"
| extend addID_ = tostring(TargetResources[0].id)
| join kind=anti (AuditLogs
    | where OperationName == "Delete user"
    | extend deleteID_ = tostring(TargetResources[0].id)) on $left.addID_ == $right.deleteID_
| extend upn = tostring(TargetResources[0].userPrincipalName)
| join kind=leftouter (SigninLogs) on $left.upn == $right.UserPrincipalName
| extend signed = isnotempty(UserPrincipalName)
| project upn, signed
```

- - - 