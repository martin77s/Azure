<#

Script Name	: Get-AzureManagedIdentitiesUsage.ps1
Description	: List Azure resources that use System Managed Identities and User Managed Identities
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/04/28 22:05
Keywords	: Azure, ManagedIdentity, MSI
Reference	: https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/services-support-managed-identities

#>

#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Az.Accounts'; ModuleVersion='1.7.5' }
#Requires -Modules @{ ModuleName='Az.Resources'; ModuleVersion='1.13.0' }
#Requires -Modules @{ ModuleName='Az.ManagedServiceIdentity'; ModuleVersion='0.7.3' }

PARAM(
    $TenantId,
    $SubscriptionId
)


if($TenantId -and $SubscriptionId) {
    # Login to azure and set the context:
    Add-AzAccount -TenantId $TenantId 
    Set-AzContext -TenantId $TenantId -SubscriptionId $SubscriptionId -Force
}

# List resources with System Managed Identities:
Get-AzResource | Where-Object { $_.Identity } |
    Select-Object ResourceType, @{N='ResourceGroup';E={$_.ResourceGroupName}}, @{N='ResourceName';E={$_.Name}},
        @{N='IdentityType';E={$_.Identity.Type}}, @{N='TenantId';E={$_.Identity.TenantId}}, @{N='PrincipalId';E={$_.Identity.PrincipalId}}


# List User Managed Identities
Get-AzUserAssignedIdentity |
    Select-Object @{N='ResourceType';E={$_.Type}}, @{N='ResourceGroup';E={$_.ResourceGroupName}}, @{N='ResourceName';E={$_.Name}}, 
        @{N='IdentityType';E={'UserAssigned'}}, TenantId, PrincipalId
