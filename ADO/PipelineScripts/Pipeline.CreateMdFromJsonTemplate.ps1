<#

Script Name	: Pipeline.CreateMdFromJsonTemplate.ps1
Description	: Create readme.md markdown file from an ARM template
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, DevOps, ARM, Markdown

#>


param (
    [CmdletBinding()]

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path -Path $_ })] $Path,
    [Switch]$PassThru
)


$json = ConvertFrom-Json -InputObject (Get-Content $Path -Raw) -ErrorAction Stop
$OutputPath = Join-Path -Path (Split-Path -Path $Path -Parent) -ChildPath 'readme.md'
$parameters = $resources = $outputs = $null


$resourceTitle = 'ARM Template: {0}' -f ($Path -replace '.*(\\|/)(.*)\.deploy\.json', '$2')
if ($json.resources.type.Count -lt 2) {
    $resourceType = ($json.resources.type -ne 'Microsoft.Resources/deployments')[0]
    $resourceTitle = '[{0}](https://docs.microsoft.com/en-us/azure/templates/{0})' -f $resourceType
}

if ($json.parameters) {
    $parameters = @'
| Name | Type | Description | DefaultValue |
| --- | --- | --- | --- |
{0}
'@ -f $(
        @(foreach ($param in ($json.parameters | Get-Member -MemberType NoteProperty)) {
                '| {0} | {1} | {2} | {3} |' -f `
                    $param.Name, $json.parameters.($param.Name).type,
                $json.parameters.($param.Name).metadata.description,
                $json.parameters.($param.Name).defaultValue
            }) -join [environment]::NewLine
    )
}


if ($json.resources) {
    $resources = @'
| Type | Name | Comment |
| --- | --- | --- |
{0}
'@ -f $(
        (@(foreach ($resource in $json.resources) {
                    '| [{0}](https://docs.microsoft.com/en-us/azure/templates/{0}) | {1} | {2} |' -f $resource.Type, $resource.Name, $resource.Comments
                }) | Sort-Object) -join [environment]::NewLine
    )
}


if ($json.outputs) {
    $outputs = @'
| Name | Type | Value|
| --- | --- | --- |
{0}
'@ -f $(
        @(foreach ($output in ($json.outputs | Get-Member -MemberType NoteProperty)) {
                if ('array' -eq $json.outputs.($output.Name).type) {
                    $outputValue = $json.outputs.($output.Name).copy.input
                } else {
                    $outputValue = $json.outputs.($output.Name).value
                }
                '| {0} | {1} | {2} |' -f $output.Name , $json.outputs.($output.Name).type, $outputValue
            }) -join [environment]::NewLine
    )
}

@'
# {0}

## Parameters

{1}

## Resources

{2}

## Outputs

{3}
'@ -f $resourceTitle, $parameters, $resources, $outputs | Out-File -FilePath $OutputPath -Force
if ($PassThru) { Get-Item -Path $OutputPath }
