<#

Script Name	: Pipeline.SetContextDetailsAsVariables.ps1
Description	: Create the servicePrincipalId, subscriptionId and tenantId ADO pipeline variables for later tasks usage
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, DevOps, Pipeline, Variables

#>

#Requires -PSEdition Core


Write-Host ("##vso[task.setvariable variable=dateTimeStamp]{0}" -f $(Get-Date -Format yyyyMMddhhmm))

$context = Get-AzContext
$servicePrincipal = (Get-AzADServicePrincipal -ApplicationId ($context).Account.Id)

$servicePrincipalId = ($servicePrincipal).Id
Write-Host "##vso[task.setvariable variable=servicePrincipalId]$servicePrincipalId"

$servicePrincipalName = ($servicePrincipal).DisplayName
Write-Host "##vso[task.setvariable variable=servicePrincipalName]$servicePrincipalName"

$subscriptionId = (Get-AzContext).Subscription.Id
Write-Host "##vso[task.setvariable variable=subscriptionId]$subscriptionId"

$tenantId = (Get-AzContext).Tenant.Id
Write-Host "##vso[task.setvariable variable=tenantId]$tenantId"


try {
    $agentIP = (Invoke-WebRequest -Uri 'https://api.ipify.org/' -ErrorAction SilentlyContinue).Content
    if (-not $agentIP) {
        $agentIP = (Invoke-WebRequest -Uri 'http://api.infoip.io/ip' -ErrorAction Stop).Content
    }
    $allowedPublicIPs = $env:allowedPublicIPs -split ','
    $allowedPublicIPs += ('{0}/32' -f $agentIP)
    $allowedPublicIPs = $allowedPublicIPs | Select-Object -Unique
    Write-Host ("##vso[task.setvariable variable=allowedPublicIPs]{0}" -f ($allowedPublicIPs -join ','))
} catch {
    Write-Host ("##[section] Unable to get the Azure DevOps agent VM public IP and add it to the list of allowedPublicIPs")
}
