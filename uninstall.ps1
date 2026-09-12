<#
.SYNOPSIS
    Remove the right-click "Folder Color" menu for the current user.

.DESCRIPTION
    Deletes the single registry key install.ps1 created. Folders you already
    coloured keep their icons for as long as this folder and its assets exist;
    run  .\Set-FolderColor.ps1 -Path <folder> -Reset  on any you want back to default.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$menuKey = 'HKCU:\Software\Classes\Directory\shell\FolderColors'

if (Test-Path $menuKey) {
    Remove-Item $menuKey -Recurse -Force
    Write-Host 'Removed the Folder Color menu.' -ForegroundColor Green
} else {
    Write-Host 'The Folder Color menu was not installed; nothing to remove.'
}
