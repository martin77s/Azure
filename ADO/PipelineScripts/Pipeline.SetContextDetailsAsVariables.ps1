<#

Script Name	: Pipeline.SetContextDetailsAsVariables.ps1
Description	: Create servicePrincipalId, subscriptionId and tenantId ADO pipeline variables for later tasks usage
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, Variables, DevOps, Pipeline
Last Update	: 2020/03/12

#>


$servicePrincipalId = (Get-AzADServicePrincipal -ApplicationId (Get-AzContext).Account.Id).Id
Write-Host "##vso[task.setvariable variable=servicePrincipalId]$servicePrincipalId"


$subscriptionId = (Get-AzContext).Subscription.Id
Write-Host "##vso[task.setvariable variable=subscriptionId]$subscriptionId"

$tenantId = (Get-AzContext).Tenant.Id
Write-Host "##vso[task.setvariable variable=tenantId]$tenantId"
