# Action Items

> Central action item tracker. Updated by automation, daily briefs, and manual capture.
> Format: Pipe-delimited rows for automation parsing. Use status markers: TODO, 🔴 THIS WEEK, 🟡 NEXT WEEK, ✅ DONE.

## How This File Works

1. **Automation reads this file** during daily brief generation to surface urgent items
2. **Status markers** drive priority sorting:
   - `🔴 THIS WEEK` — Must complete this week
   - `🟡 NEXT WEEK` — Planned for next week
   - `TODO` — Backlog / no specific deadline
   - `✅ DONE` — Completed (archive after 7 days)
3. **Charter tags** link items to your project areas (e.g., `[project-alpha]`, `[project-beta]`)
4. **The `/capture` skill** can automatically add items here from meetings

---

## Active Items

| Status | Charter | Item | Owner | Due | ADO/Link |
|--------|---------|------|-------|-----|----------|
| 🔴 THIS WEEK | [project-alpha] | Example: Ship feature spec for review | You | YYYY-MM-DD | [ADO #12345](https://link) |
| 🟡 NEXT WEEK | [project-beta] | Example: Schedule partner sync | You | YYYY-MM-DD | — |
| TODO | [project-gamma] | Example: Research competitor approach | You | — | — |

---

## Recurring Meetings & Cadences

| Meeting | Cadence | Day/Time | Attendees | Notes |
|---------|---------|----------|-----------|-------|
| Team Standup | Daily | Mon-Fri 9:00 AM | Team | Status sync |
| Sprint Planning | Biweekly | Monday 10:00 AM | Team + Manager | Sprint scope |
| 1:1 with Manager | Weekly | Wednesday 2:00 PM | You + Manager | Career + priorities |
| Partner Sync | Monthly | First Thursday | You + Partners | Integration status |

---

## Recently Completed (Archive after 7 days)

| Completed | Charter | Item | Notes |
|-----------|---------|------|-------|
| YYYY-MM-DD | [project-alpha] | Example completed item | Shipped in Sprint 42 |

---

## Stale Item Policy

Items with no status change for >5 days are flagged during `/eod` review:
- **Still relevant?** → Update status or due date
- **Blocked?** → Add blocker note and escalate
- **No longer needed?** → Move to archive section below

## Archived Items

<details>
<summary>Click to expand archived items</summary>

| Archived | Charter | Item | Outcome |
|----------|---------|------|---------|
| YYYY-MM-DD | [example] | Old item | Completed / Cancelled / Superseded by #XYZ |

</details>
