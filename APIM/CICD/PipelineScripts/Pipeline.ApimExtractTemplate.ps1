<#

Script Name	: Pipeline.ApimExtractTemplate.ps1
Description	: Extract the ARM template from an API Management set of APIs
Keywords	: Azure, APIM-CI/CD

#>


PARAM(
    [Parameter(Mandatory = $true)][string] $SourceEnvironment,
    [Parameter(Mandatory = $true)][string] $SourceSubscriptionId,
    [Parameter(Mandatory = $false)][string] $apiFilters = '*',
    [Parameter(Mandatory = $false)][string] $APIManagementTemplateModule = 'APIManagementTemplate'
)


try {
	
	$appPrefix = 'contoso'

    # Extract the token from the context
    $token = az account get-access-token --query accessToken --output tsv
    # --resource-type arm
    # --subscription
    # --tenant

    # Verify output folders exists
    './APIM', './APIM-Debug' | ForEach-Object {
        if (-not (Test-Path -Path $_ -PathType Container)) {
            New-Item -Path $_ -ItemType Container | Out-Null
        }
    }

    # Import the module
    Import-Module -Name $APIManagementTemplateModule

    # Build the command parameters
    $params = @{
        Token                             = $Token
        #Token                             = $env:SYSTEM_ACCESSTOKEN
        SubscriptionId                    = $SourceSubscriptionId
        APIManagement                     = '{0}-{1}-apim' -f $sourceEnvironment, $appPrefix
        ResourceGroup                     = '{0}-{1}-publish-rg' -f $sourceEnvironment, $appPrefix
        ExportPIManagementInstance        = $false
        FixedServiceNameParameter         = $true
        CreateApplicationInsightsInstance = $false
        DebugOutPutFolder                 = './APIM-Debug'
    }
    if ($apiFilters -ne '*') {
        $params.Add('APIFilters', $apiFilters)
    }

    # Extract the APIs from the source APIM service
    $apimTemplate = Get-APIManagementTemplate @params

    # Write the extracted ARM template to disk
    $OutputTemplateFile = './APIM/{0}-apim-extracted-{1:yyyyMMddHHmm}.json' -f $sourceEnvironment, (Get-Date)
    $apimTemplate | Out-File $OutputTemplateFile -Force

    # Create the ADO task variable
    $templateFile = (Resolve-Path -Path $OutputTemplateFile).Path
    Write-Host "##vso[task.setvariable variable=templateFile]$templateFile"

} catch {
    Write-Host ('##[error] Error extracting template from APIM. {0}' -f $_.Exception.Message)
    Write-Host ('##[error] {0}' -f (Get-ChildItem -Path ./APIM-Debug -File | Get-Content))
    # For debug only
    Write-Host ('##[error] {0}' -f ($params | Out-String))
    $Token -split '(\w{50})' | % { Write-Host ('##[error] {0}' -f $_) }

    $host.SetShouldExit(1)
}