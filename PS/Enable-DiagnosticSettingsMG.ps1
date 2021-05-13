<#

Script Name	: Enable-DiagnosticSettingsMG.ps1
Description	: Enable the diagnostic settings at the ManagementGroup level
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, Diagnostics, ManagementGroup, API
Reference	: https://docs.microsoft.com/en-us/rest/api/monitor/managementgroupdiagnosticsettings

#>


PARAM(
    [Parameter(Mandatory = $true)] [string] $managementGroupId,
    [Parameter(Mandatory = $true)] [string] $logAnalyticsWorkspace,
    [Parameter(Mandatory = $false)] [string] $diagnosticSettingsName = 'diagnostics'
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

$body = @"
{
    "properties": {
        "workspaceId": "$logAnalyticsWorkspace",
        "logs": [
        {
            "category": "Administrative",
            "enabled": true
        },
        {
            "category": "Policy",
            "enabled": true
        }
        ]
    }
}
"@

$authToken = Get-AzAccessTokenFromCurrentUser
Invoke-RestMethod -Uri $uri -Method PUT -Body $body -ContentType 'application/json' -Headers @{Authorization = $authToken }
