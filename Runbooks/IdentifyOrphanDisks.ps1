PARAM(
    [string] $SubscriptionNamePattern = 'maschvar.*',
    [string] $ConnectionName = 'AzureRunAsConnection',
    [string] $SendToEmailAddress = $null
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))


try {

    # Login to Azure
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    $null = Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    $orphanDisks = @()

    # Iterate all subscriptions
    Get-AzSubscription | Where-Object { $_.Name -match $SubscriptionNamePattern } | ForEach-Object {

        Write-Verbose ('Switching to subscription: {0}' -f $_.Name) -Verbose
        $null = Set-AzContext -SubscriptionObject $_ -Force


        # Get orphan managed disks
        $managedDisks = Get-AzDisk
        $orphanDisks += foreach ($md in $managedDisks) {
            if (($md.ManagedBy -eq $null) -and ($md -notlike '*-ASRReplica')) {
                New-Object -TypeName PSObject -Property ([ordered]@{
                        DiskType = 'Managed'
                        Id       = $md.Id
                    }
                )
            }
        }

        # Get orphan unmanaged disks
        $storageAccounts = Get-AzStorageAccount
        $orphanDisks += foreach ($storageAccount in $storageAccounts) {
            $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName)[0].Value
            $context = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageKey
            $containers = Get-AzStorageContainer -Context $context
            foreach ($container in $containers) {
                $blobs = Get-AzStorageBlob -Container $container.Name -Context $context
                $blobs | Where-Object { $_.BlobType -eq 'PageBlob' -and $_.Name.EndsWith('.vhd') } | ForEach-Object {
                    if ($_.ICloudBlob.Properties.LeaseStatus -eq 'Unlocked') {
                        New-Object -TypeName PSObject -Property ([ordered]@{
                                DiskType = 'UnManaged'
                                Id       = $_.ICloudBlob.Uri.AbsoluteUri
                            }
                        )
                    }
                }
            }
        }
    }

    # Send report by email
    if ($orphanDisks.Count -gt 0 -and $SendToEmailAddress) {
        $body = ($orphanDisks | ConvertTo-Html -Fragment) -join ''
        .\Send-GridMailMessage.ps1 -Subject 'Orphan disks identified' -content $body -bodyAsHtml `
            -FromEmailAddress AzureAutomation@azure.com -destEmailAddress $SendToEmailAddress
    }

} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
