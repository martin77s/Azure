<#

Script Name	: SpendingLimitReached.ps1
Description	: Add a resource read-only lock on a subscription and optionally shutdown all VMs in the subscription
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/06
Keywords	: Azure, ACM, Budget, Automation, Runbook

#>


PARAM (
    [string] $ConnectionName = 'AzureRunAsConnection',
    [Parameter(Mandatory)] [string] $SubscriptionId,
    [boolean] $DeallocateVMs = $false,
    [string] $LockNote = 'Spending limit reached. Please check your budget and contact the account owner'
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))

try {

    # Authenticate to ARM
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    $null = Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    if($DeallocateVMs) {
    # Set the Resource Graph query
        $query = @'
resources
| where subscriptionId == '{0}'
| where type == 'microsoft.compute/virtualmachines' or type == 'microsoft.compute/virtualmachinescalesets'
'@ -f $SubscriptionId

        # Query Azure Resource Graph for all tagged VMs and their thresholds
        $VMs = Search-AzGraph -Query $query
        foreach ($vm in $VMs) {
            Write-Output ("Stopping {0}\{1}" -f $_.ResourceGroup, $_.Name)
            Stop-AzVM -ResourceGroupName $_.ResourceGroup -Name $_.Name -Force -NoWait
        }
    }

    # Add the read-only resource lock on the subscription
    Set-AzResourceLock -LockName SpendingLimitReached -SubscriptionId $SubscriptionId -Level ReadOnly -Note $LockNote

} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
