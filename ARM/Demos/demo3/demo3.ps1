# Connect to Azure:
# Connect-AzAccount


# Define some variables:
$location = 'West Europe'
$resourceGroup = 'armdemos-rg'
$templateFile = '.\demo3\demo3.json'


# Create the target resource group:
if (-not (Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
	New-AzResourceGroup -Name $resourceGroup -Location $location
}


# Deploy the template:
New-AzResourceGroupDeployment -Name TemplateWithParam -ResourceGroupName $resourceGroup `
	-TemplateFile $templateFile -storageName strgrandomstr123