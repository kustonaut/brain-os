# Daily Intelligence

This folder is the intelligence hub for Brain OS.

## Structure

| Folder | Purpose | Retention |
|--------|---------|-----------|
| `Knowledge_Base/` | Persistent context files (committed) | Permanent |
| `Signals/` | Daily raw signals from email, ADO, calendar, chats | 14 days |
| `Daily_Briefs/` | AI-synthesized daily summaries | 30 days |
| `Daily_Logs/` | Manual daily log entries from `/eod` | Permanent |
| `Weekly_Snapshots/` | Friday aggregations of the week | Permanent |
| `Meeting_Prep/` | Auto-generated meeting prep docs | 30 days |

## Signal Files (Auto-Generated)

Created daily by the pipeline:
- `emails_YYYY-MM-DD.md` — Outlook email highlights
- `ado_YYYY-MM-DD.md` — Azure DevOps work item states
- `calendar_YYYY-MM-DD.md` — Today/tomorrow meetings
- `chats_YYYY-MM-DD.md` — Teams chat summaries

## Priority Rule

When answering questions, Copilot reads in this order:
1. **Signal files** (most current)
2. **Knowledge Base** (persistent context)
3. **Daily Briefs** (synthesized, most recent first)
