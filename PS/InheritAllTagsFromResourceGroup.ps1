PARAM(
    $SubscriptionNamePattern = '.*'
)


function Compare-TagCollection {
    param($Reference, $Difference)
    @($Reference.GetEnumerator() | ForEach-Object {
            $Difference[$_.Key] -eq $_.Value
        } | Where-Object { -not $_ }).Count -eq 0
}


function Get-TagsPairs {
    param($hashtable)
    ($hashtable.GetEnumerator() | ForEach-Object { "{'$($_.Key)'='$($_.Value)'}" }) -join ', '
}


# Iterate all subscriptions
Get-AzSubscription | Where-Object { $_.Name -match $SubscriptionNamePattern } | ForEach-Object {

    $SubscriptionName = $_.Name
    Write-Verbose ('Switching to subscription: {0}' -f $SubscriptionName) -Verbose
    $null = Set-AzContext -SubscriptionObject $_ -Force

    # Iterate all resource groups
    Get-AzResourceGroup | ForEach-Object {

        # Iterate all resources within the resource group
        Write-Output ("Checking resource group {0}" -f $_.ResourceGroupName)
        $allResources = Get-AzResource -ResourceGroupName $_.ResourceGroupName
        $resourceGroupTags = $_.Tags
        if ($resourceGroupTags.Count -eq 0) {
            Write-Output ("`tNo tags found")
        } else {
            Write-Output ("`tResource group tags: {0}" -f (Get-TagsPairs -hashtable $resourceGroupTags))

            # Iterate the resources to apply the missing tags
            foreach ($resource in $allResources) {

                # Exclude specific resources by type
                if (($ExcludeResourceTypes | Where-Object { $resource.ResourceType -like $_ }) ) {
                    Write-Output ("`tSkipping resource {0}/{1} ({2})" -f $_.ResourceGroupName, $resource.Name, $resource.ResourceType)
                } else {
                    try {

                        # Get the resource Id and current tags
                        Write-Output ("`t`tVerifying tags for {0}/{1} ({2})" -f $_.ResourceGroupName, $resource.Name, $resource.ResourceType)
                        $resourceId = $resource.resourceId
                        $resourceTags = $resource.Tags
                        $tagsSet = $null

                        # Build the parameters hashtable
                        $params = @{
                            ResourceId  = $resourceId
                            Force       = $true
                            ErrorAction = 'Stop'
                        }

                        # Workaround for media services API version issue
                        if ($resource.ResourceType -eq 'microsoft.media/mediaservices') {
                            $params.Add('ApiVersion', '2018-07-01')
                        }

                        if ((-not $resourceTags) -or $resourceTags.Count -eq 0) {
                            # Add the all the tags from parent resource group
                            $tagsSet = (Set-AzResource @params -Tag $resourceGroupTags).Tags
                        } else {
                            if ($resourceGroupTags) {
                                $tagsToSet = $resourceGroupTags.Clone()
                                foreach ($tag in $resourceTags.GetEnumerator()) {
                                    if ($tagsToSet.Keys -inotcontains $tag.Key) {
                                        $tagsToSet.Add($tag.Key, $tag.Value)
                                    }
                                }
                                if (-not (Compare-TagCollection -Reference $tagsToSet -Difference $resourceTags)) {
                                    # Add the required tags (inherit missing tags)
                                    $tagsSet = (Set-AzResource @params -Tag $tagsToSet).Tags
                                }
                            }
                        }
                        if ($tagsSet) {
                            Write-Output ("`t`t`tTags updated for {0}/{1} ({2})" -f $_.ResourceGroupName, $resource.Name, $resource.ResourceType)
                        }
                    } catch {
                        if ($resource.Name -match '/') {
                            Write-Output ("`t`tTags could not be set on the child resource {0}/{1} ({2})" -f $_.ResourceGroupName, $resource.Name, $resource.ResourceType)
                        } else {
                            Write-Output ("`t`tError setting tags on {0}/{1} ({2}): {3}" -f $_.ResourceGroupName, $resource.Name, $resource.ResourceType, $_.Exception.Message)
                        }
                    }
                }
            }
        }
    }
}