<#

Script Name	: Pipeline.ConvertCidrToIpRanges.ps1
Description	: Create the allowed IP address ranges task variable string for the APIM policy and other resources
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, APIM, IPAddress

#>

#Requires -PSEdition Core

param (
    [Parameter(Mandatory = $true)][string] $IPAddresses,
    [string] $VariableNameAPIM = 'allowedPublicIPsForAPIM',
    [string] $VariableNameToFrom = 'allowedPublicIPsToFrom'
)

function Convert-IPToInt64 () {
    param ($ip)
    $octets = $ip.split('.')
    return [int64]([int64]$octets[0] * 16777216 + [int64]$octets[1] * 65536 + [int64]$octets[2] * 256 + [int64]$octets[3])
}

function Convert-Int64ToIP() {
    param ([int64]$int)
    return (
        '{0}.{1}.{2}.{3}' -f ([System.Math]::truncate($int / 16777216)), ([System.Math]::truncate(($int % 16777216) / 65536)),
        ([System.Math]::truncate(($int % 65536) / 256)), ([System.Math]::truncate($int % 256))
    )
}

$outputAPIM = @()
$outputToFrom = @()

$IPAddresses -split ',' | ForEach-Object {
    $ip, $cidr = $_ -split '/'

    $ipAddress = [Net.IPAddress]::Parse($ip)

    $maskAddress = [Net.IPAddress]::Parse(
        (Convert-Int64ToIP -int ([System.Convert]::ToInt64(('1' * $cidr + '0' * (32 - $cidr)), 2)))
    )

    $networkAddress = New-Object -TypeName Net.IPAddress -ArgumentList (
        $maskAddress.Address -band $ipAddress.Address
    )
    $broadcastAddress = New-Object -TypeName Net.IPAddress -ArgumentList (
        ([System.Net.IPAddress]::Parse('255.255.255.255').Address -bxor $maskAddress.Address -bor $networkAddress.Address)
    )

    $startAddress = Convert-IPToInt64 -ip $networkAddress.IPAddressToString
    $endAddress = Convert-IPToInt64 -ip $broadcastAddress.IPAddressToString

    $startAddressIPv4 = Convert-Int64ToIP -int $startAddress
    $endAddressIPv4 = (Convert-Int64ToIP -int $endAddress)

    $outputAPIM += '\r\n\t\t\t<address-range from=\"{0}\" to=\"{1}\" />' -f $startAddressIPv4, $endAddressIPv4
    $outputToFrom += '{0}|{1}|{2}' -f $_, $startAddressIPv4, $endAddressIPv4
}

Write-Host "##vso[task.setvariable variable=$VariableNameAPIM]$($outputAPIM -join '')"
Write-Host "##vso[task.setvariable variable=$VariableNameToFrom]$($outputToFrom -join ',')"