<#

Script Name	: ShutdownVMsByMetricTag.ps1
Description	: Deallocate VMs by their CPU metrics and their tagged threshold
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/28
Keywords	: Azure, Automation, Runbook, Compute, VMs

#>

PARAM (
    [string] $ConnectionName = 'AzureRunAsConnection',
    [string] $MetricTagName = 'ShutdownByMetric',
    [boolean] $DeallocateVMs = $false
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))

try {

    # Authenticate to ARM
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    $null = Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    # Set the Resource Graph query
    $query = @'
resources
| where type == 'microsoft.compute/virtualmachines' and tags['{0}'] matches regex '.*'
| extend cpuThreshold = tags.{0} | project id, subscriptionId, resourceGroup, name, cpuThreshold
'@ -f $MetricTagName

    # Query Azure Resource Graph for all tagged VMs and their thresholds
    $VMs = Search-AzGraph -Query $query

    # Iterate the VMs collection and determine if they should be shutdown or not
    $report = foreach ($vm in $VMs) {

        # Set initial flag
        $isValid = $true
        $isBelowThreshold = $false
        $cpuThreshold = 'N/A'
        $cpuCurrent = 'N/A'

        # Get the VM's threshold from the tag value
        try {
            $cpuThreshold = [double]$vm.cpuThreshold
        } catch {
            $isValid = $false
        }

        # Get the VM's metrics
        try {
            $metrics = Get-AzMetric -ResourceId $vm.Id -MetricName 'Percentage CPU' -TimeGrain 00:01:00 -WarningAction SilentlyContinue -ErrorAction Stop
            $cpuCurrent = ($metrics.Data | Measure-Object -Maximum -Property Average -ErrorAction Stop).Maximum
            if (-not $cpuCurrent) { throw 'Cannot query metrics' }
        } catch {
            $isValid = $false
            $cpuCurrent = 'N/A'
        }

        # Determine if the max CPU usage was below the threshold
        if ($isValid) {
            $isBelowThreshold = $cpuCurrent -le $cpuThreshold
        } else {
            $isBelowThreshold = $false
        }

        # Create the report array
        $vm | Select-Object subscriptionId, resourceGroup, name, @{N = 'isValid'; E = { $isValid } },
        @{N = 'isBelowThreshold'; E = { $true -eq $isBelowThreshold } }, @{N = 'cpuThreshold'; E = { $cpuThreshold } }, @{N = 'cpuCurrent'; E = { $cpuCurrent } }
    }

    # Display report
    $report

    # Deallocate the relevant VMs
    if ($DeallocateVMs) {
        $vmsToDeallocate = @($report | Where-Object { $_.isBelowThreshold })
        Write-Output (("Deallocating {0} VM(s) with CPU usage below threshold") -f $vmsToDeallocate.Count)
        $vmsToDeallocate | ForEach-Object {
            Write-Output ("Stopping {0}\{1}" -f $_.ResourceGroup, $_.Name)
            Stop-AzVM -ResourceGroupName $_.ResourceGroup -Name $_.Name -Force -NoWait
        }
    } else {
        Write-Output ("{0} VM(s) have a CPU usage below the threshold and would have been shutdown" -f $vmsToDeallocate.Count)
    }

} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
