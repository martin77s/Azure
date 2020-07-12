# Get all Windows Servers not using AHBU:
function Get-AzVmNotAHuB {
    param($ResourceGroupName = '*')
    Get-AzVM -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue |
    Where-Object { $_.StorageProfile.OsDisk.OsType -eq 'Windows' -and @('Windows_Server', 'Windows_Client') -notcontains $_.LicenseType }
}


# Set all Windows Servers to use AHUB:
function Set-AzVmAHuB {
    param($ResourceGroupName = '*')
    Get-AzVM -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue |
    Where-Object { $_.StorageProfile.OsDisk.OsType -eq 'Windows' -and @('Windows_Server', 'Windows_Client') -notcontains $_.LicenseType } |
    ForEach-Object {
        $_.LicenseType = 'Windows_Server'
        $_ | Update-AzVM
    }
}