# Graph KQL Queries


## All Azure Resources

```code
summarize Resources=count()
```

- - - 

### Count of all Azure Subscriptions

```code
resourcecontainers | where type =~ 'microsoft.resources/subscriptions' | summarize Subscriptions=count()
```

- - - 

### Azure Subscriptions by OfferId

```code
resourcecontainers | where type =~ 'microsoft.resources/subscriptions' | extend quotaId = properties.subscriptionPolicies.quotaId | summarize Subscriptions=count() by tostring(quotaId)
```

- - - 

### Top subscriptions by Resource count

```code
resources
| summarize ResourcesCount=count() by subscriptionId
| join (ResourceContainers | where type=='microsoft.resources/subscriptions' | project Subscription=name, subscriptionId) on subscriptionId
| project-away subscriptionId, subscriptionId1
| order by ResourcesCount desc
| limit 10
```

- - - 

### Top 10 resource counts by type

```code
summarize ResourceCount=count() by type | order by ResourceCount | extend ['Resource count']=ResourceCount, ['Resource type']=type | project ['Resource type'], ['Resource count'] | take 10
```

- - - 

### Virtual machines count (includes classic)

```code
where type == "microsoft.compute/virtualmachines" or type=="microsoft.classiccompute/virtualmachines" | summarize VMCount=count() | extend ['Count (Virtual Machines)']=VMCount | project ['Count (Virtual Machines)']
```

- - - 

### Virtual machines by operating system

```code
where type == "microsoft.compute/virtualmachines" or type == "microsoft.classiccompute/virtualmachines" | extend OSType = iff(type == "microsoft.compute/virtualmachines", tostring(properties.storageProfile.osDisk.osType),tostring(properties.storageProfile.operatingSystemDisk.operatingSystem))  | summarize VMCount=count() by OSType | order by VMCount desc |extend ['Count (Virtual Machines)']=VMCount | project OSType, ['Count (Virtual Machines)']
```

- - - 

### Sum of all disk sizes (GB)

```code
where type == "microsoft.compute/disks" | extend SizeGB = tolong(properties.diskSizeGB) | summarize ['Total Disk Size (GB)']=sum(SizeGB)
```

- - - 

### Disks (count) by disk state

```code
where type == "microsoft.compute/disks" | summarize DiskCount=count() by State=tostring(properties.diskState) | order by DiskCount desc | extend ["Count (Disks)"]=DiskCount | project State, ["Count (Disks)"]
```

- - - 

### VM Report

```code
Resources
| where type == "microsoft.compute/virtualmachines"
| extend vmSize = properties.hardwareProfile.vmSize
| extend os = properties.storageProfile.imageReference.offer
| extend sku = properties.storageProfile.imageReference.sku
| extend licenseType = properties.licenseType
| extend priority = properties.priority
| mvexpand nic = properties.networkProfile.networkInterfaces
| extend nicId = tostring(nic.id)
| extend numOfDataDisks = array_length(properties.storageProfile.dataDisks)
| extend powerState = replace('PowerState/', '', tostring(properties.extended.instanceView.powerState.code))
| project subscriptionId, resourceGroup, id = name, location, powerState, vmSize, os, sku, licenseType, nicId, priority, numOfDataDisks
| join kind=leftouter (
	Resources
	| where type == "microsoft.network/networkinterfaces"
	| mvexpand ipconfig=properties.ipConfigurations
	| extend privateIp = ipconfig.properties.privateIPAddress
    | project nicId = id, privateIp
) on nicId
| project-away nicId1
| project subscriptionId, resourceGroup, id, location, powerState, vmSize, os, sku, licenseType, privateIp, priority, numOfDataDisks
```

- - - 

### VMs and private IPs Report

```code
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

- - - 

### Advisor Digest - Cost

```code
advisorresources
| where properties.category == "Cost"
| extend Category = properties.category
| extend Impact = properties.impact
| extend ResourceType = properties.impactedField
| extend ResourceValue = properties.impactedValue
| extend Problem = properties.shortDescription.problem
| extend Solution = properties.shortDescription.solution
| project id,Category,Impact,ResourceType,ResourceValue,Problem,Solution
```

- - - 

### Virtual Machine AutoShutdown Extension Status

```code
resources
| where type == "microsoft.compute/virtualmachines"
| join kind=leftouter (resources 
	| where type == "microsoft.devtestlab/schedules" 
	| extend state = tostring(properties.provisioningState) 
	| extend id = tostring(properties.targetResourceId) 
	| project id, state) on id 
| extend Status = case((state) =~ "", "Not Enabled", state)
| summarize count() by Status
| extend Count = count_
| project Status, Count
```

- - - 

### Virtual Machines without AutoShutdown

```code
resources
| where type == "microsoft.compute/virtualmachines"
| join kind=leftouter (resources 
	| where type == "microsoft.devtestlab/schedules" 
	| extend state = tostring(properties.provisioningState) 
	| extend id = tostring(properties.targetResourceId) 
	| project id, state) on id 
| where isempty(state) 
| project-away id1, state 
| project subscriptionId, resourceGroup, id
```

- - - 

### Storage Accounts without HttpsTrafficOnly, FileEncryption or BlobEncryption

```code
resources
| where type == "microsoft.storage/storageaccounts" 
| where aliases["Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly"] == "false" 
	or aliases["Microsoft.Storage/storageAccounts/enableFileEncryption"] == "false"
	or aliases["Microsoft.Storage/storageAccounts/enableBlobEncryption"] == "false"
| project id, subscriptionId, resourceGroup, name, kind
```

- - - 

### Virtual Networks and their Address Prefixes

```code
Resources 
| where type == 'microsoft.network/virtualnetworks' 
| project Name = name, id, Prefixes = properties.addressSpace.addressPrefixes, subscriptionId, resourceGroup
| join kind = inner (
	ResourceContainers 
	| where type=='microsoft.resources/subscriptions' 
	| project Subscription=name, subscriptionId
) on subscriptionId 
| order by Subscription asc
| project subscriptionId, resourceGroup, id, Name, AddressPrefix=Prefixes 
```

- - - 

### Subnets and their Address Prefixes

```code
Resources 
| where type == 'microsoft.network/virtualnetworks' 
| mvexpand subnets = properties.subnets
| project subscriptionId, resourceGroup, id, ['Subnet name'] = subnets.name, AddressPrefix = tostring(subnets.properties.addressPrefix)
| sort by AddressPrefix asc
```

- - - 

### Virtual Network Peerings

```code
Resources
| where type =~ 'Microsoft.Network/virtualNetworks'
| extend peering=properties.virtualNetworkPeerings
| where array_length(peering) > 0
| mvexpand peering
| extend AllowVirtualNetworkAccess = peering.properties.allowVirtualNetworkAccess
| extend AllowForwardedTraffic = peering.properties.allowForwardedTraffic
| extend AllowGatewayTransit = peering.properties.allowGatewayTransit
| extend UseRemoteGateways = peering.properties.useRemoteGateways
| extend PeeringState = peering.properties.peeringState
| extend RemoteVirtualNetwork = split(peering.properties.remoteVirtualNetwork.id, '/')[8]
| project subscriptionId, resourceGroup, id, RemoteVirtualNetwork, AllowVirtualNetworkAccess, AllowForwardedTraffic, AllowGatewayTransit, UseRemoteGateways
```

- - - 

### Public IPs Addresses

```code
resources
| where type =~ 'microsoft.network/publicipaddresses' or type =~ "microsoft.classicnetwork/reservedips"
| extend DeploymentType = iif(type == "microsoft.classicnetwork/reservedips", "Classic", "ARM")
| extend AttachedTo = iff(type == "microsoft.classicnetwork/reservedips", 
	split(properties.attachedTo.id, '/')[8], 
	split(properties.ipConfiguration.id, '/')[8]
)
| project subscriptionId, resourceGroup, id, DeploymentType, ['IP Address']=properties.ipAddress, SKU=sku.name, ['Allocation Method']=properties.publicIPAllocationMethod, AttachedTo
```

- - - 

### Virtual Machines with Public IPs

```code
Resources
| where type =~ 'microsoft.compute/virtualmachines'
| extend nics=array_length(properties.networkProfile.networkInterfaces)
| mv-expand nic=properties.networkProfile.networkInterfaces
| where nics == 1 or nic.properties.primary =~ 'true' or isempty(nic)
| project vmId = id, vmName = name, vmSize=tostring(properties.hardwareProfile.vmSize), nicId = tostring(nic.id), subscriptionId, resourceGroup
| join kind=leftouter (
	Resources
	| where type =~ 'microsoft.network/networkinterfaces'
	| extend ipConfigsCount=array_length(properties.ipConfigurations)
	| mv-expand ipconfig=properties.ipConfigurations
	| where ipConfigsCount == 1 or ipconfig.properties.primary =~ 'true'
	| project nicId = id, publicIpId = tostring(ipconfig.properties.publicIPAddress.id)
) on nicId
| project-away nicId1
| summarize by subscriptionId, resourceGroup, publicIpId, vmId, vmName, nicId
| join kind=leftouter (
	Resources
	| where type =~ 'microsoft.network/publicipaddresses'
	| project publicIpId = id, publicIpAddress = properties.ipAddress
) on publicIpId
| project-away publicIpId1
| where isnotempty(publicIpId)
| project subscriptionId, resourceGroup, id=publicIpId, ['IP Address']=publicIpAddress, ['VM Name']=vmName, vmId, nicId
```

- - - 

### Orphan Disks

```code
resources
| where type == "microsoft.compute/disks"
| where isempty(managedBy) and id notcontains "-ASRReplica"
| project subscriptionId, resourceGroup, id, ["Sku"]=sku.name, location, tags
```

- - - 

### Orphan Network Interfaces

```code
resources
| where type == "microsoft.network/networkinterfaces"
| where isempty(managedBy)
| project subscriptionId, resourceGroup, id, location, tags
```

- - - 

### Orphan Public IPs

```code
resources
| where type =~ 'microsoft.network/publicipaddresses' or type =~ "microsoft.classicnetwork/reservedips"
| extend DeploymentType = iif(type == "microsoft.classicnetwork/reservedips", "Classic", "ARM")
| extend AttachedTo = iff(type == "microsoft.classicnetwork/reservedips", 
	split(properties.attachedTo.id, '/')[8], 
	split(properties.ipConfiguration.id, '/')[8]
)
| where isempty(AttachedTo)
| project subscriptionId, resourceGroup, id, DeploymentType, ['IP Address']=properties.ipAddress, location
```

- - - 

### Orphan Resource Groups

```code
ResourceContainers
 | where type == "microsoft.resources/subscriptions/resourcegroups"
 | extend rgAndSub = strcat(resourceGroup, "--", subscriptionId)
 | join kind=leftouter (
     Resources
     | extend rgAndSub = strcat(resourceGroup, "--", subscriptionId)
     | summarize count() by rgAndSub
 ) on rgAndSub
 | where isnull(count_)
 | project-away rgAndSub1, count_
 | project subscriptionId, id,  location, tags
```

- - - 

### Orphan NSGs

```code
Resources
| where type == "microsoft.network/networksecuritygroups" and isnull(properties.networkInterfaces) and isnull(properties.subnets)
| project subscriptionId, resourceGroup, id, location, tags
```

- - - 

### Orphan Availabity Sets

```code
where type =~ 'Microsoft.Compute/availabilitySets'
| where properties.virtualMachines == "[]"
| project subscriptionId, resourceGroup, id, location, tags
```


- - - 

### Private IPs report

```code
resources 
| where type =~ 'microsoft.network/loadbalancers' or type =~ 'microsoft.network/applicationgateways' or type =~ 'microsoft.network/azurefirewalls'
| mvexpand ipconfig = iif(type == 'microsoft.network/azurefirewalls', properties.ipConfigurations, properties.frontendIPConfigurations)
| extend privateIp = tostring(ipconfig.properties.privateIPAddress)
| union ( resources
	| where type =~ 'microsoft.compute/virtualmachines'
	| mv-expand nic = properties.networkProfile.networkInterfaces
	| project id, type, nicId = tostring(nic.id), subscriptionId, resourceGroup
	| join kind=leftouter (
		resources
		| where type =~ 'microsoft.network/networkinterfaces'
		| mv-expand ipconfig = properties.ipConfigurations
		| extend nicId = id, privateIp = tostring(ipconfig.properties.privateIPAddress)
	) on nicId
) 
| where isnotempty(privateIp)
| project subscriptionId, resourceGroup, id, type, privateIp
```

