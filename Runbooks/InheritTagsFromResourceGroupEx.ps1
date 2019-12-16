PARAM(
    [string] $SubscriptionNamePattern = 'maschvar.*',
    [string] $ConnectionName = 'AzureRunAsConnection',
    [string[]] $ExcludeResourceTypes = @(
        'microsoft.visualstudio/*', 'Microsoft.DevOps/*', 'microsoft.insights/*', 'Microsoft.Classic*'
    )
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))

function Compare-TagCollection {
    param($Reference, $Difference)
    @($Reference.GetEnumerator() | ForEach-Object {
            $Difference[$_.Key] -eq $_.Value
        } | Where-Object { -not $_ }).Count -eq 0
}

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

                # Exclude specific resources by type or all sub-resources
                if (($ExcludeResourceTypes | Where-Object { $resource.ResourceType -like $_ }) -or ($resource.Name -match '/')) {
                    Write-Output ('Skipping resource {0}/{1} ({2})' -f $_.ResourceGroupName, $resource.Name, $resource.ResourceType)
                } else {
                    Write-Output ('Verifying tags for {0}/{1}' -f $_.ResourceGroupName, $resource.Name)
                    $resourceid = $resource.resourceId
                    $resourcetags = $resource.Tags
                    $tagsSet = $null

                    if ((-not $resourcetags) -or $resourcetags.Count -eq 0) {
                        $tagsSet = (Set-AzResource -ResourceId $resourceid -Tag $resourceGroupTags -Force).Tags

                    } else {
                        if ($resourceGroupTags) {
                            $tagsToSet = $resourceGroupTags.Clone()
                            foreach ($tag in $resourcetags.GetEnumerator()) {
                                if ($tagsToSet.Keys -inotcontains $tag.Key) {
                                    $tagsToSet.Add($tag.Key, $tag.Value)
                                }
                            }
                            if (-not (Compare-TagCollection -Reference $tagsToSet -Difference $resourcetags)) {
                                $tagsSet = (Set-AzResource -ResourceId $resourceid -Tag $tagsToSet -Force).Tags
                            }
                        }
                    }
                    if ($tagsSet) {
                        Write-Output ('Tags updated for {0}/{1}' -f $_.ResourceGroupName, $resource.Name)
                    }
                }
            }
        }
    }
} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
