<#

Script Name	: Get-AzureAdAuthToken.ps1
Description	: Authenticate and get the token from AzureAD
Author		: Martin Schvartzman, Microsoft
Last Update	: 2021/02/08
Keywords	: AzureAD, AuthToken, GraphAPI
References  : https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-use-vm-token

 ============[DISCLAIMER]=========================================================================================================
  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
  INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object
  code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software 
  product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the 
  Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or 
  lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
 =================================================================================================================================

#>

[CmdletBinding()]

PARAM(
    $TenantId = 'common',
	$TimeOut = 60
)

$localEpoch = (Get-Date -Date '1970/01/01 00:00:00').AddMinutes((Get-TimeZone).BaseUtcOffset.TotalMinutes)

if(-not ($global:aadApi_token -and $localEpoch.AddSeconds(($global:aadApi_token).expires_on) -gt (Get-Date))) {

	$ClientID = '1950a258-227b-4e31-a9cf-717495945fc2' # Azure PowerShell
	$Resource = 'https://graph.microsoft.com/'

	$DeviceCodeRequestParams = @{
		Method = 'POST'
		Uri    = "https://login.microsoftonline.com/$TenantID/oauth2/devicecode"
		Body   = @{
			client_id = $ClientId
			resource  = $Resource
		}
	}

	$DeviceCodeRequest = Invoke-RestMethod @DeviceCodeRequestParams
	Write-Host $DeviceCodeRequest.message -ForegroundColor Yellow

	do {
		Start-Sleep -Seconds 3
		$TimeOut -= 3

		$TokenRequestParams = @{
			Method = 'POST'
			Uri    = "https://login.microsoftonline.com/$TenantId/oauth2/token"
			Body   = @{
				grant_type = 'urn:ietf:params:oauth:grant-type:device_code'
				code       = $DeviceCodeRequest.device_code
				client_id  = $ClientId
			}
		}
		try {
			$token = Invoke-RestMethod @TokenRequestParams
		} catch {
			$token = $null
		}

	} while ((-not $token) -and ($TimeOut -gt 0))
	
	$global:aadApi_token = $token
}

return $global:aadApi_token
