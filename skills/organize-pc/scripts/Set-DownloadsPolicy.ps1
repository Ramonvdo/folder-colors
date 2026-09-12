<#
.SYNOPSIS
    Make Downloads a transit folder: Storage Sense deletes files untouched for N days.

.DESCRIPTION
    Reads the current Storage Sense settings first and prints them. With -Apply it turns
    Storage Sense on, enables the Downloads rule with the chosen age, and sets the run
    cadence to weekly if it was "only when disk space is low" (the rule never fires
    otherwise). Registry only, current user only: the same values Settings > System >
    Storage > Storage Sense writes.

.EXAMPLE
    .\Set-DownloadsPolicy.ps1                # show current state
    .\Set-DownloadsPolicy.ps1 -Days 7 -Apply
    .\Set-DownloadsPolicy.ps1 -Days 0 -Apply # 0 = never delete (rule off)
#>
[CmdletBinding()]
param(
    [ValidateSet(0, 1, 14, 30, 60)][int]$Days = 14,   # the values the Settings page offers
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
$cadenceNames = @{ 0 = 'only when disk space is low'; 1 = 'every day'; 7 = 'every week'; 30 = 'every month' }

function Read-State {
    if (-not (Test-Path $key)) { return [pscustomobject]@{ Enabled = $false; Cadence = 0; DownloadsRule = $false; DownloadsDays = 0 } }
    $p = Get-ItemProperty $key
    [pscustomobject]@{ Enabled = [bool]$p.'01'; Cadence = [int]$p.'2048'; DownloadsRule = [bool]$p.'32'; DownloadsDays = [int]$p.'512' }
}
function Show-State($s, [string]$label) {
    Write-Output ("{0}: Storage Sense {1}, runs {2}; Downloads rule {3}{4}" -f $label, $(if ($s.Enabled) { 'on' } else { 'off' }), $cadenceNames[$s.Cadence], $(if ($s.DownloadsRule) { 'on' } else { 'off' }), $(if ($s.DownloadsRule) { ", delete after $($s.DownloadsDays) days" } else { '' }))
}

$before = Read-State
Show-State $before 'Current'
if (-not $Apply) { Write-Output "Intended: Downloads rule $(if ($Days) { "on, delete after $Days days" } else { 'off' }). Re-run with -Apply to set it."; return }

if (-not (Test-Path $key)) { $null = New-Item -Path $key -Force }
if ($Days -eq 0) {
    Set-ItemProperty $key -Name '32' -Value 0 -Type DWord
} else {
    Set-ItemProperty $key -Name '01'  -Value 1 -Type DWord
    Set-ItemProperty $key -Name '32'  -Value 1 -Type DWord
    Set-ItemProperty $key -Name '512' -Value $Days -Type DWord
    if ($before.Cadence -eq 0) { Set-ItemProperty $key -Name '2048' -Value 7 -Type DWord }
}
Show-State (Read-State) 'Now'
Write-Output 'Check: Settings > System > Storage > Storage Sense shows the same values.'
