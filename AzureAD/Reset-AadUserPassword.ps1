<#

Script Name	: Reset-AadUserPassword.ps1
Description	: Reset an Azure AD (cloud only) user's password, authenticating using a service principal
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, AAD

#>


PARAM(
    [Parameter(Mandatory)] [string] $tenantId,
    [Parameter(Mandatory)] [string] $clientId,
    [Parameter(Mandatory)] [string] $clientSecret,
    [Parameter(Mandatory)] [string] $userPrincipalName ,
    [string] $newPassword = 'Qwerty!@3456',
    [bool] $forceChangePasswordNextSignIn = $false
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


# Get the authentication token:
$authToken = Get-AzToken -TenantId $tenantId -ClientId $clientId -ClientSecret $clientSecret


# Get the user's profile
$apiUri = 'https://graph.microsoft.com/v1.0/users/{0}' -f $userPrincipalName
$payload = '{}'
$method = 'GET'
$response = Invoke-AadApi -apiUri $apiUri -payload $payload -method $method -authToken $authToken

if ($response) {
    # Reset the user's password
    $apiUri = 'https://graph.microsoft.com/v1.0/users/{0}' -f ($response | ConvertFrom-Json).id
    $payload = @{
        passwordProfile = @{
            forceChangePasswordNextSignIn = $forceChangePasswordNextSignIn
            password                      = $newPassword
        }
    } | ConvertTo-Json
    $method = 'Patch'
    $response = Invoke-AadApi -apiUri $apiUri -payload $payload -method $method -authToken $authToken
} else {
    Write-Host "Error getting the user's profile"
}