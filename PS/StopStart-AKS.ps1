#Requires -Module Az.Accounts

PARAM(
    [Parameter(Mandatory)]
    [String] $SubscriptionId,

    [Parameter(Mandatory)]
    [String] $ResourceGroupName,

    [Parameter(Mandatory)]
    [String] $AksClusterName,

    [Parameter(Mandatory)]
    [ValidateSet('Start', 'Stop')]
    [String] $Operation
)

$settings = @{
    ApiVersion = '2021-05-01'
    GetUri     = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.ContainerService/managedClusters/{2}?api-version={3}'
    PostUri    = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.ContainerService/managedClusters/{2}/{3}?api-version={4}'
}

try {

    $accessToken = Get-AzAccessToken | Select-Object -ExpandProperty Token
    $headers = @{'Authorization' = "Bearer $accessToken" }

    try {
        $getUri = $settings.GetUri -f $SubscriptionId, $ResourceGroupName, $AksClusterName, $settings.ApiVersion
        $response = (Invoke-WebRequest -Method Get -Headers $headers -Uri $getUri -UseBasicParsing).Content | ConvertFrom-Json
        $state = $response.properties.powerState.code

        $postUri = $settings.PostUri -f $SubscriptionId, $ResourceGroupName, $AksClusterName, $operation.ToLower(), $settings.ApiVersion
        Switch ($operation) {
            'Start' {
                if ($state -eq 'Stopped') {
                    $response = Invoke-WebRequest -UseBasicParsing -Method Post -Headers $headers -Uri $postUri
                    $responseCode = $response.StatusCode
                } else {
                    Write-Output ('Cluster is already in the desired state')
                }
            }
            'Stop' {
                if ($state -eq 'Running') {
                    $response = Invoke-WebRequest -UseBasicParsing -Method Post -Headers $headers -Uri $postUri
                    $responseCode = $response.StatusCode
                } else {
                    Write-Output ('Cluster is already in the desired state')
                }
            }
        }
    } catch {
        Write-Output ('Error: {0}' -f $_.Exception.Message)
    }
    if (($responseCode -ge 200) -and ($responseCode -lt 300)) {
        Write-Output ('Operation {0} on {1} was successfully completed successfully' -f $operation, $aksClusterName)
    } else {
        Write-Output ('Could not perform operation {0} on {1}. Error {2}' -f $operation, $aksClusterName, $responseCode)
    }
} catch {
    Write-Output ('Error: {0}' -f $_.Exception.Message)
}