---
name: m365_meeting_prep
description: Auto-generate meeting preparation documents by combining calendar data, recent signals, ADO items, and Work IQ intelligence. Produces structured prep docs with agenda, talking points, and context.
---

# /m365_meeting_prep - Intelligent Meeting Preparation

Auto-generate meeting preparation documents by cross-referencing calendar, signals, ADO, and M365 data.

## Usage

```
/m365_meeting_prep <action> | [options]
```

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `prep` | Generate full meeting prep doc | `/m365_meeting_prep prep \| EM sync tomorrow` |
| `agenda` | Generate a structured agenda | `/m365_meeting_prep agenda \| project-alpha monthly review` |
| `brief` | Quick 1-page briefing for a meeting | `/m365_meeting_prep brief \| manager 1:1` |
| `today` | Prep docs for all today's meetings | `/m365_meeting_prep today` |
| `week` | Preview prep needs for the week | `/m365_meeting_prep week` |

## Examples

```
/m365_meeting_prep prep | EM meeting with manager Feb 14
/m365_meeting_prep agenda | project-alpha monthly review with all EMs
/m365_meeting_prep brief | Partner Corp partner sync
/m365_meeting_prep today
/m365_meeting_prep prep | feature discussion with team members
```

## Instructions

### For `prep` action:

1. **Identify the meeting:**
   - Check `00_Daily_Intelligence/Signals/calendar_YYYY-MM-DD.md` for meeting details
   - Use Work IQ: `mcp_workiq_ask_work_iq("What are the details of [meeting name] on [date]?")`
   - Extract: title, time, attendees, recurring/one-off, organizer

2. **Gather context (in parallel where possible):**

   **From Workspace:**
   - `00_Daily_Intelligence/Knowledge_Base/Key_Contacts.md` — attendee roles, relationships
   - `00_Daily_Intelligence/Knowledge_Base/Action_Items.md` — open items for these attendees
   - `00_Daily_Intelligence/Knowledge_Base/Charter_Areas.md` — relevant charter context
   - `00_Daily_Intelligence/Signals/emails_YYYY-MM-DD.md` — recent email threads with attendees
   - `00_Daily_Intelligence/Signals/ado_YYYY-MM-DD.md` — ADO state changes relevant to meeting
   - Recent files in project folders (e.g., `projects/project-alpha/`, `projects/project-beta/` etc.)

   **From Work IQ:**
   - Recent emails/chats with each attendee (last 7 days)
   - Any shared documents or decks recently modified
   - Previous meeting notes (if recurring)
   - Action items from last occurrence of this meeting

   **From ADO (if applicable):**
   - Use `mcp_azure-devops_wit_my_work_items` for assigned items
   - Use `mcp_azure-devops_search_workitem` for items related to meeting topics
   - Use `mcp_azure-devops_wit_get_work_items_batch_by_ids` for specific tracked items

3. **Generate prep document:**

   ```markdown
   # Meeting Prep: [Meeting Title]
   
   **Date:** [date/time]
   **Duration:** [duration]
   **Attendees:** [name (role)] for each attendee
   **Location/Link:** [Teams link or room]
   **Recurring:** [Yes/No — last met: date]
   
   ---
   
   ## 🎯 Meeting Objective
   [1-2 sentences: What needs to be accomplished]
   
   ## 📋 Suggested Agenda
   | # | Topic | Time | Lead | Notes |
   |---|-------|------|------|-------|
   | 1 | [topic] | 5 min | [name] | [context] |
   | 2 | [topic] | 10 min | [name] | [context] |
   
   ## 🔑 Key Context
   ### What Happened Since Last Meeting
   - [Signal 1 — from emails/ADO/chats]
   - [Signal 2]
   - [Signal 3]
   
   ### Open Action Items for These Attendees
   | # | Action | Owner | Status | Due |
   |---|--------|-------|--------|-----|
   | 1 | [item] | [name] | [status] | [date] |
   
   ### Relevant ADO Items
   | ID | Title | State | Assigned | Changed |
   |----|-------|-------|----------|---------|
   | [id] | [title] | [state] | [name] | [date] |
   
   ## 💬 Talking Points for You
   1. **[Topic]:** [What to say, data to reference]
   2. **[Topic]:** [Position, ask, or update]
   3. **[Topic]:** [Risk to flag or decision to request]
   
   ## ❓ Questions to Ask
   1. [Question for specific attendee]
   2. [Question about timeline/blocker]
   
   ## 🎯 Desired Outcomes
   - [ ] [Decision 1]
   - [ ] [Commitment 1]
   - [ ] [Next step 1]
   
   ## 📎 Reference Materials
   - [Link to relevant doc/deck/report]
   - [ADO query link]
   ```

4. **Save to workspace:**
   - Save as `00_Daily_Intelligence/Meeting_Prep/prep_YYYY-MM-DD_[meeting-slug].md`
   - Display summary to user

### For `agenda` action:

1. Same context gathering as `prep` but output only the agenda section
2. Format as a numbered list with time allocations
3. Include facilitator notes for each item

### For `brief` action:

1. Condensed 1-page version of `prep`
2. Focus on: Objective, 3 key points, 2 asks, 1 risk
3. No tables — bullets only for quick scanning

### For `today` action:

1. Read `00_Daily_Intelligence/Signals/calendar_YYYY-MM-DD.md` for today's meetings
2. For each meeting, generate a `brief` (not full `prep`)
3. Output as a single document with meeting sections
4. Highlight conflicts or back-to-back meetings
5. Save to `00_Daily_Intelligence/Meeting_Prep/today_YYYY-MM-DD.md`

### For `week` action:

1. Use Work IQ to get this week's calendar: `mcp_workiq_ask_work_iq("What meetings do I have this week?")`
2. Generate a week preview:
   ```
   ## Week of [date range]
   
   | Day | Time | Meeting | Attendees | Prep Status |
   |-----|------|---------|-----------|-------------|
   | Mon | 10AM | Project Review | Team Lead, Team Member... | ✅ Prepped |
   | Tue | 2PM | Manager 1:1 | Your Manager | 🔲 Needs prep |
   ```
3. Flag meetings that need prep attention

## Meeting Type Templates

| Type | What's Included | Extra Intelligence |
|------|----------------|-------------------|
| **1:1 with EM** | Career items, blockers, status | Recent feedback signals |
| **Project Review** | Funnel metrics, gap status, ADO epic | GitHub issue trends |
| **Partner Sync** | Feature timeline, open issues | Partner history from `Partners.md` |
| **Feature Discussion** | API pipeline, feature gaps | Team members' recent work |
| **All-hands/Big Meeting** | Team OKRs, charter status, shoutouts | Recent accomplishments |
| **Release Review** | Bug counts, release gates, P0 status | Active incidents |

## Context Sources (Auto-Checked)

| Source | What It Provides | Priority |
|--------|-----------------|----------|
| Calendar signals | Meeting details, attendees, time | 1 |
| Work IQ | Emails/chats/docs with attendees | 2 |
| Key_Contacts.md | Roles, relationships, preferences | 3 |
| Action_Items.md | Open items per attendee | 4 |
| ADO signals | Work item state changes | 5 |
| Charter_Areas.md | Feature/scope context | 6 |
| Email signals | Recent thread context | 7 |

## Output Location

```
00_Daily_Intelligence/
  Meeting_Prep/
    prep_2026-02-14_em-sync.md
    prep_2026-02-14_monthly-review.md
    today_2026-02-14.md
    week_2026-02-10.md
```

## Error Handling

- **No calendar signal file:** Use Work IQ to get calendar data directly
- **Meeting not found:** Ask user to specify meeting title or time
- **Work IQ unavailable:** Generate from workspace signals only (degraded mode)
- **No previous meeting notes:** Flag as "First occurrence" and use general context

## Cross-Skill References

| When You Need To... | Use This Skill | How |
|---------------------|---------------|-----|
| Send follow-up email after meeting | `/m365_email_drafter followup` | Feed prep doc's action items into follow-up template |
| Check ADO items for attendees | `/m365_ado_reporter query` | Fetch assigned items by attendee name |
| Draft pre-meeting Teams message | `/m365_teams_comms draft` | Share agenda or pre-read in Teams chat |
| Generate a formal meeting brief | `/m365_doc_generator brief` | Create 1-page Word brief from prep data |

## Time Saved

~20-30 minutes per meeting (context gathering from 5+ sources, structuring agenda, formulating talking points)
