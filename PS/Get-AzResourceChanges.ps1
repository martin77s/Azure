<#

Script Name	: Get-AzResourceChanges.ps1
Description	: Get the specified resource's changes for the last timespan specified
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/22
Keywords	: Azure, Resource, Graph, ResourceChanges

#>

[CmdletBinding(DefaultParameterSetName = 'byResourceId')]

PARAM(

    [Parameter(Mandatory = $true, ParameterSetName = 'byResourceId')] [string] $ResourceID,

    [Parameter(Mandatory = $true, ParameterSetName = 'byResourceName')] [string]$ResourceGroupName,
    [Parameter(Mandatory = $true, ParameterSetName = 'byResourceName')] [string]$ResourceName,
    [Parameter(Mandatory = $true, ParameterSetName = 'byResourceName')] [string]$ResourceType,

    [timespan]$TimeSpan = 36000000000
)

try {
    if ($PSCmdlet.ParameterSetName -eq 'byResourceName') {
        $rid = (Get-AzResource -ResourceGroupName $ResourceGroupName -Name $ResourceName -ResourceType $ResourceType).ResourceId
    } else {
        $rid = (Get-AzResource -ResourceId $ResourceID).ResourceId
    }
} catch {
    throw 'Cannot find such resource'
}

$context = Get-AzContext
$cachedTokens = ($context.TokenCache).ReadItems() |
    Where-Object { $_.TenantId -eq $context.Tenant.Id } |
        Sort-Object -Property ExpiresOn -Descending
$accessToken = $cachedTokens[0].AccessToken

$endTime = (Get-Date (Get-Date).ToUniversalTime() -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')
$startTime = (Get-Date (Get-Date).AddMilliseconds(-1 * $TimeSpan.TotalMilliseconds).ToUniversalTime() -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')

$body = @{
    resourceId = $rid
    interval   = @{
        start = $startTime
        end   = $endTime
    }
} | ConvertTo-Json

$getChangesParams = @{
    Method          = 'POST'
    Body            = $body
    UseBasicParsing = $true
    Headers         = @{ 'Authorization' = 'Bearer ' + $accessToken; 'Content-Type' = 'application/json' }
    Uri             = 'https://management.azure.com/providers/Microsoft.ResourceGraph/resourceChanges?api-version=2018-09-01-preview'
}; $changes = (Invoke-WebRequest @getChangesParams).Content | ConvertFrom-Json


foreach ($changeId in $changes.changes.changeId ) {
    $body = @{
        resourceId = $rid
        changeId   = $changeId
    } | ConvertTo-Json

    $getChangeDetailsParams = @{
        Method  = 'POST'
        Body    = $body
        Headers = @{ 'Authorization' = 'Bearer ' + $accessToken; 'Content-Type' = 'application/json' }
        Uri     = 'https://management.azure.com/providers/Microsoft.ResourceGraph/resourceChangeDetails?api-version=2018-09-01-preview'
    }; $response = Invoke-RestMethod @getChangeDetailsParams
    $response.beforeSnapshot.content | ConvertTo-Json -Depth 100 | Out-File before.json
    $response.afterSnapshot.content | ConvertTo-Json -Depth 100 | Out-File after.json
    $diff = Compare-Object -ReferenceObject (Get-Content before.json) -DifferenceObject (Get-Content after.json)
    if ($diff) {
        [PSCustomObject]@{
            AfterSnapshotTimestamp  = $response.afterSnapshot.timestamp
            BeforeSnapshotTimestamp = $response.beforeSnapshot.timestamp
            Changes                 = $diff.InputObject.Trim()
        }
    }
    Remove-Item before.json, after.json -Force
}
