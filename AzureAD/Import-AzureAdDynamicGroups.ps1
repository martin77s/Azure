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
    $TenantId = '00000000-0000-0000-0000-000000000000',
    $DataFile = 'C:\Temp\groups.csv'
)

#endregion


#region Helper functions

function Connect-AadApi {
    
    PARAM($TimeOut = 60)

    $ClientID = '1950a258-227b-4e31-a9cf-717495945fc2' # Azure PowerShell
    $TenantID = 'common'
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
    $token
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
        "Authorization" = "Bearer $($authToken)";
        "Content-Type"  = "application/json";
    }

    # Build the params and call the API:
    $params = @{
        Uri             = $apiUri
        Method          = $method
        Headers         = $headers
        Body            = if ($method -eq 'Get') { $null } else { $payload }
        ErrorAction     = 'Stop'
        UseBasicParsing = $true
    }; $response = Invoke-RestMethod @params
    if ($?) {
        $response | ConvertTo-Json -Depth 100
    }
}

#endregion



#region Main

$authToken = Connect-AadApi

Import-Csv -Path $DataFile | Where-Object { $_.membershipType -eq 'Dynamic' } | Select-Object -First 2 | ForEach-Object {

    $payload = @{
        displayName = $_.'New Name'
        mailNickname = $_.'New Name'
        description = $_.'New Name'
        membershipRule = ($_.'Dynamic Rule' -replace "''", '"') -replace '^or '
        membershipRuleProcessingState = 'On'
    }

    if($_.groupType -eq 'Security' ) { 
        $payload['mailEnabled'] = $false
        $payload['securityEnabled'] = $true
        $payload['groupTypes'] = @('DynamicMembership')
    
    } else { ## groupType = 'Microsoft 365'
        $payload['mailEnabled'] = $true
        $payload['securityEnabled'] = $false
        $payload['groupTypes'] = @('DynamicMembership', 'Unified')
    }

    $body = ConvertTo-Json -InputObject $payload
    try {
        $null = Invoke-AadApi -apiUri 'https://graph.microsoft.com/beta/groups' -payload $body -method POST -authToken $authToken.access_token
    } catch {
        Write-Output ('Error creating group {0}. {1}' -f $payload.displayName, $_.Exception.Message)
    }
}

#endregion