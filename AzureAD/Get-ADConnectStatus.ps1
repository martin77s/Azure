function Get-BearerToken {
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential] $Credential
    )

    $params = @{
        'Body'        = @{
            'username'     = ($Credential).UserName
            'password'     = [System.Web.HttpUtility]::UrlEncode(($Credential).GetNetworkCredential().Password)
            'grant_type'   = 'password'
            'redirect_uri' = 'urn:ietf:wg:oauth:2.0:oob' # PowerShell redirect Uri
            'client_id'    = '1950a258-227b-4e31-a9cf-717495945fc2' # PowerShell client Id
            'resource'     = '74658136-14ec-4630-ad9b-26e160ff0fc6' # Ibiza 1st party applicationId
        }
        'Method'      = 'Post'
        'ContentType' = 'application/x-www-form-urlencoded'
        'Uri'         = 'https://login.microsoftonline.com/common/oauth2/token'
    }
    $accessToken = Invoke-RestMethod @params | Select-Object -ExpandProperty access_token
    $accessToken
}

function Get-ADConnectStatus {
    param(
        [Parameter(Mandatory = $true)] [string] $accessToken
    )
    $uri = 'https://main.iam.ad.ext.azure.com/api/Directories/ADConnectStatus'
    $headers = @{
        'Authorization' = 'Bearer ' + $accessToken
        'Content-Type'  = 'application/json'
        'x-ms-command-name'      = 'DirectoryManagement - GetAdConnectStatus'
        'x-ms-effective-locale'  = 'en.en-us'
        'Accept'                 = '*/*'
        'x-ms-client-request-id' = [guid]::NewGuid().ToString()
        'x-ms-client-session-id' = [guid]::NewGuid().ToString()
    }
    (Invoke-WebRequest -Uri $uri -UseBasicParsing -Headers  $headers -Method Get).Content | ConvertFrom-Json
}

$credential = Get-Credential
$accessToken = Get-BearerToken -Credential $credential
Get-ADConnectStatus -accessToken $accessToken