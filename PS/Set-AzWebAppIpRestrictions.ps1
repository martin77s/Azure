<#

Script Name	: Set-AzWebAppIpRestrictions.ps1
Description	: Set IP restrictions (and SCM restrictions) to all webApps in a resource group
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/10/18
Keywords	: Azure, Security, IP, SCM, IPRestrictions, WebApp

#>


[cmdletBinding()]

#region Script parameters
PARAM(
    [Parameter(Mandatory = $false)] [string] $TenantId = (Get-AzContext).Tenant.Id,
    [Parameter(Mandatory = $false)] [string] $SubscriptionId = (Get-AzContext).Subscription.Id,
    [Parameter(Mandatory = $false)] [string] $ResourceGroupName = 'rg-web',
    [Parameter(Mandatory = $false)] [string[]] $IpRestrictions = $null,
	[Parameter(Mandatory = $false)] [string[]] $scmIpRestrictions = $null
)
#endregion


#region Script variables

$apiVersion = '2019-08-01'
$basePath = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Web/sites/{2}/config/web?api-version={3}'

#endregion


#region Helper Functions

function Get-AzAccesTokenFromServicePrincipal {
    param(
        [string] $TenantID,
        [string] $ClientID,
        [string] $ClientSecret
    )

    $TokenEndpoint = 'https://login.windows.net/{0}/oauth2/token' -f $TenantID
    $ARMResource = 'https://management.core.windows.net/'

    $Body = @{
        'resource'      = $ARMResource
        'client_id'     = $ClientID
        'grant_type'    = 'client_credentials'
        'client_secret' = $ClientSecret
    }
    $params = @{
        ContentType = 'application/x-www-form-urlencoded'
        Headers     = @{'accept' = 'application/json' }
        Body        = $Body
        Method      = 'Post'
        URI         = $TokenEndpoint
    }
    $token = Invoke-RestMethod @params
    ('Bearer ' + ($token.access_token).ToString())
}


function Get-AzAccesTokenFromCurrentUser {
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList $azProfile
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    ('Bearer ' + $token.AccessToken)
}

#endregion


#region Login to Azure and set the subscription context

Write-Verbose -Message 'Login to Azure (PowerShell)'
# *** Add-AzAccount -TenantId $tenantId | Out-Null

Write-Verbose -Message 'Login to Azure (az cli)'
# *** az login -t $tenantId 2>&1>null

Write-Verbose -Message 'Setting the subscription context (PowerShell)'
Set-AzContext -SubscriptionId $SubscriptionId -Tenant $tenantId -Force | Out-Null

Write-Verbose -Message 'Setting the subscription context (az cli)'
az account set -s $subscriptionId

#endregion


#region Main

# Build the ipSecurityRestrictions collection:
if ([string]::IsNullOrEmpty($IpRestrictions)) {
	$IPsCollection = @()
} else {
	$IPsCollection = @(($IpRestrictions -replace '\s') -split ',')
}
$IPsCollection = $IPsCollection | ForEach-Object {
	if ($_ -notmatch '\/\d{2}$') { '{0}/32' -f $_ } else { $_ }
}

if ([string]::IsNullOrEmpty($scmIpRestrictions)) {
	$scmIPsCollection = @()
} else {
	$scmIPsCollection = @(($scmIpRestrictions -replace '\s') -split ',')
}
$scmIPsCollection = $scmIPsCollection | ForEach-Object {
	if ($_ -notmatch '\/\d{2}$') { '{0}/32' -f $_ } else { $_ }
}


# Build the IP restrictions objects:
$ipSecurityRestrictions = @()
$ipSecurityRestrictions += for ($i = 0; $i -lt @($IPsCollection).Count; $i++) {
	$ipRange = if (@($IPsCollection).Count -eq 1) { $IPsCollection } else { ($IPsCollection)[$i] }
	[PSCustomObject]@{
		name      = $ipRange
		ipAddress = $ipRange
		action    = 'Allow'
		priority  = (3000 + $i)
	}
}

$scmIpSecurityRestrictions = @()
$scmIpSecurityRestrictions += for ($i = 0; $i -lt @($scmIPsCollection).Count; $i++) {
	$ipRange = if (@($scmIPsCollection).Count -eq 1) { $scmIPsCollection } else { ($scmIPsCollection)[$i] }
	[PSCustomObject]@{
		name      = $ipRange
		ipAddress = $ipRange
		action    = 'Allow'
		priority  = (3000 + $i)
	}
}


# Get the bearer token for the current logged on user:
$AuthorizationToken = Get-AzAccesTokenFromCurrentUser


# Get the webApp resources
$webApps = Get-AzWebApp -ResourceGroupName $ResourceGroupName


foreach ($app in $webApps) {

	Write-Host ("`nWorking on {0}" -f $app.Name)

	# Build the path:
	$path = $basePath -f $subscriptionId, $app.ResourceGroup, $app.Name, $apiVersion

	# Build the json payload:
	$body = @"
{
	"properties": {
		"ipSecurityRestrictions": $($ipSecurityRestrictions | ConvertTo-Json -AsArray -Compress),
		"scmIpSecurityRestrictions": $($scmIpSecurityRestrictions | ConvertTo-Json -AsArray -Compress)
	}
}
"@
	if ($null -eq $scmIpRestrictions) {
		$body = $body -replace '"scmIpSecurityRestrictions":', '"scmIpSecurityRestrictions":[]'
	}

	# For debugging only:
	#Write-Debug -Message $body -Debug
	#Write-Debug -Message $path -Debug

	# Add the IP restrictions
	Write-Host ("`tSaving the IP restrictions on the web resource")
	$res = Invoke-AzRestMethod -Path $path -Method PUT -Payload $body
	if(-not $res) {
		Write-Host ("`t##[warning] There was an error saving the IP restrictions")
	} elseif (200 -ne $res.StatusCode) {
		Write-Host ("`t##[warning] Error {0}: {1}" -f $res.StatusCode, (($res.Content | ConvertFrom-Json).error.message))
		Write-Host ($res.Content.ToString())
		Write-Host ($res | Out-String)
	}

}