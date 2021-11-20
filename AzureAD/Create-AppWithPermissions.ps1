PARAM(
    $TenantId = '00000000-0000-0000-0000-000000000000',
    $SpnDisplayName = 'spn-martin2',
    [ValidateSet('v1.0', 'beta')] $GraphApiVersion = 'v1.0'
)

function Get-AzureAdAuthTokenUser {
    PARAM(
        $TenantId = 'common',
        $TimeOut = 60
    )

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
    $token
}


function Invoke-AzureAdGraphApi {
    PARAM(
        [Parameter(Mandatory = $true)] [string] $Uri,
        [Parameter(Mandatory = $true)] [string] $Body,
        [Parameter(Mandatory = $false)] [string] $Method = 'Post',
        [Parameter(Mandatory = $true)] [string] $AuthToken,
        [Parameter(Mandatory = $false)] [switch] $SkipHttpErrorCheck
    )

    # Build the request headers:
    $headers = @{
        "Authorization" = "Bearer $($AuthToken)";
        "Content-Type"  = "application/json";
    }

    # Build the params and call the API:
    $params = @{
        Uri                = $Uri
        Method             = $Method
        Headers            = $headers
        Body               = if ($Method -eq 'Get') { $null } else { $Body }
        ErrorAction        = 'Stop'
        UseBasicParsing    = $true
        SkipHttpErrorCheck = $SkipHttpErrorCheck
    }; $response = Invoke-RestMethod @params
    if ($?) {
        $response | ConvertTo-Json -Depth 100
    }
}


# Required Graph API permissions, see https://github.com/martin77s/Azure/blob/master/AzureAD/MsGraphApiOauth2Permissions.md:
$graphApiPermissions = @{
    '7ab1d382-f21e-4acd-a863-ba3e13f7da61' = 'Directory.Read.All'
    '62a82d76-70ea-41e2-9197-370581804d09' = 'Group.ReadWrite.All'
}


# Get the authentication token from the device login:
$authToken = (Get-AzureAdAuthTokenUser -TenantId $TenantId).access_token


# Create the *application* object:
$body = @{
    displayName = $SpnDisplayName
} | ConvertTo-Json
$uri = 'https://graph.microsoft.com/{0}/applications' -f $GraphApiVersion
$appResponse = Invoke-AzureAdGraphApi -Uri $uri -Body $body -Method POST -AuthToken $authToken | ConvertFrom-Json


# Verify the application object was created:
$uri = 'https://graph.microsoft.com/{0}/applications/{1}' -f $GraphApiVersion, $appResponse.Id
$appObject = Invoke-AzureAdGraphApi -Uri $uri -Body '{}' -Method GET -AuthToken $authToken | ConvertFrom-Json
if (!$appObject) {
    Write-Host 'Application object not created!'
    break
}


# Create the *servicePrincipal* object:
$body = @{
    appId = $appResponse.appId
} | ConvertTo-Json
$uri = 'https://graph.microsoft.com/{0}/servicePrincipals/' -f $GraphApiVersion
$spnResponse = Invoke-AzureAdGraphApi -Uri $uri -AuthToken $authToken -body $body -Method POST | ConvertFrom-Json


# Verify the servicePrincipal object was created:
$uri = 'https://graph.microsoft.com/{0}/servicePrincipals/{1}' -f $GraphApiVersion, $spnResponse.Id
$spnObject = Invoke-AzureAdGraphApi -Uri $uri -Body '{}' -Method GET -AuthToken $authToken | ConvertFrom-Json
if (!$spnObject) {
    Write-Host 'servicePrincipal object not created!'
    break
}


# Add a password:
$body = @{
    passwordCredential = @{
        displayName = 'key for {0} created on {1}' -f $SpnDisplayName, [datetime]::UtcNow
        endDateTime = '{0:yyyy-MM-ddTHH:mm:ss.fffK}' -f ([datetime]::UtcNow).AddYears(2)
    }
} | ConvertTo-Json
$uri = 'https://graph.microsoft.com/{0}/applications/{1}/addPassword' -f $GraphApiVersion, $appResponse.Id
$passResponse = Invoke-AzureAdGraphApi -Uri $uri -AuthToken $authToken -body $body -Method POST | ConvertFrom-Json
if (!$passResponse) {
    Write-Host 'password not added!'
    break
}


# Add MSGraph API permissions:
$body = @{
    requiredResourceAccess = @(
        @{
            resourceAppId  = '00000003-0000-0000-c000-000000000000' # Microsoft Graph
            resourceAccess = $graphApiPermissions.Keys | ForEach-Object {
                @{
                    id   = $_
                    type = 'Role'
                }
            }
        }
    )
} | ConvertTo-Json -Depth 4
$uri = 'https://graph.microsoft.com/{0}/applications/{1}' -f $GraphApiVersion, $appResponse.id
$apiPermissionResponse = Invoke-AzureAdGraphApi -Uri $uri -AuthToken $authToken -body $body -Method PATCH
$apiPermissionResponse


# Consent the MSGraph API Permissions: <-- This doesn't work
$body = @{
    clientAppId        = $spnResponse.appId
    onBehalfOfAll      = $true
    checkOnly          = $false
    tags               = @()
    constrainToRra     = $true
    dynamicPermissions = @(
        @{
            appIdentifier = '00000003-0000-0000-c000-000000000000' # Microsoft Graph
            appRoles      = @($graphApiPermissions.Values)
            scopes        = @()
        }
    )
} | ConvertTo-Json -Depth 4
$uri = 'https://graph.windows.net/myorganization/consentToApp?api-version=2.0' -f $GraphApiVersion, $spnResponse.Id
$consentResponse = Invoke-AzureAdGraphApi -Uri $uri -AuthToken $authToken -body $body -Method PUT -SkipHttpErrorCheck
$consentResponse


# Save the credentials to a file for later use:
$credentialsFile = './creds-{0}.json' -f $SpnDisplayName
@{
    TenantId     = $TenantId
    ClientId     = $appResponse.appId
    ClientSecret = $passResponse.secretText
} | ConvertTo-Json | Out-File -Encoding UTF8 -Force -FilePath $credentialsFile
