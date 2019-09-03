
# Register resource providers
@('Microsoft.Web', 'Microsoft.Storage') | ForEach-Object {
    Register-AzureRmResourceProvider -ProviderNamespace $_
}


# Create resource group
$resourceGroupName = 'rg-deploy-azfnps'
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    $resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
}


# Create storage account
$location = 'westeurope'
$storageAccountName = 'azfn{0}' -f ((New-Guid).GUID -replace '-').Substring(0, 12)
$newStorageParams = @{
    ResourceGroupName = $resourceGroupName
    AccountName       = $storageAccountName
    Location          = $location
    SkuName           = 'Standard_LRS'
}
New-AzureRmStorageAccount @newStorageParams


# Get storage account key and create connection string
$accountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccountName |
    Where-Object {$_.KeyName -eq 'Key1'} | Select-Object -ExpandProperty Value
$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$accountKey"


# Create the Function App
$functionAppName = 'azPsFunctions'
$newFunctionAppParams = @{
    ResourceType      = 'Microsoft.Web/Sites'
    ResourceName      = $functionAppName
    Kind              = 'functionapp'
    Location          = $location
    ResourceGroupName = $resourceGroupName
    Properties        = @{}
    Force             = $true
}
$functionApp = New-AzureRmResource @newFunctionAppParams


# Set Function app settings
$setWebAppParams = @{
    Name              = $functionAppName
    ResourceGroupName = $resourceGroupName
    AppSettings       = @{
        AzureWebJobDashboard                     = $storageConnectionString
        AzureWebJobsStorage                      = $storageConnectionString
        FUNCTIONS_EXTENSION_VERSION              = '~1'
        WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = $storageConnectionString
        WEBSITE_CONTENTSHARE                     = $storageAccountName
    }
}
Set-AzureRmWebApp @setWebAppParams


# Deploy the function
$functionName = 'HelloWorld'
$functionContent = @'
$requestBody = Get-Content $req -Raw | ConvertFrom-Json

# Get request body or query string parameter
if ($req_query_name) {
    $name = $req_query_name
} else {
    $name = $requestBody.name
}

$response = @{
    time = [System.DateTime]::UtcNow.ToString('u')
    Message = "Hello $name"
} | ConvertTo-Json

Out-File -InputObject $response -FilePath $res -Encoding Ascii
'@ -join ''
$functionSettings = @'
{
    "bindings": [
        {
            "name": "req",
            "type": "httpTrigger",
            "direction": "in",
            "authLevel": "function"
        },
        {
            "name": "res",
            "type": "http",
            "direction": "out"
        }
    ],
    "disabled": false
}
'@ | ConvertFrom-Json
$functionResourceId = '{0}/functions/{1}' -f $functionApp.ResourceId, $functionName
$functionProperties = @{
    config = @{'bindings' = $functionSettings.bindings}
    files  = @{'run.ps1' = "$functionContent"}
}
$newFunctionParams = @{
    ResourceId = $functionResourceId
    Properties = $functionProperties
    ApiVersion = '2015-08-01'
    Force      = $true
}
$function = New-AzureRmResource @newFunctionParams
$function


# Test the function
$getSecretsParams = @{
    ResourceId = $function.ResourceId
    Action     = 'listsecrets'
    ApiVersion = '2015-08-01'
    Force      = $true
}
$functionSecrets = Invoke-AzureRmResourceAction @getSecretsParams

# GET
Invoke-RestMethod -Uri "$($functionSecrets.trigger_url)&name=Martin"

# POST
$body = @{
    name = 'Martin'
} | ConvertTo-Json
Invoke-RestMethod -Uri $functionSecrets.trigger_url -Body $body -Method Post