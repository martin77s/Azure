<#

Script Name	: Pipeline.UpdateDscVersionVariable.ps1
Description	: Update the dscVersion variable in the pipeline according to the last modified date of the dsc.zip file.
Keywords	: Azure, DSC, StorageAccount, Container, Blob

#>

#Requires -PSEdition Core

param(
    [Parameter(Mandatory = $true)][string] $dscZipUrl,
    [Parameter(Mandatory = $false)][string] $variableName = 'dscVersion'
)

try {
    $response = Invoke-WebRequest -Uri $dscZipUrl -Method Head -ErrorAction Stop
    $dscVersion = [string](($response.Headers['Last-Modified']) -replace '\D')
    while ([int]::MaxValue -lt $dscVersion) { $dscVersion /= 1kb }
} catch {
    $dscVersion = 0
}

Write-Host ("##vso[task.setvariable variable=$variableName]{0}" -f ([int]$dscVersion))
