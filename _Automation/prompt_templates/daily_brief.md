# Template: Daily Brief
# Temperature: 0.1
# Purpose: Generate the daily intelligence brief from all signal sources

Given the following signals from {{date}}:

## Email Signals
{{email_signals}}

## ADO Signals
{{ado_signals}}

## Calendar Signals
{{calendar_signals}}

## Chat Signals
{{chat_signals}}

## Current Goals (from Goals.md)
{{goals_summary}}

## Open Action Items
{{action_items}}

---

Generate a daily brief with these sections:

1. **🔴 Urgent / Needs Attention** — Items requiring action today
2. **📊 Key Metrics & Status** — Numbers, progress, health indicators
3. **📅 Today's Agenda** — Meetings with prep notes
4. **📧 Important Communications** — Emails/chats needing response
5. **🎯 Focus Areas** — Top 3 priorities aligned with Goals.md
6. **⚡ Quick Wins** — Small tasks that can be knocked out today

Rules:
- Be factual — only reference data from the signals
- Flag risks and blockers prominently
- Link action items to Goals.md OKRs where possible
- Keep each section to 3-5 bullet points max
