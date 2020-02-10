[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $Owner = 'Azure'
    ,
    [Parameter()]
    [string]
    $Repo = 'azure-quickstart-templates'
    ,
    [Parameter()]
    [string]
    $Path = 'test/arm-ttk'
    ,
    [Parameter()]
    [string]
    $RootFolderName = ''
)


if( ($PSBoundParameters.ContainsKey('path')) -and 
    (-not $PSBoundParameters.ContainsKey('rootFolderName')) )
{
    Write-Verbose 'Assigning root folder to path folder.'
    $rootFolderName = Split-Path $path -Leaf
}

$rootUri = 'https://api.github.com'
$apiCall = "/repos/{0}/{1}/contents/{2}" -f $owner, $repo, $path
$header = @{ 
    'Authorization' = "token $GitApiKey"
}

$rootPath = Join-Path -Path $PSScriptRoot -ChildPath $rootFolderName
if(-not (Test-Path -Path $rootPath))
{
    New-Item -Path $rootPath -ItemType Directory | Out-Null
    Write-Verbose "Created folder $rootPath"
}

function Get-RestRec
{
    [CmdletBinding()]
    param(
        $uri
    )
    
    $resp = Invoke-RestMethod -Uri $uri -Method Get -Headers $header -verbose:$false

    foreach ($r in $resp)
    {
        if ($r.type -eq 'file')
        {
            Write-Verbose "File: $($r.download_url)"
            $dPath = $r.path -replace $path, ''
            $fullFilePath = Join-Path -Path $rootPath -ChildPath $dPath
            Invoke-WebRequest -Uri $r.download_url -OutFile $fullFilePath -Verbose:$false
        }
        if ($r.type -eq 'dir')
        {
            $apiCall = "/repos/{0}/{1}/contents/{2}" -f $owner, $repo, $r.path
            Write-Verbose "Dir : $($r.path)"
            $subPath = $r.path -replace $path, ''
            New-Item -Path $rootPath -Name $subPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
            Write-Verbose "  -> $apiCall"
            Get-RestRec -uri "$rootUri$apiCall"
        }
    }
}

Get-RestRec -uri "$rootUri$apiCall"