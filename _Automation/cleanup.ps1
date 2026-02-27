<#
.SYNOPSIS
    Cleanup — Archives old signals, briefs, and logs
.DESCRIPTION
    - Moves signals older than 14 days to 08_Archive/Signals/
    - Moves briefs older than 30 days to 08_Archive/Briefs/
    - Deletes log files older than 30 days
    - Safe to run daily as Step 0 of the orchestrator
#>

param(
    [switch]$DryRun,
    [int]$SignalAgeDays = 14,
    [int]$BriefAgeDays = 30,
    [int]$LogAgeDays = 30
)

$ErrorActionPreference = "Continue"
$ROOT = Split-Path -Parent $PSScriptRoot
$ARCHIVE = Join-Path $ROOT "08_Archive"
$SIGNALS_DIR = Join-Path $ROOT "00_Daily_Intelligence\Signals"
$BRIEFS_DIR = Join-Path $ROOT "00_Daily_Intelligence\Daily_Briefs"
$LOGS_DIR = Join-Path $ROOT "_Automation\logs"
$NOW = Get-Date

# Ensure archive subdirectories exist
@("$ARCHIVE\Signals", "$ARCHIVE\Briefs") | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

$stats = @{ SignalsMoved = 0; BriefsMoved = 0; LogsDeleted = 0 }

# ── Archive old signals (>14 days) — into date-based subfolders ──────────────
if (Test-Path $SIGNALS_DIR) {
    $cutoff = $NOW.AddDays(-$SignalAgeDays)
    Get-ChildItem $SIGNALS_DIR -File | Where-Object { $_.LastWriteTime -lt $cutoff } | ForEach-Object {
        $monthFolder = Join-Path "$ARCHIVE\Signals" ($_.LastWriteTime.ToString("yyyy-MM"))
        if (-not (Test-Path $monthFolder)) { New-Item -ItemType Directory -Path $monthFolder -Force | Out-Null }
        if ($DryRun) {
            Write-Host "[DRY RUN] Would archive signal: $($_.Name) → $monthFolder"
        } else {
            Move-Item $_.FullName $monthFolder -Force
            $stats.SignalsMoved++
        }
    }
}

# ── Archive old briefs (>30 days) — into date-based subfolders ────────────────
if (Test-Path $BRIEFS_DIR) {
    $cutoff = $NOW.AddDays(-$BriefAgeDays)
    Get-ChildItem $BRIEFS_DIR -File | Where-Object { $_.LastWriteTime -lt $cutoff } | ForEach-Object {
        $monthFolder = Join-Path "$ARCHIVE\Briefs" ($_.LastWriteTime.ToString("yyyy-MM"))
        if (-not (Test-Path $monthFolder)) { New-Item -ItemType Directory -Path $monthFolder -Force | Out-Null }
        if ($DryRun) {
            Write-Host "[DRY RUN] Would archive brief: $($_.Name) → $monthFolder"
        } else {
            Move-Item $_.FullName $monthFolder -Force
            $stats.BriefsMoved++
        }
    }
}

# ── Delete old logs (>30 days) ───────────────────────────────────────────────
if (Test-Path $LOGS_DIR) {
    $cutoff = $NOW.AddDays(-$LogAgeDays)
    Get-ChildItem $LOGS_DIR -File | Where-Object { $_.LastWriteTime -lt $cutoff } | ForEach-Object {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would delete log: $($_.Name)"
        } else {
            Remove-Item $_.FullName -Force
            $stats.LogsDeleted++
        }
    }
}

# ── AUTO-CLEANUP: Delete ALL .pem files immediately (SECURITY POLICY) ────────
$pemFiles = Get-ChildItem $ROOT -Recurse -Filter "*.pem" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notlike "*\.venv\*" }
$stats.PemDeleted = 0
if ($pemFiles) {
    foreach ($pem in $pemFiles) {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would delete .pem: $($pem.FullName)"
        } else {
            Remove-Item $pem.FullName -Force
            Write-Warning "SECURITY: Deleted .pem file: $($pem.FullName)"
            $stats.PemDeleted++
        }
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────
Write-Host "Cleanup complete: $($stats.SignalsMoved) signals archived, $($stats.BriefsMoved) briefs archived, $($stats.LogsDeleted) logs deleted, $($stats.PemDeleted) .pem files deleted"
