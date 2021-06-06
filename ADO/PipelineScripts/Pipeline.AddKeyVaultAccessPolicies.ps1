<#

Script Name	: Pipeline.AddKeyVaultAccessPolicies.ps1
Description	: Add AccessPolicies permissions to secrets on a KeyVault
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, KeyVault, DevOps, Pipeline

Notes		:
- For Applications (ServicePrincipals, App Registrations), use the Enterprise Application ObjectId and not the SPObjectId nor the Uri.

#>

#Requires -PSEdition Core

param(
    [Parameter(Mandatory = $true)][string] $ResourceGroupName,
    [Parameter(Mandatory = $true)][string] $KeyVaultName,
    [Parameter(Mandatory = $true)][string] $ObjectId,
    [Parameter(Mandatory = $false)][string[]] $PermissionsToSecrets = @('Get', 'List')
)

# API version and Uri (https://docs.microsoft.com/en-us/rest/api/keyvault/vaults/updateaccesspolicy)
$apiVersion = '2019-09-01'
$apiUri = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.KeyVault/vaults/{2}/accessPolicies/{3}?api-version={4}'


if ([string]::IsNullOrEmpty($ObjectId)) {
    Write-Error 'ObjectIds list is empty'
    $host.SetShouldExit(1)
} else {
    $identitiesCollection = @(($ObjectId -replace '\[|\]|"|\s') -split ',')
}

if (-not (Get-AzResourceGroup -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
    Write-Error 'ResourceGroup $resourceGroupName not found'
    $host.SetShouldExit(1)
}

$keyVault = Get-AzKeyVault -Name $KeyVaultName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $keyVault) {
    Write-Error 'keyVault $KeyVaultName not found'
    $host.SetShouldExit(1)
}


# Build the accessPolicies json
$accessPolicies = $identitiesCollection | Where-Object { $_ -ne '' } | ForEach-Object {
    @"
    {
        "tenantId": "$($keyVault.TenantId)",
        "objectId": "$_",
        "permissions": {
            "secrets": $($PermissionsToSecrets | ConvertTo-Json -AsArray)
        }
    }
"@
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
$path = $apiUri -f $subscription, $ResourceGroupName, $KeyVaultName, $operationKind, $apiVersion


# Save the accessPolicies on the keyVault
Write-Output "Setting KeyVault Access Policy for users and groups"
$res = Invoke-AzRestMethod -Path $path -Method PUT -Payload $body


# Report status
if ($res.StatusCode -eq 200 -or $res.StatusCode -eq 201) {
    Write-Output "KeyVault Access Policy changed successfully"
} else {
    Write-Error $res.Content
    $host.SetShouldExit(1)
}