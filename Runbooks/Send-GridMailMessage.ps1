Param(
    [Parameter(Mandatory = $True)]
    [String] $destEmailAddress,
    [Parameter(Mandatory = $True)]
    [String] $fromEmailAddress,
    [Parameter(Mandatory = $True)]
    [String] $subject,
    [Parameter(Mandatory = $True)]
    [String] $content,
    [switch] $bodyAsHtml
)

Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Starting' -f (Get-Date))

try {
    # Login to Azure
    $servicePrincipalConnection = Get-AutomationConnection -Name AzureRunAsConnection
    $null = Add-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    # Get the SendGrid API Key from the Credential object
    $SendGridAPIKey = (Get-AutomationPSCredential -Name SendGridAPIKey).GetNetworkCredential().Password

    # Prepare the REST web request
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer " + $SendGridAPIKey)
    $headers.Add("Content-Type", "application/json")

    if ($bodyAsHtml) {
        $contentType = 'text/html'
        $content = @'
            <style>
                table { border-collapse: collapse; }
                table, th, td { border: 1px solid black; }
                th, td { padding: 5px; text-align: left; }
            </style>
'@ + $content
    } else {
        $contentType = "text/plain"
    }

    $body = @{
        personalizations = @(
            @{
                to = @(
                    @{
                        email = $destEmailAddress
                    }
                )
            }
        )
        from             = @{
            email = $fromEmailAddress
        }
        subject          = $subject
        content          = @(
            @{
                type  = $contentType
                value = $content
            }
        )
    }

    # Invoke the API to send the email
    $bodyJson = $body | ConvertTo-Json -Depth 4
    $null = Invoke-RestMethod -Uri https://api.sendgrid.com/v3/mail/send -Method Post -Headers $headers -Body $bodyJson

} catch {
    Write-Output ($_)
} finally {
    Write-Output ('{0:yyyy-MM-dd HH:mm:ss.f} - Completed' -f (Get-Date))
}
