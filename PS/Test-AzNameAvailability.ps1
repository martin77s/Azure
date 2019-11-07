
function Get-AccesTokenFromServicePrincipal {
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


function Get-AccesTokenFromCurrentUser {
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList $azProfile
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    ('Bearer ' + $token.AccessToken)
}


function Test-AzNameAvailability {
    param(
        [Parameter(Mandatory = $true)] [string] $AuthorizationToken,
        [Parameter(Mandatory = $true)] [string] $SubscriptionId,
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [ValidateSet(
            'ApiManagement', 'KeyVault', 'ManagementGroup', 'Sql', 'StorageAccount', 'WebApp')]
        $ServiceType
    )

    $uriByServiceType = @{
        ApiManagement   = 'https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.ApiManagement/checkNameAvailability?api-version=2019-01-01'
        KeyVault        = 'https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.KeyVault/checkNameAvailability?api-version=2019-09-01'
        ManagementGroup = 'https://management.azure.com/providers/Microsoft.Management/checkNameAvailability?api-version=2018-03-01-preview'
        Sql             = 'https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Sql/checkNameAvailability?api-version=2018-06-01-preview'
        StorageAccount  = 'https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Storage/checkNameAvailability?api-version=2019-06-01'
        WebApp          = 'https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Web/checkNameAvailability?api-version=2019-08-01'
    }

    $typeByServiceType = @{
        ApiManagement   = 'Microsoft.ApiManagement/service'
        KeyVault        = 'Microsoft.KeyVault/vaults'
        ManagementGroup = '/providers/Microsoft.Management/managementGroups'
        Sql             = 'Microsoft.Sql/servers'
        StorageAccount  = 'Microsoft.Storage/storageAccounts'
        WebApp          = 'Microsoft.Web/sites'
    }

    $uri = $uriByServiceType[$ServiceType] -replace ([regex]::Escape('{subscriptionId}')), $SubscriptionId
    $body = '"name": "{0}", "type": "{1}"' -f $Name, $typeByServiceType[$ServiceType]

    $response = (Invoke-WebRequest -Uri $uri -Method Post -Body "{$body}" -ContentType "application/json" -Headers @{Authorization = $AuthorizationToken }).content
    $response | ConvertFrom-Json |
        Select-Object @{N = 'Name'; E = { $Name } }, @{N = 'Type'; E = { $ServiceType } }, @{N = 'Available'; E = { $_ | Select-Object -ExpandProperty *available } }, Reason, Message
}

<#

Get-AzResourceProvider | 
    Where-Object { $_.ResourceTypes.ResourceTypeName -eq 'checkNameAvailability' } | 
        Select-Object ProviderNamespace
		

Get-AzResourceProvider -ProviderNamespace Microsoft.Web |
    Where-Object { $_.ResourceTypes.ResourceTypeName -eq 'checkNameAvailability' } |
        Select-Object -ExpandProperty ResourceTypes | 
            Select-Object -ExpandProperty ApiVersions


# Bougus variables:
$tenantId = '72f988bf-86f1-4400-91ab-2d7cd011db47'
$clientID = 'c9e2e0c9-af17-41af-9977-5e17e5b9b762'
$clientSecret = ':B:yHOVO0qlx.w9j-4UCHt6Ug/1UpJK!'
$subscriptionId = 'd75b13e4-2bf5-4c6d-86ad-c7a943a137f6'

# Get the bearer token for a service principal:
$AuthorizationToken = Get-AccesTokenFromServicePrincipal -TenantID $tenantId -ClientID $clientID -ClientSecret $clientSecret

# Get the bearer token for the current logged on user:
$AuthorizationToken = Get-AccesTokenFromCurrentUser

# Test for the name availability for some of the services:
Test-AzNameAvailability -AuthorizationToken $AuthorizationToken -SubscriptionId $subscriptionId -Name martin -ServiceType ApiManagement
Test-AzNameAvailability -AuthorizationToken $AuthorizationToken -SubscriptionId $subscriptionId -Name kv -ServiceType KeyVault
Test-AzNameAvailability -AuthorizationToken $AuthorizationToken -SubscriptionId $subscriptionId -Name root -ServiceType ManagementGroup
Test-AzNameAvailability -AuthorizationToken $AuthorizationToken -SubscriptionId $subscriptionId -Name martin -ServiceType Sql
Test-AzNameAvailability -AuthorizationToken $AuthorizationToken -SubscriptionId $subscriptionId -Name storage -ServiceType StorageAccount
Test-AzNameAvailability -AuthorizationToken $AuthorizationToken -SubscriptionId $subscriptionId -Name www -ServiceType WebApp

# In a script:
$params = @{
    Name               = 'myCoolWebSite'
    ServiceType        = 'WebApp'
    AuthorizationToken = Get-AccesTokenFromCurrentUser
    SubscriptionId     = $subscriptionId
}
if((Test-AzNameAvailability @params).Available) {
    # Continue with the deployment
}

#>