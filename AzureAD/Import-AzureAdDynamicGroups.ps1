<#

Script Name	: Import-AzureAdDynamicGroups.ps1
Description	: Create AzureAD dynamic groups from a CSV file
Author		: Martin Schvartzman, Microsoft
Last Update	: 2021/02/08
Keywords	: AzureAD, AzureADGroups, GraphAPI, Beta
References  : https://docs.microsoft.com/en-us/graph/api/resources/groups-overview?view=graph-rest-beta

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



#region Script parameters

[CmdletBinding()]

PARAM(
    $TenantId = 'common',
    $DataFilePath = 'C:\Temp\groups.csv',
    [ValidateSet('Unicode','UTF7','UTF8','ASCII','UTF32','BigEndianUnicode','Default','OEM')]$DataFileEncoding = 'UTF8'
)

#endregion


#region Helper functions

function Connect-AadApi {
    
    PARAM($TimeOut = 60)

    $localEpoch = (Get-Date -Date '1970/01/01 00:00:00').AddMinutes((Get-TimeZone).BaseUtcOffset.TotalMinutes)

    if(-not ($global:aadApi_token -and $localEpoch.AddSeconds(($global:aadApi_token).expires_on) -gt (Get-Date))) {

        $ClientID = '1950a258-227b-4e31-a9cf-717495945fc2' # Azure PowerShell
        $Resource = "https://graph.microsoft.com/"

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
                    grant_type = "urn:ietf:params:oauth:grant-type:device_code"
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
}


function Invoke-AadApi {
    PARAM(
        [Parameter(Mandatory = $true)] [string] $apiUri,
        [Parameter(Mandatory = $true)] [string] $payload,
        [Parameter(Mandatory = $false)] [string] $method = 'Post',
        [Parameter(Mandatory = $true)] [string] $authToken
    )

    # Build the request headers:
    $headers = @{
        'Authorization'         = "Bearer $($authToken)"
        'Content-Type'          = 'application/json'
        'Accept'                = '*/*'
        'Accept-Language'       = 'en'
        'Accept-Encoding'       = 'gzip, deflate, br'
        'x-ms-effective-locale' = 'en.en-us'
    }

    # Build the params and call the API:
    $params = @{
        Uri             = $apiUri
        Method          = $method
        Headers         = $headers
        Body            = if ($method -eq 'Get') { $null } else { $payload }
        ErrorAction     = 'Stop'
        UseBasicParsing = $true
    }; $response = Invoke-RestMethod @params -UserAgent 'User-Agent: Mozilla/5.0'
    if ($?) {
        $response | ConvertTo-Json -Depth 100
    }
}

#endregion



#region Main

$authToken = Connect-AadApi

Import-Csv -Path $DataFilePath -Encoding $DataFileEncoding | Where-Object { $_.membershipType -eq 'Dynamic' } | ForEach-Object {

    $payload = @{
        displayName                   = $_.'New Name'
        mailNickname                  = $_.'New Name'
        description                   = $_.'New Name'
        membershipRule                = ($_.'Dynamic Rule' -replace "''", '"') -replace '^or '
        membershipRuleProcessingState = 'On'
    }

    if ($_.groupType -eq 'Security' ) { 
        $payload['mailEnabled'] = $false
        $payload['securityEnabled'] = $true
        $payload['groupTypes'] = @('DynamicMembership')
    
    } else {
        ## groupType = 'Microsoft 365'
        $payload['mailEnabled'] = $true
        $payload['securityEnabled'] = $false
        $payload['groupTypes'] = @('DynamicMembership', 'Unified')
    }

    $body = ConvertTo-Json -InputObject $payload

    try {
        $groupParams = @{
            apiUri    = 'https://graph.microsoft.com/beta/groups' 
            payload   = $body 
            method    = 'POST'
            authToken = $authToken.access_token
        }
        $null = Invoke-AadApi @groupParams

    } catch {
        Write-Output ('Error creating group {0}. {1}' -f $payload.displayName, $_.Exception.Message)
    }
}

#endregion