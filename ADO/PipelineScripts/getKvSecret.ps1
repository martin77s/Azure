Param(
    [Parameter(Mandatory = $true)][string] $KeyVaultName,
    [Parameter(Mandatory = $true)][string] $SecretName,
    [Parameter(Mandatory = $true)][string] $ParameterName
)

$id = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName).Id
Write-Host "##vso[task.setvariable variable=$ParameterName]$id"