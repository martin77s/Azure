<#

Script Name	: Pipeline.ConvertArmOutputToArrayVariable.ps1
Description	: Create an ADO pipeline variable array from ARM output list
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, Variables, DevOps, Pipeline
Last Update	: 2020/06/08

#>

PARAM(
    [Parameter(Mandatory)] [string] $VaraiblePrefixRegex,
    [Parameter(Mandatory)] [string] $VariableName
)

$list = (Get-ChildItem env: | Where-Object { $_.Name -match $VaraiblePrefixRegex } |
    Select-Object -ExpandProperty Value | ConvertTo-Json -Compress)

Write-Host "##vso[task.setvariable variable=$VariableName]$list"