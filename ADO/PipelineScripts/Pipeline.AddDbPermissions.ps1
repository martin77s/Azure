<#

Script Name	: Pipeline.AddDbPermissions.ps1
Description	: Add
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, SQL, MSI

Notes:
The service connection that the Azure DevOps pipeline uses to connect to the Azure Resource Manager will need to be granted access to read Azure AD entries. This right can be granted in the Azure Portal under Azure AD → App registrations → API permissions. Select Azure Active Directory Graph → Application Permissions → Directory.Read.All and click on Add Permissions. Remember to grant the admin consent in order for the change to take effect

#>

#Requires -PSEdition Core
#Requires -Module SqlServer

param(
    [Parameter(Mandatory = $true)][string] $ResourceGroupName,
    [Parameter(Mandatory = $true)][string] $sqlServerName,
    [Parameter(Mandatory = $true)][string] $sqlDatabaseName,
    [Parameter(Mandatory = $true)][string] $identityId,
    [Parameter(Mandatory = $true)][string] $identityName,
    [Parameter(Mandatory = $false)][string[]] $dbRole = @('db_datareader', 'db_datawriter')
)

function ConvertTo-Sid {
    param (
        [string]$appId
    )
    [guid]$guid = [System.Guid]::Parse($appId)
    foreach ($byte in $guid.ToByteArray()) {
        $byteGuid += [System.String]::Format('{0:X2}', $byte)
    }
    return ('0x' + $byteGuid)
}


# Get the ADO agent IP address
Write-Host ("##[section] Getting the ADO agent IP address")
try {
    $agentIP = (Invoke-WebRequest -Uri 'https://api.ipify.org/' -ErrorAction Stop).Content
} catch {
    $agentIP = (Invoke-WebRequest -Uri 'http://api.infoip.io/ip' -ErrorAction Stop).Content
}


# Add the ADO agent IP address to the sqlFirewallRules
Write-Host ("##[section] Adding the ADO agent IP address to the sqlFirewallRules")
az sql server firewall-rule create -g $ResourceGroupName -s $sqlServerName -n AdoAgentTemp --start-ip-address $agentIP --end-ip-address $agentIP


# Get the sql token
Write-Host ("##[section] Getting SQL access token")
$access_token = az account get-access-token --resource https://database.windows.net --query accessToken -o tsv


# Get the appId and SID from the identityId
Write-Host ("##[section] Getting the appId from the identityId")
$appId = az ad sp show --id $identityId --query appId -o tsv
Write-Host ("##[section] appId={0}" -f $appId)

Write-Host ("##[section] Getting SID from the applicationId")
$identitySid = ConvertTo-Sid -appId $appId
Write-Host ("##[section] SID={0}" -f $identitySid)


# Build the alter roles string
$rolesString = ($dbRole | ForEach-Object {
    'ALTER ROLE [{0}] ADD MEMBER [{1}];' -f $_, $identityName
}) -join ''

# Build the sql query (direct assignment)
# Write-Host ("##[section] Building the sql query (direct assignment)")
# $sqlQuery = @"
# IF NOT EXISTS (
#     SELECT [name]
#     FROM [sys].[database_principals]
#     WHERE [type] = N'E' AND [name] = N'$identityName'
# )
# BEGIN
#     CREATE USER [$identityName] FROM EXTERNAL PROVIDER;
#     $rolesString
# END
# "@


# Build the sql query (with calculated SID)
Write-Host ("##[section] Building the sql query (with calculated SID)")
$sqlQuery = @"
IF NOT EXISTS (
    SELECT [name]
    FROM [sys].[database_principals]
    WHERE [type] = N'E' AND [name] = N'$identityName'
)
BEGIN
    CREATE USER [$identityName] WITH DEFAULT_SCHEMA=[dbo], SID = $identitySid, TYPE= E;
    $rolesString
END
"@


# Invoke the sql query to create the login
Write-Host ("##[section] Invoking the sql query to create the login")
$paramsSql = @{
    ServerInstance    = '{0}.database.windows.net' -f $sqlServerName
    Database          = $sqlDatabaseName
    AccessToken       = $access_token
    EncryptConnection = $true
    Query             = $sqlQuery
}
SqlServer\Invoke-Sqlcmd @paramsSql | Out-String


# Remove the ADO agent IP address from the sqlFirewallRules
Write-Host ("##[section] Removing the ADO agent IP address from the sqlFirewallRules")
az sql server firewall-rule delete -g $ResourceGroupName -s $sqlServerName -n AdoAgentTemp