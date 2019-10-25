# Connect to Azure:
# Connect-AzAccount


# Define some variables:
$location = 'West Europe'
$resourceGroup = 'armdemos-rg'
$templateUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-storage-file-share/azuredeploy.json'


# Create the target resource group:
if(-not (Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
	New-AzResourceGroup -Name $resourceGroup -Location $location
}


# Deploy the template:
New-AzResourceGroupDeployment -Name FromTemplateUriUsingDefaults -ResourceGroupName $resourceGroup `
	-TemplateUri $templateUri 

	
New-AzResourceGroupDeployment -Name FromTemplateUriUsingParams -ResourceGroupName $resourceGroup `
	-TemplateUri $templateUri `
	-storageAccountName strgrandomstr789 `
	-fileShareName myshare `
	-location $location
