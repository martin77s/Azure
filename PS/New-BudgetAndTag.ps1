<#
.SYNOPSIS
    Create a budget for the subscription or resource group with an option to tag it also
.DESCRIPTION
    Running on an existing budget will update settings
.PARAMETER BudgetName
    Required. Name of the budget
.PARAMETER BudgetAmount
    Required. The finite amount for the budget
.PARAMETER BudgetEndDate
    Optional. Date to end the budget on - default is 10 years from current date
.PARAMETER BudgetStartDate = (Get-Date).ToString("yyyy-MM-01"),
    Optional. Date to start the budget on - Default is current month
.PARAMETER BudgetPeriod
    Optional. how often should the budget amount be renewd - default is Monthly
    Allowed values:
    - Monthly
    - Quarterly
    - Annually
    - BillingMonth
    - BillingQuarter
    - BillingAnnual
.PARAMETER SubscriptionId
    Required. Id of the subscription to set budget for, or for the resource group that we want to set budget for
.PARAMETER ResourceGroup
    Optional. Specific Resource group to set budget and/or tag on
.PARAMETER ThresholdPrecentage
    Optional. Array of precentages to alert on - up to 5 allowed - i.e @(50,100,120)
.PARAMETER AlertEmailTarget
    Optional. Array of email targets to be notified
.PARAMETER AlertRoleTarget
    Optional. Array of Roles to be notified
.PARAMETER TagName
    Optional. Name for a tag to set if ApplyTag is used on the target (resource group or subscription) - default is 'Budget'
.PARAMETER ApplyTag
    Optional. Use to applay a tag with the budget amount on the target (resource group or subscription)
.PARAMETER $ManagementGroupName
    Optional. Name of management group to set budget for, can't be used with tag
.EXAMPLE
    C:\PS> New-BudgetAndTag -BudgetName 1 -BudgetAmount 1 -SubscriptionId '0000-0000-0000-0000-0000-000' -AlertRoleTarget Owner -ApplyTag -ThresholdPrecentage @(60,75,70)
    Set a budget named '1' with the amount of 1 on a subscription. Also alert Owners above 60%,70% and 75%
.NOTES
    Author: Shachaf Goldstein (shgoldst@microsoft.com)
    Date:   March 24, 2020
#>
function New-BudgetAndTag
{
    [CmdletBinding(DefaultParameterSetName = "Subscription")]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The name for the budget")]
        [String]$BudgetName,
        [Parameter(Mandatory = $true, HelpMessage = "The amount of the budget")]
        [Float]$BudgetAmount,
        [Parameter(HelpMessage = "The end date for the budget")]
        [datetime]$BudgetEndDate = (Get-Date).AddYears(10).ToString("yyyy-MM-dd"),
        [Parameter(HelpMessage = "The start date for the budget")]
        [datetime]$BudgetStartDate = (Get-Date).ToString("yyyy-MM-01"),
        [Parameter(HelpMessage = "The period for the budget to renew")]
        [ValidateSet("Monthly","Quarterly","Annually","BillingMonth","BillingQuarter","BillingAnnual")]
        [String]$BudgetPeriod = "Monthly",
        [parameter(Mandatory = $true, HelpMessage = "The ID of the subscription to run on",ParameterSetName = "Subscription")]
        [String]$SubscriptionId,
        [Parameter(HelpMessage = "Resource group to filter the budget on",ParameterSetName = "Subscription")]
        [String]$ResourceGroup,
        [Parameter(HelpMessage = "Array of precentages to alert above")]
        [Int[]]$ThresholdPrecentage,
        [Parameter(HelpMessage = "Array of email targets to alert")]
        [String[]]$AlertEmailTarget,
        [Parameter(HelpMessage = "Array of role targets to alert",ParameterSetName = "Subscription")]
        [String[]]$AlertRoleTarget,
        [Parameter(HelpMessage = "The name of the tag to set",ParameterSetName = "Subscription")]
        [String]$TagName = "Budget",
        [Parameter(HelpMessage = "Add to apply the tag",ParameterSetName = "Subscription")]
        [switch]$ApplyTag,
        [Parameter(HelpMessage = "Management group name instead of subscription",ParameterSetName = "ManagementGroup")]
        [String]$ManagementGroupName
    )

    begin
    {
        $ErrorActionPreference = "stop"
        #$DebugPreference = ""
    }
    process
    {
        $BudgetScope = "subscriptions/$SubscriptionId"

        if($ManagementGroupName)
        {
            $BudgetScope = "providers/Microsoft.Management/managementGroups/$ManagementGroupName"
        }

        $budgetStructure = @{}
        $budgetStructure = [ordered]@{
            "id" = "$BudgetScope/providers/Microsoft.Consumption/budgets/$BudgetName"
            "name" = "$BudgetName"
            "type" = "Microsoft.Consumption/budgets"
            "properties" = @{}
        }

        $budgetStructure["properties"] = [ordered]@{
            "amount" = $BudgetAmount
            "category" = "Cost"
            "notifications" = @{}
            "timeGrain" = $BudgetPeriod
            "timePeriod" = @{
                "startDate" = $BudgetStartDate.ToString("yyyy-MM-01")
                "endDate" = $BudgetEndDate.ToString("yyyy-MM-dd")
            }
        }

        if($ResourceGroup)
        {
            $budgetStructure["properties"].add("resourceGroups", @($ResourceGroup))
        }

        $notificationHash  = @{}
        Foreach ($threshold in $ThresholdPrecentage) {
            $notificationHash = @{
                "Above$threshold" = [ordered]@{
                    "enabled" = $true
                    "operator" = "GreaterThan"
                    "threshold" = "$threshold"
                }
            } 

            if($AlertEmailTarget)
            {
                $notificationHash["Above$threshold"]["contactEmails"] = $AlertEmailTarget
            }

            if($AlertRoleTarget)
            {
                $notificationHash["Above$threshold"]["contactRoles"] = $AlertRoleTarget
            }

            $budgetStructure["properties"]["notifications"] += $notificationHash
        }

        $budgetStructure = ($budgetStructure | ConvertTo-Json -Compress -Depth 5).Replace('"','\"')

        if($DebugPreference -eq 'Inquire')
        {
            az rest --method put --uri "https://management.azure.com/$BudgetScope/providers/Microsoft.Consumption/budgets/$BudgetName`?api-version=2019-10-01" --debug --body $budgetStructure
        }
        else
        {
            az rest --method put --uri "https://management.azure.com/$BudgetScope/providers/Microsoft.Consumption/budgets/$BudgetName`?api-version=2019-10-01" --body $budgetStructure
        }

        if($ApplyTag)
        {
            if($ResourceGroup)
            {
                $BudgetScope += "/resourcegroups/myResourceGroup"
            }
            
            if($DebugPreference -eq 'Inquire')
            {
                az rest --method put --uri "https://management.azure.com/$BudgetScope/providers/Microsoft.Resources/tags/default?api-version=2019-10-01"  --debug --body ('{ \"properties\": { \"tags\": { \"{1}\": \"{0}\" } } }'.Replace('{0}',$BudgetAmount).Replace('{1}',$TagName))
            }
            else
            {
                az rest --method put --uri "https://management.azure.com/$BudgetScope/providers/Microsoft.Resources/tags/default?api-version=2019-10-01" --body ('{ \"properties\": { \"tags\": { \"{1}\": \"{0}\" } } }'.Replace('{0}',$BudgetAmount).Replace('{1}',$TagName))    
            }
        }
    }
}