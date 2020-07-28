<#

Script Name	: IdentifyOrphanResourceGroupsSHB.ps1
Description	: List resource groups that do not have a matching owner (by tag) on Azure AD
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/28
Keywords	: Azure, Automation, Runbook, Tags, Governance

#>

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
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint -AzureEnvironmentName AzureCloud -Verbose

    # Iterate all subscriptions and get all resource groups
    $allResourceGroups = Get-AzSubscription -PipelineVariable sub | Where-Object { $_.Name -match $SubscriptionNamePattern } | ForEach-Object {
        Write-Verbose ('Switching to subscription: {0}' -f $_.Name) -Verbose
        $context = Set-AzContext -SubscriptionObject $_ -Force
        if ($context.Subscription.Id -eq $_.SubscriptionId) {
            Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -notmatch $excludeResourceGroupNames } |
                Select-Object  @{N = 'Subscription'; E = { $sub.Name } }, ResourceGroupName, @{N = 'IsOrphan'; E = { $true } }, @{N = 'TaggedOwner'; E = { $_.Tags.Owner } }
    } else {
        Write-Output ('There was an error changing the context to {0}' -f $sub.Name)
    }
}

# Get AzureAD users list
Write-Verbose ('Retrieving AzureAD users list') -Verbose
$UsersList = Get-AzureADUser -All $true | Select-Object UserPrincipalName, @{N = 'Name'; E = { '{0} {1}' -f $_.GivenName, $_.Surname } } |
    Where-Object { $_.Name -ne ' ' }
$orphanResourceGroups = @()

# Verify the owners exist in azure Active Directory (by FullName or UPN)
$owners = $allResourceGroups | Where-Object { $_.TaggedOwner } | Group-Object TaggedOwner -NoElement | Select-Object Name, @{N = 'OrphanDetails'; E = { $true } }
foreach ($owner in $owners) {
    try {
        if ($owner.Name -match '@') {
            $OrphanDetails = @($UsersList.UserPrincipalName -contains $owner.Name).Count -eq 0
        } else {
            $OrphanDetails = @($UsersList.Name -contains $owner.Name).Count -eq 0
        }
    } catch {
        Write-Output ($_.Exception.Message)
        $OrphanDetails = 'Unable to determine'
    }
    $owner.OrphanDetails = $OrphanDetails.ToString()
}

# Update the ResourceGroups list
foreach ($rg in $allResourceGroups) {
    $ownerDetails = $owners.Where( { $_.Name -eq $rg.TaggedOwner })
    if ($ownerDetails) { $rg.IsOrphan = $ownerDetails.OrphanDetails }
}

# Filter out the ResourceGroup with owners
$orphanResourceGroups = @($allResourceGroups | Where-Object { (-not ($_.IsOrphan -eq $false)) })

# Send report by email
if ($orphanResourceGroups.Count -gt 0 -and $SendToEmailAddress) {
    $body = ($orphanResourceGroups | ConvertTo-Html -Fragment) -join ''
    .\Send-GridMailMessage.ps1 -Subject 'Orphan resource groups identified' -content $body -bodyAsHtml `
        -FromEmailAddress AzureAutomation@azure.com -destEmailAddress $SendToEmailAddress
}

} catch {
    Write-Output ($_.Exception.Message)
} finally {
    Write-Output ($orphanResourceGroups)
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
