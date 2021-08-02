<#

Script Name	: AzAdGraphExamples.ps1
Description	: Query Azure Active Directory with GraphAPI
Author		: Martin Schvartzman, Microsoft
Keywords	: AzureAD, AuthToken, GraphAPI
References	: https://docs.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0

#>

function Get-AzureAdAuthTokenUser {
    PARAM(
        $TenantId = 'common',
        $TimeOut = 60
    )

    $localEpoch = (Get-Date -Date '1970/01/01 00:00:00').AddMinutes((Get-TimeZone).BaseUtcOffset.TotalMinutes)

    if (-not ($global:aadApi_token -and $localEpoch.AddSeconds(($global:aadApi_token).expires_on) -gt (Get-Date))) {

        $ClientID = '1950a258-227b-4e31-a9cf-717495945fc2' # Azure PowerShell
        $Resource = 'https://graph.microsoft.com'

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

    $global:aadApi_token
}


function Get-AzureAdAuthTokenServicePrincipal {
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
    $authResponse
}


function Invoke-AzureAdGraphApi {
    PARAM(
        [Parameter(Mandatory = $true)] [string] $Uri,
        [Parameter(Mandatory = $true)] [string] $Body,
        [Parameter(Mandatory = $false)] [string] $Method = 'Post',
        [Parameter(Mandatory = $true)] [string] $AuthToken
    )

    # Build the request headers:
    $headers = @{
        "Authorization" = "Bearer $($AuthToken)";
        "Content-Type"  = "application/json";
    }

    # Build the params and call the API:
    $params = @{
        Uri             = $Uri
        Method          = $Method
        Headers         = $headers
        Body            = if ($Method -eq 'Get') { $null } else { $Body }
        ErrorAction     = 'Stop'
        UseBasicParsing = $true
    }; $response = Invoke-RestMethod @params
    if ($?) {
        $response | ConvertTo-Json -Depth 100
    }
}


# Get the authentication token using device login credentials:
$authToken = (Get-AzureAdAuthTokenUser).access_token



# Get the authentication token using a service principal:
$params = @{
    # Example vars, should be saved securely (at least the clientSecret)
    TenantId     = '<Enter-The-TenantId-Here>'
    ClientId     = '<Enter-The-ClientId-Here>'
    ClientSecret = '<Enter-The-ClientSecret-Here>'
};
$authToken = (Get-AzureAdAuthTokenServicePrincipal @params).access_token



# Get all users in AAD (User.Read.All):
$uri = 'https://graph.microsoft.com/v1.0/users'
$body = '{}'
$method = 'GET'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# Is Security Defaults enabled in AAD (Policy.Read.All):
$uri = 'https://graph.microsoft.com/v1.0/policies/identitySecurityDefaultsEnforcementPolicy'
$body = '{}'
$method = 'GET'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# List riskyUsers (IdentityRiskyUser.Read.All):
$uri = 'https://graph.microsoft.com/v1.0/identityProtection/riskyUsers'
$body = '{}'
$method = 'GET'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# List Groups (GroupMember.Read.All):
$uri = 'https://graph.microsoft.com/v1.0/groups'
$body = '{}'
$method = 'GET'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# Create a group (Group.ReadWrite.All):
$uri = 'https://graph.microsoft.com/v1.0/groups'
$body = @{
    description     = 'An optional description for the group'
    displayName     = 'The display name for the group. This property is required when a group is created and it cannot be cleared during updates'
    groupTypes      = @('Unified')
    mailEnabled     = $true
    mailNickname    = 'myGroup'
    securityEnabled = $false
} | ConvertTo-Json
$method = 'POST'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# Update a group (Group.ReadWrite.All):
$groupId = 'a3e52c4a-71fc-48f7-92c8-563d6eb2b3f0'
$uri = 'https://graph.microsoft.com/v1.0/groups/{0}' -f $groupId
$body = @{
    description     = 'This is my group'
    displayName     = 'My Group'
    groupTypes      = @('Unified')
    mailEnabled     = $true
    mailNickname    = 'myGroup'
    securityEnabled = $false
} | ConvertTo-Json
$method = 'PATCH'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# Add a group member (Group.ReadWrite.All):
$groupId = 'a3e52c4a-71fc-48f7-92c8-563d6eb2b3f0'
$userIdToAdd = '4ff1c705-387f-428a-8f2a-bdc759bf87c1'
$uri = 'https://graph.microsoft.com/v1.0/groups/{0}/members/$ref' -f $groupId
$body = @{
    "@odata.id" = 'https://graph.microsoft.com/v1.0/users/{0}' -f $userIdToAdd
} | ConvertTo-Json
$method = 'POST'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# Add multiple group members (Group.ReadWrite.All):
$groupId = 'a3e52c4a-71fc-48f7-92c8-563d6eb2b3f0'
$userIdsToAdd = @('1353d3af-1581-4bf0-b480-a612a8b49038', '711baa9f-6a6d-4796-84ea-2eafc61dd908', 'aec1f2f0-5cab-49a7-b062-326e85214d3a')
$uri = 'https://graph.microsoft.com/v1.0/groups/{0}/members/$ref' -f $groupId
$body = @{
    "members@odata.bind" = @(
        $userIdsToAdd | ForEach-Object { 'https://graph.microsoft.com/v1.0/users/{0}' -f $_ }
    )
} | ConvertTo-Json
$method = 'POST'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# Delete a group (Group.ReadWrite.All):
$groupId = 'a3e52c4a-71fc-48f7-92c8-563d6eb2b3f0'
$uri = 'https://graph.microsoft.com/v1.0/groups/{0}' -f $groupId
$body = '{}'
$method = 'DELETE'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# List ConditionalAccess policies (Policy.Read.All):
$uri = 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'
$body = '{}'
$method = 'GET'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# List secure scores (SecurityEvents.Read.All, SecurityEvents.ReadWrite.All):
$uri = 'https://graph.microsoft.com/v1.0/security/secureScores'
$body = '{}'
$method = 'GET'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# List secure scores control profiles (SecurityEvents.Read.All):
$uri = 'https://graph.microsoft.com/v1.0/security/secureScoreControlProfiles'
$body = '{}'
$method = 'GET'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# List directoryRoles (RoleManagement.Read.Directory, Directory.Read.All)
$uri = 'https://graph.microsoft.com/v1.0/directoryRoles'
$body = '{}'
$method = 'GET'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# List directoryRoleTemplates (RoleManagement.Read.Directory, Directory.Read.All)
$uri = 'https://graph.microsoft.com/v1.0/directoryRoleTemplates'
$body = '{}'
$method = 'GET'
Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method $method -AuthToken $authToken



# List specific role members (RoleManagement.Read.Directory, Directory.Read.All):
$roleTemplateIds = @{ # This is a partial list. For the full list, see the directoryRoleTemplates API above
    'Company Administrator'      = '62e90394-69f5-4237-9190-012177145e10'
    'Guest Inviter'              = '95e79109-95c0-4d8e-aee3-d01accf2d47b'
    'User Account Administrator' = 'fe930be7-5e62-47db-91af-98c3a49a38b1'
    'Security Reader'            = '5d6b6bb7-de71-4623-b4af-96380a352509'
    'Security Administrator'     = '194ae4cb-b126-40b2-bd5b-6091b380977d'
    'Global Reader'              = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451'
}
$directoryRoles = (Invoke-AzureAdGraphApi -Uri 'https://graph.microsoft.com/v1.0/directoryRoles' -Body '{}' -Method GET -AuthToken $authToken | ConvertFrom-Json)
$roleId = ($directoryRoles.value | Where-Object { $_.roleTemplateId -eq $roleTemplateIds['Guest Inviter'] }).id
$uri = 'https://graph.microsoft.com/v1.0/directoryRoles/{0}/members' -f $roleId
$guestInviters = Invoke-AzureAdGraphApi -Uri $uri -Body '{}' -Method GET -AuthToken $authToken
$guestInviters

$roleId = ($directoryRoles.value | Where-Object { $_.roleTemplateId -eq $roleTemplateIds['Company Administrator'] }).id
$uri = 'https://graph.microsoft.com/v1.0/directoryRoles/{0}/members' -f $roleId
$globalAdmins = Invoke-AzureAdGraphApi -Uri $uri -Body '{}' -Method GET -AuthToken $authToken
$globalAdmins


