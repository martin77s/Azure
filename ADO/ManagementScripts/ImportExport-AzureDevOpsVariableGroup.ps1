
function Export-AzureDevOpsVariableGroup {
    param (
        [string] $Organization = 'myOrg',
        [string] $Project = 'myProject',
        [string] $GroupName = 'myGroup',
        [string] $PAT = $null
    )
    $uri = "https://dev.azure.com/$Organization/$Project/_apis/distributedtask/variablegroups?api-version=5.1-preview.1"
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((':{0}' -f $PAT)))
    $all = Invoke-RestMethod -Uri $uri -Method Get -ContentType 'application/json' -Headers @{Authorization=("Basic {0}" -f $auth)} |
        ConvertTo-Json -Depth 100 | ConvertFrom-Json
    $all.value | Where-Object { $_.name -eq $GroupName }
}

function Import-AzureDevOpsVariableGroup {
    param (
        [string] $Organization = 'myOrg',
        [string] $Project = 'myProject',
        [string] $PAT = $null,
        [object] $Json
    )
    $uri = "https://dev.azure.com/$Organization/$Project/_apis/distributedtask/variablegroups?api-version=5.1-preview.1"
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((':{0}' -f $PAT)))
    Invoke-RestMethod -Uri $uri -Method POST -Body (ConvertTo-Json -InputObject $Json) -ContentType 'application/json' -Headers @{Authorization=("Basic {0}" -f $auth)} |
        ConvertTo-Json -Depth 100
}

function Update-AzureDevOpsVariableGroup {
    param($FromEnvironment, $ToEnvironment, $Json)
    $temp = $Json.psObject.Copy()
    $temp.variables | Get-Member -MemberType NoteProperty | ForEach-Object {
        $propName = $_.Name
        if($temp.variables.$propName.value -match $FromEnvironment) {
            $temp.variables.$propName.value = $temp.variables.$propName.value -replace $FromEnvironment, $ToEnvironment
        }
    }
    $temp | Get-Member -MemberType NoteProperty | ForEach-Object {
        $propName = $_.Name
        if($temp.$propName -match $FromEnvironment) {
            $temp.$propName = $temp.$propName -replace $FromEnvironment, $ToEnvironment
        }
    }
    $temp.modifiedOn = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffffffZ')
    $temp
}



$PAT = '<Insert the personal access token (PAT) value here />'

$params = @{
     Organization = 'maschvar'
     Project      = 'Olamot'
     PAT          = $PAT
     GroupName    = 'Dev Environment'
}; $output = Export-AzureDevOpsVariableGroup @params


$params = @{
    FromEnvironment = 'dev'
    ToEnvironment   = 'uat'
    Json            = $output
}; $json = Update-AzureDevOpsVariableGroup @params


$params = @{
     Organization = 'maschvar'
     Project      = 'Olamot'
     PAT          = $PAT
     Json         = $json
}
Import-AzureDevOpsVariableGroup @params
