<#
.SYNOPSIS
    Refresh the auto section of PC-MAP.md from the real folder layout.

.DESCRIPTION
    Reads the roots listed in the map's frontmatter, inventories their top level, and
    rewrites the block between <!-- organize-pc:auto-start --> and <!-- organize-pc:auto-end -->
    with a table of every top-level folder: its Folder Colors category and whether the map's
    Areas table knows it. Hand-written sections are never touched. New folders you create by
    hand therefore show up as "unmapped" the next time the map is read.

    -RegisterTask schedules this script daily at 09:00 for the current user (no admin), via
    run-hidden.vbs so nothing flashes. -UnregisterTask removes it.

.EXAMPLE
    .\Update-PcMap.ps1
    .\Update-PcMap.ps1 -RegisterTask
#>
[CmdletBinding()]
param(
    [string]$Map = (Join-Path $env:USERPROFILE 'PC-MAP.md'),
    [switch]$RegisterTask,
    [switch]$UnregisterTask
)

$ErrorActionPreference = 'Stop'
$taskName = 'organize-pc map refresh'
$startMark = '<!-- organize-pc:auto-start -->'; $endMark = '<!-- organize-pc:auto-end -->'

if ($UnregisterTask) { schtasks.exe /Delete /TN $taskName /F | Out-Null; Write-Output "Removed scheduled task '$taskName'."; return }
if ($RegisterTask) {
    $launcher = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path 'run-hidden.vbs'
    $cmd = "wscript.exe //B //Nologo \`"$launcher\`" \`"skills\organize-pc\scripts\Update-PcMap.ps1\`""
    schtasks.exe /Create /SC DAILY /ST 09:00 /TN $taskName /TR $cmd /F | Out-Null
    Write-Output "Scheduled '$taskName' daily at 09:00 for $env:USERNAME."
}

if (-not (Test-Path -LiteralPath $Map)) { throw "No map at $Map. organize-pc writes it on the first run." }
$text = [IO.File]::ReadAllText($Map, [Text.Encoding]::UTF8)

# Roots from the frontmatter list; area paths from the Areas table's second column.
$roots = @()
if ($text -match '(?ms)^roots:\s*\r?\n((?:\s+-\s+.*\r?\n)+)') { $roots = @($Matches[1] -split "`r?`n" | ForEach-Object { if ($_ -match '^\s+-\s+(.+?)\s*$') { $Matches[1].Trim('"', "'") } } | Where-Object { $_ }) }
if ($roots.Count -eq 0) { throw 'The map lists no roots in its frontmatter.' }
$areaByLower = @{}
foreach ($m in [regex]::Matches($text, '(?m)^\|\s*`[^`|]+`\s*\|\s*`([A-Za-z]:\\[^`|]*)`\s*\|')) { $v = $m.Groups[1].Value.TrimEnd('\'); $areaByLower[$v.ToLowerInvariant()] = $v }

$inventory = & (Join-Path $PSScriptRoot 'Get-PcInventory.ps1') -Roots $roots | ConvertFrom-Json
$lines = New-Object System.Collections.ArrayList
[void]$lines.Add("## Current top level (auto, refreshed $((Get-Date).ToString('yyyy-MM-dd HH:mm')))")
[void]$lines.Add('')
[void]$lines.Add('| Root | Folder | Category | Status |')
[void]$lines.Add('|---|---|---|---|')
$unmapped = 0
foreach ($r in $inventory.roots) {
    if (-not $r.exists) { [void]$lines.Add("| ``$($r.path)`` | | | root missing |"); continue }
    foreach ($e in @($r.entries | Where-Object type -eq 'folder')) {
        $full = (Join-Path $r.path $e.name).TrimEnd('\').ToLowerInvariant()
        $status = if ($areaByLower.ContainsKey($full)) { 'area' } elseif ($e.isCloudRoot) { 'cloud root' } elseif ($e.isGitRepo) { 'git repo' } else { $unmapped++; 'unmapped' }
        $cat = if ($e.folderColor) { $e.folderColor } else { '' }
        [void]$lines.Add("| ``$($r.path)`` | ``$($e.name)`` | $cat | $status |")
    }
    $loose = [int]$r.fileCount
    if ($loose -gt 0) { [void]$lines.Add("| ``$($r.path)`` | _$loose loose file(s)_ | | transit |") }
}
foreach ($a in $areaByLower.Values) { if (-not (Test-Path -LiteralPath $a)) { [void]$lines.Add("| | ``$a`` | | listed in Areas but missing on disk |") } }
[void]$lines.Add('')
[void]$lines.Add("_${unmapped} unmapped folder(s). Run organize-pc to give them a place or list them as areas._")

$block = "$startMark`n" + ($lines -join "`n") + "`n$endMark"
if ($text -match [regex]::Escape($startMark)) {
    $text = [regex]::Replace($text, [regex]::Escape($startMark) + '.*?' + [regex]::Escape($endMark), { param($m) $block }, 'Singleline')
} else {
    $text = $text.TrimEnd() + "`n`n" + $block + "`n"
}
[IO.File]::WriteAllText($Map, $text, (New-Object Text.UTF8Encoding($false)))
Write-Output "Refreshed $Map ($unmapped unmapped)."
