<#PSScriptInfo
.VERSION 1.2
.AUTHOR meirm@microsoft.com
.GUID f983f286-7c77-46e2-adad-352926c13499
#>

<# 
.DESCRIPTION 
  Script to upload PowerShell objects to Azure Monitor Logs using the Data Collector API.  
 
.PARAMETER WorkspaceId 
    The Workspace ID of the workspace that would be used to store this data
 
.PARAMETER WorkspaceKey 
    The primary or secondary key of the workspace that would be used to store this data. It can be obtained from the Windows Server tab in the workspace Advanced Settings
     
.PARAMETER LogTypeName 
    The name of the custom log table that would store these logs. This name will be automatically concatenated with "_CL"
 
.PARAMETER AddComputerName 
    If this switch is indicated, the script will add to every log record a field called Computer with the current computer name
 
.PARAMETER TaggedAzureResourceId 
    If exist, the script will associated all uploaded log records with the specified Azure resource. This will enable these log records for resource-centext queries

.PARAMETER AdditionalDataTaggingName 
    If exist, the script will add to every log record an additional field with this name and with the value that appears in AdditionalDataTaggingValue. This happens only if AdditionalDataTaggingValue is not empty
 
.PARAMETER AdditionalDataTaggingValue 
    If exist, the script will add to every log record an additional field with this value. The field name would be as specified in AdditionalDataTaggingName. If AdditionalDataTaggingName is empty, the field name will be "DataTagging"
 
.EXAMPLE 
  Import-Csv .\testcsv.csv | .\Upload-AzMonitorLog.ps1 -WorkspaceId '69f7ec3e-cae3-458d-b4ea-6975385-6e426' -WorkspaceKey $WSKey -LogTypeName 'MyNewCSV' -AddComputerName -AdditionalDataTaggingName "MyAdditionalField" -AdditionalDataTaggingValue "Foo"
  Will upload the CSV file as a custom log to Azure Monitor Logs (AKA:Log Analytics)
   
.EXAMPLE 
  Import-Csv .\testcsv.csv | .\Upload-AzMonitorLog.ps1 -WorkspaceId '69f7ec3e-cae3-458d-b4ea-6975385-6e426' -WorkspaceKey $WSKey -LogTypeName 'MyNewCSV' -AddComputerName -AdditionalDataTaggingName "MyAdditionalField" -AdditionalDataTaggingValue "Foo"
  Will upload the CSV file as a custom log to Azure Monitor Logs (AKA:Log Analytics)
 
.LINK 
    This script posted to and discussed at the following locations:PowerShell Gallery      
    https://www.powershellgallery.com/packages/Upload-AzMonitorLog
#>
param (
    [Parameter(mandatory=$true,ValueFromPipeline=$true)]$input,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$WorkspaceId,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$WorkspaceKey,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$LogTypeName,
    [Parameter(Mandatory=$false)][switch]$AddComputerName,
    [Parameter(Mandatory=$false)][string]$TaggedAzureResourceId,    
    [Parameter(Mandatory=$false)][string]$AdditionalDataTaggingName,    
    [Parameter(Mandatory=$false)][string]$AdditionalDataTaggingValue    
    )

Write-Output ("Start process " + $input.Length.ToString("N0") + " items and uploading them to Azure Log Analytcs")

$InputTypeName = $input.GetType().Name
switch -Exact ($InputTypeName)
{
    "ArrayListEnumeratorSimple" { $data = $input | ConvertTo-Json -Compress; Break }
    default { $data = $input.GetType().Name }
}

$customerId = $WorkspaceId
$sharedKey = $WorkspaceKey

# Specify the name of the record type that you'll be creating
$LogType = $LogTypeName

# Specify a field with the created time for the records
$TimeStampField = "DateValue" #OBSOLETE exist just for backward compatability

# Add computer name for each record if needed
if ($AddComputerName)
{
    $compName = $env:COMPUTERNAME
    if ($ENV:USERDNSDOMAIN -ne $env:COMPUTERNAME) { $compName = $env:COMPUTERNAME + "." + $ENV:USERDNSDOMAIN } #for domain joined computer, add FQDN
    foreach ($row in $input) {$row | Add-Member -MemberType NoteProperty -Name Computer -Value $compName}
}

# Add additional tagging if additional tagging is provided
if ($AdditionalDataTaggingValue)
{
    if(!($AdditionalDataTaggingName)) { $AdditionalDataTaggingName = "DataTagging" }
    foreach ($row in $input) {$row | Add-Member -MemberType NoteProperty -Name $AdditionalDataTaggingName -Value $AdditionalDataTaggingValue}
}

# Create json object based on the PowerShell data
try
{   
    $json = $input | ConvertTo-Json -Compress
}
catch
{
    throw("Input data cannot be converted into a JSON object. Please make sure that the input data is a standard PowerShell table")
}


# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}


#Format the post request
$method = "POST"
$contentType = "application/json"
$resource = "/api/logs"
$rfc1123date = [DateTime]::UtcNow.ToString("r")
$body = ([System.Text.Encoding]::UTF8.GetBytes($json))
$contentLength = $body.Length
$signature = Build-Signature `
    -customerId $customerId `
    -sharedKey $sharedKey `
    -date $rfc1123date `
    -contentLength $contentLength `
    -method $method `
    -contentType $contentType `
    -resource $resource
$uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

$headers = @{
    "Authorization" = $signature;
    "Log-Type" = $logType;
    "x-ms-date" = $rfc1123date;
    "x-ms-AzureResourceId" = $TaggedAzureResourceId
    "time-generated-field" = $TimeStampField;
}

#validate that payload data does not exceed limits
if ($body.Length -gt (31.9 *1024*1024))
{
    throw("Upload payload is too big and exceed the 32Mb limit for a single upload. Please reduce the payload size. Current payload size is: " + ($body.Length/1024/1024).ToString("#.#") + "Mb")
}

Write-Output ("Upload payload size is " + ($body.Length/1024).ToString("#.#") + "Kb")

##### Send the Web request
try
{
    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
}
catch
{
    if ($_.Exception.Message.startswith('The remote name could not be resolved'))
    {
        throw ("Error - data could not be uploaded. Might be because workspace ID or private key are incorrect")
    }

    throw ("Error - data could not be uploaded: " + $_.Exception.Message)
}
        
# Present message according to the response code
if ($response.StatusCode -eq 200) 
{ Write-Output  "200 - Data was successfully uploaded" }
else
{ throw ("Server returned an error response code:" + $response.StatusCode)}

