PARAM(
    [string] $SubscriptionNamePattern = 'maschvar.*',
    [string] $ConnectionName = 'AzureRunAsConnection',
    [string] $ExcludeResourceGroupNames = '^cloud-shell-storage-(\w+)|^DefaultResourceGroup-(\w+)|^AzureBackupRG_(\+w)_(\d+)|^NetworkWatcherRG|^VstsRG-(\w+)-\w{4}',
    [string] $SendToEmailAddress = $null
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))


try {

    # Login to Azure
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    $null = Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    # Login to AzureAD
    $null = Connect-AzureAD -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    $orphanResourceGroups = @()

    # Iterate all subscriptions and get all resource groups
    $allResourceGroups = Get-AzSubscription | Where-Object { $_.Name -match $SubscriptionNamePattern } | ForEach-Object {
        Write-Verbose ('Switching to subscription: {0}' -f $_.Name) -Verbose
        $null = Set-AzContext -SubscriptionId $_.SubscriptionId -Tenant $servicePrincipalConnection.TenantId -Force
        Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -notmatch $excludeResourceGroupNames } |
            Select-Object ResourceGroupName, @{N = 'IsOrphan'; E = { $true } }, @{N = 'TaggedOwner'; E = { $_.Tags.Owner } }
    }

    # Verify the owners exist in azure Active Directory (by DisplayName or UPN)
    $owners = $allResourceGroups | Where-Object { $_.TaggedOwner } | Group-Object TaggedOwner -NoElement | Select-Object Name, @{N = 'Exists'; E = { $false } }
    foreach ($owner in $owners) {
        $exists = $(
            try {
                if ($owner.Name -match '@') {
                    Get-AzureADUser -ObjectId $owner.Name -ErrorAction SilentlyContinue |
                        Where-Object { @($_.DisplayName, $_.UserPrincipalName) -contains $owner.Name }
                } else {
                    Get-AzureADUser -SearchString $owner.Name -ErrorAction SilentlyContinue |
                        Where-Object { @($_.DisplayName, $_.UserPrincipalName) -contains $owner.Name }
                }
            } catch {
                Write-Output ($_.Exception.Message)
                $false
            }
        )
        $allResourceGroups | Where-Object { $_.TaggedOwner -eq $owner.Name } | ForEach-Object {
            $_.IsOrphan = (-not [bool]($exists))
        }
    }
    $orphanResourceGroups = $allResourceGroups | Where-Object { $_.IsOrphan }

    # Send report by email
    if ($orphanResourceGroups.Count -gt 0 -and $SendToEmailAddress) {
        $body = ($orphanResourceGroups | ConvertTo-Html -Fragment) -join ''
        .\Send-GridMailMessage.ps1 -Subject 'Orphan resource groups identified' -content $body -bodyAsHtml `
            -FromEmailAddress AzureAutomation@azure.com -destEmailAddress $SendToEmailAddress
    }
    Write-Output ($orphanResourceGroups)

} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
