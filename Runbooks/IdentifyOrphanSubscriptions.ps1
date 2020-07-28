<#

Script Name	: IdentifyOrphanSubscriptions.ps1
Description	: List subscriptions that reside directly under the tenant root management group
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/28
Keywords	: Azure, Automation, Runbook, Tags, Governance

#>


PARAM(
    [string] $ConnectionName = 'AzureRunAsConnection',
    [string] $SendToEmailAddress = $null
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))


#region Helper functions
function Get-MGRecurse {
    param($MG)
    (Get-AzManagementGroup -Expand -GroupName $MG).Children |
        Where-Object { $_.Type -eq '/providers/Microsoft.Management/managementGroups' } | ForEach-Object {
            $_
            Get-MGRecurse -MG $_.Name
        }
}

function Select-MG {
    param($sub, $mgs)
    Write-Verbose ("Checking best match for: " + $sub) -Verbose
    $subParts = $sub -split '-'
    $targetMg = $mgs | ForEach-Object {
        for ($i = 0; $i -lt 3; $i++) {
            $th = ($subParts[0..$i] -join '-')
            Write-Verbose ("? {0}" -f $th) -Verbose
            if ($_.DisplayName -match $th) {
                Write-Verbose ("? matched {0}" -f $_.DisplayName) -Verbose
                New-Object PSObject -Property @{
                    Segments        = $i + 1
                    Subscription    = $sub
                    ManagementGroup = $_
                }
            }
        }
    } | Sort-Object -Descending -Property Segments | Select-Object -First 1
    Write-Verbose ("= {0}" -f $targetMg.ManagementGroup) -Verbose
    $targetMg.ManagementGroup
}
#endregion

try {

    # Login to Azure
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    $null = Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    # Get the root management group
    $root = Get-AzManagementGroup -Expand -GroupName $servicePrincipalConnection.TenantId

    # Get all the management groups recursively
    $mgmtGroups = @(Get-MGRecurse -MG $root.Name)
    Write-Output ('Management group(s): {0}' -f $mgmtGroups.Count)

    # Get all the subscriptions
    $subs = @(Get-AzSubscription -TenantId $servicePrincipalConnection.TenantId)
    Write-Output ('Subscription(s): {0}' -f $subs.Count)

    # Find orphan subscriptions (not under any management group)
    $orphanSubscriptions = @($root.Children | Where-Object { $_.Type -eq '/subscriptions' })
    Write-Output ('Orphan subscription(s): {0}' -f $orphanSubscriptions.Count)
    $orphanSubsReport = @($orphanSubscriptions | Select-Object @{N = 'Id'; E = { $_.Name } }, DisplayName)

    # Send report by email
    if ($orphanSubsReport.Count -gt 0 -and $SendToEmailAddress) {
        $body = ($orphanSubsReport | ConvertTo-Html -Fragment) -join ''
        .\Send-GridMailMessage.ps1 -Subject 'Orphan subscriptions identified' -content $body -bodyAsHtml `
            -FromEmailAddress AzureAutomation@azure.com -destEmailAddress $SendToEmailAddress
    }

    # Move the orphan subscriptions to the matching management group
    ### foreach($orphan in $orphanSubscriptions) {
    ###     $targetManagementGroup = Select-MG -sub $orphan.DisplayName -mgs $mgmtGroups
    ###     if($targetManagementGroup) {
    ###         Write-Output ('Moving subscription [{0}] to group [{1}]' -f $orphan.DisplayName, $targetManagementGroup.DisplayName)
    ###         New-AzManagementGroupSubscription -GroupName $targetManagementGroup.Name -SubscriptionId $orphan.Name
    ###     } else {
    ###         Write-Output ('Could not find a matching management group for subscription: {0}' -f $orphan.DisplayName)
    ###     }
    ### }


} catch {
    Write-Output ($_.Exception.Message)
} finally {
    Write-Output ($orphanSubsReport)
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
