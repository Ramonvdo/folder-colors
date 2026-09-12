<#
.SYNOPSIS
    Palette popup: pick a category for one folder.

.DESCRIPTION
    Opened by the right-click "Folder Color..." entry. Shows the 20 coloured folders from
    categories.json, grouped, at the mouse position. Click a tile to apply it, "Reset to
    default" to remove the colour, Esc or clicking elsewhere to cancel. The tile matching
    the folder's current colour is outlined. Applying goes through Set-FolderColor.ps1.

.EXAMPLE
    .\Pick-FolderColor.ps1 -Path 'D:\Clients\Acme'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Path,
    [switch]$ShowErrors,
    [string]$At          # "x,y" screen position instead of the cursor (used for screenshots)
)

$ErrorActionPreference = 'Stop'
$engine  = Join-Path $PSScriptRoot 'Set-FolderColor.ps1'
$iclPath = Join-Path $PSScriptRoot 'assets\Windows_11_coloured_icons.icl'

try {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    if (-not ('FolderColors.Picker' -as [type])) {
        Add-Type -Namespace FolderColors -Name Picker -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
[DllImport("shell32.dll", CharSet = CharSet.Unicode)]
public static extern int SHDefExtractIcon(string pszIconFile, int iIndex, uint uFlags, out IntPtr phiconLarge, out IntPtr phiconSmall, uint nIconSize);
[DllImport("user32.dll")] public static extern bool DestroyIcon(IntPtr h);
[DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value, int size);
'@
    }
    [void][FolderColors.Picker]::SetProcessDPIAware()

    $Path = $Path.Trim('"')
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { throw "Not a folder: $Path" }
    $cfg     = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'categories.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $current = & $engine -Path $Path -Get
    $groups  = @($cfg.groups); if ($groups.Count -eq 0) { $groups = @('') }

    # Scale everything with the monitor's DPI so the popup is crisp at 125 % and 150 %.
    $gfx = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero); $scale = $gfx.DpiX / 96; $gfx.Dispose()
    function S([double]$v) { return [int][math]::Round($v * $scale) }

    $dark = $true
    try { $dark = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -ErrorAction Stop).AppsUseLightTheme -eq 0 } catch {}
    if ($dark) { $bg = [System.Drawing.Color]::FromArgb(32, 32, 32);   $fg = [System.Drawing.Color]::White;                    $tile = [System.Drawing.Color]::FromArgb(45, 45, 45);   $hover = [System.Drawing.Color]::FromArgb(62, 62, 62);   $muted = [System.Drawing.Color]::FromArgb(160, 160, 160) }
    else       { $bg = [System.Drawing.Color]::FromArgb(243, 243, 243); $fg = [System.Drawing.Color]::FromArgb(27, 27, 27); $tile = [System.Drawing.Color]::FromArgb(251, 251, 251); $hover = [System.Drawing.Color]::FromArgb(230, 230, 230); $muted = [System.Drawing.Color]::FromArgb(96, 96, 96) }
    $accent = [System.Drawing.Color]::FromArgb(0, 120, 212)

    function Get-FolderIcon([int]$index, [int]$px) {
        $hL = [IntPtr]::Zero; $hS = [IntPtr]::Zero
        $null = [FolderColors.Picker]::SHDefExtractIcon($iclPath, $index, 0, [ref]$hL, [ref]$hS, [uint32]$px)
        $bmp = ([System.Drawing.Icon]::FromHandle($hL)).ToBitmap()
        [void][FolderColors.Picker]::DestroyIcon($hL)
        return $bmp
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$(if ($cfg.menuLabel) { $cfg.menuLabel } else { 'Folder Color' })  -  $(Split-Path $Path -Leaf)"
    $form.FormBorderStyle = 'FixedToolWindow'; $form.TopMost = $true; $form.ShowInTaskbar = $false
    $form.StartPosition = 'Manual'; $form.AutoSize = $true; $form.AutoSizeMode = 'GrowAndShrink'
    $form.BackColor = $bg; $form.ForeColor = $fg; $form.KeyPreview = $true
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $form.Padding = New-Object System.Windows.Forms.Padding((S 10), (S 6), (S 10), (S 10))

    $root = New-Object System.Windows.Forms.FlowLayoutPanel
    $root.FlowDirection = 'TopDown'; $root.WrapContents = $false; $root.AutoSize = $true; $root.AutoSizeMode = 'GrowAndShrink'
    $form.Controls.Add($root)

    $tips = New-Object System.Windows.Forms.ToolTip
    $script:busy = $false
    $columns = 5
    $tileW = S 104; $tileH = S 84; $iconPx = S 40

    function Apply([scriptblock]$action) {
        $script:busy = $true
        try { & $action } catch { [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Folder Colors', 'OK', 'Error') }
        $form.Close()
    }

    foreach ($g in $groups) {
        $members = @($cfg.categories | Where-Object { -not $g -or $_.group -eq $g })
        if ($members.Count -eq 0) { continue }
        if ($g) {
            $head = New-Object System.Windows.Forms.Label
            $head.Text = $g.ToUpperInvariant(); $head.ForeColor = $accent; $head.AutoSize = $true
            $head.Font = New-Object System.Drawing.Font('Segoe UI', 8.5, [System.Drawing.FontStyle]::Bold)
            $head.Margin = New-Object System.Windows.Forms.Padding((S 4), (S 8), 0, (S 2))
            $root.Controls.Add($head)
        }
        $row = New-Object System.Windows.Forms.FlowLayoutPanel
        $row.AutoSize = $true; $row.AutoSizeMode = 'GrowAndShrink'; $row.WrapContents = $true
        $row.MaximumSize = New-Object System.Drawing.Size(($columns * ($tileW + (S 6))), 0)
        $row.Margin = New-Object System.Windows.Forms.Padding(0)
        foreach ($c in $members) {
            $b = New-Object System.Windows.Forms.Button
            $b.Size = New-Object System.Drawing.Size($tileW, $tileH); $b.Margin = New-Object System.Windows.Forms.Padding((S 3))
            $b.FlatStyle = 'Flat'; $b.BackColor = $tile; $b.ForeColor = $fg
            $b.FlatAppearance.BorderSize = 0; $b.FlatAppearance.MouseOverBackColor = $hover
            $b.Image = Get-FolderIcon $c.index $iconPx; $b.ImageAlign = 'TopCenter'; $b.TextAlign = 'BottomCenter'
            $b.Text = $c.category; $b.UseMnemonic = $false; $b.Padding = New-Object System.Windows.Forms.Padding(0, (S 6), 0, (S 4))
            $b.Tag = [int]$c.index
            if ($current.Index -eq $c.index) { $b.FlatAppearance.BorderSize = 2; $b.FlatAppearance.BorderColor = $accent }
            $tips.SetToolTip($b, "$($c.color)`n$($c.description)")
            $b.Add_Click({ $idx = $this.Tag; Apply { & $engine -Path $Path -Index $idx | Out-Null } })
            $row.Controls.Add($b)
        }
        $root.Controls.Add($row)
    }

    $reset = New-Object System.Windows.Forms.Button
    $reset.Text = 'Reset to default'; $reset.UseMnemonic = $false; $reset.AutoSize = $true; $reset.FlatStyle = 'Flat'
    $reset.BackColor = $tile; $reset.ForeColor = $(if ($null -ne $current.Index) { $fg } else { $muted })
    $reset.FlatAppearance.BorderSize = 0; $reset.FlatAppearance.MouseOverBackColor = $hover
    $reset.Padding = New-Object System.Windows.Forms.Padding((S 10), (S 4), (S 10), (S 4))
    $reset.Margin = New-Object System.Windows.Forms.Padding((S 3), (S 12), 0, 0)
    $reset.Enabled = ($null -ne $current.Index)
    $reset.Add_Click({ Apply { & $engine -Path $Path -Reset | Out-Null } })
    $root.Controls.Add($reset)

    $form.Add_KeyDown({ if ($_.KeyCode -eq 'Escape') { $form.Close() } })
    $form.Add_Deactivate({ if (-not $script:busy) { $form.Close() } })     # clicking elsewhere cancels, like a menu

    # Place it at the cursor, kept inside the monitor's working area.
    $form.Add_HandleCreated({ if ($dark) { $on = 1; [void][FolderColors.Picker]::DwmSetWindowAttribute($form.Handle, 20, [ref]$on, 4) } })   # dark title bar
    $form.Add_Load({
        $pos = if ($At -match '^\s*(-?\d+)\s*,\s*(-?\d+)\s*$') { New-Object System.Drawing.Point([int]$Matches[1], [int]$Matches[2]) } else { [System.Windows.Forms.Cursor]::Position }
        $area = [System.Windows.Forms.Screen]::FromPoint($pos).WorkingArea
        $x = [math]::Min($pos.X, $area.Right - $form.Width); $y = [math]::Min($pos.Y, $area.Bottom - $form.Height)
        $form.Location = New-Object System.Drawing.Point([math]::Max($area.Left, $x), [math]::Max($area.Top, $y))
    })
    [void]$form.ShowDialog()
}
catch {
    if ($ShowErrors) {
        Add-Type -AssemblyName System.Windows.Forms
        [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Folder Colors', 'OK', 'Error')
        exit 1
    }
    throw
}
