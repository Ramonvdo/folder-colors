<#
.SYNOPSIS
    Read-only profile of one folder's loose files, for tidy-folder. Emits JSON.

.DESCRIPTION
    Lists every loose file with its cluster (documents, images, video, audio, code,
    installers, archives, other), size, last-write date, a date found in its name if any,
    name tokens, and a flag for "(1)"-style duplicate names; the existing subfolders with
    child counts and protected-unit markers; cluster totals; and the folder's own Folder
    Colors category, which decides whether the finance profile applies.

.EXAMPLE
    .\Get-FolderProfile.ps1 -Path 'D:\Downloads\old'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Path,
    [int]$MaxFiles = 600
)

$ErrorActionPreference = 'Stop'
$Path = (Get-Item -LiteralPath $Path.Trim('"') -Force).FullName.TrimEnd('\')

# Engine, for the folder's own category (config.json first, then three levels up).
$root = $null
$cfg = Join-Path $env:USERPROFILE '.folder-colors\config.json'
if (Test-Path -LiteralPath $cfg) { try { $root = (Get-Content -LiteralPath $cfg -Raw -Encoding UTF8 | ConvertFrom-Json).root } catch {} }
if (-not $root -or -not (Test-Path -LiteralPath (Join-Path $root 'Set-FolderColor.ps1'))) { $root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$engine = Join-Path $root 'Set-FolderColor.ps1'

$clusters = @{
    documents  = '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.md', '.csv', '.odt', '.rtf'
    images     = '.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.heic', '.bmp', '.psd', '.ai'
    video      = '.mp4', '.mov', '.mkv', '.avi', '.webm'
    audio      = '.mp3', '.wav', '.m4a', '.flac', '.ogg'
    code       = '.js', '.ts', '.py', '.ps1', '.json', '.html', '.css', '.sh', '.yml', '.yaml', '.sql'
    installers = '.exe', '.msi', '.msix', '.appx', '.dmg'
    archives   = '.zip', '.7z', '.rar', '.tar', '.gz'
}
function Get-Cluster([string]$ext) { foreach ($k in $clusters.Keys) { if ($clusters[$k] -contains $ext) { return $k } }; return 'other' }
$markers = '.git', 'CLAUDE.md', 'AGENTS.md', 'GEMINI.md', '.claude', 'package.json', 'pyproject.toml', 'Cargo.toml', 'go.mod', 'Makefile', '.obsidian'

$items = @(Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin 'desktop.ini', 'Thumbs.db' })
$files = @($items | Where-Object { -not $_.PSIsContainer })
$dirs  = @($items | Where-Object PSIsContainer)

$fileList = New-Object System.Collections.ArrayList
foreach ($f in ($files | Sort-Object Name | Select-Object -First $MaxFiles)) {
    $base = $f.BaseName
    $nameDate = $null
    if ($base -match '(20\d{2})[-_.]?(0[1-9]|1[0-2])[-_.]?(0[1-9]|[12]\d|3[01])') { $nameDate = "$($Matches[1])-$($Matches[2])-$($Matches[3])" }
    elseif ($base -match '\b(0[1-9]|[12]\d|3[01])[-_.](0[1-9]|1[0-2])[-_.](20\d{2})\b') { $nameDate = "$($Matches[3])-$($Matches[2])-$($Matches[1])" }
    $tokens = @(($base -replace '[\d_\-\.\(\)\[\]]+', ' ') -split '\s+' | Where-Object { $_.Length -ge 3 } | ForEach-Object { $_.ToLowerInvariant() } | Select-Object -Unique)
    [void]$fileList.Add([ordered]@{
        name = $f.Name; ext = $f.Extension.ToLowerInvariant(); cluster = Get-Cluster $f.Extension.ToLowerInvariant()
        bytes = $f.Length; modified = $f.LastWriteTime.ToString('yyyy-MM-dd'); created = $f.CreationTime.ToString('yyyy-MM-dd')
        nameDate = $nameDate; tokens = $tokens
        duplicateSuffix = [bool]($base -match ' \(\d+\)$'); doubleExtension = [bool]($f.Name -match '\.(pdf|jpg|png|docx?)\.\1$')
        normalised = [bool]($f.Name -match '^\d{4}-\d{2}-\d{2}_[A-Za-z]+_')
    })
}

$dirList = New-Object System.Collections.ArrayList
foreach ($d in ($dirs | Sort-Object Name)) {
    $kids = @(Get-ChildItem -LiteralPath $d.FullName -Force -ErrorAction SilentlyContinue)
    $found = @($kids | Where-Object { $markers -contains $_.Name } | ForEach-Object Name)
    [void]$dirList.Add([ordered]@{ name = $d.Name; children = $kids.Count; protectedUnit = ($found.Count -gt 0); markers = $found })
}

$totals = @{}; foreach ($f in $fileList) { $totals[$f.cluster] = 1 + $totals[$f.cluster] }
$tag = $null; try { $tag = (& $engine -Path $Path -Get).Category } catch {}
$readme = @($items | Where-Object { $_.Name -match '^(00_README|README|CLAUDE)\.md$' } | ForEach-Object Name)

[ordered]@{
    path = $Path; generated = (Get-Date).ToString('s'); category = $tag; readme = $readme
    fileCount = $files.Count; folderCount = $dirs.Count; truncated = ($files.Count -gt $MaxFiles)
    clusterTotals = $totals
    alreadyNormalised = @($fileList | Where-Object normalised).Count
    duplicateSuffixes = @($fileList | Where-Object duplicateSuffix | ForEach-Object name)
    doubleExtensions = @($fileList | Where-Object doubleExtension | ForEach-Object name)
    folders = $dirList; files = $fileList
} | ConvertTo-Json -Depth 6
