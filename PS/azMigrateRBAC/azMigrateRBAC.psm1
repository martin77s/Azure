#requires -Module AzureAD, Az.Accounts, Az.Resources, Az.KeyVault

<#

•	Step #1
Backup Role Assignments: Backup all the role assignments from the source tenant using the PowerShell commands below to login to Azure to the current (“old”) tenant, export the roles and permissions, login again to the target (“new”) tenant and export the list of users to be used for the mappings.
Import-Module AzMigrateRBAC
Initialize-AzureContext -TenantId $oldTenantId
Export-RBAC -Path C:\TargetFolder -SubscriptionId $subscriptionIdToMove
Initialize-AzureContext -TenantId $newTenantId
Export-UserList -Path C:\TargetFolder

•	Step #2
Locate the UserMappings.csv file and edit it to map the old users in the old tenant to the users in the new tenant. These users need to exist prior the next step.
You can use the NewTenantUserList.csv (created in the previous step by running the Export-UserList command) located in the target folder.


•	Step #3
Initiate Transfer: At this step, the Subscription owner in the source tenant can proceed to "Transfer" the subscription from the source tenant to the target tenant.
Do not perform this step without performing step #1 as executing this step will reset all the role assignments in the source tenant and those deleted role assignments cannot be restored from that point of time onwards.


•	Step #4
Restore Role Assignments: Restore all the role assignments on to the target tenant using the PowerShell commands below to login to Azure to the new tenant
Import-Module AzMigrateRBAC
Initialize-AzureContext -TenantId $newTenantId
Import-RBAC -Path C:\TargetFolder


Important notes:
    - The user initiating the subscription transfer needs to be invited from the source tenant to the destination tenant
    - Verify target Management group structure and policies
    - Azure DevOps:
        - Switch directory at the organization level
        - Update Service Connections if using Service Principals (at the project level as well)
        - Update administrator and users (at the project level as well)
        https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/faq-azure-access?view=azure-devops#faq-connect

#>

$script:Context = @{
    AzureAD = $null
    AzureRM = $null
}

function Initialize-AzureContext {
    param($TenantId)
    Write-Host 'Login to Azure Active Directory'
    Import-Module -Name AzureAD
    $script:Context.AzureAD = Connect-AzureAD -TenantId $TenantId

    Write-Host 'Login to Azure Resource Manager'
    Import-Module -Name Az.Accounts
    Connect-AzAccount -Tenant $TenantId | Out-Null
    $script:Context.AzureRM = Get-AzContext

}


function Find-AADObject {
    Param(
        [Parameter(Mandatory)]
        [string] $ObjectId
    )
    try {
        $objectFound = Get-AzureADObjectByObjectId -ObjectIds $ObjectId
    } catch {
        $objectFound = $null
    }
    $objectFound
}


function Import-RBAC {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('InputPath')]
        [string] $Path
    )

    $oldTenant = $null
    try {
        $oldTenant = Import-Clixml -Path (Get-ChildItem -Path $Path -Filter *.xml).FullName
    } catch {
        throw 'Error: Exported xml file missing. Make sure you are reading from the correct path.'
    }

    if (-not $script:context.AzureAD.TenantId.Guid) {
        throw 'Error: Not connected to Azure AD. Please run Initialize-AzureContext'
    }

    if (-not $script:context.AzureRM.Tenant.Id) {
        throw 'Error: Not connected to Azure RM. Please run Initialize-AzureContext'
    }

    $sub = Select-AzSubscription -SubscriptionId $oldTenant.Subscription.SubscriptionId -ErrorAction Stop -WhatIf:$false
    if ($PSCmdlet.ShouldProcess(('Azure Subscription: {0} ({1})' -f $sub.Subscription.Name, $sub.Subscription.Id))) {

        #$tenantId = $context.AzureAD.Tenant.Id.Guid
        $tenantId = (Get-AzContext).Tenant.TenantId
        $userMappings = Import-Csv -Path (Join-Path -Path $Path -ChildPath 'UserMappings.csv') -Delimiter ","
        foreach ($ace in $oldTenant.Subscription.RBAC) {
            $newRbac = Find-AADObject -ObjectId (@($userMappings | Where-Object { $_.ObjectIdInOldTenant -eq $ace.ObjectId })[0]).ObjectIdInNewTenant
            $params = @{
                ObjectId           = $newRbac.ObjectId
                RoleDefinitionName = $ace.RoleDefinitionName
                Scope              = $ace.Scope
            }
            if (-not(Get-AzRoleAssignment @params)) {
                Write-Host ('Adding role {0} to {1} scoped at {2}' -f $params.RoleDefinitionName, $params.ObjectId, $params.Scope)
                New-AzRoleAssignment @params | Out-Null
            }
        }

        $keyVaults = Get-AzKeyVault | Get-AzResource | Where-Object { $_.Properties.tenantId -ne $tenantId }
        foreach ($keyVault in $keyVaults) {

            if ($KeyVault.Properties.accessPolicies) {
                $newAccessPolicies = foreach ($policy In $KeyVault.Properties.accessPolicies) {
                    $ObjectId = (@($userMappings | Where-Object { $_.ObjectIdInOldTenant -eq $policy.ObjectId })[0]).ObjectIdInNewTenant
                    if ($ObjectId) { $newObjectId = Find-AADObject -ObjectId $ObjectId } else { $newObjectId = $null }
                    if ($newObjectId) {
                        Write-Host ('Calculating access policy for {0} ({1}) to keyvault {2}' -f $newObjectId.ObjectId, $newObjectId.DisplayName, $keyVault.Id)
                        $policy.tenantId = $tenantId
                        $policy.objectId = $newObjectId.ObjectId
                    }
                    $policy
                }

                $keyVault.Properties.tenantId = $tenantId
                $keyVault.Properties.AccessPolicies = @()
                Set-AzResource -ResourceId $keyVault.Id -Properties $keyVault.Properties -Force | Out-Null

                $newAccessPolicies | ForEach-Object {
                    $params = @{
                        VaultName         = $keyVault.Name
                        ResourceGroupName = $keyVault.ResourceGroupName
                        ObjectId          = $_.objectId
                    }
                    if ($_.permissions.keys) { $params.Add('PermissionsToKeys', $_.permissions.keys) }
                    if ($_.permissions.certificates) { $params.Add('PermissionsToCertificates', $_.permissions.certificates) }
                    if ($_.permissions.secrets) { $params.Add('PermissionsToSecrets', $_.permissions.secrets) }
                    if ($_.permissions.storage) { $params.Add('PermissionsToStorage', $_.permissions.storage) }
                    if ($_.objectId) {
                        Set-AzKeyVaultAccessPolicy @params
                    }
                }
            } else {
                Write-Host ('Important: Access policies on {0} were empty. Use the XML for manually adding the required access' -f $keyVault.Name)
            }
        }
    }
}


function Export-RBAC {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $SubscriptionId,

        [Parameter(Mandatory)]
        [Alias('OutputPath')]
        [string] $Path
    )

    if (-not $script:context.AzureAD.TenantId.Guid) {
        throw 'Error: Not connected to Azure AD. Please run Initialize-AzureContext'
    }

    if (-not $script:context.AzureRM.Tenant.Id) {
        throw 'Error: Not connected to Azure RM. Please run Initialize-AzureContext'
    }

    $exportData = @{ }
    if (-not (Test-Path -Path $Path -PathType Container)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }

    $sub = Get-AzSubscription -SubscriptionId $SubscriptionId
    Set-AzContext -SubscriptionObject $sub | Out-Null
    $script:Context.AzureRM = Get-AzContext
    Write-Verbose ('Working on Subscription {0} ({1})' -f $sub.Id, $sub.Name) -Verbose

    Write-Verbose 'Reading RBACs' -Verbose
    $subscription = New-Object psobject -Property @{
        SubscriptionId   = $sub.Id
        SubscriptionName = $sub.Name
        State            = $sub.State
        RBAC             = (Get-AzRoleAssignment | Select-Object -Unique ObjectId, DisplayName, ObjectType, RoleDefinitionName, Scope)
    }
    $exportData.Add('Subscription', $subscription)

    Write-Verbose 'Reading Users' -Verbose
    $users = Get-AzureADUser -All $true | Select-Object -Property ObjectId, DisplayName, UserPrincipalName, UserType
    $exportData.Add('Users', $users)

    Write-Verbose 'Reading Groups' -Verbose
    $groups = Get-AzureADGroup -All $true | ForEach-Object {
        $Members = Get-AzureADGroupMember -ObjectId $_.ObjectId | ForEach-Object {
            if ($_.ObjectType -eq 'Group') {
                $_ | Select-Object -Property ObjectId, DisplayName, ObjectType
            } elseif ($_.ObjectType -eq 'User') {
                $_ | Select-Object -Property ObjectId, DisplayName, ObjectType, userPrincipalName
            }
        }
        New-Object -TypeName PSObject -Property @{
            ObjectId    = $_.ObjectId
            DisplayName = $_.DisplayName
            Members     = $Members
        }
    }
    $exportData.Add('Groups', $groups)

    Write-Verbose 'Reading Applications' -Verbose
    $apps = Get-AzureADApplication -All $true | ForEach-Object {
        $owners = Get-AzureADApplicationOwner -ObjectId $_.ObjectId
        New-Object -TypeName PSObject -Property @{
            ObjectId    = $_.ObjectId
            AppId       = $_.AppId
            DisplayName = $_.DisplayName
            Owners      = $(if ($owners) { $owners.DisplayName } else { 'None' })
        }
    }
    $exportData.Add('Applications', $apps)

    Write-Verbose 'Reading Service Principal Names' -Verbose
    $spns = Get-AzureADServicePrincipal -All $true | ForEach-Object {
        $owners = Get-AzureADServicePrincipalOwner -ObjectId $_.ObjectId
        $servicePrincipal = New-Object -TypeName PSObject -Property @{
            ObjectId             = $_.ObjectId
            AppId                = $_.AppId
            DisplayName          = $_.DisplayName
            HomePage             = $_.HomePage
            ReplyURLs            = $_.ReplyURLs
            ServicePrincipalType = $_.ServicePrincipalType
            Owners               = 'None'
            UserPrincipalName    = $null
        }
        if ($owners) {
            $servicePrincipal.Owners = $owners.DisplayName
            $servicePrincipal.UserPrincipalName = $owners.UserPrincipalName
        }
        $servicePrincipal
    }
    $exportData.Add('ServicePrincipal', $spns)
    $MSIs = @($spns | Where-Object { $_.ServicePrincipalType -eq 'ManagedIdentity' })
    if ($MSIs.Count -gt 0) {
        Write-Warning -Message ('{0} Managed Identities found. They should be re-created manually on the resource after the migration' -f $MSIs.Count)
    }

    Write-Verbose 'Reading KeyVault Access Policies' -Verbose
    $keyVaults = Get-AzKeyVault | Get-AzResource
    $keyVaultAccessPolicies = foreach ($keyVault in $keyVaults) {
        foreach ($policy In $KeyVault.Properties.accessPolicies) {
            $adObject = (Find-AADObject -ObjectId $policy.ObjectId)
            $policy | Select-Object -Property @{N = 'ResourceId'; E = { $keyVault.ResourceId } },
            @{N = 'Permissions'; E = { $_.permissions } }, @{N = 'Type'; E = { $adObject.ObjectType } },
            @{N = 'ObjectIdInOldTenant'; E = { $_.ObjectId } },
            @{N = 'DisplayName'; E = { $adObject.DisplayName } },
            @{N = 'ObjectIdInNewTenant'; E = { '' } }
        }
    }
    $exportData.Add('KeyVaultAccessPolicies', $keyVaultAccessPolicies)

    Write-Verbose 'Exporting RBACs' -Verbose
    Get-ChildItem -Path $Path | Remove-Item -Recurse
    $outputFile = (Join-Path -Path $Path -ChildPath "$($SubscriptionId).xml")
    $exportData | Export-Clixml -Path $outputFile

    Write-Verbose 'Creating UserMappings.csv' -Verbose
    $UserMappings = @()
    $UserMappings += $exportData.Users | Select-Object -Property @{N = 'Type'; E = { 'User' } }, @{N = 'ObjectIdInOldTenant'; E = { $_.ObjectId } }, DisplayName, @{N = 'ObjectIdInNewTenant'; E = { '' } }
    $UserMappings += $exportData.Groups | Select-Object -Property @{N = 'Type'; E = { 'Group' } }, @{N = 'ObjectIdInOldTenant'; E = { $_.ObjectId } }, DisplayName, @{N = 'ObjectIdInNewTenant'; E = { '' } }
    $UserMappings += $exportData.Applications | Select-Object -Property @{N = 'Type'; E = { 'Application' } }, @{N = 'ObjectIdInOldTenant'; E = { $_.ObjectId } }, DisplayName, @{N = 'ObjectIdInNewTenant'; E = { '' } }
    $UserMappings += $exportData.ServicePrincipal | Select-Object -Property @{N = 'Type'; E = { 'ServicePrincipal' } }, @{N = 'ObjectIdInOldTenant'; E = { $_.ObjectId } }, DisplayName, @{N = 'ObjectIdInNewTenant'; E = { '' } }
    $UserMappings += $UserMappings | Where-Object { $exportData.Subscription.RBAC.ObjectID -contains $_.ObjectIdInOldTenant }
    $UserMappings += $exportData.KeyVaultAccessPolicies | Select-Object Type, ObjectIdInOldTenant, DisplayName, ObjectIdInNewTenant
    $UserMappings | Where-Object { ($exportData.Subscription.RBAC.ObjectId) -contains $_.ObjectIdInOldTenant } |
        Select-Object -Property Type, ObjectIdInOldTenant, DisplayName, ObjectIdInNewTenant -Unique |
            Export-Csv -NoTypeInformation -Path (Join-Path -Path $Path -ChildPath 'UserMappings.csv') -Delimiter ","

    Write-Verbose 'Creating RBAC html report' -Verbose
    $head = @'
        <style >
            table { border-collapse: collapse; }
            table, th, td { border: 1px solid black; padding: 5px; text-align: left; }
            th { background-color: #808080; color: white; }
            tr:hover { background-color: #E5E5E5; }
        </style>
'@
    $exportData.Subscription.RBAC | ConvertTo-Html -Head $head | Out-File -FilePath (Join-Path -Path $Path -ChildPath 'RBAC.htm')
}


function Export-UserList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('OutputPath')]
        [string] $Path
    )

    if (-not $script:context.AzureAD.TenantId.Guid) {
        throw 'Error: Not connected to Azure AD. Please run Initialize-AzureContext'
    }

    $exportData = @{ }

    Write-Verbose 'Reading Users' -Verbose
    $users = Get-AzureADUser -All $true | Select-Object -Property ObjectId, DisplayName, UserPrincipalName, UserType
    $exportData.Users = $users

    Write-Verbose 'Reading Groups' -Verbose
    $groups = Get-AzureADGroup -All $true | ForEach-Object {
        $Members = Get-AzureADGroupMember -ObjectId $_.ObjectId | ForEach-Object {
            if ($_.ObjectType -eq 'Group') {
                $_ | Select-Object -Property ObjectId, DisplayName, ObjectType
            } elseif ($_.ObjectType -eq 'User') {
                $_ | Select-Object -Property ObjectId, DisplayName, ObjectType, userPrincipalName
            }
        }
        New-Object -TypeName PSObject -Property @{
            ObjectId    = $_.ObjectId
            DisplayName = $_.DisplayName
            Members     = $Members
        }
    }
    $exportData.Groups = $groups

    Write-Verbose 'Reading Applications' -Verbose
    $apps = Get-AzureADApplication -All $true | ForEach-Object {
        $owners = Get-AzureADApplicationOwner -ObjectId $_.ObjectId
        New-Object -TypeName PSObject -Property @{
            ObjectId    = $_.ObjectId
            AppId       = $_.AppId
            DisplayName = $_.DisplayName
            Owners      = $(if ($owners) { $owners.DisplayName } else { 'None' })
        }
    }
    $exportData.Applications = $apps

    Write-Verbose 'Reading Service Principal Names' -Verbose
    $spns = Get-AzureADServicePrincipal -All $true | ForEach-Object {
        $owners = Get-AzureADServicePrincipalOwner -ObjectId $_.ObjectId
        $servicePrincipal = New-Object -TypeName PSObject -Property @{
            ObjectId          = $_.ObjectId
            AppId             = $_.AppId
            DisplayName       = $_.DisplayName
            HomePage          = $_.HomePage
            ReplyURLs         = $_.ReplyURLs
            Owners            = 'None'
            UserPrincipalName = $null
        }
        if ($owners) {
            $servicePrincipal.Owners = $owners.DisplayName
            $servicePrincipal.UserPrincipalName = $owners.UserPrincipalName
        }
        $servicePrincipal
    }
    $exportData.ServicePrincipal = $spns

    Write-Verbose 'Creating NewTenantUserList.csv' -Verbose
    $NewTenantUserList = @()
    $NewTenantUserList += $exportData.Users | Select-Object -Property @{N = 'Type'; E = { 'User' } }, ObjectId, DisplayName
    $NewTenantUserList += $exportData.Groups | Select-Object -Property @{N = 'Type'; E = { 'Group' } }, ObjectId, DisplayName
    $NewTenantUserList += $exportData.Applications | Select-Object -Property @{N = 'Type'; E = { 'Application' } }, ObjectId, DisplayName
    $NewTenantUserList += $exportData.ServicePrincipal | Select-Object -Property @{N = 'Type'; E = { 'ServicePrincipal' } }, ObjectId, DisplayName
    $NewTenantUserList | Export-Csv -NoTypeInformation -Path (Join-Path -Path $Path -ChildPath 'NewTenantUserList.csv') -Delimiter ","
}


function Export-AzAdApplication {
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
    $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/applications?filter=appId eq '$ApplicationId'" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Get
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

        if ($spObject.ServicePrincipal) {

            # Get role assingments
            Write-Verbose 'Getting the role assingments'
            $Scopes = @('/')
            $Scopes | ForEach-Object {
                $response = Invoke-WebRequest -UseBasicParsing -Uri "https://management.azure.com/$_/providers/Microsoft.Authorization/roleAssignments?`$filter=principalId eq '$($spObject.ServicePrincipal.Id)'&api-version=2015-07-01" -Headers @{'Authorization' = "Bearer $tokenMng"; 'Content-Type' = 'Application/JSON' } -Method Get
                $spObject.RoleAssignments += ($response.Content | ConvertFrom-Json).value
            }

            # Get AAD assignments
            Write-Verbose 'Getting the AAD assingments'
            $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/serviceprincipals/$($spObject.ServicePrincipal.Id)/getMemberObjects" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Post -Body "{'securityEnabledOnly': false}"
            $spObject.AADAssignments += ($response.Content | ConvertFrom-Json).value
        }

        $resultObject.ServicePrincipals += $spObject
    }

    Write-Verbose 'Saving to the json file'
    if (-not(Test-Path -Path $Path -PathType Container)) {
        $null = New-Item -Path $Path -ItemType Container -Force
    }
    $filePath = Join-Path -Path $Path -ChildPath ('{0}.json' -f $ApplicationId)
    $resultObject | ConvertTo-Json -Depth 100 | Out-File -FilePath $FilePath -Encoding UTF8 -Force
}


function Import-AzAdApplication {
    [CmdletBinding(SupportsShouldProcess = $false)]
    PARAM(
        [Parameter(Mandatory = $true)] [ValidateScript( { Test-Path -Path $_ -PathType Leaf })] $FilePath,

        #[Hashtable] $ReplacementDictionary = @{'oldTenant.onmicrosoft.com' = 'newTenant.onmicrosoft.com'; 'OldDomainName' = 'NewDomainName' }
        [Hashtable] $ReplacementDictionary = @{}
    )

    # Get bearer tokens
    $context = Get-AzContext
    $tokenGraph = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate(
        $context.Account, $context.Environment, $context.Tenant.Id, $null, 'Never', $null, 'https://graph.microsoft.com').AccessToken

    $tokenMng = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate(
        $context.Account, $context.Environment, $context.Tenant.Id, $null, 'Never', $null, 'https://management.azure.com').AccessToken

    # Read json and convert to application object
    try {
        $jsonString = Get-Content -Path $FilePath -Raw
        $ReplacementDictionary.Keys | ForEach-Object {
            $jsonString = $jsonString.Replace("$_", "$($ReplacementDictionary[`"$_`"])")
        }
        $jsonObject = $jsonString | ConvertFrom-Json
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
        $spJSON = $sp.ServicePrincipal | Select-Object -ExcludeProperty 'signInAudience', 'appDisplayName', 'appOwnerOrganizationId'
        $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/serviceprincipals/$($sp.ServicePrincipal.Id)" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Get -SkipHttpErrorCheck
        if ($response.StatusCode -eq 200) {
            $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/serviceprincipals/$($sp.ServicePrincipal.Id)" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Patch -Body $spJSON
            if ($response.StatusCode -ne 204) { throw [Exception]::new(('Patch failed for {0}' -f $jsonObject.ApplicationJSON.DisplayName)) }
        } else {
            $response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/serviceprincipals" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Post -Body (
                $spJSON | Select-Object -ExcludeProperty 'publishedPermissionScopes', 'servicePrincipalNames' | ConvertTo-Json -Depth 10 -Compress)
            if ($response.StatusCode -ne 201) {
                throw [Exception]::new(('Post failed for {0}' -f $jsonObject.ApplicationJSON.DisplayName))
            }
            #$response = Invoke-WebRequest -UseBasicParsing -Uri "https://graph.microsoft.com/beta/serviceprincipals" -Headers @{'Authorization' = "Bearer $tokenGraph"; 'Content-Type' = 'Application/JSON' } -Method Post -Body (
            #    $spJSON | ConvertTo-Json -Depth 10 -Compress)
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
}

Export-ModuleMember -Function Initialize-AzureContext, Export-RBAC, Import-RBAC, Export-UserList, Export-AzAdApplication, Import-AzAdApplication