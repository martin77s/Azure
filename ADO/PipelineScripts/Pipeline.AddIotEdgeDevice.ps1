<#

Script Name	: Pipeline.AddIotEdgeDevice.ps1
Description	: Add an IoT Edge device in the IoT-Hub for the IotEdgeVM
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, IoT, IoT-Edge, IoT-Device

#>

#Requires -PSEdition Core

param(
    [Parameter(Mandatory = $true)][string] $ResourceGroupName,
    [Parameter(Mandatory = $true)][string] $IotHubName,
    [Parameter(Mandatory = $true)][string] $DeviceName,
    [Parameter(Mandatory = $false)][switch] $EdgeEnabled
)

$scope = az resource list -g $ResourceGroupName -n $IotHubName --resource-type Microsoft.Devices/IotHubs --query [].id  -o tsv
if (-not $scope) {
    Write-Error 'Resource not found'
    $host.SetShouldExit(1)
}

try {

    Write-Host "Verifying the latest Azure CLI IoT extension version is installed"
    az extension add --upgrade -n azure-iot --only-show-errors

    Write-Host ("##[section] Checking if IoT device '$DeviceName' already exists")
    $devices = az iot hub device-identity list -n $IotHubName
    if ($devices | ConvertFrom-Json | Where-Object { $_.deviceId -eq $DeviceName }) {

        Write-Host ("##[section] Extracting IoT device connectionString")
        $iotHubConnectionString = az iot hub device-identity connection-string show --hub-name $IotHubName --device-id $DeviceName --query connectionString  -o tsv

    } else {
        Write-Host ("##[section] Creating the IoT device")
        if ($EdgeEnabled) {
            $output = az iot hub device-identity create --hub-name $IotHubName --device-id $DeviceName --edge-enabled | ConvertFrom-Json
        } else {
            $output = az iot hub device-identity create --hub-name $IotHubName --device-id $DeviceName | ConvertFrom-Json
        }
        $iotHubConnectionString = 'HostName={0}.azure-devices.net;DeviceId={1};SharedAccessKey={2}' -f `
            $IotHubName, $output.deviceId , $output.authentication.symmetricKey.primaryKey
    }

    Write-Host ("##vso[task.setvariable variable=iotHubConnectionString;isSecret=true]$iotHubConnectionString")

} catch {
    Write-Host ("##[error] {0}" -f $_.Exception.Message)
    $host.SetShouldExit(1)
}
