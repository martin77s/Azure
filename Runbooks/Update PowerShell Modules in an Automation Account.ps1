<#
Copyright (c) Microsoft Corporation. All rights reserved.
Licensed under the MIT License.
Adaption of https://github.com/Microsoft/AzureAutomation-Account-Modules-Update
by Barbara Forbes, 4bes.nl
#>

<#
.SYNOPSIS
Update all PowerShell modules in an Azure Automation account.
.DESCRIPTION
This Azure Automation runbook updates all PowerShell modules imported into an
Azure Automation account with the module versions published to the PowerShell Gallery.
.PARAMETER ResourceGroupName
The Azure resource group name.
.PARAMETER AutomationAccountName
The Azure Automation account name.
.PARAMETER Az
(Boolean) Set to True to use the AZ-module instead of the AzureRM module.
If you want to use Az, you need to install Az.Automation and Az.Account.
.LINK
https://docs.microsoft.com/en-us/azure/automation/automation-update-azure-modules
.LINK
http://4bes.nl/2019/09/05/script-update-all-powershell-modules-in-your-automation-account
.NOTES
Elements of https://github.com/Microsoft/AzureAutomation-Account-Modules-Update were used and adapted.
This script is usable for all Modules.
This script can be ran locally, but it does not work in PowerShell Core
#>

param(
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $AutomationAccountName,

    [Parameter()]
    [Boolean] $Az
)

Function Get-Dependency {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ModuleName,
        [Parameter(Mandatory = $false)]
        [int] $Level = 0
    )
    <#
    .SYNOPSIS
    This function is used to get the correct order of Modules, keeping track of dependencies

    .DESCRIPTION
    By using the function recursively, the module order can be handled correctly.

    .PARAMETER moduleName
    The name of the module to check dependencies on

    .PARAMETER level
    used internally to make recursive use possible

    .EXAMPLE
    Get-Dependency AzureRM.Account
    #>

    if ($Level -eq 0) {
        $OrderedModules = [System.Collections.ArrayList]@()
    }

    # Getting dependencies from the gallery
    Write-Verbose "Checking dependencies for $ModuleName"
    $ModuleUri = "https://www.powershellgallery.com/api/v2/Search()?`$filter={1}&searchTerm=%27{0}%27&targetFramework=%27%27&includePrerelease=false&`$skip=0&`$top=40"
    $CurrentModuleUrl = $ModuleUri -f $ModuleName, 'IsLatestVersion'
    $SearchResult = Invoke-RestMethod -Method Get -Uri $CurrentModuleUrl -UseBasicParsing | Where-Object { $_.title.InnerText -eq $ModuleName }

    if ($null -eq $SearchResult) {
        Write-Output "Could not find module $ModuleName in PowerShell Gallery."
        Continue
    }
    $ModuleInformation = (Invoke-RestMethod -Method Get -UseBasicParsing -Uri $SearchResult.id)

    #Creating Variables to get an object
    $ModuleVersion = $ModuleInformation.entry.properties.version
    $Dependencies = $ModuleInformation.entry.properties.dependencies
    $DependencyReadable = $Dependencies -replace '\:.*', ''

    $ModuleObject = [PSCustomObject]@{
        ModuleName    = $ModuleName
        ModuleVersion = $ModuleVersion

    }

    # If no dependencies are found, the module is added to the list
    if ([string]::IsNullOrEmpty($Dependencies) ) {
        $OrderedModules.Add($ModuleObject) | Out-Null
    }

    else {
        # If there are dependencies, they are first checked for dependencies of there own. After that they are added to the list.
        Get-Dependency -ModuleName $DependencyReadable -Level ($Level++)
        $OrderedModules.Add($ModuleObject) | Out-Null
    }

    return $OrderedModules
}

# Connect to Azurre with the runasaccount
Write-Output "Creating Connection"
try {
    $Conn = Get-AutomationConnection -Name AzureRunAsConnection
    $Parameters = @{
        Tenant                = $Conn.TenantID
        ApplicationId         = $Conn.ApplicationID
        CertificateThumbprint = $Conn.CertificateThumbprint
    }
    if ($Az) {
        Connect-AzAccount -ServicePrincipal @Parameters -ErrorAction Stop | Out-Null
    }
    else {
        Connect-AzureRmAccount -ServicePrincipal @Parameters -ErrorAction Stop | Out-Null
    }
}
Catch {
    throw $_.Exception
}
Write-Output "Connection with Azure established"

# get all modules in the Automation Account
try {
    if ($Az) {
        $AutomationModules = Get-AzAutomationModule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction Stop
    }
    else {
        $AutomationModules = Get-AzureRmAutomationModule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction Stop
    }
}
Catch {
    Throw $_.Exception
}

if ($null -eq $AutomationModules) {
    Write-Output "No modules found, script wil stop"
    Exit
}

# Create a ordered list of all modules, there old version and there current version
$OrderedModuleList = [System.Collections.ArrayList]@()
Foreach ($Module in $AutomationModules) {

    $ModulesAndDependencies = Get-Dependency -moduleName $Module.Name
    foreach ($moduleFiltered  in $ModulesAndDependencies) {
        $ExistingVersion = ($AutomationModules | Where-Object { $_.Name -eq $moduleFiltered.ModuleName }).Version
        $moduleFiltered | Add-Member -MemberType NoteProperty -Name "ExistingVersion" -Value $ExistingVersion
        $OrderedModuleList.Add($moduleFiltered) | Out-Null
    }
}

#to handle duplicate modules, we create a list of modules that are already checked
$Updated = [System.Collections.ArrayList]@()

foreach ($UpdateModule in $OrderedModuleList) {
    # continue loop if module has already been handled
    if ($Updated -contains $UpdateModule.ModuleName) { Continue }

    $ModuleName = $UpdateModule.ModuleName
    Write-Output "Starting with $ModuleName"

    if ($UpdateModule.ModuleVersion -gt $UpdateModule.ExistingVersion) {

        # Get the module file
        $ModuleContentUrl = "https://www.powershellgallery.com/api/v2/package/$ModuleName"
        do {
            $ModuleContentUrl = (Invoke-WebRequest -Uri $ModuleContentUrl -MaximumRedirection 0 -UseBasicParsing -ErrorAction Ignore).Headers.Location
        } while ($ModuleContentUrl -notlike "*.nupkg")


        Write-Output "Module $Modulename will be updated, version in Automation account is $($UpdateModule.ExistingVersion), Version in Gallery is  $($UpdateModule.ModuleVersion)"

        # Actual update
        $Parameters = @{
            ResourceGroupName     = $ResourceGroupName
            AutomationAccountName = $AutomationAccountName
            Name                  = $ModuleName
            ContentLink           = $ModuleContentUrl
        }
        Try {
            if ($Az) {
                New-AzAutomationModule @Parameters | Out-Null
            }
            else {
                New-AzureRmAutomationModule @Parameters | Out-Null
            }
        }
        Catch {
            Write-Error "Module $ModuleName could not be updated"
            Continue
        }
        # Check status
        $i = 0
        Write-Output "Checking update status"
        Do {
            Start-Sleep 10
            if ($Az) {
                $UpdateState = (Get-AzAutomationModule -Name $ModuleName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).ProvisioningState
            }
            else {
                $UpdateState = (Get-AzureRmAutomationModule -Name $ModuleName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).ProvisioningState
            }
            $i++
        } While (($UpdateState -ne "Failed" -and $UpdateState -ne "Succeeded") -or $i -gt 20)
        if ($i -gt 20) {
            Write-Error "Module $ModuleName is still creating. Please check manually"
        }
        switch ($UpdateState) {
            "Failed" { Throw "module $ModuleName has failed " }
            "Succeeded" { Write-Output "Module $ModuleName update succeeded" }
            Default { Write-Output "Module $ModuleName ended in state $Updatestate" }
        }
    }
    else {
        Write-Output "Module does not need update"
    }
    $Updated.Add($UpdateModule.ModuleName) | Out-Null
}