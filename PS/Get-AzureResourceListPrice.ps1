

function Get-AccesTokenFromCurrentUser {
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList $azProfile
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    ('Bearer ' + $token.AccessToken)
}


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


function Get-AzurePrice {
    param(
        $subscriptionId = $null,
        $apiVersion = '2015-06-01-preview',
        $offerDurableId = 'MS-AZR-0015P',
        $currency = 'USD',
        $locale = 'en-US',
        $regionInfo = 'US',
        $MeterRegion = 'US East 2',
        $MeterCategory = '*',
        $MeterName = '*',
        $authorization = $null
    )
    if($null -eq $subscriptionId) { $subscriptionId = (Get-AzContext).Subscription.Id }
    if($null -eq $authorization) { $authorization = Get-AccesTokenFromCurrentUser }

    $authHeaders = @{authorization = $authorization}
    $apiUri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Commerce/RateCard?api-version=$apiVersion&`$filter=OfferDurableId eq '$offerDurableId' and Currency eq '$currency' and Locale eq '$locale' and RegionInfo eq '$regionInfo'" 
    $prices = Invoke-RestMethod -Method Get -Uri $apiUri -Headers $authHeaders 
    $prices.Meters
}


$all = Get-AzurePrice
$managedDisks = $all | Where-Object { $_.MeterRegion -eq 'US East 2' } | Where-Object { $_.MeterCategory -like 'Storage' } | 
    Where-Object { $_.MeterSubCategory -like '*Managed Disks' } | Where-Object { $_.MeterName -match '\w\d+ Disks' }