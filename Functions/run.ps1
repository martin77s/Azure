using namespace System.Net

param($Request, $TriggerMetadata)

#region Debugging:
Write-Host "FUNCTIONS_EXTENSION_VERSION:" $env:FUNCTIONS_EXTENSION_VERSION
Write-Host "FUNCTIONS_WORKER_RUNTIME:" $env:FUNCTIONS_WORKER_RUNTIME
Write-Host (Get-Module -ListAvailable | Out-String)
#endregion


#region Authenticate
if ($env:MSI_SECRET -and (Get-Module -ListAvailable Az.Accounts)) {
    Connect-AzAccount -Identity
}
$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=https://management.azure.com&api-version=2017-09-01"
$env:tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $tokenAuthURI
#endregion

#region Get the query parameters or request body
$computername = $Request.Query.ComputerName
if (-not $computername) {
    $computername = $Request.Body.ComputerName
}
#endregion

#region Import needed modules
Import-Module Az.ResourceGraph
#endregion


#region Build and run the resource grpah query
try {
    $query = @"
        Resources
        | where type =~ 'Microsoft.Compute/virtualMachines' and properties.osProfile.computerName matches regex '$computername'
        | join (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscriptionName=name, subscriptionId) on subscriptionId
        | project subscriptionId, subscriptionName, resourceGroup, vmName = name, vmSize = properties.hardwareProfile.vmSize, osType = properties.storageProfile.osDisk.osType, image = strcat(properties.storageProfile.imageReference.offer, ' ', properties.storageProfile.imageReference.sku), vmStatus = properties.extended.instanceView.powerState.displayStatus
"@
    $results = Search-AzGraph -Query $query
    $statusCode = [HttpStatusCode]::OK
} catch {
    $results = $_.Exception.Message
    $statusCode = [HttpStatusCode]::BadRequest
}
#endregion


#region Return the result(s)
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $statusCode
    Body = $results | ConvertTo-Json -AsArray
})
#endregion