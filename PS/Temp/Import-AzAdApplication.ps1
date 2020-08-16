[CmdletBinding(SupportsShouldProcess=$false)]
PARAM(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path -Path $_ -PathType Leaf })] $FilePath
)


# Get bearer tokens
$context = Get-AzContext
$tokenGraph = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate(
    $context.Account, $context.Environment, $context.Tenant.Id, $null, 'Never', $null, 'https://graph.microsoft.com').AccessToken

$tokenMng = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate(
    $context.Account, $context.Environment, $context.Tenant.Id, $null, 'Never', $null, 'https://management.azure.com').AccessToken


# Read json and convert to application object
try {
    $jsonObject = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
    $applicationJson = ($jsonObject.ApplicationJSON |
        Select-Object -ExcludeProperty 'appId', 'createdDateTime', 'publisherDomain', 'passwordCredentials' | ConvertTo-Json -Depth 10 -Compress)
} catch {
    throw [Exception]::new(('Failed to read json object from file {0}' -f $FilePath))
    break
}

# Create the application or patch it if it already exists
$response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/applications?filter=appId eq '$($jsonObject.ApplicationJSON.appId)'" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Get
if ($response.StatusCode -eq 200 -and $response.Content -notmatch '"value":\[\]') {
    Write-Verbose('Application already exists. Patching it')
    $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/applications/$($jsonObject.ApplicationJSON.Id)" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Patch -Body $applicationJson
    if ($response.StatusCode -ne 204) { throw [Exception]::new(('Patch failed for {0}' -f $jsonObject.ApplicationJSON.DisplayName)) }
} else {
    Write-Verbose('Creating the application')
    $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/applications" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Post -Body $applicationJson
    if ($response.StatusCode -ne 201) { throw [Exception]::new(('Post failed for {0}' -f $jsonObject.ApplicationJSON.DisplayName)) }
    $jsonObject.ApplicationJSON = $response.content | ConvertFrom-Json
    $jsonObject.ServicePrincipals.ServicePrincipal.servicePrincipalNames = , $jsonObject.ServicePrincipals.ServicePrincipal.servicePrincipalNames.replace($jsonObject.ServicePrincipals.ServicePrincipal.appId, $jsonObject.ApplicationJSON.appId)
    $jsonObject.ServicePrincipals.ServicePrincipal.appId = $jsonObject.ApplicationJSON.appId
}

# Create the servicePrincipals or patch them if they already exist
Write-Verbose('Creating the service principals')
foreach ($sp in ($jsonObject.ServicePrincipals | Where-Object { $_.ServicePrincipal })) {
    $spJSON = ($sp.ServicePrincipal | Select-Object -ExcludeProperty 'signInAudience', 'appDisplayName', 'appOwnerOrganizationId' | ConvertTo-Json -Depth 10 -Compress)
    $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/serviceprincipals/$($sp.ServicePrincipal.Id)" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Get -SkipHttpErrorCheck
    if ($response.StatusCode -eq 200) {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/serviceprincipals/$($sp.ServicePrincipal.Id)" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Patch -Body $spJSON
        if ($response.StatusCode -ne 204) { throw [Exception]::new(('Patch failed for {0}' -f $jsonObject.ApplicationJSON.DisplayName)) }
    } else {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/serviceprincipals" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Post -Body $spJSON
        if ($response.StatusCode -ne 201) { throw [Exception]::new(('Post failed for {0}' -f $jsonObject.ApplicationJSON.DisplayName)) }
        $jsonObject.ServicePrincipals[0].ServicePrincipal = $response.content | ConvertFrom-Json
    }

    # Update the AD assignments
    Write-Verbose('Updating role assignments')
    $sp.AADAssignments | ForEach-Object {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/directoryObjects/$_" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Get
        if ($response.StatusCode -ne 200) {
            throw [Exception]::new(('Assignment {0} for service principal {1} cannot find Group or Role!' -f $_, $sp.ServicePrincipal.DisplayName))
        } else {
            $objType = ($response.Content | ConvertFrom-Json).'@odata.type'
            if ($objType -eq '#microsoft.graph.group') {
                $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/groups/$_/members/`$ref" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Post -Body "{ `"@odata.id`": `"https://graph.microsoft.com/beta/directoryObjects/$($sp.ServicePrincipal.Id)`" }" -SkipHttpErrorCheck
                if ($response.StatusCode -ne 204 -and $response.Content -notlike '*already exist*') {
                    throw [Exception]::new(('Group assignment {0} for service principal {1} FAILED!' -f $_, $sp.ServicePrincipal.DisplayName))
                } else {
                    Write-Verbose ('Group assignment {0} for service principal {1} Done!' -f $_, $sp.ServicePrincipal.DisplayName)
                }
            } elseif ($objType -eq '#microsoft.graph.directoryRole') {
                $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/directoryRoles/$_/members/`$ref" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Post -Body "{ `"@odata.id`": `"https://graph.microsoft.com/beta/directoryObjects/$($sp.ServicePrincipal.Id)`" }" -SkipHttpErrorCheck

                if ($response.StatusCode -ne 204 -and $response.Content -notlike '*already exist*') {
                    throw [Exception]::new(('AAD Role assignment {0} for service principal {1} FAILED!' -f $_, $sp.ServicePrincipal.DisplayName))
                } else {
                    Write-Verbose ('AAD Role assignment {0} for service principal {1} Done!' -f $_, $sp.ServicePrincipal.DisplayName)
                }
            } else {
                Write-Warning ('Assignment {0} for service principal {1} is of unknown type {2}!' -f $_, $sp.ServicePrincipal.DisplayName, $objType)
            }
        }
    }

    # Update the role assignments
    Write-Verbose('Updating AAD assignments')
    $sp.RoleAssignments | ForEach-Object {
        Write-Verbose ('Setting role assignment {0} for service principal {1}' -f $_.Id, $sp.ServicePrincipal.DisplayName)
        $response = Invoke-WebRequest -UseBasicParsing -Uri "https://management.azure.com/$($_.properties.scope)/providers/Microsoft.Authorization/roleAssignments/$($_.name)?api-version=2015-07-01" -Headers @{'Authorization' = "Bearer $tokenMng"; 'Content-Type' = 'Application/JSON' } -Method Put -Body "{`"properties`": {`"roleDefinitionId`": `"$($_.properties.roleDefinitionId)`",`"principalId`": `"$($sp.ServicePrincipal.Id)`"}}" -SkipHttpErrorCheck
        if ($response.StatusCode -ne 201 -and $response.Content -notlike '*RoleAssignmentUpdateNotPermitted*') {
            throw [Exception]::new(('Role assignment for service principal {0} on scope {1} FAILED!' -f $sp.ServicePrincipal.DisplayName, $_.Id))
        } else {
            Write-Verbose('Role assignment for service principal {0} on scope {1} Done!' -f $sp.ServicePrincipal.DisplayName, $_.Id)
        }
    }
    Write-Verbose('Import process completed')
}

