<#

Script Name	: Pipeline.AddAdtRoute.ps1
Description	: Add a route in Azure Digital Twins
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, DigitalTwins, Route

#>

#Requires -PSEdition Core

param(
    [Parameter(Mandatory = $true)][string] $ResourceGroupName,
    [Parameter(Mandatory = $true)][string] $ResourceName,
    [Parameter(Mandatory = $false)][string] $EndpointName = 'events',
    [Parameter(Mandatory = $false)][string] $RouteName = 'iot',
    [Parameter(Mandatory = $false)][string] $FilterType = 'microsoft.iot.telemetry'
)

$scope = az resource list -n $ResourceName -g $ResourceGroupName --resource-type 'Microsoft.DigitalTwins/digitalTwinsInstances' --query [].id  -o tsv
if (-not $scope) {
    Write-Error 'Resource not found'
    $host.SetShouldExit(1)
}

try {
    Write-Host "Verifying the latest Azure CLI IoT extension version is installed"
    az extension add --upgrade -n azure-iot --only-show-errors

    Write-Host "Attempting to create the route"
    az dt route create -n $ResourceName --endpoint-name $EndpointName --route-name $RouteName --filter "type = '$FilterType'"
} catch {
    Write-Host ("##[error] {0}" -f $_.Exception.Message)
    $host.SetShouldExit(1)
}
