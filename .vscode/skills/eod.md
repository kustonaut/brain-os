# End of Day — Reflective Close Skill

## Trigger
`/eod` or when user says "end of day", "close day", "wrap up", "daily reflection"

## Purpose
Interactive daily close-out: review tasks, capture what happened, archive completed work, update goals, and seed tomorrow's priorities. This is the **flywheel connector** — `/eod` output feeds tomorrow's `/morning` (daily brief).

## Actions

### `eod` (default)
Full end-of-day workflow:

#### Step 1: Show Active Tasks
Read `00_Daily_Intelligence/Knowledge_Base/Action_Items.md` and display:
- All items in 🔴 THIS WEEK section
- Any items touched/mentioned today
- Items with today's date or past-due

#### Step 2: Interactive Check-in
For each active task, ask:
- **Done** → Mark with ✅, add completion date, move to archive section
- **Carry** → Keep in active, note "carried from [date]"
- **Defer** → Move to 🟡 NEXT 2 WEEKS or ⚪ BACKLOG with reason
- **New** → Capture any new items that emerged today
- **Blocked** → Flag with blocker reason, suggest escalation path

#### Step 3: Daily Feedback
Ask the user:
- "How did today go? Any wins or frustrations?"
- "Any preferences to remember for next time?" (tone, format, approach)
- "Anything I should handle differently?"

Capture responses in a dated entry.

#### Step 4: Update Goals
Read `00_Daily_Intelligence/Knowledge_Base/Goals.md`:
- If any key result made progress today, update the status
- If a metric changed, note the delta
- Flag any goal that hasn't had activity in >5 days

#### Step 5: Generate Summary
Create a brief summary:

```
## 📊 EOD Summary — [Date]

### ✅ Completed Today
- [Item 1]
- [Item 2]

### ➡️ Carrying Forward
- [Item] — reason: [why]

### 🔴 Blocked
- [Item] — blocker: [what], escalation: [suggestion]

### 📝 New Items Added
- [Item] — routed to: [section]

### 🎯 Goal Progress
- Goal 1: [status change]
- Goal 2: [no change]

### 💡 Tomorrow's Preview
Based on calendar + tasks + goals:
1. [Top priority for tomorrow]
2. [Second priority]
3. [Meeting prep needed for...]

### 📋 Feedback Captured
- [User feedback summary]

---
**What can I start preparing for tomorrow?**
```

#### Step 6: Write Updates
- Update `Action_Items.md` with all changes
- Update `Goals.md` weekly reflection (Fridays)
- Append summary to `00_Daily_Intelligence/Daily_Logs/[date].md`

### `quick`
Abbreviated EOD — just task status + tomorrow preview (skip feedback/goals):
- Show tasks, mark Done/Carry/Defer
- Generate 3-line tomorrow preview
- Write updates

### `wins`
Just capture today's wins for weekly reporting:
- Ask for 2-3 wins
- Tag to goals
- Save for weekly snapshot aggregation

## Context Sources
- `00_Daily_Intelligence/Knowledge_Base/Action_Items.md` — active tasks
- `00_Daily_Intelligence/Knowledge_Base/Goals.md` — OKRs and metrics
- `00_Daily_Intelligence/Signals/calendar_YYYY-MM-DD.md` — tomorrow's calendar
- `00_Daily_Intelligence/Daily_Briefs/` — today's brief (what was planned)
- `00_Daily_Intelligence/Daily_Logs/` — previous EOD logs

## Rules
1. **Always interactive** — Don't auto-complete tasks. Ask the user for each one.
2. **Capture feedback** — The user's feedback trains the system. Never skip Step 3 unless explicitly told `/eod quick`.
3. **Update files atomically** — Make all changes after confirmation, not during the walkthrough.
4. **Proactive closer** — Always end with "What can I start preparing for tomorrow?"
5. **Friday special** — On Fridays, also update Goals.md weekly reflection and suggest running Weekly Snapshot.
6. **Connect the flywheel** — Reference today's brief to show what was planned vs. what happened.
