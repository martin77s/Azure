<#

Script Name	: Enable-DiagnosticSettingsMG.ps1
Description	: Enable the diagnostic settings at the ManagementGroup level
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, Diagnostics, ManagementGroup, API
Reference	: https://docs.microsoft.com/en-us/rest/api/monitor/managementgroupdiagnosticsettings

#>


PARAM(
    [Parameter(Mandatory = $true)] [string] $managementGroupId,
    [Parameter(Mandatory = $false)] [string] $diagnosticSettingsName = 'diagnostics',
    [Parameter(Mandatory = $false)] [string] $storageAccountId = $null,
    [Parameter(Mandatory = $false)] [string] $logAnalyticsWorkspace = $null,
    [Parameter(Mandatory = $false)] [string] $eventHubAuthorizationRuleId = $null,
    [Parameter(Mandatory = $false)] [string] $eventHubName = $null
)


function Get-AzAccessTokenFromCurrentUser {
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList $azProfile
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    ('Bearer ' + $token.AccessToken)
}

$apiVersion = '2020-01-01-preview'
$uri = 'https://management.azure.com/providers/microsoft.management/managementGroups/{0}/providers/microsoft.insights/diagnosticSettings/{1}?api-version={2}' -f `
    $managementGroupId, $diagnosticSettingsName, $apiVersion

$properties = [PSCustomObject]@{
    storageAccountId            = $storageAccountId
    workspaceId                 = $logAnalyticsWorkspace
    eventHubAuthorizationRuleId = $eventHubAuthorizationRuleId
    eventHubName                = $eventHubName
    logs                        = @(
        [PSCustomObject]@{
            category = 'Administrative'
            enabled  = $true
        },
        [PSCustomObject]@{
            category = 'Policy'
            enabled  = $true
        }
    )
}

if ([string]::IsNullOrEmpty($storageAccountId)) { $properties.PSObject.Properties.Remove('storageAccountId') }
if ([string]::IsNullOrEmpty($logAnalyticsWorkspace)) { $properties.PSObject.Properties.Remove('workspaceId') }
if ([string]::IsNullOrEmpty($eventHubAuthorizationRuleId) -or [string]::IsNullOrEmpty($eventHubName)) {
    $properties.PSObject.Properties.Remove('eventHubAuthorizationRuleId')
    $properties.PSObject.Properties.Remove('eventHubName')
}

$authToken = Get-AzAccessTokenFromCurrentUser
$jsonBody = @{ properties = $properties } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri $uri -Method PUT -Body $jsonBody -ContentType 'application/json' -Headers @{Authorization = $authToken }
