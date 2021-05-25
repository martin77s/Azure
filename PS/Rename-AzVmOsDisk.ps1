<#

Script Name	: Rename-AzVmOsDisk.ps1
Description	: Rename (copy and swap) a VM's managed OS disk
Author		: Martin Schvartzman, Microsoft
Keywords	: Azure, VM, OS, ManagedDisk

#>

PARAM(
    $resourceGroup = 'dev-onls-svcvm-rg',
    $virtualMachineName = 'devonlssvcvm',
    $originalOsDiskName = 'devonlssvcvm_OsDisk_1_f0ba26810c1e452aa06ec272385eb58a',
    $newOsDiskName = 'devonlssvcvm_osDisk'
)

$virtualMachine = Get-AzVM -ResourceGroupName $resourceGroup -Name $virtualMachineName
Stop-AzVM -ResourceGroupName $resourceGroup -Name $virtualMachineName

$sourceDisk = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName $originalOsDiskName
$diskConfig = New-AzDiskConfig -SourceResourceId $sourceDisk.Id -Location $sourceDisk.Location -CreateOption Copy -DiskSizeGB 127 -SkuName 'Premium_LRS'
$newOsDisk = New-AzDisk -Disk $diskConfig -DiskName $newOsDiskName -ResourceGroupName $resourceGroup
#$newOsDisk = Get-AzDisk -ResourceGroupName $resourceGroup -Name $newOsDiskName

Set-AzVMOSDisk -VM $virtualMachine -ManagedDiskId $newOsDisk.Id -Name $newOsDisk.Name
Update-AzVM -ResourceGroupName $resourceGroup -VM $virtualMachine

Start-AzVM -ResourceGroupName $resourceGroup -Name $virtualMachineName

# Remove-AzDisk -ResourceGroupName $resourceGroup -DiskName $originalOsDiskName -Force
