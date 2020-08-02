<#

Script Name	: Set-AzStorageAccountRequireSecureTransfer.ps1
Description	: Set the 'supportsHttpsTrafficOnly' to true on the storage account(s)
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/08/02
Keywords	: Azure, StorageAccount, SecureTransfer

#>
PARAM(
    [string] $SubscriptionId = $null,
    [string] $ExcludeStorageAccountNamePattern = $null
)

if ([string]::IsNullOrEmpty($SubscriptionId)) {
    $SubscriptionId = (Get-AzContext).Subscription.Id
}


$query = @'
Resources | where type =~ 'Microsoft.Storage/storageAccounts' and
subscriptionId == '{0}' and
properties.supportsHttpsTrafficOnly == false and
isempty(properties.customDomain)
| project id, subscriptionId, resourceGroup, name
'@ -f $SubscriptionId

$results = Search-AzGraph -Query $query
if (-not [string]::IsNullOrEmpty($ExcludeStorageAccountNamePattern)) {
    $resources = $results | Where-Object { $_.name -notmatch $ExcludeStorageAccountNamePattern }
} else {
    $resources = $results
}

foreach ($res in $resources) {
    $storage = Get-AzStorageAccount -ResourceGroupName $res.resourceGroup -Name $res.name
    if ($storage) {
        Set-AzStorageAccount -ResourceGroupName $storage.ResourceGroupName -AccountName $storage.StorageAccountName -EnableHttpsTrafficOnly $true
    }
}