param(
	[Parameter(Mandatory = $true, HelpMessage = "UPN")]
	[string] $LoginId,

	[Parameter(Mandatory = $true, HelpMessage = "Subscription Id")]
	[string] $SubscriptionId,

	[Parameter(Mandatory = $true, HelpMessage = "ResourceGroup Name")]
	[string] $ResourceGroupName,

	[Parameter(Mandatory = $true, HelpMessage = "Name of the App Service Certificate Resource")]
	[string] $Name
)

Set-AzContext -Subscription $SubscriptionId

## Get the KeyVault Resource Url and KeyVault Secret Name were the certificate is stored
$ascResource = Get-AzResource -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.CertificateRegistration/certificateOrders/$name"
$certProps = Get-Member -InputObject $ascResource.Properties.certificates[0] -MemberType NoteProperty
$certificateName = $certProps[0].Name
$keyVaultId = $ascResource.Properties.certificates[0].$certificateName.KeyVaultId
$keyVaultSecretName = $ascResource.Properties.certificates[0].$certificateName.KeyVaultSecretName

## Split the resource URL of KeyVault and get KeyVaultName and KeyVaultResourceGroupName
$keyVaultIdParts = $keyVaultId.Split("/")
$keyVaultName = $keyVaultIdParts[$keyVaultIdParts.Length - 1]
$keyVaultResourceGroupName = $keyVaultIdParts[$keyVaultIdParts.Length - 5]

## --- !! NOTE !! ----
## Only users who can set the access policy and has the the right RBAC permissions can set the access policy on KeyVault, if the command fails contact the owner of the KeyVault
Set-AzKeyVaultAccessPolicy -ResourceGroupName $keyVaultResourceGroupName -VaultName $keyVaultName -UserPrincipalName $loginId -PermissionsToSecrets get
Write-Host "Get Secret Access to account $loginId has been granted from the KeyVault, please check and remove the policy after exporting the certificate"

## Getting the secret from the KeyVault
$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $keyVaultSecretName
$pfxCertObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @([Convert]::FromBase64String($secret.SecretValueText), "", [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
$pfxPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 50 | ForEach-Object { [char]$_ })

$currentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
[Environment]::CurrentDirectory = $currentDirectory; Set-Location -Path $currentDirectory
[IO.File]::WriteAllBytes(".\appservicecertificate.pfx", $pfxCertObject.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $pfxPassword))

## --- !! NOTE !! ----
## Remove the Access Policy required for exporting the certificate once you have exported the certificate to prevent giving the account prolonged access to the KeyVault
## The account will be completely removed from KeyVault access policy and will prevent to account from accessing any keys/secrets/certificates on the KeyVault,
## Run the following command if you are sure that the account is not used for any other access on the KeyVault or login to the portal and change the access policy accordingly.
# Remove-AzKeyVaultAccessPolicy -ResourceGroupName $keyVaultResourceGroupName -VaultName $keyVaultName -UserPrincipalName $loginId
# Write-Host "Access to account $loginId has been removed from the KeyVault"

# Print the password for the exported certificate
Write-Host "Exported the App Service Certificate as: $currentDirectory/appservicecertificate.pfx"
Write-Warning "For security reasons, do not store the PFX password. Use it directly from the console as required."
Write-Host "PFX password: $pfxPassword"
