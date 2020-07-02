PARAM(
    [string] $ConnectionName = 'AzureRunAsConnection',
    [bool] $DeallocateVMs = $false
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))


try {

    # Authenticate to ARM
    Disable-AzContextAutosave –Scope Process | Out-Null
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null


    # Set the Resource Graph query
    $query = @'
resources
| where type == 'microsoft.compute/virtualmachines' and tags['ShutdownByMetric'] matches regex '.*'
| extend cpuThreshold = tags.ShutdownByMetric | project id, subscriptionId, resourceGroup, name, cpuThreshold
'@

    # Query Azure Resource Graph for all tagged VMs and their thresholds
    $VMs = Search-AzGraph -Query $query

    $report = foreach ($vm in $VMs) {

        # Set initial flag
        $isValid = $true

        # Get the VM's threshold from the tag value
        try {
            $cpuThreshold = [double]$vm.cpuThreshold
        } catch {
            $cpuThreshold = 'N/A'
            $isValid = $false
        }

        # Get the VM's metrics
        $metrics = Get-AzMetric -ResourceId $vm.Id -MetricName 'Percentage CPU' -TimeGrain 00:01:00 -WarningAction SilentlyContinue
        $cpuCurrent = ($metrics.Data | Measure-Object -Maximum -Property Average).Maximum

        # Determine if the metrics where collected correctly
        if (-not $cpuCurrent) {
            $cpuCurrent = 'N/A'
            $isValid = $false
        }

        # Determine if the max CPU usage was below the threshold
        if ($isValid) {
            $isBelowThreshold = $cpuThreshold -gt $cpuCurrent
        } else {
            $isBelowThreshold = $false
        }

        # Create the report array
        $vm | Select-Object subscriptionId, resourceGroup, name, @{N = 'isValid'; E = { $isValid } },
        @{N = 'isBelowThreshold '; E = { $isBelowThreshold } }, @{N = 'cpuThreshold'; E = { $cpuThreshold } }, @{N = 'cpuCurrent'; E = { $cpuCurrent } }
    }

    # Deallocate the relevant VMs
    if ($DeallocateVMs) {
        $report | Where-Object { $_.isBelowThreshold } | For-Object {
            Stop-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Force -NoWait | Out-Null
        }
    }

    # Display report
    $report

} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}