<#
.SYNOPSIS
    Colour a Windows folder by category, colour name or icon index.

.DESCRIPTION
    Writes a desktop.ini that points the folder at one of the 20 icons in
    assets\Windows_11_coloured_icons.icl. The index -> colour -> category mapping
    lives in categories.json next to this script; that file is the only thing to edit.

    The colour is stored as an icon index, so renaming a category later never
    touches folders that are already coloured.

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

    # Overwrite a desktop.ini that this tool did not write (OneDrive, special folders).
    [Parameter(ParameterSetName = 'Set')]
    [Parameter(ParameterSetName = 'Reset')]
    [switch]$Force,

    # Report failures in a message box; used by the context menu, which has no console.
    [switch]$ShowErrors
)

$ErrorActionPreference = 'Stop'

$iclPath    = Join-Path $PSScriptRoot 'assets\Windows_11_coloured_icons.icl'
$configPath = Join-Path $PSScriptRoot 'categories.json'
$ourSection = '[FolderColors]'   # marks a desktop.ini as written by this tool

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

function Read-FolderState([string]$folder) {
    $ini = Join-Path $folder 'desktop.ini'
    $state = [pscustomobject]@{ Path = $folder; Index = $null; Category = $null; Color = $null; Ours = $false; HasIni = $false }
    if (-not (Test-Path -LiteralPath $ini)) { return $state }
    $state.HasIni = $true
    $text = Get-Content -LiteralPath $ini -Raw -Force
    if ($text -notmatch [regex]::Escape($ourSection)) { return $state }
    $state.Ours = $true
    if ($text -match '(?m)^Index=(\d+)\s*$') {
        $state.Index = [int]$Matches[1]
        $match = Get-Categories | Where-Object { $_.index -eq $state.Index } | Select-Object -First 1
        if ($match) { $state.Category = $match.category; $state.Color = $match.color }
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
        $s = Read-FolderState $folder
        if ($s.HasIni -and -not $s.Ours) { $s.Category = '(desktop.ini not written by FolderColors)' }
        $s | Select-Object Path, Index, Category, Color
    }

    'Reset' {
        $folder = Resolve-Folder $Path
        $s = Read-FolderState $folder
        if (-not $s.HasIni) { Write-Output "No colour set on $folder"; return }
        if (-not $s.Ours -and -not $Force) { throw "$folder has a desktop.ini this tool did not write. Re-run with -Force to delete it anyway." }
        $ini = Join-Path $folder 'desktop.ini'
        Remove-Item -LiteralPath $ini -Force
        $dir = Get-Item -LiteralPath $folder -Force
        $dir.Attributes = $dir.Attributes -band (-bnot ([IO.FileAttributes]::ReadOnly -bor [IO.FileAttributes]::System))
        Send-ShellNotify $folder
        Write-Output "Reset $folder to the default folder icon"
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

        $folder = Resolve-Folder $Path
        $s = Read-FolderState $folder
        if ($s.HasIni -and -not $s.Ours -and -not $Force) {
            throw "$folder already has a desktop.ini this tool did not write (OneDrive or a special folder). Re-run with -Force to overwrite it."
        }

        $ini = Join-Path $folder 'desktop.ini'
        $content = @"
[.ShellClassInfo]
IconResource=$iclPath,$($target.index)

$ourSection
Index=$($target.index)
"@
        # Unicode (UTF-16 LE) keeps accented paths intact for Explorer.
        Set-Content -LiteralPath $ini -Value $content -Encoding Unicode -Force
        $iniItem = Get-Item -LiteralPath $ini -Force
        $iniItem.Attributes = $iniItem.Attributes -bor [IO.FileAttributes]::Hidden -bor [IO.FileAttributes]::System

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
