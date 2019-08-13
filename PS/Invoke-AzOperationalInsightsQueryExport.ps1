<#PSScriptInfo

.VERSION 1.2

.GUID 89b5e4a0-3220-42c9-9cf3-324254283d16

.AUTHOR jbritt@microsoft.com

.COMPANYNAME Microsoft

.COPYRIGHT Microsoft

.TAGS 

.LICENSEURI 

.PROJECTURI 
https://github.com/Azure/azure-policy/tree/master/samples/Monitoring

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
August 06, 2019 1.2
    Initial
#>

<#  
.SYNOPSIS  
  A script to programatically export raw data from Log Analytics to an export file
  
  Note  This script currently leverages the Az cmdlets
  
.DESCRIPTION  
  This script takes a SubscriptionID, ResourceGroup (of the log analytics workspace), workspaceName as parameters, ExportDirectory, Interval for Timespan, and 
  either a SavedSearchID or a Query and provides the option to export raw data from the target Log Analytics workspace to an export file.  All parameters are optional
  and if not provided, will automatically build logic for you given answers to menu items.

.PARAMETER SubscriptionId
    The subscriptionID of the Azure Subscription where you Log Analytics workspaces are that you want to choose from

.PARAMETER WorkspaceName
    The log Analytics Workspace Name
    
.PARAMETER ResourceGroup
    The log Analytics Resource Group Name

.PARAMETER Interval
    The number of minutes you want to query for related to timespan (Default is 60 mins)

.PARAMETER ExportDirectory
    Directory to export your log data to (default is current working directory of script where an export folder will be created)

.PARAMETER SavedSearchID
    A saved search ID from Log Analytics that you can use to run a saved query (pulls the query details from the SavedSearchID)

.PARAMETER Query
    Allows you to provide an adhoc query on the command line and bypass SavedSearchId option

.EXAMPLE
  .\Invoke-AzOperationalInsightsQueryExport.ps1 -ResourceGroup "MyLAWorkspaceRG" -WorkspaceName "myLAWorkspace" -subscriptionId "0869826f-9de3-4363-bb31-ddb6a0a1471a"
  Will use resource group and workspace name as your target workspace within specified subscription and will prompt for other details.
  
.EXAMPLE
  .\Invoke-AzOperationalInsightsQueryExport.ps1 -ExportDirectory "<.\exportDirectory>"
  Will export log to export directory specific.  Will prompt for subscriptionID, SavedSearchID to use, as well as Log Analytics workspace to leverage for log export

.EXAMPLE
  .\Invoke-AzOperationalInsightsQueryExport.ps1
  Will prompt for subscriptionId, Workspace to use, SavedSearchId to use and will export to the "export" folder within the working directory of the script

.EXAMPLE
  .\Invoke-AzOperationalInsightsQueryExport.ps1 -ExportDirectory ".\ExportDirectory" -subscriptionId "0869826f-9de3-4363-bb31-ddb6a0a1471a" -query "Heartbeat | summarize dcount(ComputerIP) by bin(TimeGenerated, 1h)"
  Will leverage the specified export directory (relative to current working directory of PS console or specify fully qualified directory) and will leverage the query specified. 
  It will prompt for a Log Analytics workspace to use within the subscription specified by subscriptionId.

.EXAMPLE
  .\Invoke-AzOperationalInsightsQueryExport.ps1 -subscriptionId "0869826f-9de3-4363-bb31-ddb6a0a1471a" -query "Heartbeat | summarize dcount(ComputerIP) by bin(TimeGenerated, 1h) | render timechart" -interval 480
  Will leverage the .\export directory (relative to current working directory PS script) and will leverage the query specified. 
  It will prompt for a Log Analytics workspace to use within the subscription specified by subscriptionId.   It will override the default of 60 mins for interval to scan and query across 8 hours (480 mins)

.NOTES
   AUTHOR: Jim Britt Senior Program Manager - Azure CXP API
   LASTEDIT: August 06, 2019
   Initial

.LINK
    This script posted to and discussed at the following locations:PowerShell Gallery    	
    https://aka.ms/ExportAzLALogs
#>
[cmdletbinding(
    DefaultParameterSetName='Default'
)]
param
(
    # SubscriptionId of where your Log Analytics Workspace is to get saved SearchID or leveraging query param (optional)
    [Parameter(ParameterSetName='Default')]
    [Parameter(ParameterSetName='SavedSearch')]
    [Parameter(ParameterSetName='Query')]
    [guid]$SubscriptionID,

    # Resource Group name for Log Analytics workspace (used with workspacename parameter)
    [Parameter(ParameterSetName='Default')]
    [Parameter(ParameterSetName='SavedSearch')]
    [Parameter(ParameterSetName='Query')]
    [string]$ResourceGroup,
    
    # Workspace Name (optional)
    [Parameter(ParameterSetName='Default')]
    [Parameter(ParameterSetName='SavedSearch')]
    [Parameter(ParameterSetName='Query')]
    [string]$WorkspaceName,
    
    # Log Analytics SavedSearchID (use ad hoc query if preferred)
    [Parameter(ParameterSetName='SavedSearch')]
    [string]$SavedSearchID,
    
    # Ad hoc query in lieu of SavedSearchID
    [Parameter(ParameterSetName='Query')]
    [string]$Query,

    # Base folder for export
    [Parameter(ParameterSetName='Default')]
    [Parameter(ParameterSetName='SavedSearch')]
    [Parameter(ParameterSetName='Query')]
    [string]$ExportDirectory,

    [Parameter(ParameterSetName='Default')]
    [Parameter(ParameterSetName='SavedSearch')]
    [Parameter(ParameterSetName='Query')]
    [int]$Interval
)


# Function used to build numbers in selection tables for menus
function Add-IndexNumberToArray (
    [Parameter(Mandatory=$True)]
    [array]$array
    )
{
    for($i=0; $i -lt $array.Count; $i++) 
    { 
        Add-Member -InputObject $array[$i] -Name "#" -Value ($i+1) -MemberType NoteProperty 
    }
    $array
}

<# MAIN SCRIPT #>
# If Interval is not specified - default is 60 mins
If(!($Interval))
{
    $Timespan = New-TimeSpan -Minutes 60
}
else
{
    $Timespan = New-TimeSpan -Minutes $Interval
}

$error.clear()
# Find out where we are running
if ($null -ne $MyInvocation.MyCommand.Path)
{
    $CurrentDir = Split-Path $MyInvocation.MyCommand.Path
}
else
{
    # Sometimes $myinvocation is null, it depends on the PS console host
    $CurrentDir = "."
}
if (!($ExportDirectory))
{
    $ExportDirectory = "$($CurrentDir)\Export"
}
else
{
    $ExportDirectory = $ExportDirectory
}
if(!(Test-path $ExportDirectory))
{ 
    $NULL = new-item -ItemType Directory -Path $ExportDirectory
}

# Login to Azure - if already logged in, use existing credentials.
Write-Host "Authenticating to Azure..." -ForegroundColor Cyan
try
{
    $AzureLogin = Get-AzSubscription
}
catch
{
    $null = Login-AzAccount
    $AzureLogin = Get-AzSubscription
}

# Authenticate to Azure if not already authenticated 
# Ensure this is the subscription where your Management Groups are that house Blueprints for import/export operations
If($AzureLogin -and !($SubscriptionID))
{
    [array]$SubscriptionArray = Add-IndexNumberToArray (Get-AzSubscription) 
    [int]$SelectedSub = 0

    # use the current subscription if there is only one subscription available
    if ($SubscriptionArray.Count -eq 1) 
    {
        $SelectedSub = 1
    }
    # Get SubscriptionID if one isn't provided
    while($SelectedSub -gt $SubscriptionArray.Count -or $SelectedSub -lt 1)
    {
        Write-host "Please select a subscription from the list below for the " -NoNewline
        write-host $Mode -ForegroundColor Yellow -NoNewline
        write-host " Operation"
        $SubscriptionArray | Select-Object "#", Name, ID | Format-Table
        try
        {
            $SelectedSub = Read-Host "Please enter a selection from 1 to $($SubscriptionArray.count) for the $Mode Operation"
        }
        catch
        {
            Write-Warning -Message 'Invalid option, please try again.'
        }
    }
    if($($SubscriptionArray[$SelectedSub - 1].Name))
    {
        $SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].Name)
    }
    elseif($($SubscriptionArray[$SelectedSub - 1].SubscriptionName))
    {
        $SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].SubscriptionName)
    }
    write-verbose "You Selected Azure Subscription: $SubscriptionName"
    
    if($($SubscriptionArray[$SelectedSub - 1].SubscriptionID))
    {
        [guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].SubscriptionID)
    }
    if($($SubscriptionArray[$SelectedSub - 1].ID))
    {
        [guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].ID)
    }
    $SubscriptionID = $SubscriptionID.Guid
}
Write-Host "Selecting Azure Subscription: $($SubscriptionID) ..." -ForegroundColor Cyan
$Null = Select-AzSubscription -SubscriptionId $SubscriptionID

# Use workspacename and resourcegroup if that is provided as parameters and validate it is a workspace that can be accessed
if(($WorkspaceName) -and ($ResourceGroup))
{
    try {
        Write-Host "You Selected Workspace: " -nonewline -ForegroundColor Cyan
        Write-Host $WorkspaceName -ForegroundColor Yellow
        $Workspace = Get-AzOperationalInsightsWorkspace -Name $WorkspaceName -ResourceGroupName $ResourceGroup
    }
    catch {
        Write-Warning -Message 'No Workspace found'
    }
}
# Build a list of workspaces to choose from.  If workspace is in another subscription
# provide the resourceID of that workspace as a parameter
if(!($WorkspaceName))
{
    [array]$Workspaces=@()
    try
    {
        $Workspaces = Add-IndexNumberToArray (Get-AzOperationalInsightsWorkspace) 
        Write-Host "Generating a list of workspaces from Azure Subscription Selected..." -ForegroundColor Cyan

        [int]$SelectedWS = 0
        if ($Workspaces.Count -eq 1)
        {
            $SelectedWS = 1
        }

        # Get WS Resource ID if one isn't provided
        while($SelectedWS -gt $Workspaces.Count -or $SelectedWS -lt 1 -and $Null -ne $Workspaces)
        {
            Write-Host "Please select a workspace from the list below"
            $Workspaces| Select-Object "#", Name, Location, ResourceGroupName, ResourceId | Format-Table
            if($Workspaces.count -ne 0)
            {

                try
                {
                    $SelectedWS = Read-Host "Please enter a selection from 1 to $($Workspaces.count)"
                }
                catch
                {
                    Write-Warning -Message 'Invalid option, please try again.'
                }
            }
        }
    }
    catch
    {
        Write-Warning -Message 'No Workspace found - try specifying workspacename, resourcegroup and subscriptionID parameters'
    }
    If($Workspaces)
    {
        Write-Host "You Selected Workspace: " -nonewline -ForegroundColor Cyan
        Write-Host "$($Workspaces[$SelectedWS - 1].Name)" -ForegroundColor Yellow
        $WorkspaceName = $($Workspaces[$SelectedWS - 1].Name)
        $ResourceGroup = $($Workspaces[$SelectedWS - 1].ResourceGroupName)

    }
    else
    {
        Throw "No OMS workspaces available in selected subscription $SubscriptionID"
    }
}

# Checking for SavedSearchID or presenting all saved searches
If(!($SavedSearchID)-and !($Query))
{
    [int]$SelectedID = 0

    $SavedSearchIDArray = Add-IndexNumberToArray ($(Get-AzOperationalInsightsSavedSearch -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName).Value)

    # Only one saved
   if ($SavedSearchIDArray.Count -eq 1) 
   {
       $SelectedID = 1
   }
   # Get SavedSearchID if one isn't provided
   while($SelectedID -gt $SavedSearchIDArray.Count -or $SelectedID -lt 1)
   {
       Write-host "Please select a Saved Search from the list below."
       $SavedSearchIDArray | Select-Object "#", @{Label = "DisplayName";Expression={$_.Properties.DisplayName}}|Format-Table
       try
       {
           $SelectedID = Read-Host "Please enter a selection from 1 to $($SavedSearchIDArray.count)"
       }
       catch
       {
           Write-Warning -Message 'Invalid option, please try again.'
       }
   }
   
   $SavedSearchID = $($SavedSEarchIDArray[$SelectedID - 1].ID.split("/")[9])
   Write-Host "Using SavedSearchID $($SavedSearchID)" -ForegroundColor Cyan
}

# Get the workspace object to query against
if(!($Workspace))
{
    $Workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName
}

if(!($Query))
{
    if($savedSearchIDArray)
    {
        $Query = $($SavedSearchIDArray[$SelectedID-1].Properties.query)
    }
    else
    {
        try 
        {
            $SavedSearch = Get-AzOperationalInsightsSavedSearch -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -SavedSearchId $SavedSearchID
            $Query = $($SavedSearch.Properties.Query) 
        }
        catch 
        {
            Write-Warning -Message 'SavedSearchID potentially Invalid.  Please try again or use "query" parameter.'
        }
    }
}

    
Write-host "Now querying for data to export for the last $($Timespan.TotalMinutes) minutes" -ForegroundColor Cyan

$Data = $(Invoke-AzOperationalInsightsQuery -Workspace $Workspace -Query $Query -Timespan ($Timespan)).Results
If($Data -ne "")
{
    $FileName = "$($ExportDirectory)\$(get-date -format filedatetime).txt"
    Write-Host "Now Exporting data to " -NoNewline 
    Write-Host $FileName -ForegroundColor Yellow
    $Data | Out-File $FileName
}
else {
    write-host "Query returned no data!"
}
remove-variable SubscriptionID
Write-host "Complete!"
