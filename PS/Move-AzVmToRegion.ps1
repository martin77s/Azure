#Requires -Version 5.1
#Requires -Module Az.Accounts, Az.Compute, Az.Network, Az.Storage, Az.Resources

<#
    Name        : Move-AzVmToRegion.ps1
    Version     : 1.0.0.5
    Last Update : 2020/05/13
    Keywords    : Azure, VM, Move
    Created by  : Martin Schvartzman, Microsoft
    Description : This script moves a virtual machine and all it's dependencies to a different region
    Process     :
                    1. Verify target region can host the VM size
                    2. Create the target resource group (if needed)
                    3. Read the VM's networking configuration
                    4. Stop the virtual machine
                    5. Create a temp storage account and vhds container in the target region
                    6. Export the managed disks as SAS url
                    7. Copy the disks (VHD files) to the temp storage account
                    8. Create new managed disks from the vhds
                    9. Create the networking components (vnet, subnet, NSG, IP, etc.)
                    6. Recreate the virtual machine
    Todo        :
                    1. Handle the diagnostic settings and it's storage account
                    2. Handle the Public IP's FQDN
                    3. Handle the VM Extensions
                    4. Better error handling and logging
#>

[CmdletBinding(SupportsShouldProcess = $true)]

param(
	[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
	[Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VM,

	[Parameter(Mandatory = $true)] 
	[Alias('Location')]
	$TargetLocation,

	[Parameter(Mandatory = $true)] 
	[Alias('ResourceGroup')]
	$TargetResourceGroup,

	[int]    $SasTokenDuration = 3600,
	[string] $AzCopyPath = '.\azcopy.exe',
	[switch] $UseAzCopy
)

#region Location
Write-Verbose -Message ('{0:HH:mm:ss} - Verifying target location' -f (Get-Date))
$locations = Get-AzLocation | Where-Object { $_.Providers -contains 'Microsoft.Compute' }
if ($TargetLocation -match '\s') {
	$TargetLocation = @($locations | Where-Object { $_.DisplayName -eq $TargetLocation } | Select-Object -ExpandProperty Location)[0]
} else {
	$TargetLocation = @($locations.Location -match $TargetLocation)[0]
}

if (-not $TargetLocation) {
	Write-Warning 'Target location error. Process aborted.'
	break
}

if ($VM.Location -eq $TargetLocation) {
	Write-Warning 'Source and target location are the same. Process aborted.'
	break
}

Write-Verbose -Message ('{0:HH:mm:ss} - Checking size availability in the target region' -f (Get-Date))
$sizes = Get-AzVMSize -Location $TargetLocation | Select-Object -ExpandProperty Name
if ($sizes -notcontains $VM.HardwareProfile.VmSize) {
	Write-Warning 'Target location doesnt support the VM size. Process aborted.'
	break
}
#endregion

#region verify copy mode
if ($UseAzCopy -and (-not (Test-Path -Path $AzCopyPath))) {
	Write-Warning 'AzCopy.exe was not found in the specified path. The Start-AzStorageBlobCopy cmdlet will be used instead'
	$UseAzCopy = $false
}
#endregion

if ($PSCmdlet.ShouldProcess($VM.Name, "Move to $TargetLocation")) {

	#region Verify the ResourceGroup
	Write-Verbose -Message ('{0:HH:mm:ss} - Verifying the resource group' -f (Get-Date))
	if (-not $TargetResourceGroup) {
		$TargetResourceGroup = '{0}-new' -f $VM.ResourceGroupName
	}
	if (-not (Get-AzResourceGroup -Name $TargetResourceGroup -ErrorAction SilentlyContinue)) {
		New-AzResourceGroup -Name $TargetResourceGroup -Location $TargetLocation -Force | Out-Null
	}
	#endregion

	#region Get Networking details
	Write-Verbose -Message ('{0:HH:mm:ss} - Collecting network configuration' -f (Get-Date))
	$nic = Get-AzNetworkInterface -ResourceId $VM.NetworkProfile.NetworkInterfaces.Id
	$pubIp = Get-AzPublicIpAddress | Where-Object { $_.Id -eq $nic.IpConfigurations.PublicIpAddress.Id }
	$nsg = Get-AzNetworkSecurityGroup | Where-Object { $_.Id -eq $nic.NetworkSecurityGroup.Id }
	$vnetName = $nic.IpConfigurations[0].Subnet.Id -replace '.*\/virtualNetworks\/(.*)\/subnets\/.*', '$1'
	$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $VM.ResourceGroupName
	$targetVnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $TargetResourceGroup -ErrorAction SilentlyContinue
	#endregion

	#region Verify VM status
	Write-Verbose -Message ('{0:HH:mm:ss} - Verifying VM is shutdown' -f (Get-Date))
	$vmStatus = $VM | Get-AzVM -Status
	if ($vmStatus.PowerState -ne 'VM deallocated') {
		$VM | Stop-AzVM -Force | Out-Null
	}
	#endregion

	#region Create a temp target storage account and container
	Write-Verbose -Message ('{0:HH:mm:ss} - Creating a temporary storage account' -f (Get-Date))
	$storageAccountParams = @{
		ResourceGroupName = $TargetResourceGroup
		Location          = $TargetLocation
		SkuName           = 'Standard_LRS'
		Name              = 'tempstrg{0:yyyyMMddHHmmssff}' -f (Get-Date)
	}; $targetStorage = New-AzStorageAccount @storageAccountParams

	Write-Verbose -Message ('{0:HH:mm:ss} - Creating the target container' -f (Get-Date))
	$storageContextParams = @{
		StorageAccountName = $targetStorage.StorageAccountName
		StorageAccountKey  = (
			Get-AzStorageAccountKey -ResourceGroupName $targetStorage.ResourceGroupName -Name $targetStorage.StorageAccountName
		)[0].Value
	}; $storageContext = New-AzStorageContext @storageContextParams
	New-AzStorageContainer -Name vhds -Context $storageContext | Out-Null
	#endregion

	#region Export the managed disks
	Write-Verbose -Message ('{0:HH:mm:ss} - Generating SASAccess for the OSDisk' -f (Get-Date))
	$osDiskAccessParams = @{
		ResourceGroupName = $VM.ResourceGroupName
		DiskName          = $VM.StorageProfile.OsDisk.Name
		DurationInSecond  = $SasTokenDuration
		Access            = 'Read'
	}; $osDiskSAS = Grant-AzDiskAccess @osDiskAccessParams

	$sourceDataDisks = $VM.StorageProfile.DataDisks
	$dataDisksSAS = @{ }
	foreach ($dataDisk in $sourceDataDisks) {
		Write-Verbose -Message ('{0:HH:mm:ss} - Generating SASAccess for DataDisk: {1}' -f (Get-Date), $dataDisk.Name)
		$dataDiskAccessParams = @{
			ResourceGroupName = $VM.ResourceGroupName
			DiskName          = $dataDisk.Name
			DurationInSecond  = $SasTokenDuration
			Access            = 'Read'
		}; $dataDisksSAS.Add($dataDisk.Name, (Grant-AzDiskAccess @dataDiskAccessParams))
	}
	#endregion

	#region Copy the vhds
	Write-Verbose -Message ('{0:HH:mm:ss} - Copying the vhds to the target container' -f (Get-Date))
	function Copy-ManagedDiskToTargetContainer {
		param(
			$storageContext,
			$AccessSAS,
			$DestinationBlob,
			[switch]$useAzCopy
		)
		if ($useAzCopy) {
			$storageSasParams = @{
				Context    = $storageContext
				ExpiryTime = (Get-Date).AddSeconds($SasTokenDuration)
				FullUri    = $true
				Name       = 'vhds'
				Permission = 'rw'
			}
			$targetContainer = New-AzStorageContainerSASToken @storageSasParams
			$azCopyArgs = @('copy', $AccessSAS, $targetContainer)
			Start-Process -FilePath $AzCopyPath -ArgumentList $azCopyArgs -Wait
		} else {
			$blobCopyParams = @{
				AbsoluteUri   = $AccessSAS
				DestContainer = 'vhds'
				DestContext   = $storageContext
				DestBlob      = $DestinationBlob
			}
			Start-AzStorageBlobCopy @blobCopyParams | Out-Null
			do {
				Start-Sleep -Seconds 30
				$copyState = Get-AzStorageBlobCopyState -Blob $blobCopyParams.DestBlob -Container 'vhds' -Context $storageContext
				$progress = [Math]::Round((($copyState.BytesCopied / $copyState.TotalBytes) * 100))
				Write-Host ('WAITING: {0:HH:mm:ss} - Waiting for the {1} blob copy process to complete ({2} %)' -f (Get-Date), $DestinationBlob, $progress) -ForegroundColor Yellow
			} until ($copyState.Status -ne [Microsoft.Azure.Storage.Blob.CopyStatus]::Pending)
		}
	}

	Copy-ManagedDiskToTargetContainer -storageContext $storageContext -AccessSAS $osDiskSAS.AccessSAS -DestinationBlob ('{0}_OsDisk.vhd' -f $VM.Name)
	$dataDisksSAS.GetEnumerator() | ForEach-Object {
		Copy-ManagedDiskToTargetContainer -storageContext $storageContext -AccessSAS $_.Value.AccessSAS -DestinationBlob ('{0}.vhd' -f $_.Key)
	}
	#endregion

	#region Get the storage properties for the new managed disks
	$disksDetails = @{ }
	$oldOsDisk = Get-AzResource -ResourceId ($VM.StorageProfile.OsDisk.ManagedDisk.Id)
	$disksDetails.Add(($oldOsDisk.Name),
		[PSCustomObject]@{
			SkuName = $oldOsDisk.Sku.Name
			Caching = $VM.StorageProfile.OsDisk.Caching
		}
	)
	foreach ($dataDisk in $sourceDataDisks) {
		$oldDisk = Get-AzResource -ResourceId ($dataDisk.ManagedDisk.Id)
		$disksDetails.Add(($dataDisk.Name),
			[PSCustomObject]@{
				SkuName = $oldDisk.Sku.Name
				Caching = $dataDisk.Caching
				Lun     = $dataDisk.Lun
			}
		)
	}
	#endregion

	#region Create the new managed disks
	Write-Verbose -Message ('{0:HH:mm:ss} - Creating the new OS managed disk from the vhd' -f (Get-Date))
	$newDiskConfigParams = @{
		CreateOption     = 'Import'
		StorageAccountId = $targetStorage.Id
		SkuName          = ($disksDetails[($oldOsDisk.Name)]).SkuName
		OsType           = $VM.StorageProfile.OsDisk.OsType
		Location         = $TargetLocation
		SourceUri        = 'https://{0}.blob.core.windows.net/vhds/{1}_OsDisk.vhd' -f $targetStorage.StorageAccountName, $VM.Name
	}; $newOsDiskConfig = New-AzDiskConfig @newDiskConfigParams

	$newDiskParams = @{
		Disk              = $newOsDiskConfig
		ResourceGroupName = $TargetResourceGroup
		DiskName          = $oldOsDisk.Name
	}; $newOsDisk = New-AzDisk @newDiskParams

	Write-Verbose -Message ('{0:HH:mm:ss} - Creating the new data managed disks from the vhds' -f (Get-Date))
	$newDataDisks = @()
	foreach ($dataDisk in $sourceDataDisks) {
		Write-Verbose -Message ('{0:HH:mm:ss} - Generating data managed disk: {1}' -f (Get-Date), $dataDisk.Name)
		$newDiskConfigParams = @{
			CreateOption     = 'Import'
			StorageAccountId = $targetStorage.Id
			SkuName          = ($disksDetails[($dataDisk.Name)]).SkuName
			Location         = $TargetLocation
			SourceUri        = 'https://{0}.blob.core.windows.net/vhds/{1}.vhd' -f $targetStorage.StorageAccountName, $dataDisk.Name
		}; $newDataDiskConfig = New-AzDiskConfig @newDiskConfigParams
		$newDiskParams = @{
			Disk              = $newDataDiskConfig
			ResourceGroupName = $TargetResourceGroup
			DiskName          = $dataDisk.Name
		}; $newDataDisks += New-AzDisk @newDiskParams
	}
	#endregion

	#region VM config: Storage and License
	Write-Verbose -Message ('{0:HH:mm:ss} - Creating the new basic VM config' -f (Get-Date))
	$vmConfigParams = @{
		VMName      = $VM.Name
		VMSize      = $VM.HardwareProfile.VmSize
		Tags        = $VM.Tags
	}
	if($VM.LicenseType) { $vmConfigParams.Add('LicenseType', $VM.LicenseType) }
	$newVmConfig = New-AzVMConfig @vmConfigParams

	Write-Verbose -Message ('{0:HH:mm:ss} - Updating the VM config with the storage details' -f (Get-Date))
	$newVmConfig.FullyQualifiedDomainName = $VM.FullyQualifiedDomainName
	$newVmConfig.Location = $TargetLocation
	$azVMOSDiskParams = @{
		VM                 = $newVmConfig
		ManagedDiskId      = $newOsDisk.Id
		CreateOption       = 'Attach'
		Caching            = ($disksDetails[($oldOsDisk.Name)]).Caching
		StorageAccountType = ($disksDetails[($oldOsDisk.Name)]).SkuName
	}
	if ($VM.StorageProfile.OsDisk.OsType -eq 'Windows') { $azVMOSDiskParams.Add('Windows', $true) }
	else { $azVMOSDiskParams.Add('Linux', $true) }
	$newVmConfig = Set-AzVMOSDisk @azVMOSDiskParams

	for ($i = 0; $i -lt $newDataDisks.Count; $i++) {
		$newDataDiskAttachConfig = @{
			CreateOption       = 'Attach'
			Name               = $newDataDisks[$i].Name
			ManagedDiskId      = $newDataDisks[$i].Id
			Lun                = ($disksDetails[($newDataDisks[$i].Name)]).Lun
			Caching            = ($disksDetails[($newDataDisks[$i].Name)]).Caching
			StorageAccountType = ($disksDetails[($newDataDisks[$i].Name)]).SkuName
		}
		$newVmConfig = Add-AzVMDataDisk -VM $newVmConfig @newDataDiskAttachConfig
	}
	#endregion

	#region VM config: Networking
	Write-Verbose -Message ('{0:HH:mm:ss} - Verifying network configuration' -f (Get-Date))
	$targetSubnetName = $nic.IpConfigurations[0].Subnet.Id -replace '.*\/(\w+)$', '$1'
	if (-not $targetVnet) {
		$newSubnets = $vnet.Subnets | ForEach-Object {
			$newSubnetParams = @{
				Name          = $_.Name
				AddressPrefix = $_.AddressPrefix
			}
			if ($_.NetworkSecurityGroup) {
				$newNsgParams = @{
					Name              = $_.NetworkSecurityGroup.Name
					ResourceGroupName = $TargetResourceGroup
					Location          = $TargetLocation
					SecurityRules     = $_.NetworkSecurityGroup.SecurityRules
					Tag               = $_.NetworkSecurityGroup.Tag
				}
				$newNSG = New-AzNetworkSecurityGroup @newNsgParams
				$newSubnetParams.Add('NetworkSecurityGroup', $newNSG)
			}
			New-AzVirtualNetworkSubnetConfig @newSubnetParams
		}

		$newVnetParams = @{
			Name              = $vnetName
			ResourceGroupName = $TargetResourceGroup
			Location          = $TargetLocation
			AddressPrefix     = $vnet.AddressSpace.AddressPrefixes
			Subnet            = $newSubnets
			Tag               = $vnet.Tag
		}
		if ($vnet.DhcpOptions) { $newVnetParams.Add('DnsServer', $vnet.DhcpOptions.DnsServers) }
		if ($vnet.EnableDdosProtection) {
			$newVnetParams.Add('EnableDdosProtection', $vnet.EnableDdosProtection)
			$newVnetParams.Add('DdosProtectionPlanId', $vnet.DdosProtectionPlan)
		}
		$newVnet = New-AzVirtualNetwork @newVnetParams
		$targetSubnetId = $newVnet.Subnets | Where-Object { $_.Name -eq $targetSubnetName } | Select-Object -ExpandProperty Id
	} else {
		$targetSubnetId = $targetVnet.Subnets | Where-Object { $_.Name -eq $targetSubnetName } | Select-Object -ExpandProperty Id
	}

	$newNicParams = @{
		Name              = $nic.Name
		ResourceGroupName = $TargetResourceGroup
		Location          = $TargetLocation
		SubnetId          = $targetSubnetId
	}
	$newNic = New-AzNetworkInterface @newNicParams

	if ($nsg) {
		$newNsgParams = @{
			Name              = $nsg.Name
			ResourceGroupName = $TargetResourceGroup
			Location          = $TargetLocation
			SecurityRules     = $nsg.SecurityRules
			Tag               = $nsg.Tag
		}
		$newNSG = New-AzNetworkSecurityGroup @newNsgParams
		$newNic.NetworkSecurityGroup = $newNSG
		$newNic = $newNic | Set-AzNetworkInterface
	}

	if ($pubIp) {
		Write-Verbose -Message ('{0:HH:mm:ss} - Creating the new public IP' -f (Get-Date))
		$newPubIpParams = @{
			Name                 = $pubIp.Name
			ResourceGroupName    = $TargetResourceGroup
			Location             = $TargetLocation
			AllocationMethod     = $pubIp.PublicIpAllocationMethod
			#DomainNameLabel      = $pubIp.DnsSettings.DomainNameLabel
			Sku                  = $pubIp.Sku.Name
			IdleTimeoutInMinutes = $pubIp.IdleTimeoutInMinutes
			IpAddressVersion     = $pubIp.PublicIpAddressVersion
			Tag                  = $pubIp.Tag
		}
		$newPubIp = New-AzPublicIpAddress @newPubIpParams
		$newIpConfig = ($pubIp.IpConfiguration.Id -split '/')[-1]
		do { Start-Sleep -Seconds 2 } while ((-not (Get-AzPublicIpAddress | Where-Object { $_.Id -eq $newPubIp.Id })))
		$newNic = $newNic | Set-AzNetworkInterfaceIpConfig -Name $newIpConfig -PublicIpAddress $newPubIp | Set-AzNetworkInterface
	}

	Write-Verbose -Message ('{0:HH:mm:ss} - Updating the VM config with the network details' -f (Get-Date))
	$newVmConfig = $newVmConfig | Add-AzVMNetworkInterface -Id $newNic.Id
	#endregion

	#region VM config: Diagnostics
	if ($VM.DiagnosticsProfile.BootDiagnostics.Enabled) {
		Write-Verbose -Message ('{0:HH:mm:ss} - Using the temp storage account for boot diagnostics' -f (Get-Date))
		$newVmConfig.DiagnosticsProfile = $VM.DiagnosticsProfile
		$newVmConfig.DiagnosticsProfile.BootDiagnostics.StorageUri = $storageContext.BlobEndPoint
	}
	#endregion

	#region Create the new VM
	Write-Verbose -Message ('{0:HH:mm:ss} - Creating the VM' -f (Get-Date))
	$newVmConfig | New-AzVM -Location $TargetLocation -ResourceGroupName $TargetResourceGroup
	#endregion

	#region Cleanup
	if ($newVmConfig.DiagnosticsProfile.BootDiagnostics.Enabled) {
		Write-Verbose -Message ('{0:HH:mm:ss} - Cleanning up the vhds container from the temp storage account' -f (Get-Date))
		Remove-AzStorageContainer -Name vhds -Context $storageContext -Force
	} else {
		Write-Verbose -Message ('{0:HH:mm:ss} - Removing the temp storage account' -f (Get-Date))
		Remove-AzStorageAccount -Name $storageContext.StorageAccountName -ResourceGroupName $TargetResourceGroup
	}
	#endregion

	#region Final messages
	if ($pubIp) {
		Write-Host ("IMPORTANT: The VM's OLD public IP was: {0}" -f $pubIp.IpAddress) -ForegroundColor DarkMagenta
		if ($pubIp.DnsSettings.Fqdn) {
			Write-Host ('IMPORTANT: The VM had an FQDN: {0}' -f $pubIp.DnsSettings.Fqdn) -ForegroundColor DarkMagenta
		}
	}
	if ($newPubIp) {
		Write-Host ("IMPORTANT: The VM's NEW IP Address is: {0}" -f $newPubIp.IpAddress) -ForegroundColor DarkMagenta
	}
	#endregion

}

<# Usage example:

	Login-AzAccount
	$vm = Get-AzVM -ResourceGroupName 'rg-old-home' -Name 'vm-test'
	$vm | .\Move-AzVmToRegion.ps1 -Location 'West Europe' -ResourceGroup 'rg-new-home' -Verbose

#>