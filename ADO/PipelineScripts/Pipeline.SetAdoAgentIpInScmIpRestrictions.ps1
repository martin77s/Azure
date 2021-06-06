<#

Script Name	: Pipeline.SetAdoAgentIpInScmIpRestrictions.ps1
Description	: Add/Remove the Azure DevOps pooled agent's public IP address to/from the IP restrictions list on the AppService WebApp/WebAPI
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, AppService, IPRestrictions

#>

#Requires -PSEdition Core

PARAM(
	[Parameter(Mandatory)] [string] $ResourceGroupName,
	[Parameter(Mandatory)] [string] $AppServiceResourceName,
	[switch] $Remove
)


# Script variables:
$apiVersion = '2019-08-01'
$basePath = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Web/sites/{2}/config/web?api-version={3}'
$subscriptionId = (Get-AzContext).Subscription.Id
$adoIpRestrictionName = 'adoAgent'
$adoIpRestrictionPriority = '5000'
$ipifyUri = 'https://api.ipify.org/?format=json'
$saveFlagOn = $true

# Get the webApp resource
$app = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceResourceName
if ($app) {

	Write-Host ("`nFound the webApp resource: {0}" -f $app.name)

	# Build the path to the API:
	$path = $basePath -f $subscriptionId, $app.ResourceGroup, $app.Name, $apiVersion

	Write-Host ("`tGetting the current IP restrictions")
	$res = (Invoke-AzRestMethod -Path $path -Method GET).Content | ConvertFrom-Json
	$webSiteIpRestrictions = $res.properties.ipSecurityRestrictions
	$currentScmIpRestrictions = $res.properties.scmIpSecurityRestrictions

	if($Remove) {
		if ($currentScmIpRestrictions | Where-Object { $_.name -eq $adoIpRestrictionName }) {
			Write-Host ("`t`tRemoving the Azure DevOps agent IP from the list")
			$scmIpRestrictions = $currentScmIpRestrictions | Where-Object { $_.name -ne $adoIpRestrictionName }
		} else {
			Write-Host ("`t`tThe Azure DevOps agent IP wasn't in the list")
			$saveFlagOn = $false
		}
	} else {
		Write-Host ("`tGetting the Azure DevOps agent public IP address")
		$publicIp = (Invoke-WebRequest -Uri $ipifyUri).Content | ConvertFrom-Json
		$adoIpToSet = '{0}/32' -f $publicIp.ip
		Write-Host ("`t`tAzure DevOps agent public IP address: {0}" -f $adoIpToSet)

		$adoIpRestrictionExists = $currentScmIpRestrictions | Where-Object { $_.name -eq $adoIpRestrictionName }
		if ($adoIpRestrictionExists) {
			Write-Host ("`t`tUpdating the Azure DevOps agent IP in the list")
			$scmIpRestrictions = @(foreach ($item in $currentScmIpRestrictions) {
					[PSCustomObject]@{
						ipAddress = if ($item.name -eq $adoIpRestrictionName) { $adoIpToSet } else { $item.ipAddress }
						action    = $item.action
						priority  = $item.priority
						name      = $item.name
					}
				})
		} elseif ($currentScmIpRestrictions) {
			Write-Host ("`t`tAdding the Azure DevOps agent IP to the list")
			$scmIpRestrictions = @(foreach ($item in $currentScmIpRestrictions) {
					[PSCustomObject]@{
						ipAddress = $item.ipAddress
						action    = $item.action
						priority  = $item.priority
						name      = $item.name
					}
				})
			$scmIpRestrictions += [PSCustomObject]@{
				ipAddress = $adoIpToSet
				action    = 'Allow'
				priority  = $adoIpRestrictionPriority
				name      = $adoIpRestrictionName
			}
		} else {
			Write-Host ("`t`tAdding the Azure DevOps agent IP to the empty list")
			$scmIpRestrictions = @(
				[PSCustomObject]@{
					ipAddress = $adoIpToSet
					action    = 'Allow'
					priority  = $adoIpRestrictionPriority
					name      = $adoIpRestrictionName
				}
			)
		}
		if ($adoIpRestrictionExists -and $adoIpRestrictionExists.ipAddress -eq $adoIpToSet) {
			Write-Host ("`tThe correct IP address was already set on the resource")
			$saveFlagOn = $false
		}
	}

	if ($saveFlagOn) {

		# Build the json payload:
		$body = @"
{
	"properties": {
		"ipSecurityRestrictions": $($webSiteIpRestrictions | ConvertTo-Json -AsArray -Compress),
		"scmIpSecurityRestrictions": $($scmIpRestrictions | ConvertTo-Json -AsArray -Compress)
	}
}
"@
		# For debugging only:
		#Write-Debug -Message $body -Debug

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
} else {
	Write-Host ("`nNo such resource found ({0}/{1})" -f $ResourceGroupName, $AppServiceResourceName)
}
