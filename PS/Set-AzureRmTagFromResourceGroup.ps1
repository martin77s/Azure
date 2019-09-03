function Set-AzureRmTagFromResourceGroup {
    param($ResourceGroupName = '*')

    Get-AzureRmResourceGroup -Name $ResourceGroupName | ForEach-Object {

        $resourceGroupTags = $_.Tags

        Get-AzureRmResource -ResourceGroupName $_.ResourceGroupName | ForEach-Object {

            $tagsToApply = @{}
            $resourceTags = $_.Tags

            # Add tags from the parent resource group
            if($resourceGroupTags) {
                $resourceGroupTags.GetEnumerator() | ForEach-Object {
                    if($resourceTags.Keys -inotcontains $_.Key) {
                        $tagsToApply.Add($_.Key, $_.Value)
                    }
                }
            }

            # Add previous remaining tags
            if($resourceTags) {
                $resourceTags.GetEnumerator() | ForEach-Object {
                    if(-not ($tagsToApply.ContainsKey($_.Key))) {
                            $tagsToApply.Add($_.Key, $_.Value)
                    }
                }
            }

            # Set the tags on the resource
            Set-AzureRmResource -ResourceId $_.ResourceId -Tag $tagsToApply -Force -Verbose
        }
    }
}
