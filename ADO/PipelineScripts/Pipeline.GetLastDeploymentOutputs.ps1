<#

Script Name	: Pipeline.GetLastDeploymentOutputs.ps1
Description	: Create ADO pipeline variables from the last successful deployment in the resourceGroup
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, ARM, Variables, DevOps, Pipeline

#>

#Requires -PSEdition Core

param(
    [Parameter(Mandatory = $true)][string] $ResourceGroupName,
    [Parameter(Mandatory = $true)][string] $DeploymentNameFilter
)

$lastDeployment = Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName |
    Where-Object { $_.ProvisioningState -eq 'Succeeded' -and $_.DeploymentName -match $DeploymentNameFilter } |
        Sort-Object Timestamp -Descending | Select-Object -First 1

if(-not($lastDeployment)){
    Write-Host '##[error] Could not find any deployment matching the selected criteria'
    $host.SetShouldExit(1)
}

foreach ($key in $lastDeployment.Outputs.Keys) {
    $type = ($lastDeployment.Outputs[$key].Type).ToLower()
    $variableAttributes = @("task.setvariable variable=$($key)")
    if ($type -eq 'securestring') { $variableAttributes += 'isSecret=true' }
    if ($lastDeployment.Outputs[$key].Type -eq 'Array') {
        $value = $lastDeployment.Outputs[$key].Value.ToString() | ConvertFrom-Json  | ConvertTo-Json -AsArray -Compress
    } else {
        $value = $lastDeployment.Outputs[$key].Value
    }
    Write-Host ("##vso[{0}]{1}" -f ($variableAttributes -join ';'), $value)
}