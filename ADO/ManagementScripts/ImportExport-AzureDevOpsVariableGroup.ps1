
function Export-AzureDevOpsVariableGroup {
    param (
        [string]$Organization = 'myOrg',
        [string]$Project = 'myProject',
        [string]$User = 'ado@contoso.com',
        [string]$PAT = 'efq4q4oeiaqcpppqwmgvmp2jqxnb2fo34ntuiiqa6skkan4fzzqa'
    )
    $uri = "https://dev.azure.com/$Organization/$Project/_apis/distributedtask/variablegroups?api-version=5.1-preview.1"
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(('{0}:{1}' -f $PAT, $token)))
    Invoke-RestMethod -Uri $uri -Method Get -ContentType 'application/json' -Headers @{Authorization=("Basic {0}" -f $auth)} | 
        ConvertTo-Json -Depth 100 | ConvertFrom-Json
}

function Import-AzureDevOpsVariableGroup {
    param (
        [string]$Organization = 'myOrg',
        [string]$Project = 'myProject',
        [string]$User = 'ado@contoso.com',
        [string]$PAT = 'efq4q4oeiaqcpppqwmgvmp2jqxnb2fo34ntuiiqa6skkan4fzzqa',
        [string]$VariablesJson
    )
    $uri = "https://dev.azure.com/$Organization/$Project/_apis/distributedtask/variablegroups?api-version=5.1-preview.1"
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(('{0}:{1}' -f $PAT, $token)))
    Invoke-RestMethod -Uri $uri -Method POST -Body $VariablesJson -ContentType 'application/json' -Headers @{Authorization=("Basic {0}" -f $auth)} | 
        ConvertTo-Json -Depth 100
}

