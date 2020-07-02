PARAM(
	[Parameter(Mandatory)] [Alias('Group', 'g')] $ResourceGroup,
	[Parameter(Mandatory)] [Alias('Name', 'n')] $VmName
)

# Get the original VM configuration
$vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $VmName

# Configure the new spot VM
$params = @{
	VMName   = $vm.Name
	VMSize   = $vm.HardwareProfile.VmSize
	Priority = 'Spot'
	MaxPrice = -1
}
$newVM = New-AzVMConfig @params

# Confgure the OS Disk
$params = @{
	VM            = $newVM
	CreateOption  = 'Attach'
	Name          = $vm.StorageProfile.OsDisk.Name
	ManagedDiskId = $vm.StorageProfile.OsDisk.ManagedDisk.Id
}
Set-AzVMOSDisk @params
$newVM.StorageProfile.OsDisk.OsType = 'Linux'
if ($vm.OSProfile.WindowsConfiguration) {
	$newVM.StorageProfile.OsDisk.OsType = 'Windows'
}

# Configure the Data Disks
foreach ($disk in $vm.StorageProfile.DataDisks) {
	$params = @{
		VM            = $newVM
		Name          = $disk.Name
		ManagedDiskId = $disk.ManagedDisk.Id
		Caching       = $disk.Caching
		Lun           = $disk.Lun
		DiskSizeInGB  = $disk.DiskSizeGB
		CreateOption  = 'Attach'
	}
	Add-AzVMDataDisk @params
}

# Configure the NICs
foreach ($nic in $vm.NetworkProfile.NetworkInterfaces) {
	$params = @{
		VM      = $newVM
		Id      = $nic.Id
		Primary = ($nic.Primary)
	}
	Add-AzVMNetworkInterface @params
}

# Remove the original VM
Remove-AzVM -ResourceGroupName $resourceGroup -Name $vmName

# Recreate the VM as spot
$params = @{
	VM                = $newVM
	ResourceGroupName = $ResourceGroup
	Location          = $vm.Location
}
New-AzVM @params
