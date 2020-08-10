<#

Script Name	: Update-OwnerTag.ps1
Description	: Replace the owner tag value according to the 'ownersDictionary' hashtabe
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/08/10
Keywords	: Azure, Governance, Tags

#>

PARAM(
    [string] $SubscriptionId = $null,
    [string[]] $ExcludeResourceTypes = @(
        'microsoft.visualstudio/*', 'Microsoft.DevOps/*', 'microsoft.insights/*', 'Microsoft.Classic*'
    )
)

$ownersDictionary = @{
    'John Doe'        = 'Jane Doe'
    'Sara Smith'      = 'Mary Jane'
}


if ([string]::IsNullOrEmpty($SubscriptionId)) {
    $SubscriptionId = (Get-AzContext).Subscription.Id
}

$null = Set-AzContext -SubscriptionId $SubscriptionId -TenantId ((Get-AzContext).Tenant.Id)

foreach ($rg in (Get-AzResourceGroup)) {

    Write-Output ("Working on resource group '{0}'" -f $rg.ResourceGroupName)
    if ($rg.Tags -and $rg.Tags.ContainsKey('Owner')) {
        $rgTaggedOwner = $rg.Tags['Owner']
        if ($ownersDictionary.ContainsKey($rgTaggedOwner)) {

            Write-Output ("`tUpdating resource group owner from '{0}' to '{1}'" -f $rgTaggedOwner, $ownersDictionary[$rgTaggedOwner])
            $rg.Tags['Owner'] = $ownersDictionary[$rgTaggedOwner]
            $null = Set-AzResourceGroup -Name $rg.ResourceGroupName -Tag $rg.Tags

            Write-Output ("`tWorking on child resources under '{0}'" -f $rg.ResourceGroupName)
            $allResources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName
            foreach ($resource in $allResources) {

                if (($ExcludeResourceTypes | Where-Object { $resource.ResourceType -like $_ }) -or ($resource.Name -match '/')) {
                    Write-Output ("`t`tSkipping resource '{0}/{1}' (type: {2})" -f $rg.ResourceGroupName, $resource.Name, $resource.ResourceType)
                } else {
                    Write-Output ("`t`tUpdating resource owner on '{0}' (type: {1})" -f $resource.Name, $resource.ResourceType)
                    $resourcetags = $resource.Tags
                    if ($resourcetags -and $resourcetags.ContainsKey('Owner')) {
                        $resourcetags['Owner'] = $ownersDictionary[$rgTaggedOwner]
                    } elseif ($resourcetags) {
                        $resourcetags.Add('Owner', $ownersDictionary[$rgTaggedOwner])
                    } else {
                        $resourcetags = @{ 'Owner' = $ownersDictionary[$rgTaggedOwner] }
                    }
                    $null = $resource | Set-AzResource -Tag $resourcetags -Force
                }
            }
        }
    } else {
        Write-Output ("`tWarning: Resource group '{0}' doesn't have the Owner tag" -f $rg.ResourceGroupName)
    }
}