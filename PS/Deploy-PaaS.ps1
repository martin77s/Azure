# Define the Deployment Variables
$resourceGroupName = 'rg-deploy-paas'
$resourceGroupLocation = 'westeurope'

$appServicePlanName = 'contosoplan{0}' -f ((New-Guid).GUID -replace '-').Substring(0, 5)
$webAppName = 'contosoweb{0}' -f ((New-Guid).GUID -replace '-').Substring(0, 6)

# Create the App Service Plan
$appServicePlanParams = @{
    ResourceGroupName = $resourceGroupName
    Location          = $resourceGroupLocation
    Name              = $appServicePlanName
    Tier              = 'Standard'
    WorkerSize        = 'Small'
    Verbose           = $true
}
$appServicePlan = New-AzureRmAppServicePlan @appServicePlanParams

# Create the Web App
$webAppParams = @{
    ResourceGroupName = $resourceGroupName
    Location          = $resourceGroupLocation
    AppServicePlan    = $appServicePlan.ServerFarmWithRichSkuName
    Name              = $webAppName
    Verbose           = $true
}
New-AzureRmWebApp @webAppParams