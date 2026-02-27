---
name: m365_teams_comms
description: Draft and send Teams messages, channel posts, and status updates. Supports structured formats for standups, announcements, and cross-team comms.
---

# /m365_teams_comms - Teams Communication Drafter

Draft and manage Teams messages — chat messages, channel posts, standups, announcements, and cross-team communications.

## Usage

```
/m365_teams_comms <action> | [options]
```

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `draft` | Draft a Teams message | `/m365_teams_comms draft \| standup update` |
| `announce` | Draft a channel announcement | `/m365_teams_comms announce \| project-alpha backlog blitz starting` |
| `standup` | Generate daily standup message | `/m365_teams_comms standup` |
| `shoutout` | Draft a recognition message | `/m365_teams_comms shoutout \| teammate for excellent API contribution` |
| `escalate` | Draft an escalation message | `/m365_teams_comms escalate \| P0 regression in your-repo` |
| `status` | Draft a status broadcast | `/m365_teams_comms status \| weekly project-alpha update` |

## Examples

```
/m365_teams_comms standup
/m365_teams_comms draft | message to teammate about on-call rotation gap next week
/m365_teams_comms announce | feature timeline update for team channel
/m365_teams_comms shoutout | teammate for branch policy improvements
/m365_teams_comms escalate | critical issue #1234 response needed
/m365_teams_comms status | project-alpha weekly metrics update
```

## Instructions

### For `standup` action:

1. **Auto-gather context:**
   - Read `00_Daily_Intelligence/Signals/calendar_YYYY-MM-DD.md` for today's meetings
   - Read `00_Daily_Intelligence/Signals/ado_YYYY-MM-DD.md` for ADO changes
   - Read `00_Daily_Intelligence/Signals/emails_YYYY-MM-DD.md` for important emails
   - Read `00_Daily_Intelligence/Knowledge_Base/Action_Items.md` for due/overdue items

2. **Generate standup message:**
   ```
   📋 **Standup — [Date]**
   
   **✅ Yesterday:**
   • [Completed item 1]
   • [Completed item 2]
   
   **🔄 Today:**
   • [Planned item 1 — with meeting context if relevant]
   • [Planned item 2]
   
   **🚧 Blockers:**
   • [Blocker or "None" if clear]
   
   **📅 Key Meetings:**
   • [Time] — [Meeting] with [names]
   ```

3. **Present to user — ready to paste into Teams chat**

### For `draft` action:

1. **Parse intent from description**
2. **Gather recipient context from Key_Contacts.md**
3. **Check recent signals for relevant context**
4. **Draft message with appropriate tone:**
   - Team chat: Casual, concise, emoji-friendly
   - Channel post: Professional, structured
   - EM message: Direct, action-oriented
   - Cross-team: Formal, context-rich

5. **Format for Teams (markdown-compatible):**
   - Use **bold** for emphasis
   - Use bullet lists for structured info
   - Use `code` for IDs, commands, technical terms
   - Keep under 500 characters for chat, longer for channels

### For `announce` action:

1. **Identify the announcement type:**
   - Process change, timeline update, incident, feature launch, recognition

2. **Generate channel post with structure:**
   ```
   📢 **[Announcement Title]**
   
   **What:** [1-2 sentence summary]
   
   **Why:** [Context/motivation]
   
   **Impact:** [Who is affected, what changes]
   
   **Action Required:** [What recipients need to do, or "No action needed — FYI only"]
   
   **Timeline:** [Key dates]
   
   **Questions?** Reach out to [contact] or reply in this thread.
   
   cc: @[name1] @[name2]
   ```

### For `shoutout` action:

1. **Gather context on the person and their work:**
   - Check Key_Contacts.md for role and team
   - Use Work IQ to find recent accomplishments
   - Check ADO for completed items

2. **Generate recognition message:**
   ```
   🌟 **Shoutout: [Name]**
   
   Big thanks to @[name] for [specific accomplishment]!
   
   **What they did:** [2-3 sentences on the contribution]
   
   **Impact:** [How it helped the team/project]
   
   [Appropriate emoji + positive closing]
   ```

3. **Suggest appropriate channel** (team chat, team channel, etc.)

### For `escalate` action:

1. **Parse the escalation context**
2. **Gather evidence:**
   - ADO items, incidents, GitHub issues
   - Impact data, timeline, who's affected
   
3. **Generate escalation message:**
   ```
   🚨 **[Priority] Escalation: [Title]**
   
   **Severity:** [P0/P1/P2]
   **Impact:** [Who/what is affected]
   
   **Issue:** [Concise description]
   
   **Evidence:**
   • [Data point 1]
   • [Data point 2]
   • [Relevant ADO/incident/GitHub link]
   
   **Ask:** [What you need from the recipients]
   **Deadline:** [When you need it by]
   
   **Suggested Next Steps:**
   1. [Step 1]
   2. [Step 2]
   
   cc: @[EM] @[affected team lead]
   ```

### For `status` action:

1. **Aggregate from all sources:**
   - ADO status (use m365_ado_reporter logic)
   - Action items status
   - Key signals from the week
   - Metrics if applicable (project funnel metrics)

2. **Generate status broadcast:**
   ```
   📊 **[Charter/Project] Status Update — Week of [Date]**
   
   **🟢 On Track | 🟡 At Risk | 🔴 Blocked**
   
   **Highlights:**
   ✅ [Achievement 1]
   ✅ [Achievement 2]
   
   **In Progress:**
   🔄 [Item 1 — owner, ETA]
   🔄 [Item 2 — owner, ETA]
   
   **Risks/Blockers:**
   ⚠️ [Risk — mitigation plan]
   
   **Key Metrics:**
   • [Metric 1]: [value] (target: [target])
   • [Metric 2]: [value] (target: [target])
   
   **Next Week Focus:**
   • [Priority 1]
   • [Priority 2]
   ```

## Teams Formatting Guidelines

| Element | Syntax | Use For |
|---------|--------|---------|
| Bold | `**text**` | Headings, emphasis |
| Italic | `*text*` | Subtle emphasis |
| Code | `` `text` `` | IDs, commands, technical terms |
| Bullet | `• ` or `- ` | Lists |
| Emoji | Native emoji | Status indicators, tone |
| Mention | `@name` | Alerting people (user fills in) |
| Link | `[text](url)` | References |

## Tone Guide

| Audience | Tone | Emoji Level | Length |
|----------|------|-------------|--------|
| Direct team | Casual, warm | High 🎉 | Short |
| EMs | Professional-direct | Moderate 📊 | Medium |
| Cross-team | Professional-structured | Low-moderate | Medium |
| Leadership | Formal, data-led | Minimal 📋 | Short |
| External/Partners | Formal, polished | None | Medium |

## Context Sources

| Source | Auto-Checked For | 
|--------|-----------------|
| `calendar_YYYY-MM-DD.md` | Standup meeting context |
| `ado_YYYY-MM-DD.md` | Status updates, sprint data |
| `emails_YYYY-MM-DD.md` | Follow-up context |
| `Action_Items.md` | Due items, ownership |
| `Key_Contacts.md` | Recipient details, @mentions |
| Work IQ | Recent chats, thread context |

## Error Handling

- **Teams context unavailable:** Draft message as plain text for manual paste
- **Recipient not in Key_Contacts.md:** Ask user for alias
- **Work IQ unavailable:** Generate from workspace signals only

## Cross-Skill References

| When You Need To... | Use This Skill | How |
|---------------------|---------------|-----|
| Send same update as email too | `/m365_email_drafter draft` | Adapt Teams message for email format |
| Include ADO metrics in status | `/m365_ado_reporter status` | Fetch sprint health or item counts |
| Reference meeting context in standup | `/m365_meeting_prep today` | Pull today's meetings into standup |
| Attach a formal doc to announcement | `/m365_doc_generator word` | Generate deliverable, link in Teams post |

## Time Saved

~5-10 minutes per message (context gathering, formatting, tone calibration)
