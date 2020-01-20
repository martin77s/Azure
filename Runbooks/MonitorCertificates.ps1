Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))

$workspaceId = Get-AutomationVariable -Name 'MonitorWorkspaceId'
$workspaceKey = Get-AutomationVariable -Name 'MonitorWorkspaceKey'
$logType = 'MonitorCertificates'
$variableName = 'MonitorWebsites'


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

    # Get the list of websites to monitor
    try {
        $websites = Get-AutomationVariable -Name $variableName
    } catch {
        Write-Output "Please create an Automation Variable named '$variableName' before continuing"
        throw "Missing Automation Variable '$variableName'"
    }

    # Connect to each site in the collection
    foreach ($website in $websites) {
        $commonName = $website -replace 'https://(.*)(:\d+)', '$1'
        $port = $(if ($website -match '.*:(?<port>\d+)$') { $matches.port } else { 443 })
        try {

            # Connect to the remote address in the relevant port
            $tcpClient = New-Object -TypeName System.Net.Sockets.TcpClient -ArgumentList ($commonName, $port)
            try {

                # Retreive the certificate
                $stream = New-Object -TypeName System.Net.Security.SslStream -ArgumentList ($tcpClient.GetStream(), $false, {
                        param($sender, $certificate, $chain, $sslPolicyErrors)
                        return $true
                    })
                $stream.AuthenticateAsClient($commonName, $null, [System.Security.Authentication.SslProtocols]::Tls12, $null)
                $cert = $stream.Get_RemoteCertificate()

                # Build the data object
                $CN = (($cert.Subject -split '=')[1] -split ',')[0]
                $ValidTo = [datetime]::Parse($cert.GetExpirationDatestring())
                $ValidDays = $($ValidTo - [datetime]::Now).Days
                $Properties = @{
                    WebsiteURL = $website
                    CommonName = $commonName
                    CN         = $CN
                    ValidTo    = $ValidTo
                    ValidDays  = $ValidDays
                }
                $Data = $Properties | ConvertTo-Json
                $EventProperties = [pscustomobject]@{Data = $Data }
                $EVENTDATA = [pscustomobject]@{EventProperties = $EventProperties }
                $json = "[$($EVENTDATA.EventProperties.Data)]"

                # Publish the data to the LogAnalytics workspace
                $post = Publish-LogAnalyticsData -WorkspaceId $WorkspaceId -SharedKey $workspaceKey -Body (
                    [System.Text.Encoding]::UTF8.GetBytes($json)) -LogType $logType -TimeStampField ([datetime]::Now)
                if ($post -eq 202 -or $post -eq 200) {
                    Write-Output "Event written to $workspaceId"
                } else {
                    Write-Output "StatusCode: $post - failed to write to $workspaceId"
                    throw "StatusCode: $post - failed to write to $workspaceId"
                }
            } catch {
                Write-Output ($_)
                throw $_
            } finally {
                $tcpClient.close()
            }
        } catch { }
    }
} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
