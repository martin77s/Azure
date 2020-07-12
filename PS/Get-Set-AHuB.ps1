# Get all Windows Servers not using AHBU:
function Get-AzVmNotAHuB {
    param($SubscriptionNamePattern = '.*', $ResourceGroupName = '*')

    Get-AzSubscription | Where-Object { ($_.Name -match $SubscriptionNamePattern) -and ($_.State -eq 'Enabled') } | ForEach-Object {
        Write-Verbose ('Switching to subscription: {0}' -f $_.Name) -Verbose
        $null = Set-AzContext -SubscriptionObject $_ -Force

        Get-AzVM -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue |
            Where-Object { $_.StorageProfile.OsDisk.OsType -eq 'Windows' -and @('Windows_Server', 'Windows_Client') -notcontains $_.LicenseType }
    }
}


# Set all Windows Servers to use AHUB:
function Set-AzVmAHuB {
    param($SubscriptionNamePattern = '.*', $ResourceGroupName = '*')

    Get-AzSubscription | Where-Object { ($_.Name -match $SubscriptionNamePattern) -and ($_.State -eq 'Enabled') } | ForEach-Object {
        Write-Verbose ('Switching to subscription: {0}' -f $_.Name) -Verbose
        $null = Set-AzContext -SubscriptionObject $_ -Force

        Get-AzVM -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue |
        Where-Object { $_.StorageProfile.OsDisk.OsType -eq 'Windows' -and @('Windows_Server', 'Windows_Client') -notcontains $_.LicenseType } |
        ForEach-Object {
            $_.LicenseType = 'Windows_Server'
            $_ | Update-AzVM
        }
    }
}