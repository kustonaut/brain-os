# Feedback Synthesis — Unified Signal Analysis Skill

## Trigger
`/feedback_synthesis` or when user says "what are customers saying", "feedback themes", "analyze feedback", "unified signals", "signal trends", "what's broken", "top complaints"

## Purpose
Aggregate and analyze feedback signals across ALL data sources — GitHub Issues, incidents, telemetry, ADO bugs, partner escalations, meeting transcripts — into unified, actionable themes. This is the PM equivalent of unified feedback analysis across support tickets, CRM, and internal channels, adapted for your team's ecosystem.

## Context Sources (Parallel Read)
Read ALL of these before synthesizing:

1. **GitHub Issues** — `projects/project-alpha/` funnel docs, GitHub dashboard data, recent `/m365_ado_reporter` outputs
2. **Incidents** — Incident signal patterns from your incident management system
3. **ADO Work Items** — `00_Daily_Intelligence/Signals/ado_*.md` (last 7 days)
4. **Email Signals** — `00_Daily_Intelligence/Signals/emails_*.md` (last 7 days)
5. **Meeting Transcripts** — Relevant `Transcripts/` files from project folders
6. **Partner Feedback** — `projects/project-alpha/Reference/`, `projects/project-beta/Reference/`
7. **Leadership Review Notes** — If available, review action items and discussion notes

## Actions

### `synthesize` (default)
Full cross-source feedback analysis:

1. **Gather signals** (use subagents for parallel reads):
   - Read last 7 days of signal files (emails, ADO, calendar, chats)
   - Read project funnel docs for GitHub Issue patterns
   - Read recent incident data if available
   - Read any partner feedback docs updated in last 14 days

2. **Cluster into themes:**
   For each theme, classify as:
   - 🐛 **Bug/Regression** — Something broke that used to work
   - 📢 **Feature Request** — Users want something new
   - 😤 **Pain Point** — Existing flow is too hard/slow
   - 🔥 **Urgent/Escalation** — Active partner or customer escalation
   - 🎉 **Praise/Positive** — What's working well (don't skip these)

3. **Output structured synthesis:**
   ```
   ## Feedback Synthesis — {{DATE_RANGE}}

   ### 🔥 Urgent (Act Now)
   | Theme | Sources | Count | Project | Suggested Action |
   |---|---|---|---|---|

   ### 🐛 Bugs & Regressions
   | Theme | Sources | Count | Project | Status |
   |---|---|---|---|---|

   ### 📢 Feature Requests (Top 5)
   | Theme | Sources | Count | Project | Priority |
   |---|---|---|---|---|

   ### 😤 Pain Points
   | Theme | Sources | Count | Project | Suggested Action |
   |---|---|---|---|---|

   ### 🎉 What's Working
   | Theme | Sources | Count | Project |
   |---|---|---|---|

   ### Cross-Cutting Patterns
   [Patterns that span multiple project areas]

   ### Recommended Actions
   1. [Action 1] — [Urgency] — [Owner suggestion]
   2. [Action 2] — [Urgency] — [Owner suggestion]

   ---
   *Sources: {{SOURCES_LIST}} | Generated {{DATE}}*
   ```

4. **Offer next steps:**
   - "Draft specs from top themes?" (→ `/insights_to_spec`)
   - "Create ADO items for untracked themes?" (→ `/delegate_ado`)
   - "Draft escalation email?" (→ `/m365_email_drafter`)
   - "Prepare leadership review talking points?" (→ `/m365_meeting_prep`)

### `charter [area]`
Focused analysis for a specific project area:
- Filter all signals to that project only
- Deep-dive into that area's funnel, partner feedback, and ADO backlog
- Compare against `Goals.md` targets for that project
- Output same format but scoped to one area

### `trend`
Compare this week vs. last week:
- Read signals from current week and previous week
- Identify: new themes, growing themes, resolved themes, stale themes
- Output trend arrows: ↑ growing, → stable, ↓ declining, ✅ resolved
- Flag any theme that has been growing for 2+ weeks without action

### `partner [name]`
Focused analysis for a specific partner:
- Read partner-specific files from `Partners.md`
- Cross-reference with recent emails, meetings, ADO items
- Output partner health summary + open issues + recommended actions

## Theme Clustering Heuristics

When clustering feedback, apply these rules:
1. **Merge similar** — "add-in won't load" + "add-in fails to activate" = same theme
2. **Separate root causes** — "add-in slow" (perf) vs "add-in crashes" (reliability) = different themes
3. **Count conservatively** — Don't double-count the same user email + GitHub issue
4. **Cite sources** — Every theme must have at least one specific source reference (issue #, email subject, incident ID)
5. **Charter assignment** — Every theme gets exactly one primary project area (use routing keywords from `config.json`)

## MCP Integration
- **Azure DevOps MCP** — Pull recent work items, bug counts, sprint data
- **GitHub MCP** — Fetch issue details, label distributions
- **Incident Management MCP** — Query incident trends, top hit services (if incident MCP configured)
- **WorkIQ MCP** — Pull related insights if available

## Save Behavior
- Save synthesis to `00_Daily_Intelligence/Reports/Feedback_Synthesis_{{DATE}}.md`
- If project-specific, save to project folder instead

## Anti-Patterns
- ❌ Don't invent feedback — only cite real signals from actual files
- ❌ Don't just list signals — cluster into themes with counts and recommendations
- ❌ Don't ignore positives — include 🎉 Praise section always
- ❌ Don't skip cross-cutting patterns — often the most valuable insight
- ❌ Don't synthesize without reading `Goals.md` first — alignment is critical
