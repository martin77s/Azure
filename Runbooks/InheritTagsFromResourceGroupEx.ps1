<#

Script Name	: InheritTagsFromResourceGroup.ps1
Description	: Set the resource group tags and values on the child resources
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/09/01
Keywords	: Azure, Automation, Runbook, Tags, Governance

#>

PARAM(
    [string] $ConnectionName = 'AzureRunAsConnection',
    [string] $SubscriptionNamePattern = '.*',
    [string[]] $ExcludeResourceTypes = @(
        'microsoft.visualstudio/*', 'Microsoft.DevOps/*', 'Microsoft.Classic*'
    )
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))

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
                            $resourceid = $resource.resourceId
                            $resourcetags = $resource.Tags
                            $tagsSet = $null

                            # Build the parameters hashtable
                            $params = @{
                                ResourceId  = $resourceid
                                Force       = $true
                                ErrorAction = 'Stop'
                            }

                            # Workaround for media services API version issue
                            if ($resource.ResourceType -eq 'microsoft.media/mediaservices') {
                                $params.Add('ApiVersion', '2018-07-01')
                            }

                            if ((-not $resourcetags) -or $resourcetags.Count -eq 0) {
                                # Add the all the tags from parent resource group
                                $tagsSet = (Set-AzResource @params -Tag $resourceGroupTags).Tags
                            } else {
                                if ($resourceGroupTags) {
                                    $tagsToSet = $resourceGroupTags.Clone()
                                    foreach ($tag in $resourcetags.GetEnumerator()) {
                                        if ($tagsToSet.Keys -inotcontains $tag.Key) {
                                            $tagsToSet.Add($tag.Key, $tag.Value)
                                        }
                                    }
                                    if (-not (Compare-TagCollection -Reference $tagsToSet -Difference $resourcetags)) {
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
} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
