<#

Script Name	: BaseTemplate.ps1
Description	:
Author		: Martin Schvartzman, Microsoft
Last Update	: 0000/00/00
Keywords	: Azure, Automation, Runbook

#>

PARAM(
    [string] $ConnectionName = 'AzureRunAsConnection'
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))


try {

	Disable-AzContextAutosave –Scope Process

    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    $connection = Connect-AzureAD -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null

    $tenantId = $servicePrincipalConnection.TenantId
    Write-Output ('Working on tenant: {0}' -f $tenantId)
    Write-Output ('Working with ApplicationId: {0}' -f $servicePrincipalConnection.ApplicationId)


} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
