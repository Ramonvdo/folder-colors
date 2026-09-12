<#
.SYNOPSIS
    Colour and tag many folders in one go, from a JSON plan.

.DESCRIPTION
    Plan: a JSON array of { "path": "<folder>", "category": "<name>" }; "none" as the
    category resets the folder. Each entry goes through Set-FolderColor.ps1, so the same
    rules apply (existing desktop.ini kept, tags written, open windows repainted).

    Inside a git repository the new desktop.ini files would show up in git status, so
    the script adds "desktop.ini" to that repository's .git\info\exclude (local, never
    committed, the repository's own .gitignore untouched). Nothing else is written.

.EXAMPLE
    .\Set-FolderColors.ps1 -Plan colours.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Plan
)

$ErrorActionPreference = 'Stop'

# The repo root: config.json first, then three levels up from this script.
$root = $null
$cfg = Join-Path $env:USERPROFILE '.folder-colors\config.json'
if (Test-Path -LiteralPath $cfg) { try { $root = (Get-Content -LiteralPath $cfg -Raw -Encoding UTF8 | ConvertFrom-Json).root } catch {} }
if (-not $root -or -not (Test-Path -LiteralPath (Join-Path $root 'Set-FolderColor.ps1'))) { $root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$engine = Join-Path $root 'Set-FolderColor.ps1'
if (-not (Test-Path -LiteralPath $engine)) { throw "Set-FolderColor.ps1 not found under $root; run install.ps1 in the checkout." }

$entries = @(); foreach ($e in (ConvertFrom-Json -InputObject (Get-Content -LiteralPath $Plan -Raw -Encoding UTF8))) { $entries += $e }
if ($entries.Count -eq 0) { throw "Plan is empty: $Plan" }

function Get-GitRoot([string]$dir) {
    $d = Get-Item -LiteralPath $dir -Force
    while ($d) {
        if (Test-Path -LiteralPath (Join-Path $d.FullName '.git') -PathType Container) { return $d.FullName }
        $d = $d.Parent
    }
    return $null
}
function Add-GitExclude([string]$gitRoot) {
    $info = Join-Path $gitRoot '.git\info'; $exclude = Join-Path $info 'exclude'
    if (-not (Test-Path -LiteralPath $info)) { $null = New-Item -ItemType Directory -Path $info }
    $lines = @(); if (Test-Path -LiteralPath $exclude) { $lines = @(Get-Content -LiteralPath $exclude) }
    if ($lines -notcontains 'desktop.ini') { Add-Content -LiteralPath $exclude -Value 'desktop.ini' -Encoding ASCII; return $true }
    return $false
}

$excluded = @{}
$results = New-Object System.Collections.ArrayList
foreach ($e in $entries) {
    $r = [ordered]@{ path = $e.path; category = $e.category; ok = $false; detail = '' }
    try {
        if (-not $e.path -or -not $e.category) { throw 'entry needs path and category' }
        if ($e.category -eq 'none') { $null = & $engine -Path $e.path -Reset }
        else { $null = & $engine -Path $e.path -Category $e.category }
        $got = & $engine -Path $e.path -Get
        $r.ok = ($e.category -eq 'none' -and $null -eq $got.Index) -or ($got.Category -eq $e.category)
        $r.detail = if ($got.Category) { "$($got.Index) $($got.Category)" } else { 'plain' }
        $git = Get-GitRoot $e.path
        if ($git -and -not $excluded.ContainsKey($git)) { $excluded[$git] = Add-GitExclude $git }
    } catch { $r.detail = $_.Exception.Message }
    [void]$results.Add([pscustomobject]$r)
}
$results | Format-Table -AutoSize -Wrap | Out-String -Width 200 | Write-Output
$done = @($results | Where-Object ok).Count
Write-Output "$done of $($results.Count) applied."
foreach ($g in $excluded.Keys) { Write-Output ("git repository $g" + $(if ($excluded[$g]) { ': desktop.ini added to .git\info\exclude' } else { ': desktop.ini already excluded' })) }
if ($done -ne $results.Count) { exit 1 }
