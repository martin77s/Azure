<#

Script Name	: Pipeline.GetLastDeploymentOutputs.ps1
Description	: Create ADO pipeline variables from the last successful deployment in the resourceGroup
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
    $variableValue = $lastDeployment.Outputs[$key].Value.ToString()

    if ($type -eq 'string') {
        Write-Host ('##vso[task.setvariable variable={0}]{1}' -f $key, $variableValue)

    } elseif ($type -eq 'securestring') {
        Write-Host ('##vso[task.setvariable variable={0};isSecret=true]{1}' -f $key, $variableValue)

    } elseif ($type -eq 'array') {
        $variableValue = $lastDeployment.Outputs[$key].Value.ToString() | ConvertFrom-Json  | ConvertTo-Json -AsArray -Compress
        Write-Host ('##vso[task.setvariable variable={0}]{1}' -f $key, $variableValue)

    } elseif ($type -eq 'object') {
        $props = $lastDeployment.Outputs[$key].Value
        $props.GetEnumerator() | ForEach-Object {
            $propName = $_.Key
            $props[$propName].GetEnumerator() | ForEach-Object {
                $variableName = '{0}_{1}_{2}' -f $key, $propName, $_.Key
                $variableValue = $_.Value
                Write-Host ('##vso[task.setvariable variable={0}]{1}' -f $variableName, $variableValue)
            }
        }

    } else {
        throw "Type '$type' is not supported for '$($_.Name)'"
    }
}