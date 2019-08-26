# Protect your Azure storage account with SSE (Storage Service Encryption) using a custom KeyVault key

# References:
# Azure Data Encryption-at-Rest
# https://docs.microsoft.com/en-us/azure/security/azure-security-encryption-atrest
# 
# Azure Storage Service Encryption for data at rest
# https://docs.microsoft.com/en-us/azure/storage/common/storage-service-encryption


# Set the variables
$location = 'WestEurope'
$resourceGroupName = 'rg-bcdr-moh-314'
$storageAccountName = 'bcdrmoh314159265'
$keyVaultName = 'kv-bcdr-moh-314'
$keyName = "KeyForStorageAccount-$storageAccountName"
$keyExpires = (Get-Date).AddYears(20).ToUniversalTime()
$keyNotBefore = (Get-Date).ToUniversalTime()

# Create the Resource group
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location


# Create the Key vault
$keyVault = New-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $keyVaultName -Location $location -Sku Standard


# Enable Soft Delete and Do Not Purge on the key vault
$resource = Get-AzResource -ResourceId (Get-AzKeyVault -VaultName $keyVaultName).ResourceId
$resource.Properties = $resource.Properties | Add-Member -MemberType NoteProperty -Name enableSoftDelete -Value 'True' -PassThru
$resource.Properties = $resource.Properties | Add-Member -MemberType NoteProperty -Name enablePurgeProtection -Value 'True' -PassThru
$resource = Set-AzResource -resourceid $resource.ResourceId -Properties $resource.Properties -Force


# Create a new RSA Key and store in KeyVault
$key = Add-AzureKeyVaultKey -VaultName $keyVaultName -Name $keyName -Expires $keyExpires -NotBefore $keyNotBefore -Destination Software -KeyOps @('encrypt','decrypt','wrapKey','unwrapKey')
 

# Create the Storage account
$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageAccountName -Location $location -SkuName Standard_GRS -Kind StorageV2


# Assign a storage account identity
$storageAccount = Set-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageAccountName -AssignIdentity


# Enable encryption on Blob Services with Keyvault
Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $storageAccount.Identity.PrincipalId -PermissionsToKeys @('wrapkey', 'unwrapkey', 'get')
Set-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageAccountName -KeyvaultEncryption -KeyName $key.Name -KeyVersion $key.Version -KeyVaultUri $keyVault.VaultUri


# FAQ for SSE with customer-managed-keys
# https://docs.microsoft.com/en-us/azure/storage/common/storage-service-encryption-customer-managed-keys#faq-for-sse-with-customer-managed-keys