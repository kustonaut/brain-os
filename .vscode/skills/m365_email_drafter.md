---
name: m365_email_drafter
description: Draft, format, and send professional emails via Outlook COM/Graph. Supports templates for status updates, escalations, meeting follow-ups, and partner comms.
---

# /m365_email_drafter - Professional Email Drafter & Sender

Draft, format, and send professional emails via Outlook. Built for PM workflows — status updates, escalations, follow-ups, partner comms.

## Usage

```
/m365_email_drafter <action> | [options]
```

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `draft` | Draft an email from template or prompt | `/m365_email_drafter draft \| status_update` |
| `send` | Draft and send immediately | `/m365_email_drafter send \| escalation to manager` |
| `reply` | Draft a reply to a recent email | `/m365_email_drafter reply \| accept meeting with notes` |
| `followup` | Auto-generate follow-up from meeting/action items | `/m365_email_drafter followup \| EM meeting Feb 14` |
| `templates` | List available email templates | `/m365_email_drafter templates` |

## Examples

```
/m365_email_drafter draft | status update on project-alpha for your manager
/m365_email_drafter draft | partner briefing for Partner Corp on feature timeline
/m365_email_drafter send | escalation to stakeholder about E5 licensing gap
/m365_email_drafter followup | EM sync meeting action items
/m365_email_drafter reply | decline with alternative time suggestion
```

## Instructions

### For `draft` action:

1. **Identify template or freestyle:**
   - If a template name is given (e.g., `status_update`, `escalation`), load template structure
   - If freestyle text, use the description to compose the email

2. **Gather context automatically:**
   - Check `00_Daily_Intelligence/Knowledge_Base/Key_Contacts.md` for recipient details (name, alias, role)
   - Check `00_Daily_Intelligence/Knowledge_Base/Action_Items.md` for relevant open items
   - Check `00_Daily_Intelligence/Signals/` for today's signals (emails, ADO, calendar)
   - Check relevant charter folder for recent deliverables

3. **Use Work IQ (mcp_workiq_ask_work_iq) when needed:**
   - Search for recent email threads with the recipient for context/tone
   - Find relevant docs or meeting notes to reference
   - Get current status of work items being discussed

4. **Draft the email with this structure:**
   ```
   Subject: [Clear, actionable subject line]
   To: [Full name] <alias@company.com>
   CC: [If applicable]
   
   [Greeting — match formality to recipient relationship]
   
   [Opening — 1 sentence context/purpose]
   
   [Body — structured with bullets or numbered items]
   
   [Ask/Action — clear next step with timeline]
   
   [Sign-off]
   [Your Name]
   Program Manager
   ```

5. **Present draft to user for review before sending**

### For `send` action:

1. Complete all `draft` steps above
2. After user confirms, send via Outlook COM:
   ```powershell
   $outlook = New-Object -ComObject Outlook.Application
   $mail = $outlook.CreateItem(0)
   $mail.To = "recipient@company.com"
   $mail.CC = "cc@company.com"  # if applicable
   $mail.Subject = "Subject Line"
   $mail.HTMLBody = @"
   <html><body style="font-family: Calibri, sans-serif; font-size: 11pt;">
   $emailBody
   </body></html>
   "@
   $mail.Send()
   ```
3. Confirm delivery and log action

### For `reply` action:

1. **Get context on the email being replied to:**
   - Use Work IQ: `mcp_workiq_ask_work_iq` to find the recent email thread
   - Or check `00_Daily_Intelligence/Signals/emails_YYYY-MM-DD.md` for today's email highlights
   
2. **Draft reply matching the thread tone and context**
   - Acknowledge their points
   - Address questions/asks
   - Provide clear next steps

3. **Present reply draft to user**

### For `followup` action:

1. **Identify the meeting/event:**
   - Check `00_Daily_Intelligence/Signals/calendar_YYYY-MM-DD.md` for meeting details
   - Use Work IQ to find meeting notes or chat context
   - Check `00_Daily_Intelligence/Knowledge_Base/Action_Items.md` for action items from that meeting

2. **Generate follow-up email:**
   ```
   Subject: Follow-up: [Meeting Name] — Action Items & Next Steps
   
   Hi team,
   
   Thank you for [meeting/sync] today. Here's a summary of what we discussed and agreed:
   
   **Key Decisions:**
   1. [Decision 1]
   2. [Decision 2]
   
   **Action Items:**
   | # | Action | Owner | Due |
   |---|--------|-------|-----|
   | 1 | [item] | [name] | [date] |
   
   **Next Meeting:** [date/time if applicable]
   
   Please flag anything I missed or got wrong.
   
   Thanks,
   [Your Name]
   ```

3. **Present draft for review**

### For `templates` action:

Display available templates:

| Template | Use Case | Key Fields |
|----------|----------|------------|
| `status_update` | Weekly/ad-hoc status to EM | Charter area, progress, blockers |
| `escalation` | Escalate a blocker or risk | Issue, impact, ask, timeline |
| `partner_briefing` | Update to external partner | Feature status, timeline, next steps |
| `meeting_followup` | Post-meeting summary + actions | Decisions, AIs, next meeting |
| `introduction` | Introduce self or connect people | Context, purpose, ask |
| `bug_update` | Update stakeholders on a bug | Bug ID, status, ETA, workaround |
| `review_request` | Ask for doc/code/spec review | Doc link, context, deadline |
| `thank_you` | Acknowledge contribution | What they did, impact, visibility |

## Email Formatting Rules

1. **Subject lines:** Always actionable. Include `[Action Required]`, `[FYI]`, `[Decision Needed]` prefixes when appropriate.
2. **Length:** Keep under 300 words for routine emails. Use bullets, not paragraphs.
3. **Tone ladder:**
   - Engineering Managers: Professional-casual, direct
   - External partners: Formal, solution-oriented
   - Peers: Casual-professional
   - Leadership: Formal, concise, data-led
4. **Always include:** Clear ask or next step. No email without a purpose.
5. **HTML formatting:** Use Calibri 11pt, minimal colors, professional layout.

## Context Sources (Auto-Checked)

| Source | What It Provides |
|--------|-----------------|
| `Key_Contacts.md` | Recipient name, alias, role, team |
| `Action_Items.md` | Open items, ownership, deadlines |
| `emails_YYYY-MM-DD.md` | Today's email signal highlights |
| `calendar_YYYY-MM-DD.md` | Today's meetings, context |
| `Charter_Areas.md` | Feature scope, status, architecture |
| Work IQ | Recent email threads, docs, meeting notes |

## Error Handling

- **Outlook not running:** Prompt user to open Outlook
- **Recipient not found:** Check Key_Contacts.md, suggest closest match
- **Work IQ unavailable:** Fall back to workspace signals only
- **Send failed:** Save draft to Outlook Drafts folder, report error

## Cross-Skill References

| When You Need To... | Use This Skill | How |
|---------------------|---------------|-----|
| Follow up after a meeting | `/m365_meeting_prep prep` | Generate prep doc first, draft follow-up from its action items |
| Include ADO status in email | `/m365_ado_reporter status` | Fetch item state, paste into email body |
| Send a formal report as attachment | `/m365_doc_generator word` | Generate Word doc, attach to email |
| Post same update in Teams too | `/m365_teams_comms draft` | Adapt email content for Teams channel format |

## Time Saved

~10-15 minutes per email (context gathering, formatting, tone calibration)
