<#
.SYNOPSIS
    Brain OS — Daily Pipeline Orchestrator
.DESCRIPTION
    Master script that runs the full daily intelligence pipeline:
    cleanup → inbox → emails → chats → ADO → calendar → brief → focus blocks → sync
.PARAMETER Force
    Skip the weekday check (normally only runs Mon-Fri)
.PARAMETER DryRun
    Preview what would run without executing steps
.PARAMETER SkipCalendar
    Skip calendar blocking step (Step 8)
#>
param(
    [switch]$Force,
    [switch]$DryRun,
    [switch]$SkipCalendar
)

# ── Setup ──
$ErrorActionPreference = 'Stop'
$ROOT   = Split-Path -Parent $PSScriptRoot
$AUTO   = $PSScriptRoot
$CONFIG = Get-Content "$AUTO\config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$LOG_DIR = Join-Path $AUTO 'logs'
if (-not (Test-Path $LOG_DIR)) { New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null }

$TODAY    = Get-Date -Format 'yyyy-MM-dd'
$LOG_FILE = Join-Path $LOG_DIR "$TODAY.log"
$STEP_ERRORS = @()

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $ts = Get-Date -Format 'HH:mm:ss'
    $line = "[$ts] [$Level] $Message"
    Write-Host $line
    Add-Content -Path $LOG_FILE -Value $line -Encoding UTF8
}

function Invoke-WithTimeout {
    param(
        [string]$StepName,
        [scriptblock]$Action,
        [int]$TimeoutSeconds = 120
    )
    Write-Log "Starting: $StepName"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        if ($DryRun) {
            Write-Log "  [DryRun] Would execute: $StepName"
        } else {
            $job = Start-Job -ScriptBlock $Action
            $completed = Wait-Job $job -Timeout $TimeoutSeconds
            if (-not $completed) {
                Stop-Job $job
                Remove-Job $job -Force
                throw "Timed out after ${TimeoutSeconds}s"
            }
            $output = Receive-Job $job
            Remove-Job $job -Force
            if ($output) { $output | ForEach-Object { Write-Log "  $_" } }
        }
    } catch {
        $script:STEP_ERRORS += "$StepName`: $($_.Exception.Message)"
        Write-Log "  FAILED: $($_.Exception.Message)" -Level 'ERROR'
    }
    $sw.Stop()
    Write-Log "Completed: $StepName (${($sw.Elapsed.TotalSeconds):N1}s)"
}

# ── Weekday Guard ──
if (-not $Force) {
    $dow = (Get-Date).DayOfWeek
    if ($dow -eq 'Saturday' -or $dow -eq 'Sunday') {
        Write-Log 'Weekend — skipping pipeline. Use -Force to override.'
        exit 0
    }
}

Write-Log "═══════════════════════════════════════════════════"
Write-Log "Brain OS Daily Pipeline — $TODAY"
Write-Log "═══════════════════════════════════════════════════"

# ══════════════════════════════════════════════════════════════════
# Step 0: CLEANUP — Archive old signals, briefs, logs
# ══════════════════════════════════════════════════════════════════
Invoke-WithTimeout "Step 0: Cleanup" {
    & "$using:AUTO\cleanup.ps1"
}

# ══════════════════════════════════════════════════════════════════
# Step 1: PARSE INBOX — Route new files from _Inbox/
# ══════════════════════════════════════════════════════════════════
Invoke-WithTimeout "Step 1: Parse Inbox" {
    & "$using:AUTO\parse_inbox.ps1"
}

# ══════════════════════════════════════════════════════════════════
# Step 2: FETCH EMAILS — Pull from Outlook (COM or Graph)
# ══════════════════════════════════════════════════════════════════
Invoke-WithTimeout "Step 2: Fetch Emails" {
    & "$using:AUTO\fetch_emails.ps1"
} -TimeoutSeconds 90

# ══════════════════════════════════════════════════════════════════
# Step 3: FETCH CHATS — Pull Teams chat highlights (Graph API)
# ══════════════════════════════════════════════════════════════════
Invoke-WithTimeout "Step 3: Fetch Chats" {
    & "$using:AUTO\fetch_chats.ps1"
} -TimeoutSeconds 60

# ══════════════════════════════════════════════════════════════════
# Step 4: FETCH ADO — Pull Azure DevOps work item states
# ══════════════════════════════════════════════════════════════════
Invoke-WithTimeout "Step 4: Fetch ADO" {
    & "$using:AUTO\fetch_ado.ps1"
} -TimeoutSeconds 90

# ══════════════════════════════════════════════════════════════════
# Step 5: FETCH CALENDAR — Today's meetings, free slots, conflicts
# ══════════════════════════════════════════════════════════════════
Invoke-WithTimeout "Step 5: Fetch Calendar" {
    & "$using:AUTO\fetch_calendar.ps1"
} -TimeoutSeconds 60

# ══════════════════════════════════════════════════════════════════
# Step 6: GENERATE BRIEF — AI-powered daily intelligence brief
# ══════════════════════════════════════════════════════════════════
Invoke-WithTimeout "Step 6: Generate Brief" {
    & "$using:AUTO\generate_brief.ps1"
} -TimeoutSeconds 180

# ══════════════════════════════════════════════════════════════════
# Step 7: CUSTOM — Add your own pipeline steps here
# ══════════════════════════════════════════════════════════════════
# Example: Invoke-WithTimeout "Step 7: Custom Metrics" {
#     & "$using:AUTO\my_custom_step.ps1"
# }

# ══════════════════════════════════════════════════════════════════
# Step 8: BLOCK CALENDAR — Create focus time for top priorities
# ══════════════════════════════════════════════════════════════════
if (-not $SkipCalendar) {
    Invoke-WithTimeout "Step 8: Block Calendar" {
        & "$using:AUTO\block_calendar.ps1"
    } -TimeoutSeconds 60
} else {
    Write-Log "Step 8: Block Calendar — SKIPPED (SkipCalendar flag)"
}

# ══════════════════════════════════════════════════════════════════
# Step 9: SYNC INSTRUCTIONS — Rebuild copilot-instructions.md
# ══════════════════════════════════════════════════════════════════
Invoke-WithTimeout "Step 9: Sync Instructions" {
    & "$using:AUTO\sync_instructions.ps1"
} -TimeoutSeconds 30

# ══════════════════════════════════════════════════════════════════
# SUMMARY — Report results
# ══════════════════════════════════════════════════════════════════
Write-Log "═══════════════════════════════════════════════════"
if ($STEP_ERRORS.Count -gt 0) {
    Write-Log "Pipeline completed with $($STEP_ERRORS.Count) error(s):" -Level 'WARN'
    $STEP_ERRORS | ForEach-Object { Write-Log "  ⚠ $_" -Level 'WARN' }
} else {
    Write-Log "Pipeline completed successfully — all steps passed ✅"
}
Write-Log "═══════════════════════════════════════════════════"

# Open brief in default browser
$briefPath = Join-Path $ROOT "00_Daily_Intelligence\Daily_Briefs\${TODAY}_Brief.md"
if ((Test-Path $briefPath) -and -not $DryRun) {
    Write-Log "Brief generated: $briefPath"
}
