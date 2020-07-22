<#

Script Name	: KeyVault-Set-SoftDelete-PurgeProtection.ps1
Description	: Set the enableSoftDelete & enablePurgeProtection on the specified KeyVault
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/22
Keywords	: Azure, KeyVault, SoftDelete, PurgeProtection

#>

PARAM(
    $keyVaultName = 'MyKeyVault'
)

$resourceId = (Get-AzKeyVault -VaultName $keyVaultName).ResourceId
$properties = (Get-AzResource -ResourceId $resourceId).Properties |
    Add-Member -MemberType NoteProperty -Name enableSoftDelete -Value "true" -PassThru |
    Add-Member -MemberType NoteProperty -Name enablePurgeProtection -Value "true" -PassThru
Set-AzResource -resourceid $resourceId -Properties $properties -Force

