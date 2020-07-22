<#

Script Name	: Get-AzToken.ps1
Description	: Get the current identity's (MSI or loggedin account) access token
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/22
Keywords	: Azure, Context, Access, Token

#>

try {
    $context = Get-AzContext
    if ($env:MSI_ENDPOINT) {
        $response = Invoke-WebRequest -Uri "$env:MSI_ENDPOINT/?resource=https://management.azure.com/" -Headers @{'Metadata' = 'true' }
        $token = [PSCustomObject]@{
            SubscriptionId = $context.Subscription
            TenantID       = $env:ACC_TID
            Token          = ($response.content | ConvertFrom-Json | Select-Object -ExpandProperty access_token)
        }
    } else {
        $cachedTokens = ($context.TokenCache).ReadItems() |
            Where-Object { $_.TenantId -eq $context.Tenant } |
                Sort-Object -Property ExpiresOn -Descending
        $accessToken = $cachedTokens[0].AccessToken
        $token = [PScustomObject]@{
            SubscriptionID = $context.Subscription
            TenantID       = $context.Tenant
            Token          = $accessToken
        }
    }
} catch {
    $token = $null
}
$token
