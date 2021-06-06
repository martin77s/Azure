<#

Script Name	: Pipeline.Get-PrivateIpFromNIC.ps1
Description	: Get the private IP address from the specified network interface
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, DevOps, Pipeline, Variables, NetworkInterface, PrivateIP

#>

#Requires -PSEdition Core

PARAM(
    [Parameter(Mandatory = $true)] $NicId,
    [string] $VariableName = 'privateIpAddress'
)

$privateIpAddress = (Get-AzNetworkInterface -ResourceId $nicId).IpConfigurations[0].PrivateIpAddress
Write-Host "##vso[task.setvariable variable=$VariableName]$($privateIpAddress)"

