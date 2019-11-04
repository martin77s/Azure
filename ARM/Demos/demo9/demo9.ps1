# Connect to Azure:
# Connect-AzAccount


# Define some variables:
$location = 'West Europe'
$templateFile = '.\demo9\demo9.json'


# Create the target resource group:
if (-not (Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
  New-AzResourceGroup -Name $resourceGroup -Location $location
}


# Deploy the template:
New-AzResourceGroup -Name myDevEnv-rg -Location $location
$parameterFile = '.\demo9\azuredeploy.parameters.dev.json'
New-AzResourceGroupDeployment -Name myDevEnv -ResourceGroupName myDevEnv-rg `
  -TemplateFile $templateFile -TemplateParameterFile $parameterFile


New-AzResourceGroup -Name myProdEnv-rg -Location $location
$parameterFile = '.\demo9\azuredeploy.parameters.prod.json'
New-AzResourceGroupDeployment -Name myProdEnv -ResourceGroupName myProdEnv-rg `
  -TemplateFile $templateFile -TemplateParameterFile $parameterFile