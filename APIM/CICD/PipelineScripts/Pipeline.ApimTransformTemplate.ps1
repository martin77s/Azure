<#

Script Name	: Pipeline.ApimTransformTemplate.ps1
Description	: Transform the ARM template to match the target environment
Keywords	: Azure, APIM-CI/CD

#>


PARAM(
    [Parameter(Mandatory = $true)][string] $TemplateFile,
    [Parameter(Mandatory = $true)][string] $TargetEnvironment,
    [Parameter(Mandatory = $true)][string] $TargetSubscriptionId
)


try {

	$appPrefix = 'contoso' # Currently supports only one string
    $targetResourceGroupName = '{0}-{1}-publish-rg' -f $TargetEnvironment, $appPrefix
    $resourceIdPattern = '/subscriptions/.*/resourceGroups/.*/providers/(.*)'
    $uriPattern = "(?<environment>\w+)(-)(?<appPrefix>$appPrefix)(-)(?<appName>\w+)(\.azurewebsites\.net.*|\.azure-api\.net.*)"
    $appNameSplitPattern = "\w+-$appPrefix"


    $targetFileName = Join-Path -Path (Split-Path -Path $TemplateFile) -ChildPath ('{0}-apim-transformed-{1:yyyyMMddHHmm}.json' -f $TargetEnvironment, (Get-Date))
    $targetFilePath = (Copy-Item -Path $TemplateFile -Destination $targetFileName -Force -PassThru).FullName
    if (-not ($targetFilePath)) {
        Write-Error 'Error copying file. Process aborted'
        break
    }

    $currentContent = Get-Content -Path $TemplateFile
    $newContent = $currentContent | ForEach-Object {
        if ($_ -match $resourceIdPattern) {
            $_ -replace $resourceIdPattern, ('/subscriptions/{0}/resourceGroups/{1}/providers/$1' -f $TargetSubscriptionId, $targetResourceGroupName)
        } else {
            $_
        }
    }

    $newContent = $newContent | ForEach-Object {
        if ($_ -match $uriPattern) {
            $_ -replace $uriPattern, ('{0}$1{1}$2{2}$3' -f $TargetEnvironment, $Matches.appPrefix, $Matches.appName)
        } else {
            $_
        }
    }

    $newContent = $newContent | ForEach-Object {
        if ($_ -match $appNamePattern) {
            ($_ -split $appNameSplitPattern) -join "$TargetEnvironment-$appPrefix"
        } else {
            $_
        }
    }

    Set-Content -Path $targetFilePath -Value $newContent -Force -Encoding UTF8
    Write-Host "##vso[task.setvariable variable=templateFile]$targetFilePath"

} catch {
    Write-Host ('##[error] Error extracting ARM template. {0}' -f $_.Exception.Message)
    $host.SetShouldExit(1)
}