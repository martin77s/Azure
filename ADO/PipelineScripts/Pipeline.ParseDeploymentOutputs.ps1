<#

Script Name	: Pipeline.ParseDeploymentOutputs.ps1
Description	: Parse the ARM deployment output and create Pipeline variables from it
Keywords	: Azure, Variables, DevOps, Pipeline

#>

#Requires -PSEdition Core

PARAM(
    [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $DeploymentOutputs
)

Write-Host 'DeploymentOutputs is:'
Write-Host $DeploymentOutputs

($DeploymentOutputs | ConvertFrom-Json).PSObject.Properties | ForEach-Object {

    $type = ($_.value.type).ToLower()
    $variableValue = $_.Value.value

    if ($type -eq 'string') {
        Write-Host ('##vso[task.setvariable variable={0}]{1}' -f $_.Name, $variableValue)

    } elseif ($type -eq 'securestring') {
        Write-Host ('##vso[task.setvariable variable={0};isSecret=true]{1}' -f $_.Name, $variableValue)

    } elseif ($type -eq 'array') {
        $variableValue = $_.Value.value | ConvertTo-Json -AsArray -Compress
        Write-Host ('##vso[task.setvariable variable={0}]{1}' -f $_.Name, $variableValue)

    } elseif ($type -eq 'object') {
        $objectName = $_.name
        foreach ($prop in ($_.Value.value).PSObject.Properties) {
            $prop.Value.PSObject.Properties | Select-Object Name, Value | ForEach-Object {
                $variableName = '{0}_{1}_{2}' -f $objectName, $prop.Name, $_.Name
                $variableValue = $_.Value
                Write-Host ('##vso[task.setvariable variable={0}]{1}' -f $variableName, $variableValue)
            }
        }

    } else {
        throw "Type '$type' is not supported for '$($_.Name)'"
    }
}

