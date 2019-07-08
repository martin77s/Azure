    $connectionName = 'AzureRunAsConnection'
    $automationAccountName = 'AutoAdmin'
    $resourceGroupName = 'auto-rg'

    #region Login to Azure
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
