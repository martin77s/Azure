# This script will be run on every COLD START of the Function App
# You can define helper functions, run commands, or specify environment variables


# Authenticate using the app's MSI 
if ($env:MSI_SECRET -and (Get-Module -ListAvailable Az.Accounts)) {
    Connect-AzAccount -Identity
}


# Authenticate using the app's MSI and save the tokenResponse as an environment variable
$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=https://management.azure.com&api-version=2017-09-01"
$env:tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $tokenAuthURI
# Connect-AzAccount -AccessToken $tokenResponse.access_token -AccountId $env:WEBSITE_SITE_NAME
