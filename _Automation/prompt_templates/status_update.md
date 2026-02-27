# Template: Status Update Email
# Temperature: 0.5
# Purpose: Generate a professional status update email for stakeholders

## Context
- **Author:** {{pm_name}}
- **Date:** {{date}}
- **Audience:** {{audience}} (e.g., "leadership", "team", "stakeholders")
- **Period:** {{period}} (e.g., "this week", "this sprint", "this month")

## Input Data
{{signals_summary}}

## Action Items
{{action_items}}

---

Generate a status update email with:

**Subject:** [{{period}}] Status Update — {{project_name}}

**Body:**

1. **Summary** (2-3 sentences) — High-level status
2. **Accomplishments** — What shipped/completed this period
3. **In Progress** — What's actively being worked on
4. **Risks & Blockers** — Issues that need attention or help
5. **Next Steps** — Planned work for next period
6. **Asks** — Specific requests from the audience (if any)

Rules:
- Professional but approachable tone
- Use bullet points, not paragraphs
- Include specific numbers/metrics where available
- Keep under 300 words
- No jargon the audience wouldn't know
