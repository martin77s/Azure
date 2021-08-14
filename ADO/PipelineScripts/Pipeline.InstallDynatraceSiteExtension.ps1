<#

Script Name	: Pipeline.InstallDynatraceSiteExtension.ps1
Description	: Install Dynatrace Site Extension on all webapps in the given environment
Keywords	: Azure, AppService, SiteExtension

#>

#Requires -PSEdition Core

PARAM(
    [Parameter(Mandatory)] [string] $Environment,
    [Parameter(Mandatory)] [string] $ApplicationName
)

# Script variables:
$apiVersion = '2019-08-01'
$basePathList = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Web/sites/{2}/siteextensions?api-version={3}'
$subscriptionId = (Get-AzContext).Subscription.Id
$extensionName = 'Dynatrace'


# Collect and loop through all the apps and slots
$apps = @()
$apps = Get-AzResource -ResourceType Microsoft.Web/sites |
    Where-Object { $_.Name -match ('({0})-({1})-' -f $Environment, $ApplicationName) }
$apps += Get-AzResource -ResourceType Microsoft.Web/sites/slots |
    Where-Object { ($_.Name -replace '/', '-') -match ('({0})-({1})-' -f $Environment, $ApplicationName) }
$apps = $apps | Sort-Object Name
Write-Host ("`nFound {0} apps (sites, api, slots) to configure:`n{1}" -f $apps.Count, ($apps.Name -join ", "))


foreach ($app in $apps) {

    Write-Host ("`nWorking on {0}" -f $app.Name)

    # Build the path:
    if ($app.Type -eq 'Microsoft.Web/sites/slots') {
        $path = $basePathList -f $subscriptionId, $app.ResourceGroupName, ('{0}/slots/{1}' -f ($app.Name -split '/')), $apiVersion
    } else {
        $path = $basePathList -f $subscriptionId, $app.ResourceGroupName, $app.Name, $apiVersion
    }

    Write-Host ("`tGetting current site extensions")
    $res = Invoke-AzRestMethod -Path $path -Method GET
    if (-not $res) {
        Write-Host ("##[warning] There was an error getting the currently installed extensions")
    } elseif (200 -ne $res.StatusCode) {
        try { $errorMessage = (($res.Content | ConvertFrom-Json).message) } catch { $errorMessage = 'Unknown error' }
        Write-Host ("##[Error] Error {0}: {1}" -f $res.StatusCode, $errorMessage)
    } else {
        $extensionsInstalled = ($res.Content | ConvertFrom-Json).value | ForEach-Object { ($_.Name -split '/')[-1] }
        if ($extensionName -in $extensionsInstalled) {
            Write-Host ("##[warning] Extension is already installed")
        } else {

            if ($app.Type -eq 'Microsoft.Web/sites/slots') {
                $resourceType = 'Microsoft.Web/sites/slots/siteextensions'
            } else {
                $resourceType = 'Microsoft.Web/sites/siteextensions'
            }

            $params = @{
                ResourceType      = $resourceType
                ResourceGroupName = $app.ResourceGroupName
                Name              = '{0}/{1}' -f $app.Name, $extensionName
                ApiVersion        = $apiVersion
                Force             = $true
                ErrorAction       = 'Stop'
            }

            try {
                Write-Host ("##[section] Installing {0} extension" -f $extensionName)
                $res = New-AzResource  @params
                Write-Host ("##[section] Extension installed successfully. Restarting application...")

                if ($app.Type -eq 'Microsoft.Web/sites/slots') {
                    $appName, $slotName = $app.Name -split '/'
                    Restart-AzWebAppSlot -ResourceGroupName $app.ResourceGroupName -Name $appName -Slot $slotName -ErrorAction Stop | Out-Null
                } else {
                    Restart-AzWebApp -ResourceGroupName $app.ResourceGroupName -Name $app.Name -ErrorAction Stop | Out-Null
                }

                Write-Host ("##[section] Restarted successfully")
            } catch {
                Write-Host ("##[warning] There was an error installing the extension")
                Write-Host ("##[warning] Error: {0}" -f $_.Exception.Message)
            }
        }
    }
}