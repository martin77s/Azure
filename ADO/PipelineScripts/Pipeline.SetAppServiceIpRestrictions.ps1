<#

Script Name	: Pipeline.SetAppServiceIpRestrictions
Description	: Set the IP restrictions on the AppService WebApps and WebAPIs
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, AppService, IPRestrictions
Last Update	: 2020/06/10

#>

PARAM(
	[Parameter(Mandatory)] [string] $wafPublicIP,
	[Parameter(Mandatory)] [string] $WebAppNamesRegex,
	[Parameter(Mandatory)] [string] $apiManagementServicePublicIP,
	[Parameter(Mandatory)] [string] $WebApiNamesRegex
)

# Get the WebApps from the environment variables:
$webAppNames = Get-ChildItem env: | Where-Object { $_.Name -match $WebAppNamesRegex } |
	Select-Object -ExpandProperty Value
Write-Host ("Found {0} web apps to configure:" -f $webAppNames.Count)
Write-Host ($webAppNames -join ", ")

# Loop through the WebApps
$webApps = Get-AzWebApp | Where-Object { $_.Name -match ('({0})-\w+-({1})' -f $Environment, ($webAppNames -join '|')) } | Sort-Object Name
foreach ($webApp in $webApps) {

	Write-Host ("Working on {0}" -f $webApp.Name)

	# Add the IP restrictions
	Add-AzWebAppAccessRestrictionRule -ResourceGroupName $webApp.ResourceGroup -WebAppName $webApp.Name `
		-Name WAF -Priority 1000 -Action Allow -IpAddress ('{0}/32' -f $wafPublicIP)
}

# Get the WebAPIs from the environment variables:
$webApiNames = Get-ChildItem env: | Where-Object { $_.Name -match $WebApiNamesRegex } |
	Select-Object -ExpandProperty Value
Write-Host ("Found {0} web apis to configure:" -f $webApiNames.Count)
Write-Host ($webApiNames -join ", ")


# Loop through the WebAPIs
$webApis = Get-AzWebApp | Where-Object { $_.Name -match ('({0})-\w+-({1})' -f $Environment, ($webApiNames -join '|')) } | Sort-Object Name
foreach ($webApi in $webApis) {

	Write-Host ("Working on {0}" -f $webApi.Name)

	# Add the IP restrictions
	Add-AzWebAppAccessRestrictionRule -ResourceGroupName $webApi.ResourceGroup -WebAppName $webApi.Name `
		-Name APIM -Priority 1200 -Action Allow -IpAddress ('{0}/32' -f $apiManagementServicePublicIP)
}