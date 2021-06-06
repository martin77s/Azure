<#

Script Name	: Pipeline.AddRbacRoleAssignment.ps1
Description	: Add RBAC permissions (role) to resources
Keywords	: Azure, KeyVault, DevOps, Pipeline

Notes		:
For Applications (ServicePrincipals, App Registrations), use the Enterprise Application ObjectId and not the SPObjectId nor the Uri.

#>

#Requires -PSEdition Core

param(
    [Parameter(Mandatory = $true)][string] $Name,
    [Parameter(Mandatory = $true)][string] $ResourceGroup,
    [Parameter(Mandatory = $false)][string] $ResourceType = 'Microsoft.KeyVault/vaults',
    [Parameter(Mandatory = $true)][string] $ObjectId,
    [Parameter(Mandatory = $false)][string] $RoleDefinitionName = 'Key Vault Secrets User'
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

$params = @{
    Name              = $Name
    ResourceGroupName = $ResourceGroup
    ResourceType      = $ResourceType
}

$resource = Get-AzResource @params
if (-not $resource) {
    Write-Error "Resource $Name not found"
    $host.SetShouldExit(1)
}

$identitiesCollection | Where-Object { $_ -and ($_.Trim() -ne '') } | ForEach-Object {
    Write-Host "Attempting to assign permissions for $_"
    $params = @{
        ObjectId           = $_
        RoleDefinitionName = $RoleDefinitionName
        Scope              = $resource.ResourceId
    }
    try {
        New-AzRoleAssignment @params -ErrorAction Stop | Out-Null
        Write-Host ("##[section] Permissions were assigned successfully.")
    } catch {
        if ($_.Exception.Message -eq 'The role assignment already exists.') {
            Write-Host ("##[warning] $($_.Exception.Message): No action is needed.")
        } else {
            Write-Host ("##[error] {0}" -f $_.Exception.Message)
            $host.SetShouldExit(1)
        }
    }
}