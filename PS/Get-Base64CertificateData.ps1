<#

Script Name	: Get-Base64CertificateData.ps1
Description	: Gets the Base64 encoded string from a PFX certificate
Author		: Martin Schvartzman, Microsoft (maschvar@microsoft.com)
Keywords	: PKI, PFX, Base64
Last Update	: 2020/06/09

#>


PARAM(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path -Path $_})]$PfxPath
)

[Convert]::ToBase64String(
	[System.Text.Encoding]::UTF8.GetBytes(
		[byte[]][System.IO.File]::ReadAllBytes($PfxPath)
))
