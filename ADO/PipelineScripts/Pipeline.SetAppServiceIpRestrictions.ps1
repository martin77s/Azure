<#

Script Name	: Pipeline.SetAppServiceIpRestrictions
Description	: Set the IP restrictions on the AppService WebApps and WebAPIs
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, AppService, IPRestrictions
Last Update	: 2020/07/21

#>

PARAM(
	[Parameter(Mandatory)] [string] $wafPublicIP,
	[Parameter(Mandatory=$false)] [string[]] $NatIPs = $null,
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

	# Remove the previous IP restrictions
	$restrictionsToRemove = $webapp.SiteConfig.IpSecurityRestrictions.Where( { $_.IpAddress -ne 'Any' -and $_.Priority -ne 2147483647 })
	$restrictionsToRemove | ForEach-Object {
		Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $webapp.ResourceGroup -WebAppName $webapp.Name -Name $_.Name
	}

	# Add the IP restrictions - Allow the WAF
	Add-AzWebAppAccessRestrictionRule -ResourceGroupName $webApp.ResourceGroup -WebAppName $webApp.Name `
		-Name WAF -Priority 1000 -Action Allow -IpAddress ('{0}/32' -f $wafPublicIP)

	# Add the NAT IP addresses
	for($i = 0; $i -lt @($NatIPs).Count; $i++) {
		Add-AzWebAppAccessRestrictionRule -ResourceGroupName $webApp.ResourceGroup -WebAppName $webApp.Name `
			-Name ('NAT-'+$i) -Priority (2000+$i) -Action Allow -IpAddress ('{0}/32' -f @($NatIPs)[$i])
	}
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

	# Remove the previous IP restrictions
	$restrictionsToRemove = $webApi.SiteConfig.IpSecurityRestrictions.Where( { $_.IpAddress -ne 'Any' -and $_.Priority -ne 2147483647 })
	$restrictionsToRemove | ForEach-Object {
		Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $webApi.ResourceGroup -WebAppName $webApi.Name -Name $_.Name
	}

	# Add the IP restrictions - Allow the WAF
	Add-AzWebAppAccessRestrictionRule -ResourceGroupName $webApp.ResourceGroup -WebAppName $webApp.Name `
		-Name WAF -Priority 1000 -Action Allow -IpAddress ('{0}/32' -f $wafPublicIP)

	# Add the IP restrictions - Allow the APIM
	Add-AzWebAppAccessRestrictionRule -ResourceGroupName $webApi.ResourceGroup -WebAppName $webApi.Name `
		-Name APIM -Priority 1100 -Action Allow -IpAddress ('{0}/32' -f $apiManagementServicePublicIP)

	# Add the NAT IP addresses
	for($i = 0; $i -lt @($NatIPs).Count; $i++) {
		Add-AzWebAppAccessRestrictionRule -ResourceGroupName $webApp.ResourceGroup -WebAppName $webApp.Name `
			-Name ('NAT-'+$i) -Priority (2000+$i) -Action Allow -IpAddress ('{0}/32' -f @($NatIPs)[$i])
	}
}