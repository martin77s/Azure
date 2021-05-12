<#

Script Name	: CreateVnetPeering.ps1
Description	: Create two-way vnet peering between the hub and a spoke vnet
Keywords	: Azure, Vnet, Peering

#>

PARAM(
    [Parameter(Mandatory = $true)][string] $hubVnetResourceId,
    [Parameter(Mandatory = $true)][string] $vnetResourceId
)


# Create Hub-to-Vnet peering
$subscriptionId, $resourceGroupName, $hubVnetName = ($hubVnetResourceId -split '/')[2, 4, 8]
$context = Get-AzContext
if (-not($subscriptionId -eq $context.Subscription.Id)) {
    $context = Set-AzContext -SubscriptionId $subscriptionId -Tenant $context.Tenant.Id -Force
}
$hubVnet = Get-AzVirtualNetwork -Name $hubVnetName -ResourceGroupName $resourceGroupName
$params = @{
    Name                   = 'Hub-To-{0}' -f (($vnetResourceId -split '/')[8])
    VirtualNetwork         = $hubVnet
    RemoteVirtualNetworkId = $vnetResourceId
    AllowGatewayTransit    = $true
}
Add-AzVirtualNetworkPeering @params


# Create Vnet-to-Hub peering
$subscriptionId, $resourceGroupName, $VnetName = ($vnetResourceId -split '/')[2, 4, 8]
if (-not($subscriptionId -eq $context.Subscription.Id)) {
    $context = Set-AzContext -SubscriptionId $subscriptionId -Tenant $context.Tenant.Id -Force
}
$vnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $resourceGroupName
$params = @{
    Name                   = '{0}-To-Hub' -f $VnetName
    VirtualNetwork         = $vnet
    RemoteVirtualNetworkId = $hubVnetResourceId
    UseRemoteGateways      = $true
}
Add-AzVirtualNetworkPeering @params
