[CmdletBinding(SupportsShouldProcess = $false)]
PARAM(
    [Parameter(Mandatory = $true)] [string] $ApplicationId,
    [string] $Path = 'C:\Temp'
)


# Get bearer tokens
Write-Verbose 'Getting access tokens from cache'
$context = Get-AzContext
$tokenGraph = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate(
    $context.Account, $context.Environment, $context.Tenant.Id, $null, 'Never', $null, 'https://graph.microsoft.com').AccessToken

$tokenMng = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate(
    $context.Account, $context.Environment, $context.Tenant.Id, $null, 'Never', $null, 'https://management.azure.com').AccessToken


# Get Application:
Write-Verbose 'Getting the application object'
$response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/applications?filter=appId eq '$ApplicationId'" -Headers @{'Authorization'="Bearer $tokenGraph";'Content-Type'='Application/JSON'} -Method Get
$resultObject = [PSCustomObject]@{
    ApplicationJSON   = ($response.Content | ConvertFrom-Json).value
    ServicePrincipals = @()
}

# Get ServicePrincipal
Write-Verbose 'Getting the service principals'
$response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/serviceprincipals?filter=appId eq '$ApplicationId'" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Get
$servicePrincipals = $response.Content | ConvertFrom-Json
foreach ($sp in $servicePrincipals) {

    $spObject = [PSCustomObject]@{
        ServicePrincipal = $sp.value
        RoleAssignments  = @()
        AADAssignments   = @()
    }

    if($spObject.ServicePrincipal) {

        # Get role assingments
        Write-Verbose 'Getting the role assingments'
        $Scopes = @('/')
        $Scopes | ForEach-Object {
            $response = Invoke-WebRequest -UseBasicParsing -Uri "https://management.azure.com/$_/providers/Microsoft.Authorization/roleAssignments?`$filter=principalId eq '$($spObject.ServicePrincipal.Id)'&api-version=2015-07-01" -Headers @{'Authorization'="Bearer $tokenMng";'Content-Type'='Application/JSON'} -Method Get
            $spObject.RoleAssignments += ($response.Content | ConvertFrom-Json).value
        }

        # Get AAD assignments
        Write-Verbose 'Getting the AAD assingments'
        $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/serviceprincipals/$($spObject.ServicePrincipal.Id)/getMemberObjects" -Headers @{'Authorization'="Bearer $tokenGraph";'Content-Type'='Application/JSON'} -Method Post -Body "{'securityEnabledOnly': false}"
        $spObject.AADAssignments += ($response.Content | ConvertFrom-Json).value
    }

    $resultObject.ServicePrincipals += $spObject
}

Write-Verbose 'Saving to the json file'
if(-not(Test-Path -Path $Path -PathType Container)) {
    $null = New-Item -Path $Path -ItemType Container -Force
}
$filePath = Join-Path -Path $Path -ChildPath ('{0}.json' -f $ApplicationId)
$resultObject | ConvertTo-Json -Depth 100 | Out-File -FilePath $FilePath -Encoding UTF8 -Force