# PomoBot — Incident Postmortem Generator

Build complete, evidence-backed incident postmortems. Produces markdown, Word (.docx), and PowerPoint (.pptx) deliverables with 5 Whys analysis and categorized repair items.

**Invoke when:** user asks to create a postmortem, POMO, PIR, or post-incident review for an incident.

## Prerequisites

This skill uses the following tools (configure based on your incident management system):

| Tool | Purpose |
|---|---|
| Incident management API/MCP | Incident details, impact, timeline |
| Kusto/Log Analytics MCP | Query incident data warehouse for detailed records |
| Chat/Comms search | Search Teams/Slack chats for incident context |

Also uses python-docx and python-pptx for document generation (install in `.venv` if needed).

## Usage

- "Create a postmortem for incident 123456789"
- "Generate POMO for incident 123456789"
- "Build a PIR for incident 123456789"

## Required Data Sources

Always gather and reconcile data from **all available** sources:

### 1) Incident Management System
Use your incident management MCP/API for canonical incident metadata:
- Incident summary and details
- Customer impact assessment
- Related/similar incidents
- Mitigation hints

### 2) Data Warehouse / Logs
Use Kusto, Log Analytics, or your log system to query detailed records:
- Current snapshot/state
- Incident history and state transitions (including **all severity changes** and **outage declaration** events)
- Incident descriptions/notes
- Relationships (parent/child/duplicates)
- Linked bugs/work items/external links
- Notifications and response actions
- Impacted tenants/services
- PIR/root-cause related records

### 3) Communication Records
Search your Teams/Slack/chat system for the incident number:
- Chat threads related to the incident
- Meeting call transcripts
- Additional context that adds timeline, decisions, or mitigation details

### 4) Bridge Call Transcript (If Available)
If a meeting recording link is found:
- Note the recording link in the Supporting Links section
- Ask the user if they can provide a transcript manually
- If transcript is provided, use it to inform timeline accuracy and decision context

**Important:** Do NOT include individual names, direct quotes, or attributed statements from any transcript in the postmortem. Synthesize into factual observations (e.g., "Root cause was identified approximately 7 minutes into the bridge call").

## Operating Workflow

1. Ask the user for an incident number.
2. Validate the value is numeric; if invalid, request correction.
3. **Create output folder**: `POMOs/{incidentId}/` in the workspace. ALL files go here.
4. Pull incident summary and details from your incident management system.
5. Query your data warehouse/logs for the same incident and all related records.
6. Search communication records for related chats and transcripts.
7. **Save supporting data**: Save raw data report to `POMOs/{incidentId}/incident_{incidentId}_data_report.md`.
8. Reconcile discrepancies:
   - Prefer latest authoritative values for status/timestamps.
   - Explicitly call out conflicts in a "Data Gaps & Conflicts" section.
9. Generate the postmortem markdown (format below). Save to `POMOs/{incidentId}/Postmortem_{incidentId}.md`.
10. **Generate Word document (.docx)**. Save to `POMOs/{incidentId}/Postmortem_{incidentId}.docx`.
11. **Generate PowerPoint summary (.pptx)**. Save to `POMOs/{incidentId}/Postmortem_{incidentId}_1slide.pptx`.
12. **Open the Word document**: `Start-Process "POMOs/{incidentId}/Postmortem_{incidentId}.docx"`
13. Confirm output location and list all generated files.

## Output Format (Required)

### A) Incident Overview
- Incident ID, Title, Severity, Status
- Owning team/tenant
- Incident window (start, mitigation, resolution)
- Impacted services/regions

### B) Executive Summary
- 1-2 concise paragraphs explaining what happened, blast radius, and current state.

### C) Timeline (UTC)

| Timestamp | Event | Source | Confidence |
|-----------|-------|--------|------------|
| ... | ... | Incident System / Logs / Comms | High/Medium/Low |

**Required timeline entries** (include every occurrence):
- **All severity changes** (e.g., Sev 3 → Sev 2 → Sev 1). Each change = separate row.
- **Outage declaration**: Dedicated row when outage declared. If none, note in Data Gaps.

### D) Impact Assessment
- Customer impact (who/how many)
- Service/SLA impact
- Internal operational impact

### E) 5 Whys Analysis

1. **Why #1** (symptom-level): [question] → [answer]
2. **Why #2**: [question] → [answer]
3. **Why #3**: [question] → [answer]
4. **Why #4**: [question] → [answer]
5. **Why #5** (systemic root cause): [question] → [answer]

Then include:
- **Root Cause Statement** (single clear sentence)
- **Contributing Factors** (bulleted)
- **What made detection slower/faster**

### F) Repair Items

| Category | Action Item | Rationale | Owner | Priority | Due | Success Metric |
|----------|------------|-----------|-------|----------|-----|----------------|
| Prevent | ... | Links to Why #N | ... | P0-P3 | ... | ... |
| Detect | ... | ... | ... | ... | ... | ... |
| Fix/Mitigate | ... | ... | ... | ... | ... | ... |
| Process | ... | ... | ... | ... | ... | ... |

Requirements:
- At least 2 items per category when evidence supports it.
- Avoid vague actions (e.g., "improve monitoring") — make each testable.

### G) Supporting Links & References

| Resource | Link | Description |
|----------|------|-------------|
| Incident | ... | Primary incident |
| Bridge Recording | ... | Recording link |
| Related Incidents | ... | Similar/parent/child |
| Work Items | ... | Linked bugs |
| ... | ... | ... |

### H) Validation & Follow-up
- Gaps in evidence
- Suggested follow-up queries
- Similar incidents worth comparing

## Word Document (.docx) Formatting

- **Font**: Calibri throughout
- **Title page**: Centered incident name + "Organization — Incident Postmortem Report"
- **Section headers**: Navy-blue (Heading 2/3)
- **Tables**: Dark navy header rows, white text, alternating row shading
- **5 Whys**: Format each Why as bold question heading ("**Why #1: Why did X happen?**") followed by explanation paragraph. NOT just a summary table — full question-and-answer format.
- **Bullet lists**: When using `List Bullet` style in python-docx, do NOT prefix text with `•` or `-` — the style renders its own bullet symbol.
- **Footer**: "CONFIDENTIAL — Internal | Postmortem {incidentId}" on every page
- **Evidence references**: Cite data sources without direct quotes or names.

## PowerPoint (.pptx) Formatting

- **Slide size**: 20" × 11.25" (wide format), single slide
- **Layout**: 3-column
  - Column 1: Executive Summary + Timeline table
  - Column 2: 5 Whys with color-coded number badges + Root Cause callout
  - Column 3: Repair Items (grouped P0/P1/P2), Contributing Factors, Impact
- **Header bar**: Dark navy with incident title and severity/duration/impact badges
- **Colors**: Navy headers, alternating row shading, accent colors for badges
- **Footer bar**: "CONFIDENTIAL — Internal"

## Quality Bar

- Ground every major claim in retrieved evidence.
- Distinguish facts vs assumptions.
- Keep repair items actionable, prioritized, and auditable.
- If confidence is low due to missing evidence, state assumptions explicitly.
- Ask: "Would the PM trust this output in a leadership review?"
