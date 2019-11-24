$resourceGroupName = 'MyResourceGroup'
$keyVaultName = 'MyKeyVault'

$resourceId = (Get-AzKeyVault -VaultName $keyVaultName).ResourceId
$properties = (Get-AzResource -ResourceId $resourceId).Properties |
    Add-Member -MemberType NoteProperty -Name enableSoftDelete -Value "true" -PassThru |
    Add-Member -MemberType NoteProperty -Name enablePurgeProtection -Value "true" -PassThru

Set-AzResource -resourceid $resourceId -Properties $properties -Force

