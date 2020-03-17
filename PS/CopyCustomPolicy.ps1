# Set the subscription scope
$SubscriptionId = '<SubscriptionId>'

# Get the first custom policy
$policyDef = Get-AzPolicyDefinition -SubscriptionId $SubscriptionId -Custom | Select-Object -First 1

# Just display the json view
$policyDef.Properties | ConvertTo-Json

# Create a new policy based on it
$newPolicyParams = @{
    Name           = 'NewPolicy'
    DisplayName    = 'My new policy definition'
    SubscriptionId = $SubscriptionId
    Mode           = $policyDef.Properties.mode
    Metadata       = $policyDef.Properties.metadata | ConvertTo-Json
    Policy         = $policyDef.Properties.policyRule | ConvertTo-Json
    Parameter      = $policyDef.Properties.parameters | ConvertTo-Json
}
New-AzPolicyDefinition @newPolicyParams