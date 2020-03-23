<#

Script Name	: Create-AzureEaSubscription.ps1
Description	: Create an Azure EA subscription (EA or Dev/Test)
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: Azure, EA, Subscription, Governance
Last Update	: 2020/03/23
Notes		:
	To create subscriptions under an enrollment account, users must have the RBAC Owner role on that account.
	You can grant a user or a group of users the RBAC Owner role on an enrollment account by running the following command:
	New-AzRoleAssignment -RoleDefinitionName Owner -ObjectId <userObjectId> -Scope /providers/Microsoft.Billing/enrollmentAccounts/<enrollmentAccountObjectId>
#>

PARAM(
    [ValidateSet('EA', 'DevTest')] $SubscriptionType = 'EA',
    $SubscriptionName = 'Azure Subscription',
    $OwnerObjectId = $null,
    $OwnerSignInName = $null
)


# Verify the module is installed:
if (-not (Get-Command -Name Get-AzEnrollmentAccount)) {
    Install-Module Az.Subscription -AllowPrerelease -Force -Verbose
}


# Set some internal variables:
$offerTypes = @{
    'EA'      = 'MS-AZR-0017P'
    'DevTest' = 'MS-AZR-0148P'
}


# Get the enrollment account details:
$ea = Get-AzEnrollmentAccount


# Create the new subscription:
$newSubscriptionParams = @{
    Name                      = $SubscriptionName
    OfferType                 = $offerTypes[$SubscriptionType]
    EnrollmentAccountObjectId = $ea.ObjectId
    OwnerObjectId             = @($ea.ObjectId)
}
if ($OwnerObjectId) { $newSubscriptionParams.OwnerObjectId += $OwnerObjectId }
if ($OwnerSignInName) { $newSubscriptionParams.Add('OwnerSignInName', $OwnerSignInName) }
New-AzSubscription @newSubscriptionParams
