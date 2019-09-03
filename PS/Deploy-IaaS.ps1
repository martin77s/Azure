# Define the Deployment Variables
$resourceGroupName = 'rg-deploy-iaas'
$resourceGroupLocation = 'westeurope'

$vNetName = 'vnet-contoso'
$vNetAddressPrefix = '172.16.0.0/16'

$vNetSubnet1Name = 'subnet-1'
$vNetSubnet1Prefix = '172.16.1.0/24'

$vNetSubnet2Name = 'subnet-2'
$vNetSubnet2Prefix = '172.16.2.0/24'

$storageAccountType = 'Standard_LRS'
$storageAccountName = 'strg{0}' -f ((New-Guid).GUID -replace '-').Substring(0, 12)


# Create the Virtual Network Subnets
$subnet1Params = @{
    Name          = $vNetSubnet1Name
    AddressPrefix = $vNetSubnet1Prefix
    Verbose       = $true
}
$vNetSubnet1 = New-AzureRmVirtualNetworkSubnetConfig @subnet1Params

$subnet2Params = @{
    Name          = $vNetSubnet2Name
    AddressPrefix = $vNetSubnet2Prefix
    Verbose       = $true
}
$vNetSubnet2 = New-AzureRmVirtualNetworkSubnetConfig @subnet2Params


# Create the Virtual Network
$vnetParams = @{
    ResourceGroupName = $resourceGroupName
    Location          = $resourceGroupLocation
    Name              = $vNetName
    AddressPrefix     = $vNetAddressPrefix
    Subnet            = $vNetSubnet1, $vNetSubnet2
    Verbose           = $true
    Force             = $true
}
New-AzureRmVirtualNetwork @vnetParams


# Create the Storage Account
$storageParams = @{
    ResourceGroupName = $resourceGroupName
    Location          = $resourceGroupLocation
    Name              = $storageAccountName
    Type              = $storageAccountType
    Verbose           = $true
}
New-AzureRmStorageAccount $storageParams
