#region Create the extension properties in Azure AD

# Set the extension properties names
$propertyNames = 'unitId', 'roleId'

# Creating extension properties requires creating an application and a service principal:
$app = New-AzureADApplication -DisplayName 'Extension Properties Bag' -IdentifierUris ('https://{0:yyyyMMddHHmm}' -f (Get-Date))
$spn = New-AzureADServicePrincipal -AppId (Get-AzureADApplication -SearchString 'Extension Properties Bag').AppId

# Create the extension properties
$props = $propertyNames | ForEach-Object {
    New-AzureADApplicationExtensionProperty -ObjectId $app.ObjectId -Name $_ -DataType String -TargetObjects User
}

#endregion



#region Adding extension properties to the same property bag

# Additional extension properties names
$propertyNames = 'divisionId'

# Add the extension properties to the same application
$app = Get-AzureADApplication -SearchString 'Extension Properties Bag'
$props = $propertyNames | ForEach-Object {
    New-AzureADApplicationExtensionProperty -ObjectId $app.ObjectId -Name $_ -DataType String -TargetObjects User
}

#endregion



#region Create a new user with values in the extension properties

# Get the extension properties' names
$bag = Get-AzureADApplicationExtensionProperty -ObjectId (Get-AzureADApplication -SearchString 'Extension Properties Bag').ObjectId
$unitId = $bag | Where-Object { $_.Name -match '_unitId' } | Select-Object -ExpandProperty Name
$roleId = $bag | Where-Object { $_.Name -match '_roleId' } | Select-Object -ExpandProperty Name

# Set values in the extension properties collection
$extProps = New-Object 'System.Collections.Generic.Dictionary``2[System.String,System.String]'
$extProps.Add($unitId, '820')
$extProps.Add($roleId, 'P105')

# Create the new user
$newUserParams = @{
    DisplayName       = 'myUser'
    UserPrincipalName = 'myUser@contoso.com'
    MailNickName      = 'myUser'
    AccountEnabled    = $true
    ExtensionProperty = $extProps
    PasswordProfile   = [Microsoft.Open.AzureAD.Model.PasswordProfile]::new('P@55w0rd!', $true, $true)
}
New-AzureADUser @newUserParams

#endregion



#region Update an existing user

# Get the extension properties' names
$bag = Get-AzureADApplicationExtensionProperty -ObjectId (Get-AzureADApplication -SearchString 'Extension Properties Bag').ObjectId
$unitId = $bag | Where-Object { $_.Name -match '_unitId' } | Select-Object -ExpandProperty Name
$divisionId = $bag | Where-Object { $_.Name -match '_divisionId' } | Select-Object -ExpandProperty Name

# Set values in the extension properties collection
$extProps = New-Object 'System.Collections.Generic.Dictionary``2[System.String,System.String]'
$extProps.Add($unitId, '920')
$extProps.Add($divisionId, '9090')

# Update the user

$setUserParams = @{
    ObjectId          = 'myUser@contoso.com'
    ExtensionProperty = $extProps
}
Set-AzureADUser @setUserParams

#endregion



#region Show the user's extension properties

Get-AzureADUser -ObjectId 'myUser@contoso.com' | Select-Object -ExpandProperty ExtensionProperty

#endregion



#region Get all users with a specific value in an extension property

$filter = @{unitId = 920 }

Get-AzureADUser -All $true | ForEach-Object {
    $key = $_.ExtensionProperty.Keys -like "*$($filter.Keys)"
    if ($key -and $_.ExtensionProperty[$key] -eq $filter.Values) { $_ }
}


#endregion
