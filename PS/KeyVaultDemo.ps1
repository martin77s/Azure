# Script variables
$location = 'westeurope'
$resourceGroupName = 'rg-keyvault-demo'
$keyVaultName = 'myAzVault123'
$storageAccountName = 'myazvault123logs'
$backupKeyVaultName = 'myAzVault123Backup'


# Create the resource group
if (-not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $resourceGroupName -Location $location | Out-Null
}


# Create the primary KeyVault
$kvParams = @{
    ResourceGroupName            = $resourceGroupName
    VaultName                    = $keyVaultName
    Location                     = $location
    Sku                          = 'Standard'
    EnabledForTemplateDeployment = $true
    EnabledForDeployment         = $true
    EnableSoftDelete             = $true
    EnablePurgeProtection        = $true
}; $keyVault = New-AzKeyVault @kvParams

<#

$resourceId = (Get-AzKeyVault -VaultName $keyVaultName).ResourceId
$properties = (Get-AzResource -ResourceId $resourceId).Properties |
    Add-Member -MemberType NoteProperty -Name enableSoftDelete -Value "true" -PassThru |
    Add-Member -MemberType NoteProperty -Name enablePurgeProtection -Value "true" -PassThru
Set-AzResource -resourceid $resourceId -Properties $properties -Force
$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroupName

#>


# Create the storage account for the diagnostics auditing
$saParams = @{
    ResourceGroupName = $resourceGroupName
    Name              = $storageAccountName
    SkuName           = 'Standard_LRS'
    Location          = $location
    Kind              = 'StorageV2'
    AccessTier        = 'Hot'
}; $storageAccount = New-AzStorageAccount @saParams


# Configure logging
$azDiagParams = @{
    Name             = 'KeyVaultAuditing'
    ResourceId       = $keyVault.ResourceId
    StorageAccountId = $storageAccount.Id
    Enabled          = $true
    Category         = 'AuditEvent'
    RetentionEnabled = $true
    RetentionInDays  = 90
}; Set-AzDiagnosticSetting @azDiagParams | Out-Null


# Store some secrets in the KeyVault
$userName = 'myVmAdmin' | ConvertTo-SecureString -AsPlainText -Force
$password = 'P@55w0rd?' | ConvertTo-SecureString -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name myLocalVmAdminUser     -ContentType txt -SecretValue $userName | Out-Null
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name myLocalVmAdminPassword -ContentType txt -SecretValue $password | Out-Null


# Store some keys in the KeyVault
Add-AzKeyVaultKey -VaultName $keyVaultName -Name myApplicationId -Destination Software | Out-Null
Add-AzKeyVaultKey -VaultName $keyVaultName -Name myImportantGUID -Destination Software | Out-Null


# Store a certificate in the KeyVault
$policyParams = @{
    SecretContentType = 'application/x-pkcs12'
    SubjectName       = 'CN=contoso.com'
    IssuerName        = 'Self'
    ValidityInMonths  = 12
    ReuseKeyOnRenewal = $true
}; $policy = New-AzKeyVaultCertificatePolicy @policyParams
Add-AzKeyVaultCertificate -VaultName $keyVaultName -Name myWebCertificate -CertificatePolicy $policy | Out-Null



# Get the audit events for our KeyVault
$logsPath = Join-Path -Path $env:TEMP -ChildPath KeyVaultAuditLogs
New-Item -Path $logsPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$blobParams = @{
    Context   = $storageAccount.Context
    Container = 'insights-logs-auditevent'
    Blob      = ("*/VAULTS/$keyVaultName/*").ToUpper()
}
Get-AzStorageBlob @blobParams | Get-AzStorageBlobContent -Destination "$logsPath\" -Force


# Create a backup KeyVault
$kvBackupParams = @{
    ResourceGroupName            = $resourceGroupName
    VaultName                    = $backupKeyVaultName
    Location                     = $location
    Sku                          = 'Standard'
    EnabledForTemplateDeployment = $true
    EnabledForDeployment         = $true
}; New-AzKeyVault @kvBackupParams | Out-Null



# Export the keys, secrets and certificates from the pimary KeyVault
$exportedItemsPath = Join-Path -Path $env:TEMP -ChildPath ExportedKeyVaultItems
'Keys', 'Secrets', 'Certificates' | ForEach-Object {
    New-Item -Path $exportedItemsPath -Name $_ -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
}

$keyVault | Get-AzKeyVaultKey | ForEach-Object {
    $_ | Backup-AzKeyVaultKey -Force -OutputFile ('{0}\Keys\{1}.blob' -f $exportedItemsPath, $_.Name) -ErrorAction SilentlyContinue
}

$keyVault | Get-AzKeyVaultSecret | ForEach-Object {
    $_ | Backup-AzKeyVaultSecret -Force -OutputFile ('{0}\Secrets\{1}.blob' -f $exportedItemsPath, $_.Name) -ErrorAction SilentlyContinue
}

$keyVault | Get-AzKeyVaultCertificate | ForEach-Object {
    $_ | Backup-AzKeyVaultCertificate -Force -OutputFile ('{0}\Certificates\{1}.blob' -f $exportedItemsPath, $_.Name) -ErrorAction SilentlyContinue
}


# Restore the keys, secrets and certificates to the backup KeyVault
Get-ChildItem -Path "$exportedItemsPath\Keys" | ForEach-Object {
    Restore-AzKeyVaultKey -VaultName $backupKeyVaultName -InputFile $_.FullName -ErrorAction SilentlyContinue | Out-Null
}
Get-ChildItem -Path "$exportedItemsPath\Secrets" | ForEach-Object {
    Restore-AzKeyVaultSecret -VaultName $backupKeyVaultName -InputFile $_.FullName -ErrorAction SilentlyContinue | Out-Null
}
Get-ChildItem -Path "$exportedItemsPath\Certificates" | ForEach-Object {
    Restore-AzKeyVaultCertificate -VaultName $backupKeyVaultName -InputFile $_.FullName -ErrorAction SilentlyContinue | Out-Null
}


# Example to retreive credentials from the *backup* KeyVault
$user = Get-AzKeyVaultSecret -VaultName $backupKeyVaultName -Name myLocalVmAdminUser
$pass = Get-AzKeyVaultSecret -VaultName $backupKeyVaultName -Name myLocalVmAdminPassword
$retrievedCreds = New-Object -TypeName PSCredential -ArgumentList $user.SecretValueText, $pass.SecretValue
$retrievedCreds
$retrievedCreds.GetNetworkCredential().Password
