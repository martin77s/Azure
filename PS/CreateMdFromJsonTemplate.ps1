param (
    $Path = (Join-Path -Path $PSScriptRoot -ChildPath azuredeploy.json),
	$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath azuredeploy.md),
    [Switch]$PassThru
)

$json = ConvertFrom-Json -InputObject (Get-Content $Path -Raw) -ErrorAction Stop

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

$resources = @'
| Type | Name | Comment |
| --- | --- | --- |
{0}
'@ -f $(
    (@(foreach($resource in $json.resources) {
        '| {0} | {1} | {2} |' -f $resource.Type, $resource.Name, $resource.Comments
    }) | Sort-Object) -join [environment]::NewLine
)

$outputs = @'
| Name | Type | Value|
| --- | --- | --- |
{0}
'@ -f $(
    @(foreach($output in ($json.outputs | Get-Member -MemberType NoteProperty)) {
        '| {0} | {1} | {2} |' -f $output.Name , $json.outputs.($output.Name).type, $json.outputs.($output.Name).value
    }) -join [environment]::NewLine
)

@'
# {0}

## Parameters

{1}

## Resources

{2}

## Outputs

{3}
'@ -f (Split-Path -Path $Path -Leaf), $parameters, $resources, $outputs | Out-File -FilePath $OutputPath
if($PassThru) { Get-Item -Path $OutputPath }
