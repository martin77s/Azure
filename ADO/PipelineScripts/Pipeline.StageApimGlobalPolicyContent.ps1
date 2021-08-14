<#

Script Name	: Pipeline.StageApimGlobalPolicyContent.ps1
Description	: Read the Variables\apimGlobalPolicy.xml and prepare it as a task variable for the publish template
Keywords	: Azure, APIM

#>

#Requires -PSEdition Core

param (
    [Parameter(Mandatory = $true)][string] $apimPolicyFile
)

try {
    $apimGlobalPolicy = (Get-Content -Path $apimPolicyFile) -join '\r\n'
    $apimGlobalPolicy = $apimGlobalPolicy -replace '\s{4}', '\t'
    $apimGlobalPolicy = $apimGlobalPolicy -replace '"', '\"'
    Write-Host "##vso[task.setvariable variable=apimGlobalPolicy]$apimGlobalPolicy"
} catch {
    Write-Host ("##[error] {0}" -f $_.Exception.Message)
    $host.SetShouldExit(1)
}