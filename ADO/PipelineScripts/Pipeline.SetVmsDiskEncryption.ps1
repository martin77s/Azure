<#

Script Name	: Pipeline.SetVmsDiskEncryption.ps1
Description	: Creates the KeyVault (if doesn't already exist), creates the KEK (if doesn't already exist), Sets the VMDiskEncryptionExtension on the specified VMs
Keywords	: Azure, KeyVault, Encryption, Disk

#>

#Requires -PSEdition Core

param(
    [Parameter(Mandatory = $true)][string] $ResourceGroupName,
    [Parameter(Mandatory = $true)][string] $KeyVaultName,
    [Parameter(Mandatory = $true)][string] $servicePrincipalId,
    [Parameter(Mandatory = $true)][string] $VmResourceIds,
    [Parameter(Mandatory = $false)] [ValidateSet('All', 'OS')] [string] $VolumeType = 'All',
    [Parameter(Mandatory = $false)][string] $KekName = 'DiskEncryption20210428'
)


# Verify VMs list is not empty
if ([string]::IsNullOrEmpty($VmResourceIds)) {
    Write-Error 'VmResourceIds list is empty'
    $host.SetShouldExit(1)
} else {
    $vmsCollection = @($VmResourceIds -replace '\[|\]|"|\s' -split ',')
}


# Verify ResourceGroup
$ResourceGroup = Get-AzResourceGroup -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $ResourceGroup) {
    Write-Error "ResourceGroup $ResourceGroupName not found"
    $host.SetShouldExit(1)
}


# Verify KeyVault exists (with EnabledForDiskEncryption and EnablePurgeProtection)
$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $keyVault) {
    $params = @{
        Name                      = $keyVaultName
        ResourceGroupName         = $ResourceGroupName
        Location                  = $ResourceGroup.Location
        EnabledForDiskEncryption  = $true
        EnablePurgeProtection     = $true
        SoftDeleteRetentionInDays = 90
    }
    $keyVault = New-AzKeyVault @params
} else {
    if (-not $keyVault.EnabledForDiskEncryption) {
        Set-AzKeyVaultAccessPolicy -ResourceGroupName $ResourceGroupName -VaultName $keyVaultName -EnabledForDiskEncryption
    }
    if (-not $keyVault.EnablePurgeProtection) {
        $keyVault = $keyVault | Update-AzKeyVault -EnablePurgeProtection
    }
}
try {
    $params = @{
        ResourceGroupName = $ResourceGroupName
        VaultName         = $keyVaultName
        ObjectId          = $servicePrincipalId
        PermissionsToKeys = 'All'
        ErrorAction       = 'Stop'
    }
    Set-AzKeyVaultAccessPolicy @params
} catch {
    Write-Host ("##[warning] $($_.Exception.Message): No action is needed.")
}


# Verify KEK
$KEK = Get-AzKeyVaultKey -VaultName $keyVaultName -Name $KekName -ErrorAction SilentlyContinue
if (-not $KEK) {
    $KEK = Add-AzKeyVaultKey -Name $KekName -VaultName $keyVaultName -Destination 'Software'
}


# Create a new sequenceVersion for newly added data disk(s)
$sequenceVersion = [Guid]::NewGuid().Guid


# Verify Disk Encryption
$vmsCollection | Where-Object { $_ -and ($_.Trim() -ne '') } | ForEach-Object {
    $vmResourceGroup, $vmName = ($_ -split '/')[4, 8]
    Write-Output "Verifying VMDiskEncryption for $vmName"
    $encryptionStatus = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vmResourceGroup -VMName $vmName
    Write-Output $encryptionStatus
    if ($encryptionStatus.OsVolumeEncrypted -eq 'NotEncrypted' -or $encryptionStatus.DataVolumesEncrypted -eq 'NotEncrypted') {
        $params = @{
            VMName                    = $vmName
            ResourceGroupName         = $vmResourceGroup
            DiskEncryptionKeyVaultUrl = $KeyVault.VaultUri
            DiskEncryptionKeyVaultId  = $KeyVault.ResourceId
            KeyEncryptionKeyVaultId   = $KeyVault.ResourceId
            KeyEncryptionKeyUrl       = $KEK.Id
            VolumeType                = $VolumeType
            SkipVmBackup              = $true
            SequenceVersion           = $sequenceVersion
            Force                     = $true
        }
        Set-AzVMDiskEncryptionExtension @params
    }
}