<#

Script Name	: KeyVault.AddPermissions-v2.ps1
Description	: Add AccessPolicies permissions to secrets
Keywords	: Azure, KeyVault, DevOps, Pipeline

Notes		:
For Applications (ServicePrincipals, App Registrations), use the Enterprise Application ObjectId and not the SPObjectId nor the Uri.

#>

#Requires -PSEdition Core

param(
    [Parameter(Mandatory = $true)][string] $keyVaultName,
    [Parameter(Mandatory = $true)][string] $ResourceGroup,
    [Parameter(Mandatory = $true)][string] $ObjectId,
    [Parameter(Mandatory = $false)][string[]] $PermissionsToSecrets = @('Get', 'List', 'Set', 'Delete')
)

if ([string]::IsNullOrEmpty($ObjectId)) {
    Write-Error 'ObjectIds list is empty'
    $host.SetShouldExit(1)
} else {
    $identitiesCollection = @($ObjectId -replace '\[|\]|"|\s' -split ',')
}

if (-not (Get-AzResourceGroup -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue)) {
    Write-Error 'ResourceGroup $resourceGroupName not found'
    $host.SetShouldExit(1)
}

if (-not (Get-AzResource -Name $keyVaultName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue)) {
    Write-Error 'keyVault $keyVaultName not found'
    $host.SetShouldExit(1)
}

# Get the key vault resource reference
$keyVault = Get-AzKeyVault -Name $keyVaultName -ResourceGroupName $resourceGroup

# Build the accessPolicies json
$accessPolicies = @()
$identitiesCollection | Where-Object { $_ -and ($_.Trim() -ne '') } | ForEach-Object {
    Write-Output "Creating Access Policy for [$_]"
    $accessPolicies += @"
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
$apiVersion = '2019-09-01'
$subscription = $keyVault.ResourceId -replace '.*/subscriptions/(.*)/resourceGroups/.*', '$1'
$apiUri = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.KeyVault/vaults/{2}/accessPolicies/{3}?api-version={4}' -f `
    $subscription, $ResourceGroup, $keyVaultName, $operationKind, $apiVersion

# Save the accessPolicies on the keyVault
Write-Output "Setting KeyVault Access Policy for users and groups"
$res = Invoke-AzRestMethod -Path $apiUri -Method PUT -Payload $body

# Report status
if ($res.StatusCode -eq 200 -or $res.StatusCode -eq 201) {
    Write-Output "KeyVault Access Policy changed successfully"
    exit 0
} else {
    Write-Error $res.Content
    exit 1
}