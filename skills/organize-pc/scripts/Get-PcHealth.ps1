<#
.SYNOPSIS
    The weekly audit as one table: transit folders, drift, stale areas, missing READMEs,
    uncoloured areas. Read-only.

.DESCRIPTION
    Reads PC-MAP.md (roots and areas) and the inventory, then reports one row per check
    with a status (ok / attention) and the detail. Nothing is written.

.EXAMPLE
    .\Get-PcHealth.ps1
    .\Get-PcHealth.ps1 -StaleDays 180
#>
[CmdletBinding()]
param(
    [string]$Map = (Join-Path $env:USERPROFILE 'PC-MAP.md'),
    [int]$StaleDays = 90,
    [int]$TransitLimit = 10      # loose files in a transit folder before it is flagged
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Map)) { throw "No map at $Map. organize-pc writes it on the first run." }
$text = [IO.File]::ReadAllText($Map, [Text.Encoding]::UTF8)

$roots = @()
if ($text -match '(?ms)^roots:\s*\r?\n((?:\s+-\s+.*\r?\n)+)') { $roots = @($Matches[1] -split "`r?`n" | ForEach-Object { if ($_ -match '^\s+-\s+(.+?)\s*$') { $Matches[1].Trim('"', "'") } } | Where-Object { $_ }) }
$areas = @([regex]::Matches($text, '(?m)^\|\s*`([^`|]+)`\s*\|\s*`([A-Za-z]:\\[^`|]*)`\s*\|') | ForEach-Object { [pscustomobject]@{ Name = $_.Groups[1].Value; Path = $_.Groups[2].Value.TrimEnd('\') } })

$inv = & (Join-Path $PSScriptRoot 'Get-PcInventory.ps1') -Roots $roots | ConvertFrom-Json
$rows = New-Object System.Collections.ArrayList
function Row($check, $ok, $detail) { [void]$rows.Add([pscustomobject]@{ Check = $check; Status = $(if ($ok) { 'ok' } else { 'attention' }); Detail = $detail }) }

# Transit folders: Desktop, Downloads and any 00_INBOX among the roots or areas.
$downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
$transit = @([Environment]::GetFolderPath('Desktop'), $downloads) + @($areas | Where-Object Name -match 'INBOX' | ForEach-Object Path)
foreach ($t in $transit | Select-Object -Unique) {
    if (-not (Test-Path -LiteralPath $t)) { continue }
    $n = @(Get-ChildItem -LiteralPath $t -File -Force -ErrorAction SilentlyContinue | Where-Object Name -notin 'desktop.ini', 'Thumbs.db').Count
    Row "transit: $(Split-Path $t -Leaf)" ($n -le $TransitLimit) "$n loose file(s)"
}

# Drift: top-level folders in the roots that are neither areas nor units.
$areaLower = @($areas | ForEach-Object { $_.Path.ToLowerInvariant() })
$unmapped = @()
foreach ($r in $inv.roots) { if (-not $r.exists) { Row "root: $($r.path)" $false 'missing on disk'; continue }
    foreach ($e in @($r.entries | Where-Object type -eq 'folder')) {
        $full = (Join-Path $r.path $e.name).TrimEnd('\')
        if ($areaLower -notcontains $full.ToLowerInvariant() -and -not $e.isCloudRoot -and -not $e.isGitRepo -and -not $e.isWorkspace) { $unmapped += $full }
    }
}
Row 'drift: unmapped top-level folders' ($unmapped.Count -eq 0) $(if ($unmapped) { $unmapped -join '; ' } else { 'none' })

# Areas: exist, coloured, README present, not stale.
$cats = @{}; $cfg = Join-Path $PSScriptRoot '..\..\..\categories.json'
foreach ($a in $areas) {
    if (-not (Test-Path -LiteralPath $a.Path)) { Row "area: $($a.Name)" $false 'listed in the map but missing on disk'; continue }
    $ini = Join-Path $a.Path 'desktop.ini'; $coloured = (Test-Path -LiteralPath $ini) -and ((Get-Content -LiteralPath $ini -Raw -Force -ErrorAction SilentlyContinue) -match '\[FolderColors\]')
    $readme = Test-Path -LiteralPath (Join-Path $a.Path '00_README.md')
    $newest = (Get-ChildItem -LiteralPath $a.Path -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object Name -ne 'desktop.ini' | Measure-Object LastWriteTime -Maximum).Maximum
    $stale = $newest -and $newest -lt (Get-Date).AddDays(-$StaleDays) -and $a.Name -notmatch 'ARCHIVE|TEMPLATES|MASTER'
    $problems = @(); if (-not $coloured) { $problems += 'no colour' }; if (-not $readme) { $problems += 'no 00_README.md' }; if ($stale) { $problems += "untouched since $($newest.ToString('yyyy-MM-dd'))" }
    Row "area: $($a.Name)" ($problems.Count -eq 0) $(if ($problems) { $problems -join ', ' } else { 'coloured, documented, active' })
}

# Storage Sense rule for Downloads.
$ss = $inv.storageSense
Row 'downloads: Storage Sense rule' ([bool]($ss -and $ss.downloadsCleanup)) $(if ($ss -and $ss.downloadsCleanup) { "delete after $($ss.downloadsDays) days" } else { 'off' })

$rows | Format-Table -AutoSize -Wrap | Out-String -Width 160 | Write-Output
$bad = @($rows | Where-Object Status -eq 'attention').Count
Write-Output "$bad item(s) need attention."
