<#
.SYNOPSIS
    Colour a Windows folder by category, colour name or icon index.

.DESCRIPTION
    Writes a desktop.ini that points the folder at one of the 20 icons in
    assets\Windows_11_coloured_icons.icl. The index -> colour -> category mapping
    lives in categories.json next to this script; that file is the only thing to edit.

    The colour is stored as an icon index, so renaming a category later never
    touches folders that are already coloured.

    An existing desktop.ini (folder-type template, folder picture, a custom icon set
    through Properties) is kept: only the icon lines change, and the previous icon
    is remembered so -Reset puts it back.

.EXAMPLE
    .\Set-FolderColor.ps1 -List
    .\Set-FolderColor.ps1 -Path 'D:\Clients\Acme' -Category Clients
    .\Set-FolderColor.ps1 -Path 'D:\Clients\Acme' -Color 'Light Blue'
    .\Set-FolderColor.ps1 -Path 'D:\Clients\Acme' -Index 12
    .\Set-FolderColor.ps1 -Path 'D:\Clients\Acme' -Get
    .\Set-FolderColor.ps1 -Path 'D:\Clients\Acme' -Reset
#>
[CmdletBinding(DefaultParameterSetName = 'Set')]
param(
    [Parameter(ParameterSetName = 'List', Mandatory = $true)]
    [switch]$List,

    [Parameter(ParameterSetName = 'Get', Mandatory = $true)]
    [switch]$Get,

    [Parameter(ParameterSetName = 'Reset', Mandatory = $true)]
    [switch]$Reset,

    [Parameter(ParameterSetName = 'Get',   Mandatory = $true, Position = 0)]
    [Parameter(ParameterSetName = 'Reset', Mandatory = $true, Position = 0)]
    [Parameter(ParameterSetName = 'Set',   Mandatory = $true, Position = 0)]
    [string]$Path,

    [Parameter(ParameterSetName = 'Set')]
    [string]$Category,

    [Parameter(ParameterSetName = 'Set')]
    [string]$Color,

    [Parameter(ParameterSetName = 'Set')]
    [int]$Index = -1,

    # Report failures in a message box; used by the context menu, which has no console.
    [switch]$ShowErrors
)

$ErrorActionPreference = 'Stop'

$iclPath    = Join-Path $PSScriptRoot 'assets\Windows_11_coloured_icons.icl'
$configPath = Join-Path $PSScriptRoot 'categories.json'
$shellSection = '.ShellClassInfo'
$ourSection   = 'FolderColors'      # our own section; its presence marks a folder as coloured by this tool
$iconKeys     = 'IconResource', 'IconFile', 'IconIndex'

function Get-Categories {
    if (-not (Test-Path -LiteralPath $configPath)) { throw "categories.json not found at $configPath" }
    $cfg = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    return @($cfg.categories | Sort-Object index)
}

# "Light Blue", "light-blue" and "LightBlue" all compare equal.
function Normalize([string]$s) { return ($s -replace '[^A-Za-z0-9]', '').ToLowerInvariant() }

function Resolve-Folder([string]$p) {
    $p = $p.Trim('"')
    if (-not (Test-Path -LiteralPath $p -PathType Container)) { throw "Not a folder: $p" }
    $full = (Get-Item -LiteralPath $p -Force).FullName.TrimEnd('\')
    if ($full -match ':$') { $full += '\' }   # keep a drive root as C:\
    return $full
}

# --- desktop.ini as an ordered list of sections, each an ordered list of lines ------------

function Read-Ini([string]$file) {
    $ini = [ordered]@{}
    if (-not (Test-Path -LiteralPath $file)) { return $ini }
    $current = ''
    foreach ($line in ((Get-Content -LiteralPath $file -Raw -Force) -split "`r?`n")) {
        if ($line -match '^\s*\[(.+?)\]\s*$') {
            $current = $Matches[1]
            if (-not $ini.Contains($current)) { $ini[$current] = New-Object System.Collections.ArrayList }
        } elseif ($line.Trim()) {
            if (-not $ini.Contains($current)) { $ini[$current] = New-Object System.Collections.ArrayList }
            [void]$ini[$current].Add($line)
        }
    }
    return $ini
}

function Write-Ini([string]$file, $ini) {
    $out = New-Object System.Collections.ArrayList
    foreach ($name in $ini.Keys) {
        if ($ini[$name].Count -eq 0 -and $name -ne $shellSection) { continue }
        if ($name) { [void]$out.Add("[$name]") }
        foreach ($l in $ini[$name]) { [void]$out.Add($l) }
    }
    # Unicode (UTF-16 LE) keeps accented paths intact for Explorer.
    Set-Content -LiteralPath $file -Value ($out -join "`r`n") -Encoding Unicode -Force
    $item = Get-Item -LiteralPath $file -Force
    $item.Attributes = $item.Attributes -bor [IO.FileAttributes]::Hidden -bor [IO.FileAttributes]::System
}

function Get-IniValue($ini, [string]$section, [string]$key) {
    if (-not $ini.Contains($section)) { return $null }
    foreach ($l in $ini[$section]) { if ($l -match "^\s*$([regex]::Escape($key))\s*=(.*)$") { return $Matches[1].Trim() } }
    return $null
}

function Remove-IniKeys($ini, [string]$section, [string[]]$keys) {
    if (-not $ini.Contains($section)) { return }
    $pattern = '^\s*(' + (($keys | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\s*='
    $keep = @($ini[$section] | Where-Object { $_ -notmatch $pattern })
    $ini[$section] = New-Object System.Collections.ArrayList
    foreach ($l in $keep) { [void]$ini[$section].Add($l) }
}

function Test-IniEmpty($ini) {
    foreach ($name in $ini.Keys) { if ($ini[$name].Count -gt 0) { return $false } }
    return $true
}

# --- folder state ----------------------------------------------------------------------

function Read-FolderState([string]$folder) {
    $ini = Read-Ini (Join-Path $folder 'desktop.ini')
    $state = [pscustomobject]@{ Path = $folder; Index = $null; Category = $null; Color = $null; Ours = $ini.Contains($ourSection) }
    if ($state.Ours) {
        $idx = Get-IniValue $ini $ourSection 'Index'
        if ($idx -match '^\d+$') {
            $state.Index = [int]$idx
            $match = Get-Categories | Where-Object { $_.index -eq $state.Index } | Select-Object -First 1
            if ($match) { $state.Category = $match.category; $state.Color = $match.color }
        }
    }
    return $state
}

# Tell Explorer the folder changed so the icon repaints now instead of minutes later.
function Send-ShellNotify([string]$folder) {
    if (-not ('FolderColors.Shell' -as [type])) {
        Add-Type -Namespace FolderColors -Name Shell -MemberDefinition @'
[DllImport("shell32.dll", CharSet = CharSet.Unicode)]
public static extern void SHChangeNotify(int wEventId, int uFlags, string dwItem1, IntPtr dwItem2);
'@
    }
    $SHCNE_UPDATEITEM = 0x2000; $SHCNE_UPDATEDIR = 0x1000
    $SHCNF_PATHW = 0x0005;      $SHCNF_FLUSH = 0x1000
    [FolderColors.Shell]::SHChangeNotify($SHCNE_UPDATEITEM, $SHCNF_PATHW -bor $SHCNF_FLUSH, $folder, [IntPtr]::Zero)
    $parent = Split-Path -Path $folder -Parent
    if ($parent) { [FolderColors.Shell]::SHChangeNotify($SHCNE_UPDATEDIR, $SHCNF_PATHW -bor $SHCNF_FLUSH, $parent, [IntPtr]::Zero) }
}

try {
switch ($PSCmdlet.ParameterSetName) {

    'List' {
        Get-Categories | ForEach-Object {
            [pscustomobject]@{ Index = $_.index; Color = $_.color; Category = $_.category; Description = $_.description }
        }
    }

    'Get' {
        $folder = Resolve-Folder $Path
        Read-FolderState $folder | Select-Object Path, Index, Category, Color
    }

    'Reset' {
        $folder = Resolve-Folder $Path
        $iniFile = Join-Path $folder 'desktop.ini'
        $ini = Read-Ini $iniFile
        if (-not $ini.Contains($ourSection)) { Write-Output "No colour set by Folder Colors on $folder"; return }

        # Drop our icon, put back whatever icon lines were there before us.
        Remove-IniKeys $ini $shellSection $iconKeys
        foreach ($k in $iconKeys) {
            $prev = Get-IniValue $ini $ourSection "Previous.$k"
            if ($null -ne $prev) { [void]$ini[$shellSection].Insert(0, "$k=$prev") }
        }
        $prevAttrs = Get-IniValue $ini $ourSection 'Previous.Attributes'
        $ini.Remove($ourSection)

        if (Test-IniEmpty $ini) {
            Remove-Item -LiteralPath $iniFile -Force
        } else {
            Write-Ini $iniFile $ini      # other customisations stay
        }
        $dir = Get-Item -LiteralPath $folder -Force
        if ($prevAttrs) { $dir.Attributes = [IO.FileAttributes]$prevAttrs }
        else { $dir.Attributes = $dir.Attributes -band (-bnot ([IO.FileAttributes]::ReadOnly -bor [IO.FileAttributes]::System)) }
        Send-ShellNotify $folder
        Write-Output "Reset $folder to its previous icon"
    }

    'Set' {
        $given = @(@($Category, $Color) | Where-Object { $_ })
        if ($Index -ge 0) { $given += "$Index" }
        if ($given.Count -ne 1) { throw 'Give exactly one of -Category, -Color or -Index.' }
        if (-not (Test-Path -LiteralPath $iclPath)) { throw "Icon library not found at $iclPath" }

        $cats = Get-Categories
        if ($Index -ge 0)  { $target = $cats | Where-Object { $_.index -eq $Index } }
        elseif ($Category) { $target = $cats | Where-Object { (Normalize $_.category) -eq (Normalize $Category) } }
        else               { $target = $cats | Where-Object { (Normalize $_.color)    -eq (Normalize $Color) } }
        $target = @($target) | Select-Object -First 1
        if (-not $target) {
            $valid = ($cats | ForEach-Object { "$($_.index) $($_.category) ($($_.color))" }) -join "`n  "
            throw "No match. Valid values:`n  $valid"
        }

        $folder  = Resolve-Folder $Path
        $iniFile = Join-Path $folder 'desktop.ini'
        $ini = Read-Ini $iniFile
        if (-not $ini.Contains($shellSection)) { $ini[$shellSection] = New-Object System.Collections.ArrayList }

        if (-not $ini.Contains($ourSection)) {
            # First time here: remember the icon the folder had, if any, so -Reset can restore it.
            $ini[$ourSection] = New-Object System.Collections.ArrayList
            foreach ($k in $iconKeys) {
                $prev = Get-IniValue $ini $shellSection $k
                if ($null -ne $prev) { [void]$ini[$ourSection].Add("Previous.$k=$prev") }
            }
            [void]$ini[$ourSection].Add("Previous.Attributes=$((Get-Item -LiteralPath $folder -Force).Attributes)")
        }
        Remove-IniKeys $ini $shellSection $iconKeys
        [void]$ini[$shellSection].Insert(0, "IconResource=$iclPath,$($target.index)")
        Remove-IniKeys $ini $ourSection @('Index')
        [void]$ini[$ourSection].Insert(0, "Index=$($target.index)")
        Write-Ini $iniFile $ini

        # Explorer only honours desktop.ini on folders flagged ReadOnly or System.
        $dir = Get-Item -LiteralPath $folder -Force
        $dir.Attributes = $dir.Attributes -bor [IO.FileAttributes]::ReadOnly -bor [IO.FileAttributes]::System

        Send-ShellNotify $folder
        Write-Output "Set $folder -> $($target.index) $($target.category) ($($target.color))"
    }
}
}
catch {
    if ($ShowErrors) {
        Add-Type -AssemblyName System.Windows.Forms
        [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Folder Colors', 'OK', 'Error')
        exit 1
    }
    throw
}
