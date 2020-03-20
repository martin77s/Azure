# Install the Blueprints module:
Install-Module -Name Az.Blueprint -AllowClobber -Force -Verbose


# Set some variables:
$localPath = 'C:\Temp\Blueprints'
$subscriptionName = '<Subscription Name>'
$managementGroupName = '<Management Group Name>'
$subscriptionId = (Get-AzSubscription -SubscriptionName $subscriptionName).id
$managementGroupId = ((Get-AzManagementGroup -GroupName $managementGroupName).id -split '/')[4]


# Export Blueprints from a Management Group
Get-AzBlueprint -ManagementGroupId $managementGroupId | ForEach-Object {
    Export-AzBlueprintWithArtifact -Blueprint $_ -OutputPath $localPath -Force -Verbose
}


# Export Blueprints from a Subscription
Get-AzBlueprint -SubscriptionId $subscriptionId | ForEach-Object {
    Export-AzBlueprintWithArtifact -Blueprint $_ -OutputPath $localPath -Force -Verbose
}


# Import Blueprint to Management Group
Get-ChildItem -Path $localPath | ForEach-Object {
    Import-AzBlueprintWithArtifact -Name $_.Name -InputPath $_.FullName `
        -ManagementGroupId $managementGroupId -Force -Verbose
}


# Import Blueprint to Subscription
Get-ChildItem -Path $localPath | ForEach-Object {
    Import-AzBlueprintWithArtifact -Name $_.Name -InputPath $_.FullName `
        -SubscriptionId $subscriptionId -Force -Verbose
}