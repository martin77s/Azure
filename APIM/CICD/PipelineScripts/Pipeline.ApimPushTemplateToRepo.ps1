<#

Script Name	: Pipeline.ApimPushTemplatesToRepo.ps1
Description	: Push extracted and transformed APIM ARM templates back to the repository
Keywords	: Azure, APIM-CI/CD, GIT

#>


PARAM(
    [Parameter(Mandatory = $true)][string] $Path,
    [Parameter(Mandatory = $false)][string] $CommitMessage = 'APIM extracted and transformed templates - [skip ci]'
)


$templates = @(Get-ChildItem $Path -Recurse -Include *apim*.json |
    Where-Object { $_.Name -match 'apim-extracted|apim-transformed' })
if ($templates.Count -gt 0) {
    Write-Verbose ('Found {0} relevant template(s)' -f $templates.Count) -Verbose
    git config --global user.email "$($env:Build_QueuedById)@$($env:System_TeamProject)"
    git config --global user.name "$($env:Build_Repository_Name)"
    foreach($file in $templates) { git add $($file.FullName) }
    git commit -m $CommitMessage
    git push origin HEAD:$($env:Build_SourceBranchName)
} else {
    Write-Host ('##[error] No templates found to commit back. {0}' -f $_.Exception.Message)
    $host.SetShouldExit(1)
}