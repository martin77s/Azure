# KQL Queries


## All Azure Resources

```
summarize Resources=count()
```

- - - 

### Count of all Azure Subscriptions

```
resourcecontainers | where type =~ 'microsoft.resources/subscriptions' | summarize Subscriptions=count()
```

- - - 

### Azure Subscriptions by OfferId

```
resourcecontainers | where type =~ 'microsoft.resources/subscriptions' | extend quotaId = properties.subscriptionPolicies.quotaId | summarize Subscriptions=count() by tostring(quotaId)
```

- - - 

### Top subscriptions by Resource count

```
resources
| summarize ResourcesCount=count() by subscriptionId
| join (ResourceContainers | where type=='microsoft.resources/subscriptions' | project Subscription=name, subscriptionId) on subscriptionId
| project-away subscriptionId, subscriptionId1
| order by ResourcesCount desc
| limit 10
```

- - - 

### Top 10 resource counts by type

```
summarize ResourceCount=count() by type | order by ResourceCount | extend ['Resource count']=ResourceCount, ['Resource type']=type | project ['Resource type'], ['Resource count'] | take 10
```

- - - 

### Virtual machines count (includes classic)

```
where type == "microsoft.compute/virtualmachines" or type=="microsoft.classiccompute/virtualmachines" | summarize VMCount=count() | extend ['Count (Virtual Machines)']=VMCount | project ['Count (Virtual Machines)']
```

- - - 

### Virtual machines by operating system

```
where type == "microsoft.compute/virtualmachines" or type == "microsoft.classiccompute/virtualmachines" | extend OSType = iff(type == "microsoft.compute/virtualmachines", tostring(properties.storageProfile.osDisk.osType),tostring(properties.storageProfile.operatingSystemDisk.operatingSystem))  | summarize VMCount=count() by OSType | order by VMCount desc |extend ['Count (Virtual Machines)']=VMCount | project OSType, ['Count (Virtual Machines)']
```

- - - 

### Sum of all disk sizes (GB)

```
where type == "microsoft.compute/disks" | extend SizeGB = tolong(properties.diskSizeGB) | summarize ['Total Disk Size (GB)']=sum(SizeGB)
```

- - - 

### Disks (count) by disk state

```
where type == "microsoft.compute/disks" | summarize DiskCount=count() by State=tostring(properties.diskState) | order by DiskCount desc | extend ["Count (Disks)"]=DiskCount | project State, ["Count (Disks)"]
```

- - - 

### VM Report

```
Resources
| where type == "microsoft.compute/virtualmachines"
| extend vmSize = properties.hardwareProfile.vmSize
| extend os = properties.storageProfile.imageReference.offer
| extend sku = properties.storageProfile.imageReference.sku
| extend licenseType = properties.licenseType
| mvexpand nic = properties.networkProfile.networkInterfaces
| extend nicId = tostring(nic.id)
| project subscriptionId, resourceGroup, vmName = name, location, vmSize, os, sku, licenseType, nicId
| join kind=leftouter (
	Resources
	| where type == "microsoft.network/networkinterfaces"
	| mvexpand ipconfig=properties.ipConfigurations
	| extend privateIp = ipconfig.properties.privateIPAddress
    | project nicId = id, privateIp
) on nicId
| project-away nicId1
| project subscriptionId, resourceGroup, vmName, location, vmSize, os, sku, licenseType, privateIp
```