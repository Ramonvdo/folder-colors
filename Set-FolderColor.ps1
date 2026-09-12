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
# Explorer reads folder properties from desktop.ini sections named by property-set GUID:
# "PropN=31,value" where N is the property id and 31 is VT_LPWSTR. Multi-values are ;-separated.
$tagSlots = @(
    @{ Section = '{F29F85E0-4FF9-1068-AB91-08002B27B3D9}'; Key = 'Prop5' },   # System.Keywords  (Tags column)
    @{ Section = '{D5CDD502-2E9C-101B-9397-08002B2CF9AE}'; Key = 'Prop2' }    # System.Category  (Categories column)
)

function Get-Config {
    if (-not (Test-Path -LiteralPath $configPath)) { throw "categories.json not found at $configPath" }
    return Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
}
function Get-Categories {
    $cats = @((Get-Config).categories | Sort-Object index)
    foreach ($c in $cats) {
        # Names end up as desktop.ini values and ;-separated tags, so they must stay plain text.
        foreach ($v in @($c.category, $c.color)) {
            if ($v -match '[\x00-\x1f\[\];=]') { throw "categories.json: '$v' contains a character that cannot go into desktop.ini ([ ] ; = or a control character)" }
        }
    }
    return $cats
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
        if ($ini[$name].Count -eq 0) { continue }
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

# Add or remove one value in a ;-separated folder property, leaving the other values alone.
function Edit-TagValue($ini, [string]$section, [string]$key, [string]$remove, [string]$add) {
    $values = New-Object System.Collections.ArrayList
    $current = Get-IniValue $ini $section $key
    if ($current -match '^\d+,(.*)$') { foreach ($v in $Matches[1] -split ';') { if ($v.Trim()) { [void]$values.Add($v.Trim()) } } }
    if ($remove) { $values = New-Object System.Collections.ArrayList (,@($values | Where-Object { $_ -ne $remove })) }
    if ($add -and ($values -notcontains $add)) { [void]$values.Add($add) }
    if (-not $ini.Contains($section)) { $ini[$section] = New-Object System.Collections.ArrayList }
    Remove-IniKeys $ini $section @($key)
    if ($values.Count -gt 0) { [void]$ini[$section].Add("$key=31,$($values -join ';')") }
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

# Apply the icon through the shell's own folder-customisation API (what Properties > Customize
# uses). Writing desktop.ini alone leaves open Explorer windows showing the old icon until they
# are closed; this call also invalidates the cached folder icon, so windows repaint at once.
function Set-ShellFolderIcon([string]$folder, [string]$iconFile, [int]$iconIndex) {
    if (-not ('FolderColors.Shell' -as [type])) {
        Add-Type -Namespace FolderColors -Name Shell -MemberDefinition @'
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct SHFOLDERCUSTOMSETTINGS {
    public uint dwSize; public uint dwMask; public IntPtr pvid;
    public string pszWebViewTemplate; public uint cchWebViewTemplate; public string pszWebViewTemplateVersion;
    public string pszInfoTip; public uint cchInfoTip; public IntPtr pclsid; public uint dwFlags;
    public string pszIconFile; public uint cchIconFile; public int iIconIndex;
    public string pszLogo; public uint cchLogo;
}
[DllImport("shell32.dll", CharSet = CharSet.Unicode)]
public static extern int SHGetSetFolderCustomSettings(ref SHFOLDERCUSTOMSETTINGS pfcs, string pszPath, uint dwReadWrite);
[DllImport("shell32.dll", CharSet = CharSet.Unicode)]
public static extern void SHChangeNotify(int wEventId, int uFlags, string dwItem1, IntPtr dwItem2);
'@
    }
    $fcs = New-Object FolderColors.Shell+SHFOLDERCUSTOMSETTINGS
    $fcs.dwSize = [Runtime.InteropServices.Marshal]::SizeOf($fcs)
    $fcs.dwMask = 0x10                     # FCSM_ICONFILE
    $fcs.pszIconFile = $iconFile           # empty string = no custom icon
    $fcs.iIconIndex = $iconIndex
    $hr = [FolderColors.Shell]::SHGetSetFolderCustomSettings([ref]$fcs, $folder, 2)   # FCS_FORCEWRITE
    if ($hr -ne 0) { throw ("Windows refused to update the folder icon (HRESULT 0x{0:X8})" -f $hr) }
    $SHCNE_UPDATEITEM = 0x2000; $SHCNF_PATHW = 0x0005; $SHCNF_FLUSH = 0x1000
    [FolderColors.Shell]::SHChangeNotify($SHCNE_UPDATEITEM, $SHCNF_PATHW -bor $SHCNF_FLUSH, $folder, [IntPtr]::Zero)
}

# "file,index" as stored in desktop.ini -> file and index
function Split-IconResource([string]$value) {
    if ($value -match '^(.*),(-?\d+)\s*$') { return @($Matches[1].Trim(), [int]$Matches[2]) }
    return @($value.Trim(), 0)
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
        $ourTag = Get-IniValue $ini $ourSection 'Tag'
        if ($ourTag) { foreach ($t in $tagSlots) { Edit-TagValue $ini $t.Section $t.Key -remove $ourTag -add '' } }
        $ini.Remove($ourSection)

        $prevIcon = Get-IniValue $ini $shellSection 'IconResource'
        if ($prevIcon) { $file, $idx = Split-IconResource $prevIcon; Set-ShellFolderIcon $folder $file $idx }
        else           { Set-ShellFolderIcon $folder '' 0 }

        if (Test-IniEmpty $ini) {
            Remove-Item -LiteralPath $iniFile -Force
        } else {
            Write-Ini $iniFile $ini      # other customisations stay
        }
        $dir = Get-Item -LiteralPath $folder -Force
        if ($prevAttrs) { $dir.Attributes = [IO.FileAttributes]$prevAttrs }
        else { $dir.Attributes = $dir.Attributes -band (-bnot ([IO.FileAttributes]::ReadOnly -bor [IO.FileAttributes]::System)) }
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

        # The category name also goes into the folder's Tags and Categories (Explorer columns, Group by).
        $ourTag = Get-IniValue $ini $ourSection 'Tag'
        $writeTags = (Get-Config).writeTags
        if ($null -eq $writeTags -or $writeTags) {
            foreach ($t in $tagSlots) { Edit-TagValue $ini $t.Section $t.Key -remove $ourTag -add $target.category }
            Remove-IniKeys $ini $ourSection @('Tag')
            [void]$ini[$ourSection].Add("Tag=$($target.category)")
        }
        Write-Ini $iniFile $ini

        # Explorer only honours desktop.ini on folders flagged ReadOnly or System.
        $dir = Get-Item -LiteralPath $folder -Force
        $dir.Attributes = $dir.Attributes -bor [IO.FileAttributes]::ReadOnly -bor [IO.FileAttributes]::System

        Set-ShellFolderIcon $folder $iclPath $target.index
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
