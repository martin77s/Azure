param (
    [CmdletBinding()]
    
    [Parameter(Mandatory=$true)] 
    [ValidateScript({Test-Path -Path $_})] $Path,
    [Switch]$PassThru
)


$json = ConvertFrom-Json -InputObject (Get-Content $Path -Raw) -ErrorAction Stop
$OutputPath = Join-Path -Path (Split-Path -Path $Path -Parent) -ChildPath 'readme.md'
$parameters = $resources = $outputs = $null
$resourceType = ((Split-Path -Path $Path -Leaf) -replace '(\.deploy)?(\.json)')

if($json.parameters) {
    $parameters = @'
| Name | Type | Description | DefaultValue |
| --- | --- | --- | --- |
{0}
'@  -f $(
        @(foreach ($param in ($json.parameters | Get-Member -MemberType NoteProperty)) {
            '| {0} | {1} | {2} | {3} |' -f `
                $param.Name, $json.parameters.($param.Name).type,
                $json.parameters.($param.Name).metadata.description,
                $json.parameters.($param.Name).defaultValue
        }) -join [environment]::NewLine
    )
}


if($json.resources) {
    $resources = @'
| Type | Name | Comment |
| --- | --- | --- |
{0}
'@ -f $(
        (@(foreach($resource in $json.resources) {
            '| {0} | {1} | {2} |' -f $resource.Type, $resource.Name, $resource.Comments
        }) | Sort-Object) -join [environment]::NewLine
    )
}


if($json.outputs) {
    $outputs = @'
| Name | Type | Value|
| --- | --- | --- |
{0}
'@ -f $(
        @(foreach($output in ($json.outputs | Get-Member -MemberType NoteProperty)) {
            '| {0} | {1} | {2} |' -f $output.Name , $json.outputs.($output.Name).type, $json.outputs.($output.Name).value
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
'@ -f $resourceType, $parameters, $resources, $outputs | Out-File -FilePath $OutputPath -Force
if($PassThru) { Get-Item -Path $OutputPath }
