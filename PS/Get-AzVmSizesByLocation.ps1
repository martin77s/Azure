function Get-AzVmSizesByLocation {
    [CmdletBinding()]
    param($LocationFilter = '*')

    Write-Verbose -Message 'Getting all locations with the vmSizes providers'
    $locations = Get-AzResourceProvider | 
        Where-Object { $_.ResourceTypes.ResourceTypeName -contains 'locations/vmSizes' } | 
            Select-Object -ExpandProperty Locations


    Write-Verbose -Message 'Filtering in the specified locations'
    $filteredLocations = $locations | Where-Object { 
        $location = $_
        $LocationFilter | Where-Object { $location -like $_ }
    }

    Write-Verbose -Message 'Getting all the sizes, and adding the Location property'
    $sizes = $filteredLocations | ForEach-Object {
        $location = $_
        Get-AzVMSize -Location $location | Select-Object Name, NumberOfCores, MemoryInMB, 
            OSDiskSizeInMB, ResourceDiskSizeInMB, MaxDataDiskCount, @{N='Location';E={$location}}
    } 

    $sizes
}

# Usage examples:
$vmSizes = Get-AzVmSizesByLocation
$vmSizes = Get-AzVmSizesByLocation -LocationFilter '*Europe*'
$vmSizes = Get-AzVmSizesByLocation -LocationFilter @('*Africa*', 'West US*')

# Optional: Save the output to file (or show in datagrid)
$vmSizes | Export-Csv -NoTypeInformation -Path C:\Temp\VMSizes.csv
$vmSizes | Out-GridView