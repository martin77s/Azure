<#

Script Name	: Pipeline.SetAppServiceIpRestrictions.ps1
Description	: Set IP restrictions on the AppService WebApps and Functions (posting the json directly to the API)
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, AppService, IPRestrictions

#>

#Requires -PSEdition Core

PARAM(
	[Parameter(Mandatory)] [string] $webResources,
	[Parameter(Mandatory)] [string] $allowedPublicIPs,
	[Parameter(Mandatory)] [string] $appgwPublicIp,
	[Parameter(Mandatory)] [string] $apimPublicIp
)


# Script variables:
$apiVersion = '2019-08-01'
$basePath = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Web/Sites/{2}/config/web?api-version={3}'
$subscriptionId = (Get-AzContext).Subscription.Id
$apimCorsProxyIP = '13.91.254.72' # For APIM cors proxy & swagger reader


# Fix the IP addresses (add '/32' if needed)
if ($appgwPublicIp -notmatch '\/\d{2}$') { $appgwPublicIp = '{0}/32' -f $appgwPublicIp }
if ($apimPublicIp -notmatch '\/\d{2}$') { $apimPublicIp = '{0}/32' -f $apimPublicIp }
if ($apimCorsProxyIP -notmatch '\/\d{2}$') { $apimCorsProxyIP = '{0}/32' -f $apimCorsProxyIP }
$allowedPublicIPsCollection = @($allowedPublicIPs -replace '\[|\]|"|\s' -split ',') | ForEach-Object {
	if ($_ -notmatch '\/\d{2}$') { '{0}/32' -f $_ } else { $_ }
}


# Build the IP restrictions objects:
$ipSecurityRestrictions = @(
	[PSCustomObject]@{
		ipAddress = $appgwPublicIp
		action    = 'Allow'
		priority  = 1000
		name      = 'WAF'
	}
)
$ipSecurityRestrictions += @(
	[PSCustomObject]@{
		ipAddress = $apimPublicIp
		action    = 'Allow'
		priority  = 2000
		name      = 'APIM'
	}
)
$ipSecurityRestrictions += @(
	[PSCustomObject]@{
		ipAddress = $apimCorsProxyIP
		action    = 'Allow'
		priority  = 2100
		name      = 'APIMCorsProxy'
	}
)
$ipSecurityRestrictions += for ($i = 0; $i -lt @($allowedPublicIPsCollection).Count; $i++) {
	$ipAllowed = if (@($allowedPublicIPsCollection).Count -eq 1) { $allowedPublicIPsCollection } else { ($allowedPublicIPsCollection)[$i] }
	[PSCustomObject]@{
		ipAddress = $ipAllowed
		action    = 'Allow'
		priority  = (3000 + $i)
		name      = $ipAllowed -replace '\.|/', '-'
	}
}
$webSiteIpRestrictions = $ipSecurityRestrictions | Where-Object { $_.Name -notmatch 'APIM' }
$functionIpRestrictions = $ipSecurityRestrictions | Where-Object { $_.Name -notmatch 'WAF' }
$scmIpRestrictions = $ipSecurityRestrictions | Where-Object { $_.Name -notmatch 'APIM|WAF' }


# Loop through all the apps
foreach ($resourceId in @($webResources -replace '\[|\]|"|\s' -split ',')) {

	Write-Host ("`nSearching for {0}" -f $resourceId)
	$resourceGroup, $name = ($resourceId -split '/')[4, 8]
	$app = Get-AzWebApp -ResourceGroupName $resourceGroup -Name $name
	#$app = Get-AzResource -ResourceId $resourceId -ExpandProperties
	Write-Host ("`tWorking on {0}" -f $app.Name)

	# Select the relevant IP restrictions per application type (webApp|function):
	switch ($app.Kind) {
		'app' {
			Write-Host ("`t{0} is a webApp" -f $app.Name)
			$ipRestrictions = $webSiteIpRestrictions
			break
		}
		'functionapp' {
			Write-Host ("`t{0} is a function" -f $app.Name)
			$ipRestrictions = $functionIpRestrictions
			break
		}
		default {
			Write-Host ("`t{0} is a {1}" -f $app.Name, $app.Kind)
			$ipRestrictions = $webSiteIpRestrictions
		}
	}


	# Build the path:
	$path = $basePath -f $subscriptionId, $app.ResourceGroup, $app.Name, $apiVersion


	# Build the json payload:
	$body = @"
{
"properties": {
"ipSecurityRestrictions": $($ipRestrictions | ConvertTo-Json -AsArray -Compress),
"scmIpSecurityRestrictions": $($scmIpRestrictions | ConvertTo-Json -AsArray -Compress)
}
}
"@

	# For debugging only:
	#Write-Debug -Message $body -Debug
	#Write-Debug -Message $path -Debug

	# Add the IP restrictions
	Write-Host ("`tSaving the IP restrictions on the web resource")
	$res = Invoke-AzRestMethod -Path $path -Method PUT -Payload $body
	if (-not $res) {
		Write-Host ("`t##[warning] There was an error saving the IP restrictions")
	} elseif (200 -ne $res.StatusCode) {
		Write-Host ("`t##[warning] Error {0}: {1}" -f $res.StatusCode, (($res.Content | ConvertFrom-Json).error.message))
		Write-Host ($res.Content.ToString())
		Write-Host ($res | Out-String)
	}
}