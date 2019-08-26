# Install the ResourceGraph module:
Install-Module -Name Az.ResourceGraph


# Get count of all resources:
Search-AzGraph -Query "summarize count()"


# Get count of all ARM VMs:
Search-AzGraph -Query "where type =~ 'Microsoft.Compute/virtualMachines' | summarize count()"


# Get count of all VMs (ARM and Classic):
Search-AzGraph -Query "where type == 'microsoft.compute/virtualmachines' or type == 'microsoft.classiccompute/virtualmachines' | summarize count()"


# Get count of VMs by OS:
Search-AzGraph -Query "where type =~ 'Microsoft.Compute/virtualMachines' | summarize count() by tostring(properties.storageProfile.osDisk.osType)"


# Get count of VMs by Size:
Search-AzGraph -Query "where type =~ 'Microsoft.Compute/virtualMachines' | project SKU = tostring(properties.hardwareProfile.vmSize)| summarize count() by SKU" | Format-Table


# Count resources by types per subscription:
Search-AzGraph -Query "summarize count() by type, subscriptionId | order by type, subscriptionId asc"


# List VMs that match a regex pattern:
Search-AzGraph -Query "where type =~ 'microsoft.compute/virtualmachines' and name matches regex @'^Contoso(.*)[0-9]+$' | project name | order by name asc"


# List all VMs not using managed disks:
Search-AzGraph -Query "where type =~ 'Microsoft.Compute/virtualMachines' | where isnull(properties.storageProfile.osDisk.managedDisk) | project name, resourceGroup, subscriptionId"


# List all the Public IP Addresses:
Search-AzGraph -Query "where type contains 'publicIPAddresses' and isnotempty(properties.ipAddress) | project properties.ipAddress"


# List WebApps:
Search-AzGraph -Query "where type=='microsoft.web/sites' | project name, subscriptionId, type | order by type, subscriptionId"


# List Storage accounts:
Search-AzureRmGraph -Query "where type=='microsoft.storage/storageaccounts' | project name, resourceGroup,subscriptionId"


# List Storage accounts that don't have encryption enabled:
Search-AzGraph -Query "where type =~ 'microsoft.storage/storageaccounts' | where aliases['Microsoft.Storage/storageAccounts/enableBlobEncryption'] =='false'| project name"
