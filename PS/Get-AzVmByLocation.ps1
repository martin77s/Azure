param($LocationFilter = @('*Africa*', 'West US*'))

# Get all locations with the vmSizes providers
$locations = Get-AzResourceProvider | 
    Where-Object { $_.ResourceTypes.ResourceTypeName -contains 'locations/vmSizes' } | 
        Select-Object -ExpandProperty Locations


# Filter in only the specific locations
$filteredLocations = $locations | Where-Object { 
    $location = $_
    $LocationFilter | Where-Object { $location -like $_ }
}

# Get all the sizes, and add the Location property
$sizes = $filteredLocations | ForEach-Object {
    $location = $_
    Get-AzVMSize -Location $location | Select-Object Name, NumberOfCores, MemoryInMB, 
        OSDiskSizeInMB, ResourceDiskSizeInMB, MaxDataDiskCount, @{N='Location';E={$location}}
} 

# Return the sizes
$sizes

# Optional: Save the output to file (or show in datagrid)
# $sizes | Export-Csv -NoTypeInformation -Path C:\Temp\VMSizes.csv
# $sizes | Out-GridView