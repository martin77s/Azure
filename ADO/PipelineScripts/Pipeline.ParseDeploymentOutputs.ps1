<#

Script Name	: Pipeline.ParseDeploymentOutputs.ps1
Description	: Parse the ARM deployment output and create Pipeline variables from it
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, Variables, DevOps, Pipeline
Last Update	: 2020/02/27

#>

#Requires -Version 6.0
#Requires -PSEdition Core

PARAM(
    [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $DeploymentOutputs
)

Write-Host 'DeploymentOutputs is:'
Write-Host $DeploymentOutputs

($DeploymentOutputs | ConvertFrom-Json).PSObject.Properties | ForEach-Object {

    $type = ($_.value.type).ToLower()
    $variableAttributes = @("task.setvariable variable=$($_.Name)")

    if ($type -eq 'securestring') {
        $variableAttributes += 'isSecret=true'

    } elseif ($type -eq 'array') {
        #$value = $_.Value.value -join ','
        $value = $_.Value.value | ConvertTo-Json -AsArray -Compress

    } elseif ($type -ne 'string') {
        throw "Type '$type' is not supported for '$($_.Name)'"

    } else {
        $value = $_.Value.value
    }

    Write-Host ("##vso[{0}]{1}" -f ($variableAttributes -join ';'), $value)
}

