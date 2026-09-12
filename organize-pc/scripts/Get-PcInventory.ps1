<#
.SYNOPSIS
    Read-only inventory of the folders organize-pc works on. Emits JSON.

.DESCRIPTION
    For each root: its top-level entries with size, age, and markers (git repo, cloud root,
    README present, Folder Colors category), plus an age profile and extension clusters of
    the loose files. Also reports cloud sync roots, Desktop item count and the Storage Sense
    rule for Downloads. Nothing is written anywhere.

.EXAMPLE
    .\Get-PcInventory.ps1                                  # Desktop, Downloads, Documents
    .\Get-PcInventory.ps1 -Roots 'D:\', "$env:USERPROFILE\Documents"
#>
[CmdletBinding()]
param(
    [string[]]$Roots,
    [int]$MaxEntries = 400        # per root; larger roots are summarised, not listed
)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $PSScriptRoot '..\..\categories.json'
$cats = @{}
if (Test-Path -LiteralPath $configPath) {
    foreach ($c in (Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json).categories) { $cats[[int]$c.index] = $c.category }
}

function Get-KnownFolder([string]$name) {
    switch ($name) {
        'Downloads' { return (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path }
        default     { return [Environment]::GetFolderPath($name) }
    }
}
if (-not $Roots) { $Roots = @((Get-KnownFolder 'Desktop'), (Get-KnownFolder 'Downloads'), (Get-KnownFolder 'MyDocuments')) }

$skipNames = '$RECYCLE.BIN', 'System Volume Information', 'desktop.ini', 'Thumbs.db', 'node_modules'
$clusters = @{
    documents  = '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.md', '.csv', '.odt', '.rtf'
    images     = '.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.heic', '.bmp', '.psd', '.ai'
    video      = '.mp4', '.mov', '.mkv', '.avi', '.webm'
    audio      = '.mp3', '.wav', '.m4a', '.flac', '.ogg'
    code       = '.js', '.ts', '.py', '.ps1', '.json', '.html', '.css', '.sh', '.yml', '.yaml', '.sql'
    installers = '.exe', '.msi', '.msix', '.appx'
    archives   = '.zip', '.7z', '.rar', '.tar', '.gz'
}
function Get-Cluster([string]$ext) {
    foreach ($k in $clusters.Keys) { if ($clusters[$k] -contains $ext) { return $k } }
    return 'other'
}
function Get-AgeBucket([datetime]$t) {
    $d = ((Get-Date) - $t).TotalDays
    if ($d -le 7) { return '0-7d' } elseif ($d -le 30) { return '8-30d' } elseif ($d -le 180) { return '31-180d' } else { return '180d+' }
}
function Get-FolderColor([string]$dir) {
    $ini = Join-Path $dir 'desktop.ini'
    if (-not (Test-Path -LiteralPath $ini)) { return $null }
    $text = Get-Content -LiteralPath $ini -Raw -Force -ErrorAction SilentlyContinue
    if ($text -match '(?ms)^\[FolderColors\].*?^Index=(\d+)') { $i = [int]$Matches[1]; if ($cats.ContainsKey($i)) { return $cats[$i] } else { return "index $i" } }
    return $null
}

# Cloud roots: OneDrive from its env vars, Google Drive and Dropbox from their usual markers.
$cloud = New-Object System.Collections.ArrayList
foreach ($e in 'OneDrive', 'OneDriveConsumer', 'OneDriveCommercial') { $v = [Environment]::GetEnvironmentVariable($e); if ($v -and (Test-Path -LiteralPath $v)) { [void]$cloud.Add(@{ kind = 'OneDrive'; path = $v }) } }
foreach ($d in Get-PSDrive -PSProvider FileSystem) { if ($d.Description -match 'Google Drive') { [void]$cloud.Add(@{ kind = 'Google Drive'; path = $d.Root }) } }
$dbInfo = Join-Path $env:APPDATA 'Dropbox\info.json'
if (Test-Path -LiteralPath $dbInfo) { try { $j = Get-Content -LiteralPath $dbInfo -Raw | ConvertFrom-Json; foreach ($p in $j.PSObject.Properties) { if ($p.Value.path) { [void]$cloud.Add(@{ kind = 'Dropbox'; path = $p.Value.path }) } } } catch {} }
$cloudPaths = @($cloud | ForEach-Object { $_.path.TrimEnd('\') })

$result = [ordered]@{
    generated  = (Get-Date).ToString('s')
    user       = $env:USERNAME
    cloudRoots = @($cloud)
    storageSense = $null
    roots      = New-Object System.Collections.ArrayList
}

$ss = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
if (Test-Path $ss) {
    $p = Get-ItemProperty $ss
    $result.storageSense = [ordered]@{ enabled = [bool]$p.'01'; cadence = $p.'2048'; downloadsCleanup = [bool]$p.'32'; downloadsDays = $p.'512' }
}

foreach ($root in $Roots) {
    $root = $root.TrimEnd('\'); if ($root -match ':$') { $root += '\' }
    $entry = [ordered]@{ path = $root; exists = (Test-Path -LiteralPath $root -PathType Container) }
    if (-not $entry.exists) { [void]$result.roots.Add($entry); continue }

    $items = @(Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue | Where-Object { $skipNames -notcontains $_.Name -and -not ($_.Attributes -band [IO.FileAttributes]::System -and $_.Attributes -band [IO.FileAttributes]::Hidden) })
    $folders = @($items | Where-Object PSIsContainer); $files = @($items | Where-Object { -not $_.PSIsContainer })
    $entry.folderCount = $folders.Count; $entry.fileCount = $files.Count
    $entry.fileBytes = ($files | Measure-Object Length -Sum).Sum
    $ages = @{}; $clus = @{}
    foreach ($f in $files) { $b = Get-AgeBucket $f.LastWriteTime; $ages[$b] = 1 + $ages[$b]; $c = Get-Cluster $f.Extension.ToLowerInvariant(); $clus[$c] = 1 + $clus[$c] }
    $entry.fileAges = $ages; $entry.fileClusters = $clus
    $entry.hasReadme = [bool](Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(00_README|README|CLAUDE)\.md$' })
    $entry.folderColor = Get-FolderColor $root

    $list = New-Object System.Collections.ArrayList
    foreach ($i in ($items | Sort-Object { -not $_.PSIsContainer }, Name | Select-Object -First $MaxEntries)) {
        $e = [ordered]@{ name = $i.Name; type = $(if ($i.PSIsContainer) { 'folder' } else { 'file' }); modified = $i.LastWriteTime.ToString('yyyy-MM-dd') }
        if ($i.PSIsContainer) {
            $kids = @(Get-ChildItem -LiteralPath $i.FullName -Force -ErrorAction SilentlyContinue)
            $e.children = $kids.Count
            $newest = ($kids | Measure-Object LastWriteTime -Maximum).Maximum
            $e.newest = $(if ($newest) { $newest.ToString('yyyy-MM-dd') } else { $null })   # newest direct child; the folder's own date says little
            $e.isGitRepo = Test-Path -LiteralPath (Join-Path $i.FullName '.git')
            $e.isCloudRoot = $cloudPaths -contains $i.FullName.TrimEnd('\')
            $e.hasReadme = [bool]($kids | Where-Object { $_.Name -match '^(00_README|README|CLAUDE)\.md$' })
            $e.folderColor = Get-FolderColor $i.FullName
        } else {
            $e.bytes = $i.Length; $e.cluster = Get-Cluster $i.Extension.ToLowerInvariant()
            if ($i.BaseName -match ' \(\d+\)$') { $e.duplicateSuffix = $true }
        }
        [void]$list.Add($e)
    }
    $entry.entries = $list
    $entry.truncated = ($items.Count -gt $MaxEntries)
    [void]$result.roots.Add($entry)
}

$result | ConvertTo-Json -Depth 6
