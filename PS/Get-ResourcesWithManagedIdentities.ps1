<#

Script Name	: Get-ResourcesWithManagedIdentities.ps1
Description	: List Azure resources that use Managed Identities
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/04/28 20:05
Keywords	: Azure, ManagedIdentity, MSI
Reference   : https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/services-support-managed-identities

#>

PARAM(
    $TenantId,
    $SubscriptionId
)


if($TenantId -and $SubscriptionId) {
    # Login to azure and set the context:
    Add-AzAccount -TenantId $TenantId 
    Set-AzContext -TenantId $TenantId -SubscriptionId $SubscriptionId -Force
}

# List resources with managed identities:
Get-AzVm | Where-Object { $_.Identity } | 
    Select-Object @{N='ResouceType';E={$_.Type}}, @{N='ResourceGroup';E={$_.ResourceGroupName}}, Name -ExpandProperty Identity

Get-AzVmss | Where-Object { $_.Identity } | 
    Select-Object @{N='ResouceType';E={$_.Type}}, @{N='ResourceGroup';E={$_.ResourceGroupName}}, Name -ExpandProperty Identity

Get-AzWebApp | Where-Object { $_.Identity } | 
    Select-Object @{N='ResouceType';E={$_.Type}}, ResourceGroup, Name -ExpandProperty Identity

