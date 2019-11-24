$sub = (Get-AzSubscription | Out-GridView -Title 'Select Subscription' -OutputMode Single | Set-AzContext)
$role = Get-AzRoleDefinition 'Virtual Machine Operator'
$role.Id = $null
$role.Name = 'Virtual Machine Operator'
$role.Description = 'Can stop and start virtual machines'
$role.Actions.Clear()
$role.Actions.Add('Microsoft.Compute/*/Read')
$role.Actions.Add('Microsoft.Compute/VirtualMachines/restart/Action')
$role.Actions.Add('Microsoft.Compute/VirtualMachines/start/Action')
$role.Actions.Add('Microsoft.Compute/VirtualMachines/poweroff/Action')
$role.Actions.Add('Microsoft.Resources/subscriptions/resourceGroups/read')
$role.AssignableScopes.Clear()
$role.AssignableScopes.Add("/subscriptions/$($sub.Subscription.Id)")
New-AzRoleDefinition -Role $role