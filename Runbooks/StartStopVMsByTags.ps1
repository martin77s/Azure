Workflow StartStopVMsByTags {

    param (
        [string]$ConnectionName = 'AzureRunAsConnection'
        ,
        [string]$SubscriptionNamePattern = '^SUB_DEV-.*' # '^SUB_DEV-.*|^SUB_SANDBOX-.*'
        ,
        [boolean]$DryRun = $true
    )

    #region Login to Azure
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    $null = Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
    #endregion

    #region Get all VMs only from the relevant subscriptions
    $AzVms = @(Get-AzSubscription | Where-Object { $_.Name -match $SubscriptionNamePattern } | ForEach-Object {
            $SubscriptionName = $_.Name
            Write-Verbose ('Switching to subscription: {0}' -f $SubscriptionName) -Verbose
            $null = Set-AzContext -SubscriptionObject $_ -Force
            Get-AzVM -Status | Select-Object Name, ResourceGroupName, Tags, PowerState, @{N = 'SubscriptionName'; E = { $SubscriptionName } }
        })
    Write-Output ('Found {0} VMs to work on' -f $AzVms.Count)
    #endregion

    #region Create the UTC datetime object
    function Get-DateTimeInUTC {
        param([string]$Time)
        if ([datetime]$Time) {
            Get-Date -Date ('{0} {1}' -f [datetime]::UtcNow.ToShortDateString(), $Time)
        } else {
            throw
        }
    }
    #endregion

    foreach -parallel ($AzVm in $AzVms) {

        #region Initialize variables
        $AzVmNightShift = $false
        $AzVMCurrentTimeStamp = [datetime]::UtcNow
        $AzVmActionRequired = $null
        #endregion

        #region Normalize PowerOn/Off tag values
        try { $AzVmPowerOn = (Get-DateTimeInUTC -Time ($VM.Tags.PowerOn)) } catch { $AzVmPowerOn = $null }
        try { $AzVmPowerOff = (Get-DateTimeInUTC -Time ($VM.Tags.PowerOff)) } catch { $AzVmPowerOff = $null }
        #endregion

        #region Handle the "night shift" VMs
        if ($AzVmPowerOn -and $AzVmPowerOff -and ($AzVmPowerOff.Hour -lt $AzVmPowerOn.Hour)) {
            $AzVmPowerOff = $AzVmPowerOff.AddDays(1);
            $AzVmNightShift = $true
        }
        #endregion

        #region Check if the VM shoud be running or not (DesiredState)
        if ($AzVMPowerOn -and $AzVMPowerOff) {
            if ($AzVmPowerOn -lt $AzVmCurrentTimeStamp -and $AzVmCurrentTimeStamp -lt $AzVmPowerOff) {
                $AzVmDesiredState = 1
            } else {
                $AzVmDesiredState = 0
            }

        } elseif ($AzVmPowerOn) {
            if ($AzVmPowerOn -lt $AzVmCurrentTimeStamp) {
                $AzVmDesiredState = 1
            } else {
                $AzVmDesiredState = 0
            }

        } elseif ($AzVmPowerOff) {
            if ($AzVmPowerOff -lt $AzVmCurrentTimeStamp) {
                $AzVmDesiredState = 0
            } else {
                $AzVmDesiredState = 1
            }
        }
        #endregion

        #region Caculate start/stop required actions
        if (@('VM starting', 'VM deallocating') -contains $AzVm.PowerState) {
            $AzVmActionNote = ("Do nothing. The VM is in a transitioning state ({0})" -f $Az.VmPowerState)

        } elseif (($null -eq $AzVmPowerOn) -and ($null -eq $AzVmPowerOff)) {
            $AzVmActionNote = "Do nothing. The VM doesn't have any compliant value for the PowerOn/PowerOff tags"

        } elseif (($AzVm.PowerState -eq 'VM running') -and ($AzVmDesiredState -eq 0)) {
            $AzVmActionNote = "The VM will be stopped, because it's outside of it's running window"
            $AzVmActionRequired = 'Stop'

        } elseif (($AzVm.PowerState -eq 'VM deallocated') -and ($AzVmDesiredState -eq 1)) {
            $AzVmActionNote = "The VM will be started, because it's inside it's running window"
            $AzVmActionRequired = 'Start'

        } else {
            $AzVmActionNote = "VM should be left in it's current status"
        }
        #endregion

        #region Action accordingly
        switch -CaseSensitive ($AzVmActionRequired) {

            'Start' {
                $AzVmActionStatusCode = (
                    Start-AzVM -Name $AzVm.Name -ResourceGroupName $AzVm.ResourceGroupName -WhatIf:$DryRun).Status
            }

            'Stop' {
                $AzVmActionStatusCode = (
                    Stop-AzVM -Name $AzVm.Name -ResourceGroupName $AzVm.ResourceGroupName -Force -WhatIf:$DryRun).Status
            }
        }
        #endregion

        #region Output the full details object
        $output = New-Object -TypeName PSObject -Property @{
            Name              = $AzVm.Name
            ResourceGroupName = $AzVm.ResourceGroupName
            PowerState        = $AzVm.PowerState
            SubscriptionName  = $AzVm.SubscriptionName
            PowerOn           = $AzVmPowerOn
            PowerOff          = $AzVmPowerOff
            NightShift        = $AzVmNightShift
            DesiredState      = $AzVmDesiredState
            ActionRequired    = $AzVmActionRequired
            ActionNote        = $AzVmActionNote
            ActionStatusCode  = $AzVmActionStatusCode
            CurrentTimeStamp  = $AzVMCurrentTimeStamp
        }
        Write-Output -InputObject $output
        #endregion
    }
}
