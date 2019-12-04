PARAM(
    [string]$SubscriptionNamePattern = 'maschvar.*',
    [string]$ConnectionName = 'AzureRunAsConnection'
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))

try {

    # Login to Azure
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    $null = Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    # Iterate all subscriptions
    Get-AzSubscription | Where-Object { $_.Name -match $SubscriptionNamePattern } | ForEach-Object {

        $SubscriptionName = $_.Name
        Write-Verbose ('Switching to subscription: {0}' -f $SubscriptionName) -Verbose
        $null = Set-AzContext -SubscriptionObject $_ -Force

        # Iterate all resource groups
        Get-AzResourceGroup | ForEach-Object {

            # List all resources within the resource group
            Write-Output ('Chekcing resource group {0}' -f $_.ResourceGroupName)
            $allResources = Get-AzResource -ResourceGroupName $_.ResourceGroupName
            $resourceGroupTags = $_.Tags

            # Iterate the resources and apply the missing tags
            foreach ($resource in $allResources) {

                Write-Output ('Verifying tags for {0}/{1}' -f $_.ResourceGroupName, $resource.Name)
                $resourceid = $resource.resourceId
                $resourcetags = $resource.Tags

                if ($resourcetags -eq $null) {
                    $tagsSet = Set-AzResource -ResourceId $resourceid -Tag $resourceGroupTags -Force
                } else {
                    $tagsToSet = $resourceGroupTags.Clone()
                    foreach ($tag in $resourcetags.GetEnumerator()) {
                        if ($tagsToSet.Keys -inotcontains $tag.Key) {
                            $tagsToSet.Add($tag.Key, $tag.Value)
                        }
                    }
                    $tagsSet = Set-AzResource -ResourceId $resourceid -Tag $tagsToSet -Force -WhatIf
                }
                Write-Verbose $tagsSet
            }
        }
    }
} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
