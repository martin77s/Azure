<#

Script Name	: IdentifyPublicContainers.ps1
Description	: List all storage account containers with public anonymous access
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/28
Keywords	: Azure, Automation, Runbook, Storage, Containers

#>

PARAM(
    [string] $ConnectionName = 'AzureRunAsConnection',
    [string] $SubscriptionNamePattern = '.*'
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))


try {

    Disable-AzContextAutosave –Scope Process | Out-Null

    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null

    $subscriptions = @(Get-AzSubscription | Where-Object { ($_.Name -match $SubscriptionNamePattern) -and ($_.State -eq 'Enabled') })

    $report = foreach ($subscription in $subscriptions) {

        Set-AzContext -SubscriptionId $subscription.Id -TenantId $servicePrincipalConnection.TenantId -Force | Out-Null

        foreach ($account in (Get-AzStorageAccount)) {
            try {
                Get-AzStorageContainer -Context $account.Context | Where-Object { $_.PublicAccess -ne 'Off' } |
                    Select-Object @{N = 'SubscriptionId'; E = { ($account.Id -split '/')[2] } }, @{N = 'ResourceGroupName'; E = { $account.ResourceGroupName } },
                    @{N = 'StorageAccount'; E = { $account.StorageAccountName } }, @{N = 'ContainerName'; E = { $_.Name } },
                    @{N = 'ItemCount'; E = { (Get-AzStorageBlob -Container $_.Name -Context $_.Context).Count } },
                    PublicAccess, LastModified
            } catch {}
        }
    }
    $report
} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}