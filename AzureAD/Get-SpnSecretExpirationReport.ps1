<#

Script Name	: Get-SpnSecretExpirationReport.ps1
Description	: Get a report on the expiring secrets of appRegistrations (servicePrincipals) in Azure AD
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, AAD, API, Applications, AppRegistrations
Reference	: https://docs.microsoft.com/en-us/graph/api/application-list

#>


PARAM(
    $ExpirationDaysThreshold = 90
)

function Get-AzToken {
    PARAM(
        [Parameter(Mandatory = $true)] [string] $tenantId,
        [Parameter(Mandatory = $true)] [string] $clientId,
        [Parameter(Mandatory = $true)] [string] $clientSecret
    )

    $body = @{
        'tenant'        = $tenantId
        'client_id'     = $clientId
        'scope'         = 'https://graph.microsoft.com/.default'
        'client_secret' = $clientSecret
        'grant_type'    = 'client_credentials'
    }

    $params = @{
        'Uri'         = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
        'Method'      = 'Post'
        'body'        = $body
        'ContentType' = 'application/x-www-form-urlencoded'
    }
    $authResponse = Invoke-RestMethod @params
    $authResponse.access_token
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


# Example vars, should be saved securely (at least the clientSecret):
$tenantId = ''
$clientId = ''
$clientSecret = ''

# Get the authentication token:
$authToken = Get-AzToken -TenantId $tenantId -ClientId $clientId -ClientSecret $clientSecret

# Get the appRegistrations using paging (requires: Application.Read.All | Application.ReadWrite.All | Directory.Read.All)
$apps = @()
$apiUri = 'https://graph.microsoft.com/v1.0/applications?$select=appId,displayName,passwordCredentials&$top=999'
do {
    $response = Invoke-AadApi -apiUri $apiUri -payload '{}' -method GET -authToken $authToken | ConvertFrom-Json
    $apps += $response.Value
    $apiUri = $response.'@odata.nextLink'
} until ($null -eq $response.'@odata.nextLink')
$report = $apps | Where-Object -PipelineVariable app { $_.passwordCredentials } | ForEach-Object {
    $_.passwordCredentials | Select-Object @{N = 'appId'; E = { $app.appId } },
    @{N = 'appDisplayName'; E = { $app.displayName } }, @{N = 'secretDescription'; E = { $_.displayName } },
    @{N = 'secretEndDateTime'; E = { $_.endDateTime } }, @{N = 'secretStartDateTime'; E = { $_.startDateTime } },
    @{N = 'secretStatus'; E = {
            switch ( $_.endDateTime) {
                { $_ -lt (Get-Date) } { 'Expired'; break; }
                { $_ -lt (Get-Date).AddDays($ExpirationDaysThreshold) } { 'AboutToExpire'; break; }
                default { 'OK' }
            }
        }
    }
} | Sort-Object -Property secretEndDateTime

# $report
$report | Where-Object { $_.secretStatus -ne 'OK' }