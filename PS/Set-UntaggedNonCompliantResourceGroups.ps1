$TenantId = (Get-AzContext).Tenant.TenantId
Get-AzSubscription | ForEach-Object {
    Set-AzContext -SubscriptionId $_.SubscriptionId -Tenant $TenantId -Force
    (Get-AzPolicyState -From (Get-Date).ToUniversalTime() -Filter "complianceState ne 'Compliant' and resourcetype eq 'Microsoft.Resources/subscriptions/resourceGroups'" -Select "resourcegroup,ResourceId") | ForEach-Object {
        $tags = Get-AzTag -ResourceId $_.ResourceId
        if ((-not $tags) -or (-not $tags.Properties.TagsProperty) -or (-not $tags.Properties.TagsProperty.ContainsKey('Environment'))) {
            New-AzTag -Tag @{Environment='Dev'} -ResourceId $_.ResourceId -WhatIf
        }
    }
}