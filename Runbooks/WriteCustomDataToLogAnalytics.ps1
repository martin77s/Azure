<#

Script Name	: WriteCustomDataToLogAnalytics.ps1
Description	: Write custom data to a log analytics workspace table
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/28
Keywords	: Azure, Automation, Runbook, LogAnalytics

#>

PARAM(
    $WorkspaceId = '',
    $SharedKey = '',
    $LogType = 'CustomData'
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))

#region Helper functions
function New-Signature {
    param($WorkspaceId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
    $xHeaders = 'x-ms-date:' + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $WorkspaceId, $encodedHash
    return $authorization
}

function Publish-LogAnalyticsData {
    param($WorkspaceId, $SharedKey, $Body, $LogType, $TimeStampField)

    $method = 'POST'
    $contentType = 'application/json'
    $resource = '/api/logs'
    $rfc1123date = [datetime]::UtcNow.ToString("r")
    $contentLength = $Body.Length
    $signature = New-Signature `
        -WorkspaceId $WorkspaceId `
        -sharedKey $SharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -fileName $fileName `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = 'https://' + $WorkspaceId + '.ods.opinsights.azure.com' + $resource + '?api-version=2016-04-01'
    $headers = @{
        'Authorization'        = $signature;
        'Log-Type'             = $LogType;
        'x-ms-date'            = $rfc1123date;
        'time-generated-field' = $TimeStampField;
    }
    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode
}
#endregion

try {

    # Get the automation account service principal
    $spConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'

    # Login to Azure
    Add-AzAccount -ServicePrincipal -Tenant $spConnection.TenantId `
        -ApplicationId $spConnection.ApplicationId `
        -CertificateThumbprint $spConnection.CertificateThumbprint | Out-Null

    # Build the data object
    $TimeRecorded = [datetime]::Now.ToString('yyyy-MM-ddTHH:mm:sszzz')
    $data = @{
        'Title'        = 'Title'
        'Description'  = 'Description'
        'TimeRecorded' = $TimeRecorded
    }
    $json = $data | ConvertTo-Json

    # Publish the data to the LogAnalytics workspace
    Publish-LogAnalyticsData -WorkspaceId $WorkspaceId -SharedKey $SharedKey -Body (
        [System.Text.Encoding]::UTF8.GetBytes($json)) -LogType $LogType -TimeStampField ([datetime]::Now)

} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
