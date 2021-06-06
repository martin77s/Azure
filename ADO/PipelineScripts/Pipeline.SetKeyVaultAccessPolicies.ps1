<#

Script Name	: Pipeline.SetKeyVaultAccessPolicies.ps1
Description	: Set AccessPolicies permissions to secrets/keys/certificates on a KeyVault
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, KeyVault, DevOps, Pipeline

Notes		:
- For Applications (ServicePrincipals, App Registrations), use the Enterprise Application ObjectId and not the SPObjectId nor the Uri.

#>

#Requires -PSEdition Core

param(
    [Parameter(Mandatory = $false)][string] $ResourceGroupName,
    [Parameter(Mandatory = $true)][string] $KeyVaultName,
    [Parameter(Mandatory = $true)][string] $ObjectId,
    [Parameter(Mandatory = $false)][string[]] $PermissionsToSecrets = @(),
    [Parameter(Mandatory = $false)][string[]] $PermissionsToKeys = @(),
    [Parameter(Mandatory = $false)][string[]] $PermissionsToCertificates = @()
)

# API version and Uri (https://docs.microsoft.com/en-us/rest/api/keyvault/vaults/updateaccesspolicy)
$apiVersion = '2019-09-01'
$apiUri = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.KeyVault/vaults/{2}/accessPolicies/{3}?api-version={4}'


if ([string]::IsNullOrEmpty($ObjectId)) {
    Write-Error 'ObjectIds list is empty'
    $host.SetShouldExit(1)
} else {
    $identitiesCollection = @($ObjectId -replace '\[|\]|"|\s' -split ',')
}


if ($ResourceGroupName) {
    # Get the specific keyVault
    $keyVault = Get-AzKeyVault -Name $KeyVaultName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
} else {
    # Search for the keyVault on all allowed subscriptions
    $keyVault = foreach ($sub In (Get-AzSubscription -TenantId (Get-AzContext).Tenant.Id)) {
        Set-AzContext -SubscriptionId $sub.SubscriptionId -Tenant $sub.TenantId -Force | Out-Null
        $vault = Get-AzKeyVault | Where-Object { $_.VaultName -eq $KeyVaultName }
        if ($vault) {
            Get-AzKeyVault -ResourceGroupName $vault.ResourceGroupName -VaultName $vault.VaultName
            break
        }
    }
}
if (-not $keyVault) {
    Write-Error 'keyVault $KeyVaultName not found'
    $host.SetShouldExit(1)
}


# Build the accessPolicies json
$accessPolicies = $identitiesCollection | ForEach-Object {
    $accessPolicy = @{
        objectId    = $_
        tenantId    = $keyVault.TenantId
        permissions = @{
            keys         = $PermissionsToKeys
            secrets      = $PermissionsToSecrets
            certificates = $PermissionsToCertificates
        }
    }
    ConvertTo-Json -InputObject $accessPolicy
}


# Build the body json
$body = @"
{
  "properties": {
    "accessPolicies": [ $($accessPolicies -join ',' ) ]
  }
}
"@


# Build the api URI
$operationKind = 'replace'
$subscription = $keyVault.ResourceId -replace '.*/subscriptions/(.*)/resourceGroups/.*', '$1'
$path = $apiUri -f $subscription, $keyVault.ResourceGroupName, $KeyVault.VaultName, $operationKind, $apiVersion


# Save the accessPolicies on the keyVault
Write-Output "Setting KeyVault Access Policy for the requested identities"
$res = Invoke-AzRestMethod -Path $path -Method PUT -Payload $body


# Report status
if ($res.StatusCode -eq 200 -or $res.StatusCode -eq 201) {
    Write-Output "KeyVault Access Policy set successfully"
} else {
    Write-Error $res.Content
    $host.SetShouldExit(1)
}
