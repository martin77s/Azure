# Create the Key vault
$kv = New-AzKeyVault -Name CredsKeyVault -ResourceGroupName rg-general -Location westeurope -Sku Standard -EnabledForDeployment -EnabledForTemplateDeployment


# Store the credentials
$cred = Get-Credential
$userName = $cred.UserName | ConvertTo-SecureString -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName CredsKeyVault -Name LocalAdminUser -SecretValue $userName -ContentType txt
Set-AzKeyVaultSecret -VaultName CredsKeyVault -Name LocalAdminPassword -SecretValue $cred.Password -ContentType txt


# Retreive the credentials for automation usage
$user = Get-AzKeyVaultSecret -VaultName CredsKeyVault -Name LocalAdminUser
$pass = Get-AzKeyVaultSecret -VaultName CredsKeyVault -Name LocalAdminPassword
$cred = [PSCredential]::new($user.SecretValueText, $pass.SecretValue)
