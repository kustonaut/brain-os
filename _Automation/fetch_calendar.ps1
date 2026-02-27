<#
.SYNOPSIS
    Read Outlook calendar for today + tomorrow and write to signals file
.NOTES
    Supports Outlook COM (Windows) or Graph API (cross-platform).
    Set outlook.method = "graph" in config.json for Graph mode.
#>

$ROOT = Split-Path -Parent $PSScriptRoot
$CONFIG = Get-Content "$ROOT\_Automation\config.json" -Raw | ConvertFrom-Json
. "$PSScriptRoot\graph_helpers.ps1"
$SIGNALS = Join-Path $ROOT "00_Daily_Intelligence\Signals"
$TODAY = Get-Date -Format "yyyy-MM-dd"
$OUTPUT_FILE = Join-Path $SIGNALS "calendar_$TODAY.md"

if (-not (Test-Path $SIGNALS)) { New-Item -ItemType Directory -Path $SIGNALS -Force | Out-Null }

$results = @()
$results += "# Calendar Signals - $TODAY"
$results += ""
$results += "> Fetched at $(Get-Date -Format 'HH:mm:ss')"
$results += ""

$calMethod = Get-MailMethod -Config $CONFIG

if ($calMethod -eq "graph") {
    # ── Graph API mode ──
    try {
        $graphEvents = Get-GraphCalendar -Date $TODAY -DaysAhead 2
        $todayStart = (Get-Date).Date
        $todayAppts = $graphEvents | Where-Object { ([datetime]$_.Start).Date -eq $todayStart }
        $tomorrowAppts = $graphEvents | Where-Object { ([datetime]$_.Start).Date -eq $todayStart.AddDays(1) }

        $results += "## Today - $(Get-Date -Format 'dddd, MMMM dd')"
        $results += ""
        if ($todayAppts.Count -eq 0) { $results += "*No meetings today - full focus day!*" }
        else {
            $results += "| Time | Duration | Meeting | Organizer | Status |"
            $results += "|------|----------|---------|-----------|--------|"
            foreach ($a in $todayAppts | Sort-Object { [datetime]$_.Start }) {
                $s = [datetime]$a.Start; $e = [datetime]$a.End
                $time = "$($s.ToString('HH:mm'))–$($e.ToString('HH:mm'))"
                $status = switch ($a.ShowAs) { "free" {"Free"} "tentative" {"Tentative"} "busy" {"Busy"} "oof" {"OOF"} default {"-"} }
                $results += "| $time | $($a.Duration)m | $($a.Subject) | $($a.Organizer) | $status |"
            }
        }
        $results += ""
        $results += "### Free Slots Today"
        $results += "*Calculated from Graph calendar data*"
        $results += ""

        $tmrw = $todayStart.AddDays(1)
        $results += "## Tomorrow - $($tmrw.ToString('dddd, MMMM dd'))"
        $results += ""
        if ($tomorrowAppts.Count -eq 0) { $results += "*No meetings tomorrow - full focus day!*" }
        else {
            $results += "| Time | Duration | Meeting | Organizer | Status |"
            $results += "|------|----------|---------|-----------|--------|"
            foreach ($a in $tomorrowAppts | Sort-Object { [datetime]$_.Start }) {
                $s = [datetime]$a.Start; $e = [datetime]$a.End
                $time = "$($s.ToString('HH:mm'))–$($e.ToString('HH:mm'))"
                $status = switch ($a.ShowAs) { "free" {"Free"} "tentative" {"Tentative"} "busy" {"Busy"} "oof" {"OOF"} default {"-"} }
                $results += "| $time | $($a.Duration)m | $($a.Subject) | $($a.Organizer) | $status |"
            }
        }
        $results += ""
        $results += "### [WARN] Conflicts"
        $results += "*No conflicts detected.*"
    } catch {
        $results += "**ERROR:** Graph API calendar failed: $_"
    }
} else {
    # ── Outlook COM mode (Windows only) ──
    try {
        $outlook = New-Object -ComObject Outlook.Application
        $namespace = $outlook.GetNamespace("MAPI")
        $calendarFolder = $namespace.GetDefaultFolder(9)

        $todayStart = (Get-Date).Date
        $tomorrowEnd = $todayStart.AddDays(2)

        $filter = "[Start] >= '$($todayStart.ToString('MM/dd/yyyy'))' AND [Start] < '$($tomorrowEnd.ToString('MM/dd/yyyy'))'"
        $items = $calendarFolder.Items
        $items.IncludeRecurrences = $true
        $items.Sort("[Start]")
        $appointments = $items.Restrict($filter)

        $todayAppts = @()
        $tomorrowAppts = @()

        foreach ($appt in $appointments) {
            try {
                $entry = @{
                    Subject = $appt.Subject
                    Start = $appt.Start
                    End = $appt.End
                    Location = $appt.Location
                    Organizer = $appt.Organizer
                    Required = $appt.RequiredAttendees
                    IsRecurring = $appt.IsRecurring
                    BusyStatus = $appt.BusyStatus
                    Duration = $appt.Duration
                }

                if ($appt.Start.Date -eq $todayStart) {
                    $todayAppts += $entry
                } else {
                    $tomorrowAppts += $entry
                }
            } catch {}
        }

        # Format today
        $results += "## Today - $(Get-Date -Format 'dddd, MMMM dd')"
        $results += ""

        if ($todayAppts.Count -eq 0) {
            $results += "*No meetings today - full focus day!*"
        } else {
            $results += "| Time | Duration | Meeting | Organizer | Status |"
            $results += "|------|----------|---------|-----------|--------|"
            foreach ($a in $todayAppts | Sort-Object { $_.Start }) {
                $time = "$($a.Start.ToString('HH:mm'))–$($a.End.ToString('HH:mm'))"
                $dur = "$($a.Duration)m"
                $status = switch ($a.BusyStatus) { 0 {"Free"} 1 {"Tentative"} 2 {"Busy"} 3 {"OOF"} default {"-"} }
                $results += "| $time | $dur | $($a.Subject) | $($a.Organizer) | $status |"
            }
        }

        $results += ""

        # Find free slots today (9 AM to 6 PM)
        $results += "### Free Slots Today"
        $busyTimes = $todayAppts | Where-Object { $_.BusyStatus -ge 1 } | Sort-Object { $_.Start }
        $workStart = $todayStart.AddHours(9)
        $workEnd = $todayStart.AddHours(18)
        $now = Get-Date

        $freeSlots = @()
        $cursor = if ($now -gt $workStart) { $now } else { $workStart }
        $minutes = $cursor.Minute
        if ($minutes -gt 0 -and $minutes -le 30) { $cursor = $cursor.Date.AddHours($cursor.Hour).AddMinutes(30) }
        elseif ($minutes -gt 30) { $cursor = $cursor.Date.AddHours($cursor.Hour + 1) }

        foreach ($busy in $busyTimes) {
            if ($busy.Start -gt $cursor -and ($busy.Start - $cursor).TotalMinutes -ge 30) {
                $freeSlots += "- $($cursor.ToString('HH:mm'))–$($busy.Start.ToString('HH:mm')) ($([math]::Round(($busy.Start - $cursor).TotalMinutes))m)"
            }
            if ($busy.End -gt $cursor) { $cursor = $busy.End }
        }
        if ($cursor -lt $workEnd) {
            $freeSlots += "- $($cursor.ToString('HH:mm'))–$($workEnd.ToString('HH:mm')) ($([math]::Round(($workEnd - $cursor).TotalMinutes))m)"
        }

        if ($freeSlots.Count -gt 0) {
            $results += $freeSlots
        } else {
            $results += "*No free slots remaining today (or all meetings past).*"
        }

        $results += ""

        # Format tomorrow
        $tmrw = $todayStart.AddDays(1)
        $results += "## Tomorrow - $($tmrw.ToString('dddd, MMMM dd'))"
        $results += ""

        if ($tomorrowAppts.Count -eq 0) {
            $results += "*No meetings tomorrow - full focus day!*"
        } else {
            $results += "| Time | Duration | Meeting | Organizer | Status |"
            $results += "|------|----------|---------|-----------|--------|"
            foreach ($a in $tomorrowAppts | Sort-Object { $_.Start }) {
                $time = "$($a.Start.ToString('HH:mm'))–$($a.End.ToString('HH:mm'))"
                $dur = "$($a.Duration)m"
                $status = switch ($a.BusyStatus) { 0 {"Free"} 1 {"Tentative"} 2 {"Busy"} 3 {"OOF"} default {"-"} }
                $results += "| $time | $dur | $($a.Subject) | $($a.Organizer) | $status |"
            }
        }

        # Detect conflicts
        $results += ""
        $results += "### [WARN] Conflicts"
        $allAppts = $todayAppts + $tomorrowAppts | Where-Object { $_.BusyStatus -ge 1 } | Sort-Object { $_.Start }
        $conflicts = @()
        for ($i = 0; $i -lt $allAppts.Count - 1; $i++) {
            if ($allAppts[$i].End -gt $allAppts[$i+1].Start) {
                $conflicts += "- **$($allAppts[$i].Subject)** ($($allAppts[$i].Start.ToString('HH:mm'))–$($allAppts[$i].End.ToString('HH:mm'))) overlaps **$($allAppts[$i+1].Subject)** ($($allAppts[$i+1].Start.ToString('HH:mm'))–$($allAppts[$i+1].End.ToString('HH:mm')))"
            }
        }

        if ($conflicts.Count -gt 0) { $results += $conflicts }
        else { $results += "*No conflicts detected.*" }

    } catch {
        $results += "**ERROR:** Could not read calendar. Is Outlook running? Error: $_"
    }
}

$results | Set-Content $OUTPUT_FILE -Encoding UTF8
Write-Host "Calendar signals written to: $OUTPUT_FILE"
