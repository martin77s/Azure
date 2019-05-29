# Script to retrieve Azure AD audit logs

$clientID = '<serviceprincipal_app_id>'
$clientSecret = '<serviceprincipal_secret>'
$tenantName = 'contoso.onmicrosoft.com'
$logsFolder = 'C:\Logs\AAD'
$resource = 'https://graph.windows.net'
$loginURL = 'https://login.microsoftonline.com/'

function Connect-GraphAPILocally() {
    $requestTokensBody = @{
        grant_type    = 'client_credentials'
        resource      = $resource
        client_id     = $clientID
        client_secret = $clientSecret
    }
    $responseTokens = Invoke-RestMethod -Method Post -Uri "$loginURL/$tenantName/oauth2/token?api-version=1.0" -Body $requestTokensBody
    return "$($responseTokens.token_type) $($responseTokens.access_token)"
}

$authorization = Connect-GraphAPILocally
$daysago = "{0:s}Z" -f (Get-Date).AddDays(-7)
$currentUrl = "https://graph.windows.net/$tenantName/activities/audit?api-version=beta&`$filter=(activityDate+ge+" + $daysago + ")"

$activitiesHeaderParams = @{
    Authorization = $authorization
}

do {
    $activities = Invoke-RestMethod -UseBasicParsing -Headers $activitiesHeaderParams -Method Get -Uri $currentUrl
    $currentUrl = $activities.'@odata.nextLink'
    $events = @{ }
    foreach ($activity in $activities.value) {
        $date = ([datetime] $activity.activityDate).ToString('yyyy-MM-dd')
        if (!$events.ContainsKey($date)) {
            $events.Add($date, @())
        }
        $events[$date] += $activity
    }

} while ($null -ne $currentUrl)

foreach ($date in $events.Keys) {
    $events[$date] | ConvertTo-Json | Out-File -FilePath ($logsFolder + '\' + $date + '.json') -Force
}
