<#
.SYNOPSIS
    Build the right-click "Folder Color" menu from categories.json.

.DESCRIPTION
    Writes one cascading verb under HKCU\Software\Classes\Directory\shell, so it
    needs no admin rights and applies to the current user only. Safe to re-run:
    the key is rebuilt from scratch every time, which is also how you apply edits
    to categories.json or a move of this folder (the menu holds absolute paths).

    Explorer shows at most 16 entries per cascade, so categories sit one level
    down, under the groups listed in categories.json:

        Folder Color > Work > Clients (Light Blue)
                     > Personal > ...
                     > Status > ...
                     > Reset to default
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$MaxPerCascade = 16   # Explorer's hard limit for a cascading menu

$root       = $PSScriptRoot
$iclPath    = Join-Path $root 'assets\Windows_11_coloured_icons.icl'
$engine     = Join-Path $root 'Set-FolderColor.ps1'
$launcher   = Join-Path $root 'Set-FolderColor.vbs'     # starts the engine with no console window
$configPath = Join-Path $root 'categories.json'
$menuKey    = 'HKCU:\Software\Classes\Directory\shell\FolderColors'

foreach ($f in $iclPath, $engine, $launcher, $configPath) {
    if (-not (Test-Path -LiteralPath $f)) { throw "Missing file: $f" }
}
# Files downloaded as a zip carry a mark-of-the-web that blocks scripts; clear it.
Unblock-File -LiteralPath $iclPath, $engine, $launcher, $configPath

$cfg    = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$cats   = @($cfg.categories)          # array order = menu order inside each group
$groups = @($cfg.groups)
if ($cats.Count -ne 20) { throw "categories.json must list exactly 20 categories (found $($cats.Count))" }
if ((($cats | ForEach-Object { $_.index } | Sort-Object) -join ',') -ne ((0..19) -join ',')) { throw 'categories.json indices must be exactly 0..19, each once' }
if (@($cats | ForEach-Object { $_.category } | Select-Object -Unique).Count -ne 20) { throw 'categories.json category names must be unique' }
if (@($cats | ForEach-Object { $_.color }    | Select-Object -Unique).Count -ne 20) { throw 'categories.json colour names must be unique' }
if ($groups.Count -eq 0) { throw 'categories.json needs a "groups" list' }
if ($groups.Count + 1 -gt $MaxPerCascade) { throw "At most $($MaxPerCascade - 1) groups fit in the menu (found $($groups.Count))" }
foreach ($c in $cats) {
    if ($groups -notcontains $c.group) { throw "Category '$($c.category)' has group '$($c.group)', which is not in the groups list" }
}
foreach ($g in $groups) {
    $n = @($cats | Where-Object { $_.group -eq $g }).Count
    if ($n -gt $MaxPerCascade) { throw "Group '$g' has $n categories; Explorer shows at most $MaxPerCascade per cascade" }
}

$menuLabel   = if ($cfg.menuLabel)   { $cfg.menuLabel }   else { 'Folder Color' }
$labelFormat = if ($cfg.labelFormat) { $cfg.labelFormat } else { '{category} ({color})' }

function Format-Label($c) { $labelFormat.Replace('{category}', $c.category).Replace('{color}', $c.color) }
function Safe-Name([string]$s) { $s -replace '[^A-Za-z0-9]', '' }
function Menu-Text([string]$s) { $s -replace '&', '&&' }      # a lone & would become an accelerator

# A cascade is a key with MUIVerb + Icon + an empty SubCommands, whose own shell subkey holds the entries.
function New-Cascade([string]$key, [string]$label, [string]$icon) {
    $null = New-Item "$key\shell" -Force
    Set-ItemProperty $key -Name 'MUIVerb'     -Value (Menu-Text $label)
    Set-ItemProperty $key -Name 'Icon'        -Value $icon
    Set-ItemProperty $key -Name 'SubCommands' -Value ''
}

$engineCall = "wscript.exe //B //Nologo `"$launcher`" -Path `"%1`" -ShowErrors"

if (Test-Path $menuKey) { Remove-Item $menuKey -Recurse -Force }
New-Cascade $menuKey $menuLabel "$iclPath,13"

$gi = 0
foreach ($g in $groups) {
    $gi++
    $members  = @($cats | Where-Object { $_.group -eq $g })
    $groupKey = "$menuKey\shell\$('{0:D2}' -f $gi)-$(Safe-Name $g)"
    New-Cascade $groupKey $g "$iclPath,$($members[0].index)"          # group wears its first member's colour
    $ci = 0
    foreach ($c in $members) {
        $ci++
        $sub  = "$groupKey\shell\$('{0:D2}' -f $ci)-$(Safe-Name $c.category)"   # entries sort by key name
        $null = New-Item "$sub\command" -Force
        Set-ItemProperty $sub -Name 'MUIVerb' -Value (Menu-Text (Format-Label $c))
        Set-ItemProperty $sub -Name 'Icon'    -Value "$iclPath,$($c.index)"
        Set-ItemProperty "$sub\command" -Name '(default)' -Value "$engineCall -Index $($c.index)"
    }
}

$reset = "$menuKey\shell\99-Reset"
$null  = New-Item "$reset\command" -Force
Set-ItemProperty $reset -Name 'MUIVerb'      -Value 'Reset to default'
Set-ItemProperty $reset -Name 'CommandFlags' -Value 0x20 -Type DWord      # separator above this entry
Set-ItemProperty "$reset\command" -Name '(default)' -Value "$engineCall -Reset"

Write-Host "Installed '$menuLabel' for the current user:" -ForegroundColor Green
foreach ($g in $groups) {
    Write-Host "  $g"
    foreach ($c in @($cats | Where-Object { $_.group -eq $g })) { Write-Host ('    {0,2}  {1}' -f $c.index, (Format-Label $c)) }
}
Write-Host '  Reset to default'
Write-Host 'Right-click any folder to use it. Edit categories.json and re-run this script to change the menu.'
