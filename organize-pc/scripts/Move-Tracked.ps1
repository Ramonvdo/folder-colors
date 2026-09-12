<#
.SYNOPSIS
    Move files and folders from a plan, with a log that makes every batch reversible.

.DESCRIPTION
    The only thing in organize-pc that moves anything. A plan is a JSON array of
    { "from": "<path>", "to": "<new full path>" }. Without -Apply the plan is checked and
    printed; with -Apply each move runs, refusing to overwrite, and is appended to
    %USERPROFILE%\.folder-colors\organize-log.jsonl with a batch id. -Undo reverses the
    most recent batch (or -Batch <id>) in reverse order. -List shows the batches.

.EXAMPLE
    .\Move-Tracked.ps1 -Plan moves.json            # dry run
    .\Move-Tracked.ps1 -Plan moves.json -Apply
    .\Move-Tracked.ps1 -List
    .\Move-Tracked.ps1 -Undo
    .\Move-Tracked.ps1 -Undo -Batch 20260912-101500
#>
[CmdletBinding(DefaultParameterSetName = 'Plan')]
param(
    [Parameter(ParameterSetName = 'Plan', Mandatory = $true)][string]$Plan,
    [Parameter(ParameterSetName = 'Plan')][switch]$Apply,
    [Parameter(ParameterSetName = 'Undo', Mandatory = $true)][switch]$Undo,
    [Parameter(ParameterSetName = 'Undo')][string]$Batch,
    [Parameter(ParameterSetName = 'List', Mandatory = $true)][switch]$List
)

$ErrorActionPreference = 'Stop'
$logDir = Join-Path $env:USERPROFILE '.folder-colors'
$logFile = Join-Path $logDir 'organize-log.jsonl'

function Read-Log {
    if (-not (Test-Path -LiteralPath $logFile)) { return @() }
    return @(Get-Content -LiteralPath $logFile -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
}
function Write-LogLine($obj) {
    if (-not (Test-Path -LiteralPath $logDir)) { $null = New-Item -ItemType Directory -Path $logDir }
    Add-Content -LiteralPath $logFile -Value ($obj | ConvertTo-Json -Compress) -Encoding UTF8
}
function Invoke-Move([string]$from, [string]$to) {
    if (-not (Test-Path -LiteralPath $from)) { throw "Source missing: $from" }
    if (Test-Path -LiteralPath $to) { throw "Destination exists, refusing to overwrite: $to" }
    $parent = Split-Path -Path $to -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
    Move-Item -LiteralPath $from -Destination $to
}

switch ($PSCmdlet.ParameterSetName) {

    'List' {
        Read-Log | Group-Object batch | ForEach-Object {
            [pscustomobject]@{ Batch = $_.Name; When = $_.Group[0].when; Moves = @($_.Group | Where-Object op -eq 'move').Count; Undone = @($_.Group | Where-Object op -eq 'undo').Count }
        }
    }

    'Plan' {
        # PowerShell 5.1 hands a JSON array back as one object; foreach is what unrolls it reliably.
        $moves = @(); foreach ($m in (ConvertFrom-Json -InputObject (Get-Content -LiteralPath $Plan -Raw -Encoding UTF8))) { $moves += $m }
        if ($moves.Count -eq 0) { throw "Plan is empty: $Plan" }
        # Check everything before touching anything.
        $problems = New-Object System.Collections.ArrayList
        $seen = @{}
        foreach ($m in $moves) {
            if (-not $m.from -or -not $m.to) { [void]$problems.Add("entry without from/to: $($m | ConvertTo-Json -Compress)"); continue }
            if (-not (Test-Path -LiteralPath $m.from)) { [void]$problems.Add("source missing: $($m.from)") }
            if (Test-Path -LiteralPath $m.to) { [void]$problems.Add("destination exists: $($m.to)") }
            if ($seen.ContainsKey($m.to.ToLowerInvariant())) { [void]$problems.Add("two entries target the same path: $($m.to)") }
            $seen[$m.to.ToLowerInvariant()] = $true
            if ($m.to.TrimEnd('\').ToLowerInvariant().StartsWith($m.from.TrimEnd('\').ToLowerInvariant() + '\')) { [void]$problems.Add("destination is inside its own source: $($m.from)") }
        }
        if ($problems.Count) { throw ("Plan rejected:`n  " + ($problems -join "`n  ")) }

        foreach ($m in $moves) { Write-Output $m.from; Write-Output "    -> $($m.to)" }
        if (-not $Apply) { Write-Output "Dry run: $($moves.Count) move(s) checked, nothing moved. Re-run with -Apply."; return }

        $batch = (Get-Date).ToString('yyyyMMdd-HHmmss')
        $done = 0
        foreach ($m in $moves) {
            Invoke-Move $m.from $m.to
            Write-LogLine ([ordered]@{ batch = $batch; when = (Get-Date).ToString('s'); op = 'move'; from = $m.from; to = $m.to })
            $done++
        }
        Write-Output "Applied $done move(s) as batch $batch. Undo with: Move-Tracked.ps1 -Undo -Batch $batch"
    }

    'Undo' {
        $log = Read-Log
        if (-not $log) { throw 'Nothing to undo: the log is empty.' }
        if (-not $Batch) { $Batch = ($log | Where-Object op -eq 'move' | Select-Object -Last 1).batch }
        $entries = @($log | Where-Object { $_.batch -eq $Batch -and $_.op -eq 'move' })
        if ($entries.Count -eq 0) { throw "No moves logged for batch $Batch" }
        $alreadyUndone = @($log | Where-Object { $_.batch -eq $Batch -and $_.op -eq 'undo' })
        if ($alreadyUndone.Count -ge $entries.Count) { throw "Batch $Batch was already undone." }
        [array]::Reverse($entries)
        $done = 0
        foreach ($e in $entries) {
            Invoke-Move $e.to $e.from
            Write-LogLine ([ordered]@{ batch = $Batch; when = (Get-Date).ToString('s'); op = 'undo'; from = $e.to; to = $e.from })
            $done++
        }
        Write-Output "Undid $done move(s) of batch $Batch."
        # Folders the batch created are left in place; say which ones are empty now so they can be removed by hand.
        $empty = @($entries | ForEach-Object { Split-Path -Path $_.to -Parent } | Sort-Object -Unique | Where-Object { (Test-Path -LiteralPath $_) -and @(Get-ChildItem -LiteralPath $_ -Force | Where-Object Name -ne 'desktop.ini').Count -eq 0 })
        foreach ($e in $empty) { Write-Output "  left empty: $e" }
    }
}
