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


# List directoryRoles (RoleManagement.Read.Directory, Directory.Read.All)
$apiUri = 'https://graph.microsoft.com/v1.0/directoryRoles'
$payload = '{}'
$method = 'GET'
Invoke-AadApi -apiUri $apiUri -payload $payload -method $method -authToken $authToken


# List directoryRoleTemplates (RoleManagement.Read.Directory, Directory.Read.All)
$apiUri = 'https://graph.microsoft.com/v1.0/directoryRoleTemplates'
$payload = '{}'
$method = 'GET'
Invoke-AadApi -apiUri $apiUri -payload $payload -method $method -authToken $authToken


# List specific role members (RoleManagement.Read.Directory, Directory.Read.All):
$roleTemplateIds = @{ # This is a partial list. For the full list, see the directoryRoleTemplates API above
    'Company Administrator'      = '62e90394-69f5-4237-9190-012177145e10'
    'Guest Inviter'              = '95e79109-95c0-4d8e-aee3-d01accf2d47b'
    'User Account Administrator' = 'fe930be7-5e62-47db-91af-98c3a49a38b1'
    'Security Reader'            = '5d6b6bb7-de71-4623-b4af-96380a352509'
    'Security Administrator'     = '194ae4cb-b126-40b2-bd5b-6091b380977d'
    'Global Reader'              = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451'
}
$directoryRoles = (Invoke-AadApi -apiUri 'https://graph.microsoft.com/v1.0/directoryRoles' -payload '{}' -method GET -authToken $authToken | ConvertFrom-Json)
$roleId = ($directoryRoles.value | Where-Object { $_.roleTemplateId -eq $roleTemplateIds['Guest Inviter'] }).id
$apiUri = 'https://graph.microsoft.com/v1.0/directoryRoles/{0}/members' -f $roleId
$guestInviters = Invoke-AadApi -apiUri $apiUri -payload '{}' -method GET -authToken $authToken
$guestInviters

$roleId = ($directoryRoles.value | Where-Object { $_.roleTemplateId -eq $roleTemplateIds['Company Administrator'] }).id
$apiUri = 'https://graph.microsoft.com/v1.0/directoryRoles/{0}/members' -f $roleId
$globalAdmins = Invoke-AadApi -apiUri $apiUri -payload '{}' -method GET -authToken $authToken
$globalAdmins
