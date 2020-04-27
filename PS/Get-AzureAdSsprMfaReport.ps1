#Requires -Version 7.0

PARAM(
    [parameter(Mandatory)]
    $TenantId
)


# Verify the module is installed:
$psGetVersion = ((Get-Module -Name PowerShellGet -ListAvailable) | Sort-Object Version -Descending)[0].Version
if ($psGetVersion -lt [version]'2.0.4') {
    Install-Module PowerShellGet -Force -Verbose
}

if (-not (Get-Module -Name Microsoft.Graph -ListAvailable)) {
    Install-Module -Name Microsoft.Graph -Verbose -Force
}


# Connect to MSGraph:
Connect-Graph -Scopes 'Reports.Read.All', 'AuditLog.Read.All' -TenantId $TenantId


# Get the CredentialUserRegistrationDetail report:
Get-MgReportCredentialUserRegistrationDetail | Select-Object UserDisplayName, UserPrincipalName, 
    @{N='IsSsprEnabled';E={$_.IsEnabled}}, @{N='IsSsprOrMfaCapable';E={$_.IsCapable}}, 
        @{N='IsSsprRegistered';E={$_.IsRegistered}}, IsMfaRegistered, AuthMethods
