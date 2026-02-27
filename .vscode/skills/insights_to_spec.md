# Insights to Spec — Signal-to-Action Skill

## Trigger
`/insights_to_spec` or when user says "turn this into a spec", "write a PRD", "convert to feature spec", "spec this", "draft a spec from signals"

## Purpose
Convert analysis outputs, signal patterns, or investigation findings into structured feature specifications. This is the **Action** step in the Signal → Analysis → Insight → Spec → Ticket pipeline. Inspired by the "Vibe PMing" workflow where insights flow directly into engineerable specs.

## Context Sources (Read Before Drafting)
1. `00_Daily_Intelligence/Knowledge_Base/Goals.md` — Align spec to current OKRs
2. `00_Daily_Intelligence/Knowledge_Base/Action_Items.md` — Check for existing related items
3. `00_Daily_Intelligence/Knowledge_Base/Charter_Areas.md` — Scope and ownership context
4. `00_Daily_Intelligence/Signals/` — Latest signal files for supporting data
5. `_Automation/prompt_templates/prd_template.md` — **USE THIS TEMPLATE** for spec format
6. Project folder docs (e.g., `projects/project-alpha/Project_Funnel.md`) — Current state context

## Actions

### `spec` (default)
Generate a feature spec from an insight or analysis:

1. **Identify the insight source:**
   - User-provided analysis text
   - GitHub issue reference (fetch via MCP if available)
   - Incident management pattern
   - Signal file anomaly
   - Meeting notes or `/capture` output
   - Stakeholder review discussion point

2. **Apply PM heuristics (from prd_template.md):**
   - SIMPLICITY — strip to minimum viable scope
   - USER SIGNAL — ground in concrete user pain
   - ACCEPTANCE CRITERIA — binary pass/fail only
   - BLAST RADIUS — list dependencies and regression risks
   - MEASUREMENT — define metric + target
   - ONE-PAGER TEST — if too long, split

3. **Generate spec using `prd_template.md` format:**
   - Fill all template fields
   - Link to specific ADO items, GitHub issues, or incidents
   - Set project-specific defaults from template
   - Flag any fields that need user input with ❓

4. **Save spec:**
   - Save to relevant project folder at root level (e.g., `projects/project-alpha/Spec_[Title].md`)
   - If project unclear, save to `_Inbox/` for routing

5. **Offer next steps:**
   - "Create ADO work item from this spec?" (→ `/delegate_ado` or `/m365_ado_reporter`)
   - "Draft stakeholder email about this?" (→ `/m365_email_drafter`)
   - "Refine further?" (iterate in chat)

### `from_signals`
Scan recent signals and propose spec candidates:

1. Read last 3 days of signal files (`emails_*.md`, `ado_*.md`, `calendar_*.md`)
2. Cross-reference with `Action_Items.md` for gaps (signals not yet tracked)
3. Identify patterns: recurring themes, escalating trends, unowned risks
4. For each candidate, output:
   ```
   📋 Spec Candidate: [Title]
   Signal: [Source + date]
   Charter: [Area]
   Urgency: 🔴/🟡/🟢
   Rationale: [1 sentence]
   ```
5. Ask user: "Which ones should I draft into full specs?"

### `refine`
Take an existing spec and improve it:

1. Read the spec file
2. Run the Quality Checklist from `prd_template.md`
3. Flag issues:
   - Missing acceptance criteria
   - Vague success metrics (no numbers)
   - Empty Out of Scope section
   - Unlinked ADO/GitHub items
4. Auto-fix what can be fixed, ask about the rest

## Output Format
```
## [Feature Title]

**Owner:** [PM Name]
**Status:** Draft
**Date:** [Today]
**Charter:** [Area]
**Related ADO:** [IDs]

### Problem Statement
[Grounded in data]

### User Signal
[Evidence]

### Proposed Solution
[Concise]

### Acceptance Criteria
- [ ] [Binary criterion]

### Dependencies / Risks / Success Metric / Out of Scope / Open Questions
[Per template]
```

## MCP Integration
- **Azure DevOps MCP** — Create work items directly from specs (`mcp_azure-devops_wit_create_work_item`)
- **GitHub MCP** — Reference or create issues (`github-pull-request_issue_fetch`)
- **WorkIQ MCP** — Pull related context if available

## Quality Gate
Before marking a spec "ready":
- [ ] Passes all 8 checks from `prd_template.md` Quality Checklist
- [ ] User has reviewed and confirmed
- [ ] At least one ADO item linked or created
- [ ] Charter area explicitly assigned

## Anti-Patterns
- ❌ Don't generate specs from vague requests ("make the project better") — ask for specific signal/insight
- ❌ Don't exceed 1 page — split into multiple specs instead
- ❌ Don't invent user signals — only cite real data from signals/issues/incidents
- ❌ Don't skip the heuristics check — it prevents bloated specs
