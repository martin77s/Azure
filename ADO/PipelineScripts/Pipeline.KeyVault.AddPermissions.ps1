<#

Script Name	: KeyVault.AddPermissions.ps1
Description	: Add AccessPolicies permissions to secrets
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, KeyVault, DevOps, Pipeline

Notes		:
For Applications (ServicePrincipals, App Registrations), use the Enterprise Application ObjectId and not the SPObjectId nor the Uri.

#>

param(
    [Parameter(Mandatory = $true)][string] $keyVaultName,
    [Parameter(Mandatory = $true)][string] $ResourceGroup,
    [Parameter(Mandatory = $true)][string[]] $ObjectId,
    [Parameter(Mandatory = $false)][string[]] $PermissionsToSecrets = @('Get','List','Set','Delete')
)

if (-not (Get-AzResourceGroup -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue)) {
    Write-Error 'ResourceGroup $resourceGroupName not found'
    $host.SetShouldExit(1)
}

if (-not (Get-AzResource -Name $keyVaultName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue)) {
    Write-Error 'keyVault $keyVaultName not found'
    $host.SetShouldExit(1)
}

$kvParams = @{
	VaultName                = $keyVaultName
	ResourceGroupName        = $ResourceGroup
	PermissionsToSecrets     = $PermissionsToSecrets
}

Write-Output "Setting KeyVault Access Policy for users and groups"
$ObjectId | ForEach-Object {
    Set-AzKeyVaultAccessPolicy @kvParams -ObjectID $_ -BypassObjectIdValidation
}
