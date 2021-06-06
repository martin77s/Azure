<#

Script Name	: Pipeline.StageIotEdgeVmPostDeployScript.ps1
Description	: Stage the IotEdge VM post deployment script in a storage account,
			  and create the cseTimestamp, cseCommandToExecute & cseFileUri (with the SAS token url for it)
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, StorageAccount, Container

#>

#Requires -PSEdition Core


PARAM(
    [Parameter(Mandatory)] [string] $ResourceGroupName,
    [Parameter(Mandatory)] [string] $StorageAccountName,
    [Parameter(Mandatory = $false)] [string] $ContainerName = 'iotedgevm',
    [Parameter(Mandatory = $false)] [string] $LocalFileToUpload = $null

)


# Get the storage account context
$account = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
if (-not $account) {
    Write-Error 'Resource not found'
    $host.SetShouldExit(1)
}


# Verify the container exists
$container = Get-AzStorageContainer -Name $ContainerName.ToLower() -Context $account.Context -ErrorAction SilentlyContinue
if (-not $container) {
    $container = New-AzStorageContainer -Name $ContainerName.ToLower() -Context $account.Context -Permission Off
}
if (-not $container) {
    Write-Error 'Could not get or create the container'
    $host.SetShouldExit(1)
}


# Upload the file(s)
$bareFileName = (Split-Path -Path $LocalFileToUpload -Leaf).ToLower()
$blobContentParams = @{
    File      = $LocalFileToUpload
    Blob      = $bareFileName
    Container = $ContainerName.ToLower()
    Context   = $account.Context
    Force     = $true
}; Set-AzStorageBlobContent @blobContentParams
if (-not $?) {
    Write-Error 'Could not upload the file to the storage account container'
    $host.SetShouldExit(1)
}


# Create the SAS token to return
$sasTokenParams = @{
    Context    = $account.Context
    Name       = $ContainerName.ToLower()
    Permission = 'r'
    StartTime  = (Get-Date).AddHours(-1)
    ExpiryTime = (Get-Date).AddHours(1)
}; $sasToken = New-AzStorageContainerSASToken @sasTokenParams
$cseFileUri = '{0}{1}/{2}{3}' -f $account.context.BlobEndPoint, $ContainerName.ToLower(), $bareFileName, $sasToken


# Determine the file version (based on the commit id)
try {
    $cdTo = $LocalFileToUpload
    do {
        $cdTo = Split-Path $cdTo -Parent -ErrorAction SilentlyContinue
        $break = (Get-Item -Path "$cdTo\.git" -Force -ErrorAction SilentlyContinue) -or ($cdTo -eq '')
    } until ($break)
    $LocalFileToUpload = $LocalFileToUpload -replace '\\', '/'
    $cdTo = $cdTo -replace '\\', '/'
    $relativePath = ($LocalFileToUpload -replace [regex]::Escape($cdTo))
    Push-Location -Path $cdTo
    $cseTimestamp = (git rev-list --max-count=1 --all -- ".$relativePath") -replace '\D'
    while ([int]::MaxValue -lt $cseTimestamp) { $cseTimestamp /= 1kb }
    $cseTimestamp = [int]$cseTimestamp
    Pop-Location
} catch {
    $cseTimestamp = 0
}


# Create the cseFileUri, cseCommandToExecute & cseTimestamp pipeline variables for the intake layer deployment
Write-Host "##vso[task.setvariable variable=cseFileUri]$cseFileUri"
Write-Host "##vso[task.setvariable variable=cseCommandToExecute]sh $bareFileName"
Write-Host "##vso[task.setvariable variable=cseTimestamp]$cseTimestamp"