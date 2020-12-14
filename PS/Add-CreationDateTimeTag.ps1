<#

Script Name	: Add-CreationDateTimeTag.ps1
Description	: Add the CreationDateTime tag on all resources that don't have a CreationDateTime tag
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, Governance, Tags
Last Update	: 2020/12/14

#>

PARAM(
    [string] $SubscriptionId = $null
)

if ([string]::IsNullOrEmpty($SubscriptionId)) {
    $SubscriptionId = (Get-AzContext).Subscription.Id
}

$tagToAdd = @{'CreationDateTime' = ('{0:yyyy-MM-ddTHH:mm:ss.fffffffZ}') -f [datetime]::MinValue }

$query = @'
Resources | where subscriptionId == '{0}' and tags !contains 'CreationDateTime'
| project id, subscriptionId, resourceGroup, name
'@ -f $SubscriptionId
$results = Search-AzGraph -Query $query
$tagged = 0

foreach ($resource in $results) {
    try {
        'Tagging {0}' -f $resource.ResourceId
        New-AzTag -Tag $tagToAdd -ResourceId $resource.ResourceId -ErrorAction Stop | Out-Null
        $tagged++
    }
    catch {
        "`tError: {0}" -f $_.Exception.Message
    }
}

"`nTagged {0} out of {1} resource(s)" -f $tagged, $results.Count