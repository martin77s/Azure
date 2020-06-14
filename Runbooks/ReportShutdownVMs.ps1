PARAM(
    [string] $ConnectionName = 'AzureRunAsConnection',
    [string] $SubscriptionNamePattern = '.*',
    [bool] $DeallocateShutdownVMs = $false
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))


try {

    Disable-AzContextAutosave –Scope Process | Out-Null

    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null

    $subscriptions = @(Get-AzSubscription | Where-Object { ($_.Name -match $SubscriptionNamePattern) -and ($_.State -eq 'Enabled') })

    $report = foreach ($subscription in $subscriptions) {

        Set-AzContext -SubscriptionId $subscription.Id -TenantId $servicePrincipalConnection.TenantId -Force | Out-Null
        $VMs = @(Get-AzVM -Status)

        if ($VMs.Count -gt 0) {
            foreach ($vm in $VMs) {
                if ($vm.PowerState -eq 'VM stopped') {
                    New-Object -TypeName PSObject -Property ([ordered]@{
                            SubscriptionId    = $subscription.Id
                            SubscriptionName  = $subscription.Name
                            ResourceGroupName = $vm.ResourceGroupName
                            Name              = $vm.Name
                        }
                    )
                    if($DeallocateShutdownVMs) {
                        Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force -NoWait | Out-Null
                    }
                }
            }
        }
    }
    $report

} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}