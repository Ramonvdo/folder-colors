<#
.SYNOPSIS
    Add the right-click "Folder Color..." entry for the current user.

.DESCRIPTION
    Writes one verb under HKCU\Software\Classes\Directory\shell, so it needs no admin
    rights and applies to the current user only. The entry opens Pick-FolderColor.ps1,
    a palette of every category in categories.json. Safe to re-run: the key is rebuilt
    from scratch, which is also how you apply a move of this folder (the registry holds
    absolute paths). Edits to categories.json need no re-run; the palette reads it live.

    Explorer caps a cascading menu at 16 entries, nested ones included, which is why
    the categories live in a palette window rather than in submenus.
#>
[CmdletBinding()]
param(
    # Also link every skill under skills\ into %USERPROFILE%\.claude\skills as a junction
    # (the developer path; the plugin route needs no links).
    [switch]$LinkSkills
)

$ErrorActionPreference = 'Stop'

$root       = $PSScriptRoot
$iclPath    = Join-Path $root 'assets\Windows_11_coloured_icons.icl'
$engine     = Join-Path $root 'Set-FolderColor.ps1'
$picker     = Join-Path $root 'Pick-FolderColor.ps1'
$launcher   = Join-Path $root 'run-hidden.vbs'      # starts a script with no console window
$configPath = Join-Path $root 'categories.json'
$menuKey    = 'HKCU:\Software\Classes\Directory\shell\FolderColors'

foreach ($f in $iclPath, $engine, $picker, $launcher, $configPath) {
    if (-not (Test-Path -LiteralPath $f)) { throw "Missing file: $f" }
}
# Files downloaded as a zip carry a mark-of-the-web that blocks scripts; clear it.
Unblock-File -LiteralPath $iclPath, $engine, $picker, $launcher, $configPath

$cfg    = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$cats   = @($cfg.categories)
$groups = @($cfg.groups)
if ($cats.Count -ne 20) { throw "categories.json must list exactly 20 categories (found $($cats.Count))" }
if ((($cats | ForEach-Object { $_.index } | Sort-Object) -join ',') -ne ((0..19) -join ',')) { throw 'categories.json indices must be exactly 0..19, each once' }
if (@($cats | ForEach-Object { $_.category } | Select-Object -Unique).Count -ne 20) { throw 'categories.json category names must be unique' }
if (@($cats | ForEach-Object { $_.color }    | Select-Object -Unique).Count -ne 20) { throw 'categories.json colour names must be unique' }
foreach ($c in $cats) {
    if ($groups.Count -gt 0 -and $groups -notcontains $c.group) { throw "Category '$($c.category)' has group '$($c.group)', which is not in the groups list" }
}

$menuLabel = if ($cfg.menuLabel) { $cfg.menuLabel } else { 'Folder Color' }

if (Test-Path $menuKey) { Remove-Item $menuKey -Recurse -Force }
$null = New-Item "$menuKey\command" -Force
Set-ItemProperty $menuKey -Name 'MUIVerb' -Value (($menuLabel -replace '&', '&&') + '...')   # a lone & would become an accelerator
Set-ItemProperty $menuKey -Name 'Icon'    -Value "$iclPath,13"
Set-ItemProperty "$menuKey\command" -Name '(default)' -Value "wscript.exe //B //Nologo `"$launcher`" `"Pick-FolderColor.ps1`" -Path `"%1`" -ShowErrors"

# Where the checkout is, for the skills: a skill directory may be a junction or a plugin-cache copy.
$stateDir = Join-Path $env:USERPROFILE '.folder-colors'
if (-not (Test-Path -LiteralPath $stateDir)) { $null = New-Item -ItemType Directory -Path $stateDir }
$cfgFile = Join-Path $stateDir 'config.json'
$existing = $null
if (Test-Path -LiteralPath $cfgFile) { try { $existing = Get-Content -LiteralPath $cfgFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $existing = $null } }
$out = [ordered]@{ root = $root; installed = (Get-Date).ToString('s') }
if ($existing -is [pscustomobject]) {   # keep keys other tools may have added (never a hashtable's own members)
    foreach ($prop in @($existing.PSObject.Properties)) { if ($prop.Name -notin 'root', 'installed', 'IsReadOnly', 'IsFixedSize', 'IsSynchronized', 'Keys', 'Values', 'SyncRoot', 'Count') { $out[$prop.Name] = $prop.Value } }
}
[IO.File]::WriteAllText($cfgFile, ($out | ConvertTo-Json), (New-Object Text.UTF8Encoding($false)))

if ($LinkSkills) {
    $skillsHome = Join-Path $env:USERPROFILE '.claude\skills'
    if (-not (Test-Path -LiteralPath $skillsHome)) { $null = New-Item -ItemType Directory -Path $skillsHome }
    foreach ($skill in Get-ChildItem -LiteralPath (Join-Path $root 'skills') -Directory) {
        $link = Join-Path $skillsHome $skill.Name
        if (Test-Path -LiteralPath $link) {
            $item = Get-Item -LiteralPath $link -Force
            if ($item.LinkType -ne 'Junction') { Write-Warning "$link exists and is not a junction; left alone."; continue }
            cmd.exe /c rmdir "$link" | Out-Null      # removes the junction only, never its target
        }
        $null = New-Item -ItemType Junction -Path $link -Target $skill.FullName
        Write-Host "  linked $link -> $($skill.FullName)"
    }
}

Write-Host "Installed '$menuLabel...' for the current user. Right-click any folder to use it." -ForegroundColor Green
foreach ($g in $groups) {
    Write-Host "  $g"
    foreach ($c in @($cats | Where-Object { $_.group -eq $g })) { Write-Host ('    {0,2}  {1} ({2})' -f $c.index, $c.category, $c.color) }
}
Write-Host 'Edit categories.json to change categories, groups or labels; the palette reads it live.'
Write-Host "Skills: install the plugin (see README) or run .\install.ps1 -LinkSkills to link skills\* into ~\.claude\skills."

