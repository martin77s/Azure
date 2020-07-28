<#

Script Name	: GetVMReport.ps1
Description	: List all Virtual Machines and some of their details
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/28
Keywords	: Azure, Automation, Runbook, Compute, VMs

#>

PARAM(
    [string] $ConnectionName = 'AzureRunAsConnection'
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))


try {

    Disable-AzContextAutosave –Scope Process | Out-Null

    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null

    $query = @'
Resources
| where type == "microsoft.compute/virtualmachines"
| extend vmSize = properties.hardwareProfile.vmSize
| extend os = properties.storageProfile.imageReference.offer
| extend sku = properties.storageProfile.imageReference.sku
| extend licenseType = properties.licenseType
| extend priority = properties.priority
| extend numDataDisks = array_length(properties.storageProfile.dataDisks)
| join kind=leftouter (
	resourcecontainers
	| where type == "microsoft.resources/subscriptions"
	| extend subscriptionName = tostring(name)
	| project subscriptionName, subscriptionId
) on subscriptionId
| project-away subscriptionId1
| project subscriptionName, subscriptionId, resourceGroup, vmName = name, location, vmSize, os, sku, licenseType, priority, numDataDisks, properties
'@

    $report = Search-AzGraph -Query $query
    $report
} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}