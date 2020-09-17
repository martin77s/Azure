<#

Script Name	: Add-ResourceLockByType.ps1
Description	: Add a resource lock to all the resources from a given type
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/09/17
Keywords	: Azure, Governance, ResourceLock

#>

PARAM(
    [string] $SubscriptionId = $null,
    [string] $ResourceType = 'Microsoft.KeyVault/vaults',
    [ValidateSet('ReadOnly', 'CanNotDelete')] [string] $LockLevel = 'CanNotDelete',
    [string] $LockNote = 'Governance Lock',
    [string] $LockName = 'Governance'
)

if ($null -eq $SubscriptionId) {
    $subscriptions = Get-AzSubscription
} elseif ($SubscriptionId -eq ((Get-AzContext).Subscription.Id)) {
    $subscriptions = (Get-AzContext).Subscription
} else {
    $subscriptions = Get-AzSubscription -SubscriptionId $subscriptionId
}

foreach ($subscription in $subscriptions) {

    # Set the context
    if ($subscription.Id -ne ((Get-AzContext).Subscription.Id)) {
        $null = Set-AzContext -SubscriptionId $subscription.Id -Force
    }

    # Set the Resource Graph query
    $query = "resources | where subscriptionId == '{0}' and type =~ '{1}'" -f $subscription.Id, $ResourceType

    # Query Azure Resource Graph for all tagged VMs and their thresholds
    $resources = Search-AzGraph -Query $query
    foreach ($resource in $resources) {

        # Add the lock on the resource
        if(Set-AzResourceLock -LockLevel $LockLevel -LockNotes $LockNote -LockName $LockName -Scope $resource.ResourceId -Force) {
            Write-Output ("`tA '{0}' lock was added on {1}\{2}" -f $LockLevel, $resource.resourceGroup, $resource.name)
        }
    }
}

