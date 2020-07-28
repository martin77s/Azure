<#

Script Name	: SendAdvisorDigest.ps1
Description	: Create an HTML digest report for the Azure Advisor Recommendations
Author		: Martin Schvartzman, Microsoft
Last Update	: 2020/07/28
Keywords	: Azure, Automation, Runbook, Advisor, ACM

#>

PARAM(
    [string] $ConnectionName = 'AzureRunAsConnection'
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))


try {

    Disable-AzContextAutosave –Scope Process | Out-Null

    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null

        $queries = @{
            'Advisor Recommendations by Category' = @'
            advisorresources | summarize Count=count() by Category=tostring(properties.category) | where Category!='' | sort by Category asc
'@
            'Advisor Cost Recommendations' = @'
            advisorresources | where type == 'microsoft.advisor/recommendations' and properties.category == 'Cost' | summarize Resources = dcount(tostring(properties.resourceMetadata.resourceId)), Savings = sum(todouble(properties.extendedProperties.savingsAmount)) by Solution = tostring(properties.shortDescription.solution), Currency = tostring(properties.extendedProperties.savingsCurrency) | project Solution, Resources, Savings = bin(Savings, 0.01), Currency | order by Savings desc
'@
            'Advisor High Availability Recommendations' = @'
            advisorresources | where type == 'microsoft.advisor/recommendations' and properties.category == 'HighAvailability' | project Solution=tostring(properties.shortDescription.solution) | summarize Count=count() by Solution | sort by Count
'@
            'Advisor Operational Excellence Recommendations' = @'
            advisorresources | where type == 'microsoft.advisor/recommendations' and properties.category == 'OperationalExcellence' | project Solution=tostring(properties.shortDescription.solution) | summarize Count=count() by Solution | sort by Count
'@
            'Advisor Performance Recommendations' = @'
            advisorresources | where type == 'microsoft.advisor/recommendations' and properties.category == 'Performance' | project Solution=tostring(properties.shortDescription.solution) | summarize Count=count() by Solution | sort by Count
'@
        }

        $report = $queries.GetEnumerator() | ForEach-Object {
            '<h1>{0}</h1>' -f $_.Key
            Search-AzGraph -Query $_.Value | ConvertTo-Html -Fragment
        }

        $report

} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}