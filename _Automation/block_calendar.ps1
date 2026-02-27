<#
.SYNOPSIS
    Block focus time on Outlook calendar for today's top tasks
.DESCRIPTION
    Reads calendar signals to find free slots, then creates focus time blocks.
    Supports Outlook COM (Windows) or Graph API (cross-platform).
    Set outlook.method = "graph" in config.json for Graph mode.
#>

$ROOT = Split-Path -Parent $PSScriptRoot
$CONFIG = Get-Content "$ROOT\_Automation\config.json" -Raw | ConvertFrom-Json
. "$PSScriptRoot\graph_helpers.ps1"
$SIGNALS = Join-Path $ROOT "00_Daily_Intelligence\Signals"
$KB = Join-Path $ROOT "00_Daily_Intelligence\Knowledge_Base"
$TODAY = Get-Date -Format "yyyy-MM-dd"

# ── Load top tasks dynamically from Action_Items.md ─────────────────────
$topTasks = @()
$actionFile = Join-Path $KB "Action_Items.md"
if (Test-Path $actionFile) {
    $actionContent = Get-Content $actionFile -Raw -ErrorAction SilentlyContinue
    $actionLines = ($actionContent -split "`n") | Where-Object { $_ -match 'TODO|URGENT|🔴|ONGOING' }
    foreach ($line in ($actionLines | Select-Object -First 3)) {
        $taskName = ($line -replace '^\s*[\|\-\*]+\s*', '' -replace '\*\*', '').Trim()
        if ($taskName.Length -gt 10) {
            $topTasks += @{
                Name = $taskName
                Charter = ""
                Duration = 60
                References = @()
                Body = "Auto-extracted from Action_Items.md"
            }
        }
    }
}
if ($topTasks.Count -eq 0) {
    $topTasks = @(
        @{
            Name = "Review top priority items"
            Charter = ""
            Duration = 60
            References = @()
            Body = "Review and triage today's highest-priority items"
        }
    )
}

# ── Read calendar to find free slots ────────────────────────────────────
$calendarFile = Join-Path $SIGNALS "calendar_$TODAY.md"
$freeSlots = @()
$calMethod = Get-MailMethod -Config $CONFIG

if ($calMethod -eq "graph") {
    # ── Graph API mode ──
    try {
        $graphEvents = Get-GraphCalendar -Date $TODAY -DaysAhead 1
        $todayStart = (Get-Date).Date
        $busyTimes = @()
        foreach ($evt in $graphEvents) {
            if ($evt.ShowAs -ne "free" -and ([datetime]$evt.Start).Date -eq $todayStart) {
                $busyTimes += @{ Start = [datetime]$evt.Start; End = [datetime]$evt.End }
            }
        }
        $busyTimes = $busyTimes | Sort-Object { $_.Start }

        $workStart = $todayStart.AddHours(9); $workEnd = $todayStart.AddHours(18)
        $now = Get-Date
        $cursor = if ($now -gt $workStart) { $now.AddMinutes(15 - ($now.Minute % 15)) } else { $workStart }
        foreach ($busy in $busyTimes) {
            if ($busy.Start -gt $cursor -and ($busy.Start - $cursor).TotalMinutes -ge 30) {
                $freeSlots += @{ Start = $cursor; End = $busy.Start }
            }
            if ($busy.End -gt $cursor) { $cursor = $busy.End }
        }
        if ($cursor -lt $workEnd) { $freeSlots += @{ Start = $cursor; End = $workEnd } }

        # Create focus blocks via Graph
        $blocksCreated = 0
        $maxBlocks = $CONFIG.calendar.max_blocks_per_day
        foreach ($task in $topTasks) {
            if ($blocksCreated -ge $maxBlocks) { break }
            foreach ($slot in $freeSlots) {
                $slotMinutes = ($slot.End - $slot.Start).TotalMinutes
                if ($slotMinutes -ge $task.Duration) {
                    $result = New-GraphCalendarEvent `
                        -Subject "🎯 Focus: $($task.Name)" `
                        -Start $slot.Start.ToString("yyyy-MM-ddTHH:mm:ss") `
                        -DurationMinutes $task.Duration `
                        -Body $task.Body `
                        -Category $CONFIG.calendar.block_category
                    if ($result.Success) {
                        Write-Host "Created (Graph): 🎯 Focus: $($task.Name) at $($slot.Start.ToString('HH:mm'))"
                        $slot.Start = $slot.Start.AddMinutes($task.Duration + 15)
                        $blocksCreated++
                    }
                    break
                }
            }
        }
        Write-Host "$blocksCreated focus time blocks created via Graph API."
    } catch {
        Write-Host "Graph calendar blocking failed: $_" -ForegroundColor Red
    }
} else {
    # ── Outlook COM mode (Windows only) ──
    try {
        $outlook = New-Object -ComObject Outlook.Application
        $namespace = $outlook.GetNamespace("MAPI")
        $calendarFolder = $namespace.GetDefaultFolder(9)

        $todayStart = (Get-Date).Date
        $filter = "[Start] >= '$($todayStart.ToString('MM/dd/yyyy'))' AND [Start] < '$($todayStart.AddDays(1).ToString('MM/dd/yyyy'))'"
        $items = $calendarFolder.Items
        $items.IncludeRecurrences = $true
        $items.Sort("[Start]")
        $appointments = $items.Restrict($filter)

        $busyTimes = @()
        foreach ($appt in $appointments) {
            try {
                if ($appt.BusyStatus -ge 1) {
                    $busyTimes += @{ Start = $appt.Start; End = $appt.End }
                }
            } catch {}
        }
        $busyTimes = $busyTimes | Sort-Object { $_.Start }

        $workStart = $todayStart.AddHours(9)
        $workEnd = $todayStart.AddHours(18)
        $now = Get-Date
        $cursor = if ($now -gt $workStart) { $now.AddMinutes(15 - ($now.Minute % 15)) } else { $workStart }

        foreach ($busy in $busyTimes) {
            if ($busy.Start -gt $cursor -and ($busy.Start - $cursor).TotalMinutes -ge 30) {
                $freeSlots += @{ Start = $cursor; End = $busy.Start }
            }
            if ($busy.End -gt $cursor) { $cursor = $busy.End }
        }
        if ($cursor -lt $workEnd) {
            $freeSlots += @{ Start = $cursor; End = $workEnd }
        }

        # Create focus time blocks
        $blocksCreated = 0
        $maxBlocks = $CONFIG.calendar.max_blocks_per_day

        foreach ($task in $topTasks) {
            if ($blocksCreated -ge $maxBlocks) { break }

            foreach ($slot in $freeSlots) {
                $slotMinutes = ($slot.End - $slot.Start).TotalMinutes
                if ($slotMinutes -ge $task.Duration) {
                    $appt = $outlook.CreateItem(1)
                    $appt.Subject = "🎯 Focus: $($task.Name)"
                    $appt.Start = $slot.Start
                    $appt.Duration = $task.Duration
                    $appt.BusyStatus = 2
                    $appt.ReminderMinutesBeforeStart = 5
                    $appt.Categories = $CONFIG.calendar.block_category

                    $bodyLines = @()
                    $bodyLines += "FOCUS TIME - $($task.Charter)"
                    $bodyLines += "=" * 40
                    $bodyLines += ""
                    $bodyLines += $task.Body
                    $bodyLines += ""
                    $bodyLines += "REFERENCE DOCUMENTS:"
                    foreach ($ref in $task.References) {
                        $bodyLines += "  - $ref"
                    }
                    $bodyLines += ""
                    $bodyLines += "---"
                    $bodyLines += "Auto-created by PM Daily Orchestrator"
                    $bodyLines += "Knowledge Base: 00_Daily_Intelligence/Knowledge_Base/"

                    $appt.Body = $bodyLines -join "`r`n"
                    $appt.Save()

                    Write-Host "Created: $($appt.Subject) at $($slot.Start.ToString('HH:mm'))–$($slot.Start.AddMinutes($task.Duration).ToString('HH:mm'))"

                    $slot.Start = $slot.Start.AddMinutes($task.Duration + 15)
                    $blocksCreated++
                    break
                }
            }
        }

        Write-Host "$blocksCreated focus time blocks created."

    } catch {
        Write-Host "Calendar blocking failed: $_" -ForegroundColor Red
        Write-Host "Ensure Outlook is running, or set outlook.method to 'graph' in config.json."
    }
}
