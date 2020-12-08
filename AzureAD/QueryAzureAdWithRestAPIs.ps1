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
Param (
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
    if($?) {
        $response | ConvertTo-Json
    }
}


# Example vars, should be saved securely (at least the clientSecret):
$tenantId = '<Enter-The-TenantId-Here>'
$clientId = '<Enter-The-ClientId-Here>'
$clientSecret = '<Enter-The-ClientSecret-Here>'

# Get the authentication token:
$authToken = Get-AzToken -TenantId $tenantId -ClientId $clientId -ClientSecret $clientSecret


# To get a list of all the APIs and the minimum required permissions, see:
# https://docs.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0


# Get all users in AAD (User.Read.All):
$apiUri = 'https://graph.microsoft.com/v1.0/users'
$payload = '{}'
$method = 'GET'
Invoke-AadApi -apiUri $apiUri -payload $payload -method $method -authToken $authToken


# Is Security Defaults enabled in AAD (Policy.Read.All):
$apiUri = 'https://graph.microsoft.com/v1.0/policies/identitySecurityDefaultsEnforcementPolicy'
$payload = '{}'
$method = 'GET'
Invoke-AadApi -apiUri $apiUri -payload $payload -method $method -authToken $authToken


# List riskyUsers (IdentityRiskyUser.Read.All):
$apiUri = 'https://graph.microsoft.com/v1.0/identityProtection/riskyUsers'
$payload = '{}'
$method = 'GET'
Invoke-AadApi -apiUri $apiUri -payload $payload -method $method -authToken $authToken


# List ConditionalAccess policies (Policy.Read.All):
$apiUri = 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'
$payload = '{}'
$method = 'GET'
Invoke-AadApi -apiUri $apiUri -payload $payload -method $method -authToken $authToken


# List secure scores (SecurityEvents.Read.All, SecurityEvents.ReadWrite.All):
$apiUri = 'https://graph.microsoft.com/v1.0/security/secureScores'
$payload = '{}'
$method = 'GET'
Invoke-AadApi -apiUri $apiUri -payload $payload -method $method -authToken $authToken


# List secure scores control profiles (SecurityEvents.Read.All):
$apiUri = 'https://graph.microsoft.com/v1.0/security/secureScoreControlProfiles'
$payload = '{}'
$method = 'GET'
Invoke-AadApi -apiUri $apiUri -payload $payload -method $method -authToken $authToken


