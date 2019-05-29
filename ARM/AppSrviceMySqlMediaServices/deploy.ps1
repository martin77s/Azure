
$ScriptParameters = @{
    SubscriptionName  = 'my subscription'
    UserPrincipalName = 'myUser@contoso.com'
    Region            = 'westeurope'
    ApplicationName   = 'myApp123'
    WebSiteName       = 'myApp123Site'
    MySqlServerAdmin  = 'myApp123DbAdmin' # Maximum length is 16
}

# Authenticate to Azure
Login-AzAccount

# Track the starting timestamp
$start = Get-Date

# Set the subscription context
Set-AzContext -Subscription $ScriptParameters.subscriptionName

# Get the current principals' object id, for access permissions to the KeyVault
$KeyVaultOwnerId = (Get-AzADUser -UserPrincipalName $ScriptParameters.userPrincipalName).Id

# Create the resource group
$ResourceGroupName = $ScriptParameters.ApplicationName + '-rg'
if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroupName -Location $ScriptParameters.Region
}

# Helper function to create a password for the mySql admin user
function New-Password {
    param([string]$Prefix = '', $Length = 24)
    $Suffix = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 |
            Sort-Object {Get-Random})[0..$Length] -join ''
    ($Prefix + $Suffix).Substring(0, $Length)
}

# Prepare the template parameters
$deploymentParams = @{
    TemplateFile             = '.\azuredeploy.json'
    ResourceGroupName        = $ResourceGroupName
    ApplicationName          = $ScriptParameters.ApplicationName
    WebSiteName              = $ScriptParameters.WebSiteName
    MySqlServerLoginUser     = $ScriptParameters.MySqlServerAdmin
    MySqlServerLoginPassword = (New-Password) | ConvertTo-SecureString -AsPlainText -Force
    KeyVaultOwnerId          = $KeyVaultOwnerId
    Force                    = $true
    Verbose                  = $true
}

# Deploy the template
New-AzResourceGroupDeployment @deploymentParams

# Calculate total runtime
"Complete deployment runtime: {0:N2} minutes" -f (((Get-Date) - $start).TotalMinutes)