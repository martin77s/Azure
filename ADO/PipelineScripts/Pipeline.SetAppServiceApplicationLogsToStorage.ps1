<#

Script Name	: Pipeline.SetAppServiceApplicationLogsToStorage
Description	: Set the AppServices to write their application logs to the environment's storage account
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, AppService, ApplicationLogSettings
Last Update	: 2020/06/11

#>

PARAM(
    [Parameter(Mandatory)] [string] $Environment,
    [Parameter(Mandatory)] [string] $ApplicationName,
    [Parameter(Mandatory)] [string] $StorageAccountName,
    $LogLevel = 'Information',
    $RetentionInDays = 180
)


# Get the storage account details, context and existing containers
$storageAccount = Get-AzResource -Name $StorageAccountName -ResourceType 'Microsoft.Storage/storageAccounts'
$storageAccountContext = (Get-AzStorageAccount -Name $storageAccount.Name -ResourceGroupName $storageAccount.ResourceGroupName).Context
$containers = Get-AzStorageContainer -Context $storageAccountContext
Write-Host ("Storage Account Id for the application logs: {0}" -f $storageAccount.Id)


# Loop through the WebApps and WebAPIs in the environment and have the ApplicationName prefix
$webApps = Get-AzWebApp | Where-Object { $_.Name -match ('({0})-({1})-' -f $Environment, $ApplicationName) } | Sort-Object Name
Write-Host ("Found {0} web apps to configure:" -f $webAppNames.Count)
Write-Host ($webAppNames -join ", ")

foreach ($webApp in $webApps) {

    Write-Host ("Working on {0}" -f $webApp.Name)

    # Get the webApp log settings
    $params = @{
        ResourceName      = "$($webApp.Name)/logs"
        ResourceGroupName = $webApp.ResourceGroup
        ResourceType      = 'Microsoft.Web/sites/config'
        ApiVersion        = '2016-08-01'
        ExpandProperties  = $true
    }
    $webAppResource = Get-AzResource @params


    # Verify the storage account container exists
    if (-not ($containers | Where-Object { $_.Name -contains $webApp.Name })) {
        Write-Host ("Creating a new container for {0}" -f $webApp.Name)
        $containers += New-AzStorageContainer -Context $storageAccountContext -Name $webApp.Name -Permission Off
    }


    # Generate a SAS token Url
    $AzStorageContainerSASTokenParams = @{
        Context    = $storageAccountContext
        Name       = $webApp.Name
        Permission = 'rwdl'
        StartTime  = (Get-Date).AddHours(-1)
        ExpiryTime = (Get-Date).AddYears(200)
    }
    Write-Host ("Generating SAS token for {0}" -f $webApp.Name)
    $sasToken = New-AzStorageContainerSASToken @AzStorageContainerSASTokenParams
    $sasUrl = '{0}{1}{2}' -f $storageAccountContext.BlobEndPoint, $webApp.Name, $sasToken


    # Set the webApp application log settings properties
    $webAppResource.Properties.applicationLogs.azureBlobStorage.level = $LogLevel
    $webAppResource.Properties.applicationLogs.azureBlobStorage.retentionInDays = $RetentionInDays
    $webAppResource.Properties.applicationLogs.azureBlobStorage.sasUrl = $sasUrl


    # Update the webApp log settings
    $params = @{
        ResourceName      = "$($webApp.Name)/logs"
        ResourceGroupName = $webApp.ResourceGroup
        ResourceType      = 'Microsoft.Web/sites/config'
        Properties        = $webAppResource.Properties
        ApiVersion        = '2016-08-01'
        Force             = $true
    }
    Write-Host ("Updating setting for {0}" -f $webApp.Name)
    Set-AzResource @params
}
