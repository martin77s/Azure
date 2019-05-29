$azContext = Get-AzContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList $azProfile
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}

# Define the REST API to communicate with
$resourceGroupName = 'rg-web'
$resourceName = 'akada'
$restUri = "https://management.azure.com/subscriptions/$($azContext.Subscription.Id)/resourceGroups/$($resourceGroupName)/providers/Microsoft.Web/sites/$($resourceName)?api-version=2016-08-01"

# Invoke the REST API
$response = Invoke-RestMethod -Uri $restUri -Method GET -Headers $authHeader

# View the JSON response object
$response.properties