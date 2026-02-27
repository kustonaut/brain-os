# Capture — Context Out Skill

## Trigger
`/capture` or when user says "capture", "what was decided", "log action items", "meeting notes"

## Purpose
Extract decisions, action items, and key signals from meetings/conversations and route them to the correct project files. This is the **Context OUT** complement to `/m365_meeting_prep` (Context IN).

## Actions

### `capture` (default)
Pull meeting context and extract structured output:

1. **Identify source:**
   - Teams meeting chat (via Work IQ / Graph if available)
   - User-pasted meeting notes
   - Transcript file from `Transcripts/` folder
   - Current conversation context

2. **Extract:**
   - **Decisions** — What was decided, by whom, with rationale
   - **Action Items** — Task, owner, deadline (if mentioned)
   - **Key Signals** — Risks, blockers, escalations, dependencies
   - **Follow-ups** — Questions deferred, people to loop in

3. **Route to files:**
   - Action items → `00_Daily_Intelligence/Knowledge_Base/Action_Items.md` (appropriate section)
   - Charter-specific items → respective project folder (`projects/project-alpha/`, `projects/project-beta/`, etc.)
   - Cross-cutting signals → `00_Daily_Intelligence/Signals/` as dated note

4. **Confirm with user:**
   - Show extracted items in structured format
   - Ask: "Did I capture everything? Any corrections?"
   - Apply feedback before writing to files

### `route`
Route a specific item to the correct file:
- Parse the item description
- Match to project area using keywords from `config.json`
- Write to the appropriate file
- Confirm the routing

### `review`
Show what was captured today:
- List all items added to Action_Items.md today
- List all files modified by `/capture` today
- Flag any items without owners or deadlines

## Output Format
```
## 📋 Captured from [Meeting Name] — [Date]

### Decisions
1. **[Decision]** — Owner: [Name] | Rationale: [Why]

### Action Items
| # | Action | Owner | Deadline | Route |
|---|--------|-------|----------|-------|
| 1 | [Task] | [Who] | [When]   | [File] |

### Signals
- 🔴 [Risk/Blocker]
- 🟡 [Watch item]
- 🟢 [Positive signal]

### Follow-ups
- [ ] [Question/person to loop in]

---
**What can I draft or update for you based on this?**
```

## Context Sources
- `00_Daily_Intelligence/Knowledge_Base/Action_Items.md` — existing action items (avoid duplicates)
- `00_Daily_Intelligence/Knowledge_Base/Key_Contacts.md` — resolve names to aliases
- `00_Daily_Intelligence/Knowledge_Base/Charter_Areas.md` — route by charter area
- `_Automation/config.json` — routing keywords
- Meeting transcripts from `*/Transcripts/` folders

## Rules
1. **Always confirm before writing** — Show extracted items, get user approval, then write
2. **Deduplicate** — Check Action_Items.md for existing items before adding
3. **Add dates** — Every captured item gets today's date
4. **Proactive next step** — Always end with "What can I draft or update for you based on this?"
5. **Tag source** — Note which meeting/conversation the item came from
