PARAM(
    $resourceGroupName = 'rg-test-vms'
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))

try {

    # Get the automation account service principal
    $spConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'


    # Login to AzureAD
    $params = @{
        TenantId              = $spConnection.TenantId
        ApplicationId         = $spConnection.ApplicationId
        CertificateThumbprint = $spConnection.CertificateThumbprint
    }
    $adConnection = Connect-AzureAD @params


    # Login to ARM
    Add-AzAccount -ServicePrincipal -Tenant $spConnection.TenantId `
        -ApplicationId $spConnection.ApplicationId `
        -CertificateThumbprint $spConnection.CertificateThumbprint | Out-Null
    

    # Get the resource group, and it's tags
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName
    $resourceGroupTags = $resourceGroup.Tags

    # List all resources within the resource group
    $allResources = Get-AzResource -ResourceGroupName $resourceGroupName

    # Iterate the resources and apply the missing tags
    foreach ($resource in $allResources) {

        $resourceid = $resource.resourceId
        $resourcetags = $resource.Tags
        Write-Output ('Setting tags for {0}' -f $resource.Name)

        if ($resourcetags -eq $null) {
            $tagsSet = Set-AzResource -ResourceId $resourceid -Tag $resourceGroupTags -Force
        } else {
            $tagsToSet = $resourceGroupTags.Clone()
            foreach ($tag in $resourcetags.GetEnumerator()) {
                if ($tagsToSet.Keys -inotcontains $tag.Key) {                        
                    $tagsToSet.Add($tag.Key, $tag.Value)
                }    

            }
            $tagsSet = Set-AzResource -ResourceId $resourceid -Tag $tagsToSet -Force
        }   
    }
} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}