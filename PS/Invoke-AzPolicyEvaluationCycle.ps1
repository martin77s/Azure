<#

Script Name	: Invoke-AzPolicyEvaluationCycle.ps1
Description	: Trigger the Azure Policy evaluation cycle
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/05
Keywords	: Azure, Policy, API

#>

[CmdletBinding(DefaultParameterSetName='bySubscription')]

PARAM(
    [Parameter()] [string] $TenantId = $null,
    [Parameter(Mandatory, ParameterSetName='bySubscription')] [string[]] $SubscriptionId,
    [Parameter(ParameterSetName='bySubscription')] [string] $ResourceGroupName = $null,
    [Parameter(Mandatory, ParameterSetName='allSubscriptions')] [switch] $AllSubscriptions
)


function _getAuthHeader {
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $token.AccessToken
    }
}


function _invokeAPI {
    param($Uri, $AuthHeader)
    Invoke-RestMethod -Uri $Uri -Method POST -Headers $AuthHeader | Out-Null
}


$uris = @{
    Subscription  = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.PolicyInsights/policyStates/latest/summarize?api-version=2018-04-04'
    ResourceGroup = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.PolicyInsights/policyStates/latest/triggerEvaluation?api-version=2018-07-01-preview'
}


if([string]::IsNullOrEmpty($TenantId)) {
    $TenantId = (Get-AzContext).Tenant.Id
}


if($AllSubscriptions) {
    $SubscriptionId = Get-AzSubscription -TenantId $TenantId | Select-Object -ExpandProperty Id
}


foreach($sub in $SubscriptionId) {
    $uri = if ($ResourceGroupName) { ($uris['ResourceGroup'] -f $sub, $ResourceGroupName) } else { ($uris['Subscription'] -f $sub) }
    Set-AzContext -Subscription $sub -Tenant $TenantId -Force | Out-Null
    _invokeAPI -Uri $uri -AuthHeader (_getAuthHeader)
}
