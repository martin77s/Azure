# Connect to Azure:
# Connect-AzAccount


# Define some variables:
$location = 'West Europe'
$resourceGroup = 'armdemos-rg'
$templateFile = '.\demo6\demo6.json'


# Create the target resource group:
if (-not (Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
	New-AzResourceGroup -Name $resourceGroup -Location $location
}


# Deploy the template:
New-AzResourceGroupDeployment -Name TemplateWithOutput -ResourceGroupName $resourceGroup `
	-TemplateFile $templateFile -storagePrefix strg -storageSKU Standard_LRS