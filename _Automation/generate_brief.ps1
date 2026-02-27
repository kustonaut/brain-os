<#
.SYNOPSIS
    Generate focused, actionable daily brief from signals + Knowledge Base
.DESCRIPTION
    Reads all signal files, cross-references with KB Action_Items.md,
    extracts real priorities, meeting prep contexts, and open actions.
    No placeholders — every section has real data or is omitted.
.NOTES
    PowerShell 5.1 compatible (no ?? or ternary operators)
#>

$ROOT = Split-Path -Parent $PSScriptRoot
$CONFIG = Get-Content "$ROOT\_Automation\config.json" -Raw | ConvertFrom-Json
$SIGNALS = Join-Path $ROOT "00_Daily_Intelligence\Signals"
$BRIEFS = Join-Path $ROOT "00_Daily_Intelligence\Daily_Briefs"
$KB = Join-Path $ROOT "00_Daily_Intelligence\Knowledge_Base"
$TODAY = Get-Date -Format "yyyy-MM-dd"
$YESTERDAY = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
$DAY_NAME = (Get-Date).ToString("dddd")
$OUTPUT_FILE = Join-Path $BRIEFS "${TODAY}_Brief.md"

if (-not (Test-Path $BRIEFS)) { New-Item -ItemType Directory -Path $BRIEFS -Force | Out-Null }

# ═══════════════════════════════════════════════════════════════════════════
# 1. READ ALL INPUTS
# ═══════════════════════════════════════════════════════════════════════════

$emailSignals    = if (Test-Path "$SIGNALS\emails_$TODAY.md")       { Get-Content "$SIGNALS\emails_$TODAY.md" -Raw -Encoding UTF8 }       else { "" }
$chatSignals     = if (Test-Path "$SIGNALS\chats_$TODAY.md")        { Get-Content "$SIGNALS\chats_$TODAY.md" -Raw -Encoding UTF8 }        else { "" }
$adoSignals      = if (Test-Path "$SIGNALS\ado_$TODAY.md")          { Get-Content "$SIGNALS\ado_$TODAY.md" -Raw -Encoding UTF8 }          else { "" }
$calendarSignals = if (Test-Path "$SIGNALS\calendar_$TODAY.md")     { Get-Content "$SIGNALS\calendar_$TODAY.md" -Raw -Encoding UTF8 }     else { "" }
$inboxSignals    = if (Test-Path "$SIGNALS\inbox_parsed_$TODAY.md") { Get-Content "$SIGNALS\inbox_parsed_$TODAY.md" -Raw -Encoding UTF8 } else { "" }
$actionItemsRaw  = if (Test-Path "$KB\Action_Items.md")             { Get-Content "$KB\Action_Items.md" -Raw -Encoding UTF8 }             else { "" }
$contactsRaw     = if (Test-Path "$KB\Key_Contacts.md")             { Get-Content "$KB\Key_Contacts.md" -Raw -Encoding UTF8 }             else { "" }

# ═══════════════════════════════════════════════════════════════════════════
# 2. PARSE CALENDAR — meetings, focus blocks, free slots, conflicts
# ═══════════════════════════════════════════════════════════════════════════

$allMeetings      = @()
$focusBlocks      = @()
$externalMeetings = @()
$selfMeetings     = @()
$conflicts        = @()
$freeSlots        = @()

if ($calendarSignals) {
    # Parse "Today" section table rows
    $todaySection = ""
    if ($calendarSignals -match '(?s)## Today.*?(?=## Tomorrow|### \[WARN\]|$)') {
        $todaySection = $Matches[0]
    }

    $tableRows = [regex]::Matches($todaySection, '\|\s*(\d{2}:\d{2}[^\|]+?\d{2}:\d{2})\s*\|\s*(\d+m)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(\w+)\s*\|')
    foreach ($row in $tableRows) {
        $time      = $row.Groups[1].Value.Trim()
        $duration  = $row.Groups[2].Value.Trim()
        $title     = $row.Groups[3].Value.Trim()
        $organizer = $row.Groups[4].Value.Trim()
        $status    = $row.Groups[5].Value.Trim()

        # Skip sleep blocks
        if ($title -match '^Sleep$') { continue }

        $isFocus = $title -match '^🎯 Focus:'
        $isSelf  = $organizer -match [regex]::Escape($CONFIG.pm_identity.name)

        $meeting = @{
            Time      = $time
            Duration  = $duration
            Title     = $title
            Organizer = $organizer
            Status    = $status
            IsFocus   = $isFocus
            IsSelf    = $isSelf
        }
        $allMeetings += $meeting

        if ($isFocus) {
            $focusBlocks += $meeting
        } elseif (-not $isSelf) {
            $externalMeetings += $meeting
        } else {
            $selfMeetings += $meeting
        }
    }

    # Free slots
    $freeSlotMatches = [regex]::Matches($calendarSignals, '-\s*(\d{2}:\d{2}[^\(]+?\d{2}:\d{2})\s*\((\d+m)\)')
    foreach ($slot in $freeSlotMatches) {
        $freeSlots += @{ Time = $slot.Groups[1].Value.Trim(); Duration = $slot.Groups[2].Value.Trim() }
    }

    # Conflicts
    $conflictMatches = [regex]::Matches($calendarSignals, '-\s*\*\*(.+?)\*\*\s*\((.+?)\)\s*overlaps\s*\*\*(.+?)\*\*\s*\((.+?)\)')
    foreach ($c in $conflictMatches) {
        $conflicts += @{
            Meeting1 = $c.Groups[1].Value.Trim(); Time1 = $c.Groups[2].Value.Trim()
            Meeting2 = $c.Groups[3].Value.Trim(); Time2 = $c.Groups[4].Value.Trim()
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# 3. PARSE ACTION ITEMS — extract urgent/medium TODOs
# ═══════════════════════════════════════════════════════════════════════════

# Charter-area keyword map — loaded from config.json
$charterMap = [ordered]@{}
foreach ($cp in $CONFIG.charter_patterns) {
    $charterMap[$cp.regex] = $cp.label
}

function Get-Charter($text) {
    foreach ($pattern in $charterMap.Keys) {
        if ($text -match $pattern) { return $charterMap[$pattern] }
    }
    return $null
}

$urgentActions = @()
$mediumActions = @()
$otherTodos    = @()

# Current section header tracker
$currentSection = ""

if ($actionItemsRaw) {
    $lines = $actionItemsRaw -split "`n"
    foreach ($line in $lines) {
        $trimmed = $line.Trim()

        # Track section headers
        if ($trimmed -match '^###?\s+(.+)') { $currentSection = $Matches[1] }

        # Skip completed/done/ongoing/pending lines
        if ($trimmed -match '✅|DONE|~~') { continue }

        # 🔴 TODO
        if ($trimmed -match '\|' -and $trimmed -match 'TODO' -and $trimmed -match '🔴') {
            $cells = $trimmed -split '\|' | Where-Object { $_.Trim() -ne '' } | ForEach-Object { $_.Trim() }
            if ($cells.Count -ge 1) {
                $actionText = ($cells[0] -replace '\*\*', '').Trim()
                if ($actionText.Length -gt 5) {
                    $charter = Get-Charter $actionText
                    if (-not $charter) { $charter = Get-Charter $currentSection }
                    if (-not $charter) { $charter = "General" }
                    $urgentActions += @{ Text = $actionText; Section = $currentSection; Charter = $charter }
                }
            }
        }
        # 🟡 TODO
        elseif ($trimmed -match '\|' -and $trimmed -match 'TODO' -and $trimmed -match '🟡') {
            $cells = $trimmed -split '\|' | Where-Object { $_.Trim() -ne '' } | ForEach-Object { $_.Trim() }
            if ($cells.Count -ge 1) {
                $actionText = ($cells[0] -replace '\*\*', '').Trim()
                if ($actionText.Length -gt 5) {
                    $charter = Get-Charter $actionText
                    if (-not $charter) { $charter = Get-Charter $currentSection }
                    if (-not $charter) { $charter = "General" }
                    $mediumActions += @{ Text = $actionText; Section = $currentSection; Charter = $charter }
                }
            }
        }
        # Plain TODO (no emoji priority)
        elseif ($trimmed -match '\|' -and $trimmed -match '\bTODO\b' -and $trimmed -notmatch 'IN PROGRESS|ONGOING|Pending|🔴|🟡|🟢') {
            $cells = $trimmed -split '\|' | Where-Object { $_.Trim() -ne '' } | ForEach-Object { $_.Trim() }
            if ($cells.Count -ge 1) {
                $actionText = ($cells[0] -replace '\*\*', '').Trim()
                if ($actionText.Length -gt 5) {
                    $charter = Get-Charter $actionText
                    if (-not $charter) { $charter = Get-Charter $currentSection }
                    if (-not $charter) { $charter = "General" }
                    $otherTodos += @{ Text = $actionText; Section = $currentSection; Charter = $charter }
                }
            }
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# 4. PARSE EMAILS — extract actual highlights (skip empty/warning sections)
# ═══════════════════════════════════════════════════════════════════════════

$emailItems = @()
$hasRealEmails = $false

if ($emailSignals -and $emailSignals -notmatch 'No matching emails found' -and $emailSignals -notmatch '\[WARN\]') {
    # Extract ### [Subject] blocks
    $emailBlocks = [regex]::Matches($emailSignals, '###\s+\[(.+?)\]\s*\n([\s\S]*?)(?=###|\z)')
    foreach ($block in $emailBlocks) {
        $hasRealEmails = $true
        $subject = $block.Groups[1].Value.Trim()
        $body = $block.Groups[2].Value.Trim()
        $sender = ""
        if ($body -match 'From:\s*(.+)') { $sender = $Matches[1].Trim() }
        $charter = Get-Charter "$subject $body"
        $emailItems += @{ Subject = $subject; Sender = $sender; Charter = $charter }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# 5. PARSE ADO — extract work item rows (skip warnings)
# ═══════════════════════════════════════════════════════════════════════════

$adoItems = @()
$hasRealADO = $false

if ($adoSignals -and $adoSignals -notmatch '\[WARN\]') {
    $adoRows = [regex]::Matches($adoSignals, '\|\s*\[?(\d{5,})\]?\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|')
    foreach ($row in $adoRows) {
        $hasRealADO = $true
        $adoItems += @{
            ID       = $row.Groups[1].Value.Trim()
            Title    = $row.Groups[2].Value.Trim()
            State    = $row.Groups[3].Value.Trim()
            Assigned = $row.Groups[4].Value.Trim()
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# 6. PARSE CHATS — check if real content exists
# ═══════════════════════════════════════════════════════════════════════════

$hasRealChats = $false
if ($chatSignals -and $chatSignals -notmatch '\[WARN\]' -and $chatSignals -notmatch 'Graph API not available') {
    $hasRealChats = $true
}

# ═══════════════════════════════════════════════════════════════════════════
# 7. PARSE INBOX — check if real files were processed
# ═══════════════════════════════════════════════════════════════════════════

$hasInboxFiles = $false
$inboxFileCount = 0
if ($inboxSignals -and $inboxSignals -notmatch 'No new files') {
    $hasInboxFiles = $true
    $inboxFileCount = ([regex]::Matches($inboxSignals, '##\s+')).Count
}

# ═══════════════════════════════════════════════════════════════════════════
# 8. BUILD TOP 3 FOCUS — cross-reference KB actions, calendar, signals
# ═══════════════════════════════════════════════════════════════════════════

$topFocus = @()

# Priority A: 🔴 KB actions that match today's calendar/focus blocks
foreach ($action in $urgentActions) {
    if ($topFocus.Count -ge 6) { break }
    $source = "Action_Items.md"
    $timeSlot = ""

    # Check if any of today's meetings/focus blocks relate to this action
    foreach ($m in $allMeetings) {
        $mCharter = Get-Charter $m.Title
        if ($mCharter -and $mCharter -eq $action.Charter) {
            $source = "Action_Items.md + Calendar"
            $timeSlot = $m.Time
            break
        }
    }

    $topFocus += @{
        Priority = "🔴"
        Title    = $action.Text
        Source   = $source
        Time     = $timeSlot
        Charter  = $action.Charter
    }
}

# Priority B: External meetings needing prep (other people's meetings)
foreach ($m in $externalMeetings) {
    if ($topFocus.Count -ge 6) { break }
    $charter = Get-Charter $m.Title
    if (-not $charter) { $charter = "General" }

    # Check if we have related action items for this meeting
    $relatedAction = ""
    foreach ($a in ($urgentActions + $mediumActions)) {
        if ($a.Charter -eq $charter) {
            $relatedAction = $a.Text
            break
        }
    }

    $entry = @{
        Priority = "🟡"
        Title    = "Prep: $($m.Title)"
        Source   = "Calendar — $($m.Organizer)"
        Time     = $m.Time
        Charter  = $charter
    }
    if ($relatedAction) { $entry.Related = $relatedAction }
    $topFocus += $entry
}

# Priority C: Email-driven items (if any real emails arrived)
foreach ($e in $emailItems) {
    if ($topFocus.Count -ge 6) { break }
    $charter = if ($e.Charter) { $e.Charter } else { "General" }
    $topFocus += @{
        Priority = "🟡"
        Title    = "Respond: $($e.Subject)"
        Source   = "Email — $($e.Sender)"
        Time     = ""
        Charter  = $charter
    }
}

# Priority D: 🟡 KB actions (fill remaining slots)
foreach ($action in $mediumActions) {
    if ($topFocus.Count -ge 6) { break }
    # Skip if already covered by a higher-priority entry
    $alreadyCovered = $false
    foreach ($f in $topFocus) {
        if ($f.Charter -eq $action.Charter -and $f.Priority -eq "🔴") {
            $alreadyCovered = $true
            break
        }
    }
    if ($alreadyCovered) { continue }

    $topFocus += @{
        Priority = "🟡"
        Title    = $action.Text
        Source   = "Action_Items.md"
        Time     = ""
        Charter  = $action.Charter
    }
}

# Cap at 3 for display
$top3 = @()
if ($topFocus.Count -gt 3) {
    $top3 = $topFocus[0..2]
} elseif ($topFocus.Count -gt 0) {
    $top3 = $topFocus
}

# ── CoT Reasoning Log Population ─────────────────────────────────────────
# Step-Back: "What does this PM most need right now?"
Add-Reasoning "Step-Back" "PM is in a multi-charter role. Prioritize by urgency (🔴 KB actions > time-locked meetings > email responses > 🟡 backlog)."

# CoT: Signal quality
$signalQuality = @()
if ($hasRealEmails) { $signalQuality += "$($emailItems.Count) email(s) parsed" } else { $signalQuality += "no emails (signal missing or empty)" }
if ($hasRealADO) { $signalQuality += "$($adoItems.Count) ADO item(s) changed" } else { $signalQuality += "no ADO changes" }
if ($allMeetings.Count -gt 0) { $signalQuality += "$($allMeetings.Count) meetings on calendar" } else { $signalQuality += "no meetings today" }
Add-Reasoning "Signal Quality" ($signalQuality -join " | ")

# CoT: Priority reasoning
if ($urgentActions.Count -gt 0) {
    Add-Reasoning "Priority Source" "🔴 KB actions drove top items ($($urgentActions.Count) urgent in Action_Items.md)"
} elseif ($externalMeetings.Count -gt 0) {
    Add-Reasoning "Priority Source" "Calendar-driven: no 🔴 KB actions; $($externalMeetings.Count) external meeting(s) need prep"
} else {
    Add-Reasoning "Priority Source" "No urgent KB actions and no meetings — review Action_Items.md directly"
}

# CoT: What might be missing?
$missingSignals = @()
if (-not $hasRealEmails) { $missingSignals += "email signals" }
if (-not $hasRealADO) { $missingSignals += "ADO signals" }
if ($allMeetings.Count -eq 0) { $missingSignals += "calendar data" }
if ($missingSignals.Count -gt 0) {
    Add-Reasoning "Blind Spots" "Missing: $($missingSignals -join ', '). Run fetch steps or check manually."
} else {
    Add-Reasoning "Blind Spots" "All signal types present. Brief confidence: HIGH."
}

# CoT: Escalation check
if ($conflicts.Count -gt 0) {
    Add-Reasoning "Scheduling Risk" "$($conflicts.Count) meeting conflict(s) detected — resolve before priority items."
}
if (($urgentActions | Where-Object { $_.Text -match 'incident|CRI|escalat' }).Count -gt 0) {
    Add-Reasoning "Escalation Detected" "Escalation pattern in KB actions — verify current incident status."
}

# ═══════════════════════════════════════════════════════════════════════════
# 9. BUILD THE BRIEF
# ═══════════════════════════════════════════════════════════════════════════
# COPILOT SYSTEM PROMPT (read this before editing this script):
# You are a PM intelligence system. Before generating each section,
# apply Step-Back reasoning: "What does a busy PM most need from this signal type?"
# Then apply CoT: "What is the most important item? What is at risk? What's time-sensitive?"
# Only surface data that exists in signals — never invent. Use "no data" for gaps.
# Temperature for brief generation: 0.1 (precision mode).
# ═══════════════════════════════════════════════════════════════════════════

$b = New-Object System.Collections.ArrayList

# CoT Reasoning Log — captures why items were prioritized
$cotLog = New-Object System.Collections.ArrayList

function Add-Reasoning($step, $finding) {
    [void]$cotLog.Add("- **$step**: $finding")
}

# ── Header ────────────────────────────────────────────────────────────────
$signalSummary = @()
if ($hasRealEmails) { $signalSummary += "$($emailItems.Count) emails" } else { $signalSummary += "0 emails" }
if ($hasRealChats) { $signalSummary += "chats" } else { $signalSummary += "0 chats" }
if ($hasRealADO) { $signalSummary += "$($adoItems.Count) ADO items" } else { $signalSummary += "0 ADO" }
if ($hasInboxFiles) { $signalSummary += "$inboxFileCount inbox files" }
$signalLine = $signalSummary -join " | "
$meetingLine = "$($externalMeetings.Count) external meetings, $($focusBlocks.Count) focus blocks, $($freeSlots.Count) free slots"

[void]$b.Add("# Daily Brief — $TODAY ($DAY_NAME)")
[void]$b.Add("")
[void]$b.Add("> Generated $(Get-Date -Format 'HH:mm') by Daily Orchestrator | **Signals:** $signalLine")
[void]$b.Add("> **Calendar:** $meetingLine")
if ($conflicts.Count -gt 0) {
    [void]$b.Add("> ⚠️ **$($conflicts.Count) conflict(s)** detected — see Calendar section")
}
[void]$b.Add("")

# ── Section 1: TOP 3 FOCUS ────────────────────────────────────────────────
[void]$b.Add("---")
[void]$b.Add("")
[void]$b.Add("## 🎯 TOP 3 FOCUS")
[void]$b.Add("")

if ($top3.Count -eq 0) {
    [void]$b.Add("No urgent signals detected. Check Action_Items.md for open items.")
    [void]$b.Add("")
} else {
    for ($i = 0; $i -lt $top3.Count; $i++) {
        $f = $top3[$i]
        $num = $i + 1
        $timeTag = ""
        if ($f.Time) { $timeTag = " ($($f.Time))" }

        [void]$b.Add("### $num. $($f.Priority) $($f.Title)")
        [void]$b.Add("- **Charter:** $($f.Charter)$timeTag")
        [void]$b.Add("- **Source:** $($f.Source)")
        if ($f.Related) { [void]$b.Add("- **Related:** $($f.Related)") }
        [void]$b.Add("")
    }
}

# ── Section 2: DAY AT A GLANCE (compact timeline) ────────────────────────
[void]$b.Add("---")
[void]$b.Add("")
[void]$b.Add("## 📅 DAY AT A GLANCE")
[void]$b.Add("")

if ($allMeetings.Count -eq 0) {
    [void]$b.Add("*No calendar data available.*")
    [void]$b.Add("")
} else {
    [void]$b.Add("| Time | What | Who | Type |")
    [void]$b.Add("|------|------|-----|------|")
    foreach ($m in $allMeetings) {
        $type = "📅"
        if ($m.IsFocus) { $type = "🎯 Focus" }
        elseif ($m.IsSelf) { $type = "🔒 Self" }
        else { $type = "👥 External" }

        $who = $m.Organizer
        if ($m.IsSelf) { $who = "Self" }

        # Truncate long titles
        $displayTitle = $m.Title
        if ($displayTitle.Length -gt 65) { $displayTitle = $displayTitle.Substring(0, 62) + "..." }

        [void]$b.Add("| $($m.Time) | $displayTitle | $who | $type |")
    }
    [void]$b.Add("")

    # Free slots
    if ($freeSlots.Count -gt 0) {
        $slotText = ($freeSlots | ForEach-Object { "$($_.Time) ($($_.Duration))" }) -join ", "
        [void]$b.Add("**Free slots:** $slotText")
        [void]$b.Add("")
    }

    # Conflicts
    if ($conflicts.Count -gt 0) {
        [void]$b.Add("**⚠️ Conflicts:**")
        foreach ($c in $conflicts) {
            [void]$b.Add("- **$($c.Meeting1)** ($($c.Time1)) overlaps **$($c.Meeting2)** ($($c.Time2))")
        }
        [void]$b.Add("")
    }
}

# ── Section 3: MEETING PREP (only for external meetings) ─────────────────
if ($externalMeetings.Count -gt 0) {
    [void]$b.Add("---")
    [void]$b.Add("")
    [void]$b.Add("## 📋 MEETING PREP")
    [void]$b.Add("")

    foreach ($m in $externalMeetings) {
        $charter = Get-Charter $m.Title
        $charterTag = ""
        if ($charter) { $charterTag = " `[$charter`]" }

        [void]$b.Add("### $($m.Time) — $($m.Title)$charterTag")
        [void]$b.Add("- **Organized by:** $($m.Organizer) | **Duration:** $($m.Duration) | **Status:** $($m.Status)")

        # Pull related action items from KB
        $relatedItems = @()
        if ($charter) {
            foreach ($a in ($urgentActions + $mediumActions + $otherTodos)) {
                if ($a.Charter -eq $charter) {
                    $relatedItems += $a
                }
            }
        }
        # Also keyword-match organizer name against action items
        $orgFirst = ($m.Organizer -split '\s')[0]
        foreach ($a in ($urgentActions + $mediumActions + $otherTodos)) {
            if ($a.Text -match [regex]::Escape($orgFirst) -or $a.Section -match [regex]::Escape($orgFirst)) {
                if ($relatedItems -notcontains $a) { $relatedItems += $a }
            }
        }

        if ($relatedItems.Count -gt 0) {
            [void]$b.Add("- **Open items to discuss:**")
            $shown = 0
            foreach ($ri in $relatedItems) {
                if ($shown -ge 4) { [void]$b.Add("  - *(+$($relatedItems.Count - 4) more in Action_Items.md)*"); break }
                [void]$b.Add("  - $($ri.Text)")
                $shown++
            }
        } else {
            [void]$b.Add("- *No tracked action items — check agenda before meeting.*")
        }
        [void]$b.Add("")
    }
}

# ── Section 4: FOCUS BLOCKS (self-created purpose blocks) ─────────────────
if ($focusBlocks.Count -gt 0) {
    [void]$b.Add("---")
    [void]$b.Add("")
    [void]$b.Add("## 🎯 FOCUS BLOCKS")
    [void]$b.Add("")
    [void]$b.Add("| Time | Task | Charter |")
    [void]$b.Add("|------|------|---------|")

    foreach ($fb in $focusBlocks) {
        $task = $fb.Title -replace '🎯 Focus:\s*', ''
        $charter = Get-Charter $task
        if (-not $charter) { $charter = "—" }
        [void]$b.Add("| $($fb.Time) | $task | $charter |")
    }
    [void]$b.Add("")
}

# ── Section 5: SIGNALS (only sections with real data) ─────────────────────
$hasAnySignal = $hasRealEmails -or $hasRealADO -or $hasRealChats -or $hasInboxFiles
if ($hasAnySignal) {
    [void]$b.Add("---")
    [void]$b.Add("")
    [void]$b.Add("## ⚡ SIGNALS")
    [void]$b.Add("")

    if ($hasRealEmails) {
        [void]$b.Add("### 📧 Emails")
        [void]$b.Add("")
        foreach ($e in $emailItems) {
            $charterTag = ""
            if ($e.Charter) { $charterTag = " `[$($e.Charter)`]" }
            $senderTag = ""
            if ($e.Sender) { $senderTag = " — $($e.Sender)" }
            [void]$b.Add("- **$($e.Subject)**$senderTag$charterTag")
        }
        [void]$b.Add("")
    }

    if ($hasRealADO) {
        [void]$b.Add("### 🔧 ADO Changes")
        [void]$b.Add("")
        [void]$b.Add("| ID | Title | State | Assigned |")
        [void]$b.Add("|---|---|---|---|")
        foreach ($item in $adoItems) {
            [void]$b.Add("| $($item.ID) | $($item.Title) | $($item.State) | $($item.Assigned) |")
        }
        [void]$b.Add("")
    }

    if ($hasRealChats) {
        [void]$b.Add("### 💬 Teams Chats")
        [void]$b.Add("")
        [void]$b.Add($chatSignals)
        [void]$b.Add("")
    }

    if ($hasInboxFiles) {
        [void]$b.Add("### 📥 New Files Processed")
        [void]$b.Add("")
        [void]$b.Add($inboxSignals)
        [void]$b.Add("")
    }
}

# ── Section 6: OPEN ACTIONS (grouped by charter) ─────────────────────────
[void]$b.Add("---")
[void]$b.Add("")
[void]$b.Add("## 📌 OPEN ACTIONS")
[void]$b.Add("")

# Group all actions by charter
$allActions = @()
foreach ($a in $urgentActions) { $allActions += @{ Text = $a.Text; Charter = $a.Charter; Priority = "🔴" } }
foreach ($a in $mediumActions) { $allActions += @{ Text = $a.Text; Charter = $a.Charter; Priority = "🟡" } }

if ($allActions.Count -eq 0) {
    [void]$b.Add("*No open action items with explicit priority. See [Action_Items.md](../Knowledge_Base/Action_Items.md) for full list.*")
    [void]$b.Add("")
} else {
    # Get unique charters, sort so they're grouped
    $charters = @{}
    foreach ($a in $allActions) {
        if (-not $charters.ContainsKey($a.Charter)) { $charters[$a.Charter] = @() }
        $charters[$a.Charter] += $a
    }

    foreach ($charter in ($charters.Keys | Sort-Object)) {
        $items = $charters[$charter]
        $urgCount = ($items | Where-Object { $_.Priority -eq "🔴" }).Count
        $medCount = ($items | Where-Object { $_.Priority -eq "🟡" }).Count
        $countTag = @()
        if ($urgCount -gt 0) { $countTag += "$urgCount 🔴" }
        if ($medCount -gt 0) { $countTag += "$medCount 🟡" }
        [void]$b.Add("### $charter ($($countTag -join ', '))")
        foreach ($item in $items) {
            [void]$b.Add("- $($item.Priority) $($item.Text)")
        }
        [void]$b.Add("")
    }

    # Show count of unprioritized TODOs
    if ($otherTodos.Count -gt 0) {
        [void]$b.Add("*+ $($otherTodos.Count) more TODOs without priority flag — see [Action_Items.md](../Knowledge_Base/Action_Items.md)*")
        [void]$b.Add("")
    }
}

# ── Section 7: AGENT REASONING LOG ──────────────────────────────────────
[void]$b.Add("---")
[void]$b.Add("")
[void]$b.Add("## 🧠 Agent Reasoning (CoT Log)")
[void]$b.Add("> How this brief was prioritized — for Copilot context and human audit")
[void]$b.Add("")
foreach ($reason in $cotLog) {
    [void]$b.Add($reason)
}
[void]$b.Add("")
[void]$b.Add("> *Prompt strategy: Step-Back → CoT → Signal-grounded output. Temperature: 0.1. See prompt_templates/daily_brief.md*")
[void]$b.Add("")

# ── Section 8: REFERENCE ─────────────────────────────────────────────────
[void]$b.Add("---")
[void]$b.Add("")
[void]$b.Add("## 📚 REFERENCE")
[void]$b.Add("")
[void]$b.Add("| Resource | Path |")
[void]$b.Add("|----------|------|")
[void]$b.Add("| Action Items | ``Knowledge_Base/Action_Items.md`` |")
[void]$b.Add("| Charter Areas | ``Knowledge_Base/Charter_Areas.md`` |")
[void]$b.Add("| Key Contacts | ``Knowledge_Base/Key_Contacts.md`` |")
[void]$b.Add("| Partners | ``Knowledge_Base/Partners.md`` |")
[void]$b.Add("| AI PM Skills | ``Knowledge_Base/AI_PM_Skills.md`` |")
[void]$b.Add("| Agent Checklist | ``Knowledge_Base/Agent_Build_Checklist.md`` |")
[void]$b.Add("| Failure Playbook | ``Knowledge_Base/Agent_Failure_Playbook.md`` |")
[void]$b.Add("| Trust Boundaries | ``Knowledge_Base/Trust_Boundaries.md`` |")
[void]$b.Add("| Prompt Templates | ``_Automation/prompt_templates/`` |")
[void]$b.Add("| Eval Suite | ``_Automation/evals/brief_eval_suite.md`` |")
[void]$b.Add("| Signals (raw) | ``00_Daily_Intelligence/Signals/`` |")
[void]$b.Add("| Landing Zone | ``_Inbox/`` |")
[void]$b.Add("")

# ═══════════════════════════════════════════════════════════════════════════
# 10. WRITE OUTPUT
# ═══════════════════════════════════════════════════════════════════════════

$b | Set-Content $OUTPUT_FILE -Encoding UTF8
Write-Host "✅ Daily brief generated: $OUTPUT_FILE"
Write-Host "   Focus items: $($top3.Count) | Meetings: $($allMeetings.Count) | Actions: $($urgentActions.Count) urgent, $($mediumActions.Count) medium"
