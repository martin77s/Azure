<#

Script Name	: SpendingLimitReachedMG.ps1
Description	: Add a resource read-only lock on all subscriptions under the specified Management Group and optionally shutdown all VMs in the subscription
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/21
Keywords	: Azure, ACM, Budget, Automation, Runbook

#>


PARAM (
    [string] $ConnectionName = 'AzureRunAsConnection',
    [Parameter(Mandatory)] [string] $ManagementGroupName,
    [boolean] $DeallocateVMs = $false,
    [string] $LockNote = 'Spending limit reached. Please check your budget and contact the account owner'
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))

function Get-AzSubscriptionsFromManagementGroup {
    param($ManagementGroupName)
    $mg = Get-AzManagementGroup -GroupName $ManagementGroupName -Expand
    foreach ($child in $mg.Children) {
        if ($child.Type -match '/managementGroups$') {
            Get-AzSubscriptionsFromManagementGroup -ManagementGroupName $child.Name
        } else {
            $child | Select-Object @{N = 'Name'; E = { $_.DisplayName } }, @{N = 'Id'; E = { $_.Name } }
        }
    }
}

try {

    # Authenticate to ARM
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    $null = Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    $subscriptions = @(Get-AzSubscriptionsFromManagementGroup -ManagementGroupName $ManagementGroupName)
    Write-Output ("Found {0} subscription(s) under the '{1}' Management Group" -f $subscriptions.Count, $ManagementGroupName)

    foreach ($subscription in $subscriptions) {

        if ($DeallocateVMs) {

            # Set the context
            $null = Set-AzContext -SubscriptionId $subscription.Id -Force

            # Set the Resource Graph query
            $query = @'
resources
| where subscriptionId == '{0}'
| where type == 'microsoft.compute/virtualmachines' or type == 'microsoft.compute/virtualmachinescalesets'
'@ -f $subscription.Id

            # Query Azure Resource Graph for all tagged VMs and their thresholds
            $VMs = Search-AzGraph -Query $query
            foreach ($vm in $VMs) {
                Write-Output ("Stopping {0}\{1}" -f $_.ResourceGroup, $_.Name)
                Stop-AzVM -ResourceGroupName $_.ResourceGroup -Name $_.Name -Force -NoWait
            }
        }

        # Add the read-only resource lock on the subscription
        Set-AzResourceLock -LockLevel ReadOnly -LockNotes $LockNote -LockName 'SpendingLimitReached' -Scope ("/subscriptions/$($subscription.Id)") -Force
    }

} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
