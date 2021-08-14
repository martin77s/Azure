<#

Script Name	: Pipeline.ApimSetVariables.ps1
Description	: Set the context variables for the source and target environments
Keywords	: Azure, Variables, DevOps, Pipeline, APIM-CI/CD

#>

PARAM(
    [Parameter(Mandatory = $true)][string] $sourceEnvironment,
    [Parameter(Mandatory = $true)][string] $targetEnvironment
)


try {

    $sourceSubscriptionId = @(Get-ChildItem env: |
        Where-Object { $_.Name -match ('{0}_subscriptionId' -f $sourceEnvironment) } |
            Select-Object -ExpandProperty Value)
    Write-Host ('##vso[task.setvariable variable=sourceEnvironment]{0}' -f $sourceEnvironment)
    Write-Host ('##vso[task.setvariable variable=sourceSubscriptionId]{0}' -f $sourceSubscriptionId)

    $targetSubscriptionId = @(Get-ChildItem env: |
        Where-Object { $_.Name -match ('{0}_subscriptionId' -f $targetEnvironment) } |
            Select-Object -ExpandProperty Value)
    Write-Host ('##vso[task.setvariable variable=targetEnvironment]{0}' -f $targetEnvironment)
    Write-Host ('##vso[task.setvariable variable=targetSubscriptionId]{0}' -f $targetSubscriptionId)

} catch {
    Write-Host ('##[error] Error parsing variables. {0}' -f $_.Exception.Message)
    $host.SetShouldExit(1)
}