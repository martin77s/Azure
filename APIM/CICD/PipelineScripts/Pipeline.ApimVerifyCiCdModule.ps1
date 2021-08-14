<#

Script Name	: Pipeline.ApimVerifyCiCdModule.ps1
Description	: Verify the APIManagementARMTemplateCreator is available on the agent
Keywords	: Azure, PowerShell, Module, APIM-CI/CD

#>

PARAM(
    [string] $ModuleName = 'APIManagementTemplate',
    [string] $SavedModulesPath,
    [string] $UseSavedModuleVersion
)

try {
    if ('true' -eq $useSavedModuleVersion) {
        $basePath = ((Get-ChildItem -Path (Join-Path -Path $SavedModulesPath -ChildPath $ModuleName) |
                    Sort-Object -Property { [version] $_.Name } -Descending)[0]).FullName
        $modulePath = (Get-ChildItem $basePath -Filter ('{0}.ps*1' -f $ModuleName))[0].FullName
    } else {
        $params = @{
            Name               = $ModuleName
            AllowClobber       = $true
            Force              = $true
            SkipPublisherCheck = $true
            #AcceptLicense      = $true
            Scope              = 'CurrentUser'
        }
        Install-Module @params
        $modulePath = (Get-Module -Name $ModuleName -ListAvailable | Sort-Object Version -Descending)[0].Path
    }
    Write-Host ('##vso[task.setvariable variable=modulePath]{0}' -f $modulePath)
} catch {
    Write-Host ('##[error] Unable to verify or update the {0} module. {1}' -f $ModuleName, $_.Exception.Message)
    $host.SetShouldExit(1)
}