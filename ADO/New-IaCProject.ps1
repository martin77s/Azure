<#
.SYNOPSIS
    Creates a new Azure DevOps project and repositories in a new organization, to host the IaC modules and solution files

.DESCRIPTION
    Creates a new Azure DevOps project and repositories in a new organization, to host the IaC modules and solution files

.PARAMETER OrganizationName
    Specifies the name of the Azure DevOps organization to create
    https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/organization-management?view=azure-devops

.PARAMETER ProjectName
    Specifies the name of the Azure DevOps project to create
    https://docs.microsoft.com/en-us/azure/devops/organizations/projects/about-projects?view=azure-devops

.PARAMETER ProcessTemplate
    Specifies the process template type of the Azure DevOps project to create (Agile / Basic / CMMI / Scrum)
    https://docs.microsoft.com/en-us/azure/devops/boards/work-items/guidance/choose-process?view=azure-devops

.PARAMETER SourceControlType
    Specifies the source control type of the Azure DevOps project to create (Git / TFVC)
    https://docs.microsoft.com/en-us/azure/devops/repos/tfvc/comparison-git-tfvc?view=azure-devops

.PARAMETER SubscriptionId
    Specifies the Id of the Azure subscription to be used when creating the related Azure resources
    https://docs.microsoft.com/en-us/powershell/module/az.accounts/get-azsubscription

.PARAMETER ResourceGroupName
    Specifies the name of the resource group to be used when creating the related Azure resources
    https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview#resource-groups

.PARAMETER Location
    Specifies the Azure region location to be used when creating the related Azure resources (Azure DevOps organization is supported only in several regions. Not all of them)
    https://azure.microsoft.com/en-us/global-infrastructure/geographies

.EXAMPLE
    .\New-IaCProject -OrganizationName ContosoInc

.EXAMPLE
    .\New-IaCProject -OrganizationName FabrikamLtd -ProjectName InfraAsCode -Template Basic -SubscriptionId '01234567-89ab-cdef-0123-456789abcdef' -Location 'East US 2'

.NOTES
	Version      : 0.0.0.3
	Last Updated : 2020-09-07
	Author       : Martin Schvartzman, Microsoft (maschvar@microsoft.com)
	Keywords     : Azure DevOps, Project, IaC
	Open Issues  :
	 1. Create service principals and grant them the required RBAC permissions
	 2. Create the service connections with the previously created service principals
#>

#Requires -PSEdition Core
#Requires -Modules Az.Accounts, Az.Resources

[CmdletBinding(SupportsShouldProcess = $false)]
PARAM(
    [Parameter(Mandatory = $true, Position = 0,
        HelpMessage = 'The name of the Azure DevOps organization to create')]
    [ValidateNotNullOrEmpty()]
    [Alias('Company')]
    [string] $OrganizationName,

    [Parameter(Mandatory = $false, Position = 1,
        HelpMessage = 'The name of the prject to create (IaC)')]
    [ValidateNotNullOrEmpty()]
    [Alias('Project')]
    [string] $ProjectName = 'IaC',

    [Parameter(Mandatory = $false, Position = 3,
        HelpMessage = 'The process template for the project (Agile)')]
    [ValidateSet('Agile', 'Basic', 'CMMI', 'Scrum')]
    [Alias('Template')]
    [string] $ProcessTemplate = 'Agile',

    [Parameter(Mandatory = $false, Position = 4,
        HelpMessage = 'The version control system type for the project (Git)')]
    [ValidateSet('Git', 'TFVC')]
    [Alias('VersionControlType')]
    [string] $SourceControlType = 'Git',

    [Parameter(Mandatory = $false, Position = 5,
        HelpMessage = 'The subscription (Id) where to create the Azure DevOps organization and any future related resources (StorageAccount, KeyVault, etc.)')]
    [ValidatePattern('[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}')]
    [string] $SubscriptionId = ((Get-AzContext).Subscription.Id),

    [Parameter(Mandatory = $false, Position = 6,
        HelpMessage = 'The name of the resource group where to create the Azure DevOps organization and any future related resources')]
    [ValidatePattern('^[-\w\._\(\)]+$')]
    [Alias('Group')]
    [string] $ResourceGroupName = 'Azure-DevOps-IaC',

    [Parameter(Mandatory = $false, Position = 7,
        HelpMessage = 'The region location where to create the Azure DevOps organization and any future related resources')]
    [ValidateSet('Australia East', 'Brazil South', 'Canada Central', 'Central US', 'East Asia', 'East US 2', 'South India', 'UK South', 'West Europe', 'West US 2')]
    [Alias('Region')]
    [string] $Location = 'West Europe'
)


#region Helper functions

function Assert-AzContext {
    PARAM(
        [Parameter(Mandatory = $true)] [string] $SubscriptionId
    )
    Write-Verbose 'Verifying we are in the correct context'
    $contextOk = $true
    try {
        $context = Get-AzContext
        if (-not ($SubscriptionId -eq ($context).Subscription.Id)) {
            Set-AzContext -SubscriptionId $subscriptionId -Tenant $context.Tenant.Id -ErrorAction Stop | Out-Null
        }
    } catch {
        $contextOk = $false
    }
    $contextOk
}


function Assert-ResourceGroup {
    PARAM(
        [Parameter(Mandatory = $true)] [string] $SubscriptionId,
        [Parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)] [string] $Location
    )
    Write-Verbose 'Verifying the resource group exists'
    $rgOk = $true
    try {
        if (-not( Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
            New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force -ErrorAction Stop | Out-Null
        }
    } catch {
        $rgOk = $false
    }
    $rgOk
}


function Test-AzAdoOrganizationNameAvailability {
    PARAM(
        [Parameter(Mandatory = $true)] [string] $SubscriptionId,
        [Parameter(Mandatory = $true)] [string] $OrganizationName
    )
    Write-Verbose "Verifying the Azure DevOps organization name '$OrganizationName' is available for use"
    try {
        $nameAvailable = $false
        $path = "/subscriptions/$SubscriptionId/providers/microsoft.visualstudio/checkNameAvailability?api-version=2014-04-01-preview"
        $body = @"
{
  "resourceType": "Account",
  "resourceName": "$OrganizationName"
}
"@
        $output = (Invoke-AzRestMethod -Path $path -Method POST -Payload $body).Content | ConvertFrom-Json
        if ($output.nameAvailable -eq 'True') {
            $nameAvailable = $true
        } else {
            Write-Verbose -Message $output.message
        }
    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
    $nameAvailable
}


function New-AzAdoOrganization {
    PARAM(
        [Parameter(Mandatory = $true)] [string] $SubscriptionId,
        [Parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)] [string] $Location,
        [Parameter(Mandatory = $true)] [string] $OrganizationName
    )
    Write-Verbose "Creating a new Azure DevOps organization named '$OrganizationName'"
    $adoOrganization = [PSCustomObject] @{
        OrganizationName = $OrganizationName
        AccountURL       = $null
    }

    try {

        $templateJson = @"
{
    "`$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "OrganizationName": {
            "type": "string",
            "defaultValue": "$OrganizationName"
        }
    },
    "resources": [
        {
            "type": "Microsoft.VisualStudio/account",
            "apiVersion": "2014-04-01-preview",
            "name": "[parameters('OrganizationName')]",
            "location": "[resourceGroup().location]",
            "properties": {
                "operationType": "Create",
                "accountName": "[parameters('OrganizationName')]"
            }
        }
    ],
    "outputs": {
        "accountURL": {
            "type": "string",
            "value": "[reference(parameters('OrganizationName'), '2014-04-01-preview').accountURL]"
        }
    }
}
"@
        $templateFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('{0:yyyyMMddHHmmss}.deploy.json' -f ([datetime]::Now))
        Set-Content -Value $templateJson -Path $templateFile -Force -Encoding utf8

        $output = New-AzResourceGroupDeployment -Mode Incremental -ResourceGroupName $ResourceGroupName -TemplateFile $templateFile -Force
        if ($output.ProvisioningState -eq 'Succeeded') {
            $adoOrganization.AccountURL = $output.Outputs['accountURL'].Value
        } else {
            $adoOrganization = $null
        }
        Remove-Item -Path $templateFile -Force
    } catch {
        $adoOrganization = $null
    }
    $adoOrganization
}


function Get-AzAdoProcessTemplate {
    PARAM(
        [Parameter(Mandatory = $true)] [string] $OrganizationName
    )
    Write-Verbose "Querying for the Azure DevOps project process template identifiers"
    $token = Get-AzToken
    $params = @{
        Method          = 'GET'
        UseBasicParsing = $true
        Headers         = @{ 'Authorization' = 'Bearer ' + $token.Token; 'Content-Type' = 'application/json' }
        Uri             = "https://dev.azure.com/$OrganizationName/_apis/process/processes?api-version=6.0"
    }; $output = (Invoke-WebRequest @params).Content | ConvertFrom-Json
    $output.value
}


function New-AzAdoProject {
    PARAM(
        [Parameter(Mandatory = $true)] [string] $OrganizationName,
        [Parameter(Mandatory = $true)] [string] $ProjectName,
        [Parameter(Mandatory = $true)] [string] $ProcessTemplateId,
        [Parameter(Mandatory = $true)] [string] $SourceControlType
    )
    Write-Verbose "Creating a new Azure DevOps project named '$ProjectName'"
    $body = @"
    {
        "name": "$ProjectName",
        "description": "$ProjectName",
        "capabilities": {
            "versioncontrol": {
                "sourceControlType": "$SourceControlType"
            },
            "processTemplate": {
                "templateTypeId": "$ProcessTemplateId"
            }
        }
    }
"@
    $token = Get-AzToken
    $params = @{
        Method          = 'POST'
        Body            = $body
        UseBasicParsing = $true
        Headers         = @{ 'Authorization' = 'Bearer ' + $token.Token; 'Content-Type' = 'application/json' }
        Uri             = "https://dev.azure.com/$OrganizationName/_apis/projects?api-version=6.0"
    }; $output = (Invoke-WebRequest @params).Content | ConvertFrom-Json
    $checkStatusUrl = $output.url
    $iMaxTimesToWait = 12
    do {
        Start-Sleep -Seconds 10
        $iMaxTimesToWait--
        $params = @{
            Method          = 'GET'
            UseBasicParsing = $true
            Headers         = @{ 'Authorization' = 'Bearer ' + $token.Token; 'Content-Type' = 'application/json' }
            Uri             = $checkStatusUrl
        }; $output = (Invoke-WebRequest @params).Content | ConvertFrom-Json
    } while (-not (($output.status -eq 'succeeded') -or ($iMaxTimesToWait -eq 0)))

    if ($output.status -eq 'succeeded') {
        $params = @{
            Method          = 'GET'
            Body            = $body
            UseBasicParsing = $true
            Headers         = @{ 'Authorization' = 'Bearer ' + $token.Token; 'Content-Type' = 'application/json' }
            Uri             = "https://dev.azure.com/$OrganizationName/_apis/projects?api-version=6.0"
        }; $output = (Invoke-WebRequest @params).Content | ConvertFrom-Json
        $project = $output.value | Where-Object { $_.name -eq $ProjectName }

        [PSCustomObject] @{
            OrganizationName  = $OrganizationName
            ProjectName       = $project.name
            ProjectId         = $project.id
            ProjectUri        = "https://dev.azure.com/$OrganizationName/$ProjectName"
            ProcessTemplateId = $ProcessTemplateId
            SourceControlType = $SourceControlType
            State             = $project.state
        }
    } else {
        $null
    }
}


function New-AzAdoRepository {
    PARAM(
        [Parameter(Mandatory = $true)] [string] $OrganizationName,
        [Parameter(Mandatory = $true)] [string] $ProjectName,
        [Parameter(Mandatory = $true)] [string] $ProjectId,
        [Parameter(Mandatory = $true)] [string] $RepositoryName
    )
    Write-Verbose "Creating a new Azure DevOps repository named '$RepositoryName'"
    try {
        $body = @"
{
    "name": "$RepositoryName",
    "project": {
        "id": "$ProjectId",
        "name": "$ProjectName"
    }
}
"@
        $token = Get-AzToken
        $params = @{
            Method          = 'POST'
            Body            = $body
            UseBasicParsing = $true
            Headers         = @{ 'Authorization' = 'Bearer ' + $token.Token; 'Content-Type' = 'application/json' }
            Uri             = "https://dev.azure.com/$OrganizationName/$ProjectName/_apis/git/Repositories?api-version=6.0"
        }; $output = (Invoke-WebRequest @params).Content | ConvertFrom-Json
        $repo = [PSCustomObject] @{
            OrganizationName = $OrganizationName
            ProjectName      = $ProjectName
            ProjectId        = $ProjectId
            RepositoryName   = $output.name
            RepositoryId     = $output.id
            remoteUrl        = $output.remoteUrl
            webUrl           = $output.webUrl
        }
    } catch {
        $repo = $null
    }
    $repo
}


function Resolve-LocalComponentsFolder {
    $i = 0; $localPath = $PSScriptRoot
    do {
        if ((Split-Path -Path $localPath -Leaf) -eq 'Components') { $localPath = Resolve-Path -Path $localPath; break }
        $i++; $localPath = Resolve-Path -Path ('{0}{1}' -f $PSScriptRoot, ('\..' * $i)) -ErrorAction SilentlyContinue
    } until ((Split-Path -Path $localPath -Qualifier) -eq ($localPath -replace '\\'))
    if ((Split-Path -Path $localPath.Path -Leaf) -eq 'Components') {
        $localPath.Path
    } else {
        $null
    }
}


function Optimize-LocalComponentsFolder {
    PARAM(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path -Path $_ -PathType Container })] [string] $Path
    )
    $filesToRemove = @('.\readme.md')
    Push-Location -Path $Path
    Get-ChildItem -Path $Path -Recurse |
        Where-Object { $filesToRemove -contains (Resolve-Path -Path $_.FullName -Relative) } |
            Remove-Item -Force
    Pop-Location
}


function Push-ToRepository {
    PARAM(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path -Path $_ -PathType Container })] [string] $Path,
        [Parameter(Mandatory = $true)] [string] $RepositoryWebUrl,
        [Parameter(Mandatory = $false)] [string] $Comment = 'Initial commit',
        [Parameter(Mandatory = $false)] [string] $Branch = 'master'

    )
    try {
        $pushResults = & {
            Write-Verbose "Pushing the local folder '$Path' to the Azure DevOps repository '$RepositoryName'"
            Push-Location -Path $Path
            Remove-Item -Path .\.git\ -Force -Recurse -ErrorAction SilentlyContinue
            git.exe init
            git.exe add .
            git.exe commit -m $Comment
            git.exe remote add origin $RepositoryWebUrl
            git.exe push origin $Branch
            Pop-Location
        }
    } catch {
        $pushResults = $null
    }
    $pushResults
}


function Get-AzToken {
    try {
        $context = Get-AzContext
        if ($env:MSI_ENDPOINT) {
            $response = Invoke-WebRequest -Uri "$env:MSI_ENDPOINT/?resource=https://management.azure.com/" -Headers @{'Metadata' = 'true' }
            $token = [PSCustomObject]@{
                SubscriptionId = $context.Subscription
                TenantID       = $env:ACC_TID
                Token          = ($response.content | ConvertFrom-Json | Select-Object -ExpandProperty access_token)
            }
        } else {
            $cachedTokens = ($context.TokenCache).ReadItems() |
                Where-Object { $_.TenantId -eq $context.Tenant } |
                    Sort-Object -Property ExpiresOn -Descending
            $accessToken = $cachedTokens[0].AccessToken
            $token = [PScustomObject]@{
                SubscriptionID = $context.Subscription
                TenantID       = $context.Tenant
                Token          = $accessToken
            }
        }
    } catch {
        $token = $null
    }
    $token
}


function Assert-Prerequisites {
    PARAM(
        [Parameter(Mandatory = $true)] [string] $SubscriptionId,
        [Parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)] [string] $Location,
        [Parameter(Mandatory = $true)] [string] $OrganizationName
    )

    if (-not (Get-AzContext)) {
        Write-Host "Please authenticate to Azure using 'Connect-AzAccount'."
        exit 1
    }

    if (-not (Assert-AzContext -SubscriptionId $SubscriptionId)) {
        Write-Host 'Could not verify or set the correct context.'
        exit 2
    }

    if (-not (Test-AzAdoOrganizationNameAvailability -SubscriptionId $SubscriptionId -OrganizationName $OrganizationName)) {
        Write-Host 'The organization name supplied is not allowed. Please try another organization name.'
        exit 3
    }

    if (-not (Assert-ResourceGroup -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -Location $Location)) {
        Write-Host ("Could not verify or create the resource group '{0}' exists in subscription '{1}'." -f $ResourceGroupName, $SubscriptionId)
        exit 4
    }

    if (-not (Get-Command -Name git.exe)) {
        Write-Host 'Could not verify git is installed and git.exe is in the system path.'
        exit 5
    }
}

#endregion


#region Main

# Verify Prerequisites (Context, ADO Organization name availability, ResourceGroup, etc.)
$params = @{
    OrganizationName  = $OrganizationName
    SubscriptionId    = $SubscriptionId
    ResourceGroupName = $ResourceGroupName
    Location          = $Location
}; Assert-Prerequisites @params


# Create the Azure DevOps Organization
$params = @{
    OrganizationName  = $OrganizationName
    SubscriptionId    = $SubscriptionId
    ResourceGroupName = $ResourceGroupName
    Location          = $Location
}; $adoOrganization = New-AzAdoOrganization @params
if ($null -eq $adoOrganization) {
    Write-Host "There was an error creating the Azure DevOps organization. Please check the deployment details in the resource group"
    exit 6
}


# Get the selected process template id
$templates = Get-AzAdoProcessTemplate -OrganizationName $OrganizationName
$processTemplateId = ($templates | Where-Object { $_.name -eq $ProcessTemplate }).id
if ($null -eq $processTemplateId) {
    Write-Host "There was an error selecting the process template type"
    exit 7
}


# Create the IaC Project
$params = @{
    OrganizationName  = $adoOrganization.OrganizationName
    ProjectName       = $ProjectName
    ProcessTemplateId = $ProcessTemplateId
    SourceControlType = $SourceControlType
}; $adoProject = New-AzAdoProject @params
if ($null -eq $adoProject) {
    Write-Host "There was an error creating the Azure DevOps project"
    exit 8
}


# Create the repository
$params = @{
    OrganizationName = $adoProject.OrganizationName
    ProjectName      = $adoProject.ProjectName
    ProjectId        = $adoProject.ProjectId
    RepositoryName   = 'Components'
}; $repo = New-AzAdoRepository @params
if ($null -eq $repo) {
    Write-Host "There was an error creating the Azure DevOps repository"
    exit 9
}


# Determine and clean the local 'Components' folder path
$localComponentsFolder = Resolve-LocalComponentsFolder
if ($null -eq $localComponentsFolder) {
    Write-Host "There was an error determing the local 'Components' folder path"
    exit 10
} else {
    Optimize-LocalComponentsFolder -Path $localComponentsFolder
}


# Push the local folder to the repository
$params = @{
    Path             = $localComponentsFolder
    RepositoryWebUrl = $repo.webUrl
}; $result = Push-ToRepository @params
if ($null -eq $result) {
    Write-Host "There was an error pushing to the Azure DevOps repository"
    exit 11
}


#endregion