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

    $subscriptions = @{ }
    Get-AzSubscription | ForEach-Object { $subscriptions += @{ [string]($_.Id) = $_.Name} }

    $query = @'
    Resources
    | where type == "microsoft.compute/virtualmachines"
    | extend vmSize = properties.hardwareProfile.vmSize
    | extend os = properties.storageProfile.imageReference.offer
    | extend sku = properties.storageProfile.imageReference.sku
    | extend licenseType = properties.licenseType
    | extend priority = properties.priority
    | extend numDataDisks = array_length(properties.storageProfile.dataDisks)
    | project subscriptionId, resourceGroup, vmName = name, location, vmSize, os, sku, licenseType, priority, numDataDisks, properties
'@

    $report = Search-AzGraph -Query $query | Select-Object @{N = 'SubscriptionName'; E = { $subscriptions[$_.subscriptionId] } },
        subscriptionId, resourceGroup, vmName, location, vmSize, os, sku, licenseType, priority, numDataDisks

    $report
} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}