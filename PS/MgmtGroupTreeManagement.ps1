Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))

try {

    $connectionName = 'AzureRunAsConnection'
    $automationAccountName = 'AAA-CloudAdmin'
    $resourceGroupName = 'cloudadmin-shared-resources'

    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    #$servicePrincipalConnection = Get-AzAutomationConnection -Name $connectionName `
    #    -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName
		
    $connection = Connect-AzureAD -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    $context = Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    $tenantId = $servicePrincipalConnection.TenantId
    Write-Output ('Working on tenant: {0}' -f $tenantId)

    $root = Get-AzManagementGroup -Expand -GroupName $tenantId
    $mgmtGroups = @(Get-AzManagementGroup -Expand -Recurse -GroupName (
        ($root.Children | Where-Object { $_.Type -eq '/providers/Microsoft.Management/managementGroups' }).Name
    )).Children
    Write-Output ('Found {0} management group(s)' -f $mgmtGroups.Count)

    $subs = @(Get-AzSubscription -TenantId $tenantId)
    Write-Output ('Found {0} subscription(s)' -f $subs.Count)

    $orphanSubscriptions = @($root.Children | Where-Object { $_.Type -eq '/subscriptions' })
    Write-Output ('Found {0} orphan subscription(s)' -f $orphanSubscriptions.Count)

    foreach($orphan in $orphanSubscriptions) {
        $targetManagementGroup = $mgmtGroups | Where-Object { $orphan.DisplayName -match ('^' + ($_.Name -replace '-mg')) }
        if($targetManagementGroup) {
            Write-Output ('Moving subscription [{0}] to group [{1}]' -f $orphan.DisplayName, $targetManagementGroup.DisplayName)
            New-AzManagementGroupSubscription -GroupName $targetManagementGroup.Id -SubscriptionId $orphan.Name
        } else {
            Write-Output ('Could not find a matching management group for subscription: {0}' -f $orphan.DisplayName)
        }
    }


    Write-Output ('Getting previous run subscriptions list')
    $previousSubscriptions = (Get-AzAutomationVariable -Name 'SubscriptionList' `
        -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName).Value

    $currentSubscriptions = $subs | Select-Object Name, Id
    if($null -eq $previousSubscriptions) {
        Write-Output ('Previous subscriptions list was empty!')
        $previousSubscriptions = $currentSubscriptions
    }

    Write-Output ('Comparing subscriptions list to current status')
    $missing = @($previousSubscriptions | Where-Object { $_.Id -notin ($currentSubscriptions).Id })
    if($missing.Count -gt 0) {
        # To do: Add logic to send email / create alert
        Write-Output ('Subscription(s) missing. Maybe deleted or moved to a different tenant')
        $missing | ForEach-Object { 
             Write-Output ('{0} = {1}' -f $_.Id, $_.Name)
        }
    }   

    Write-Output ('Updating the subscriptions list variable')
    $null = Set-AzAutomationVariable -Name 'SubscriptionList' -Encrypted $false -Value $currentSubscriptions `
        -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName

} catch {
    Write-Output ('Error: {0}' -f $_.Exception.Message)
}


Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
