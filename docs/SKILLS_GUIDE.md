# Skills Guide

> How to use, create, and customize GitHub Copilot skills for Brain OS.

## What Are Skills?

Skills are markdown files in `.vscode/skills/` that teach GitHub Copilot how to perform domain-specific tasks. When you invoke a skill (e.g., `/eod`), Copilot reads the skill file and follows its instructions using your workspace context.

**Skills are NOT plugins or extensions** — they're structured prompt instructions that leverage Copilot's existing capabilities plus your workspace files.

## Built-In Skills

### Daily Operations

| Skill | Invoke | Purpose |
|-------|--------|---------|
| End of Day | `/eod` | Daily close-out — review tasks, capture wins, update goals |
| Quick Capture | `/capture` | Capture decisions, action items from meetings |
| PM Workspace Kit | `/pm_workspace_kit` | Setup wizard, health check, diagnostics |

### Communication

| Skill | Invoke | Purpose |
|-------|--------|---------|
| Email Drafter | `/m365_email_drafter` | Draft professional emails via Outlook |
| Meeting Prep | `/m365_meeting_prep` | Auto-generate meeting prep docs |
| Teams Comms | `/m365_teams_comms` | Draft Teams messages and standups |

### Reporting

| Skill | Invoke | Purpose |
|-------|--------|---------|
| ADO Reporter | `/m365_ado_reporter` | Azure DevOps sprint health, burndowns |
| Doc Generator | `/m365_doc_generator` | Generate Word, PowerPoint, Excel docs |
| Feedback Synthesis | `/feedback_synthesis` | Aggregate feedback across all sources |

### Engineering

| Skill | Invoke | Purpose |
|-------|--------|---------|
| PM OS Architect | `/pm_os_architect` | Design and extend Brain OS automation |
| PM OS Eval | `/pm_os_eval` | Run brief generation eval suite |
| Deep Review | `/deep_review` | Adversarial code review with 3 agents |
| Insights to Spec | `/insights_to_spec` | Convert analysis into feature specs |
| Delegate ADO | `/delegate_ado` | Create ADO items from plans |
### Product Management

| Skill | Invoke | Purpose |
|-------|--------|--------|
| PRD Writer | `/prd_writer` | Generate full PRDs from scratch, signals, or rough notes |
| Design Spec | `/design_spec` | UI/UX specs, technical design docs, Figma handoff briefs |
| Dashboard Generator | `/dashboard_generator` | Interactive HTML dashboards, Kusto, Excel pivots, Power BI prep |
| MOM Generator | `/mom` | Minutes of Meeting from transcripts or live notes |
| KT Session Parser | `/kt_parser` | Parse KT sessions into structured knowledge artifacts |
### Documentation

| Skill | Invoke | Purpose |
|-------|--------|---------|
| TSG Writer | `/tsg_writer` | Write troubleshooting guides |
| AI-Ready Docs | `/ai_ready_docs` | Format docs for AI consumption |
| Postmortem Generator | `/postmortem_generator` | Build incident postmortems |

---

## How to Use a Skill

### In VS Code Copilot Chat

1. Open Copilot Chat (`Ctrl+Shift+I` or sidebar)
2. Type the skill's invoke command: `/eod`
3. Add optional context: `/eod quick` or `/capture meeting notes from standup`

### Skill Actions

Most skills support multiple actions. For example, `/m365_email_drafter` supports:

```
/m365_email_drafter draft     → Create a new email
/m365_email_drafter reply     → Draft a reply
/m365_email_drafter followup  → Generate follow-up email
/m365_email_drafter templates → Show available templates
```

### Context Sources

Skills automatically read relevant Knowledge Base files. You don't need to paste context manually — the skill instructions tell Copilot which files to check.

---

## Creating a Custom Skill

### Step 1: Create the Skill File

Create a new `.md` file in `.vscode/skills/`:

```
.vscode/skills/my_custom_skill.md
```

### Step 2: Use the Standard Template

```markdown
# Skill: My Custom Skill

## Invocation
`/my_custom_skill`

## Purpose
One-line description of what this skill does.

## Actions

### `default` (no action specified)
What happens when user just types `/my_custom_skill`

### `action_name`
What happens when user types `/my_custom_skill action_name`

## Context Sources
Before executing, read these files for context:
1. `00_Daily_Intelligence/Knowledge_Base/Goals.md` — Current priorities
2. `00_Daily_Intelligence/Knowledge_Base/Action_Items.md` — Open tasks

## Instructions

### Step 1: Gather Context
- Read the context source files listed above
- Check today's signals in `00_Daily_Intelligence/Signals/`

### Step 2: Process
- [Describe what to do with the gathered context]
- [Include any formatting rules]

### Step 3: Output
- [Define the output format]
- [Specify where to save files, if applicable]

## Examples

### Example 1: Basic usage
User: `/my_custom_skill`
Expected: [What should happen]

### Example 2: With action
User: `/my_custom_skill action_name some context`
Expected: [What should happen]

## Guardrails
- [What the skill should NOT do]
- [Data sensitivity rules]
- [Trust level: Read-Only / Write-Local / Write-External]
```

### Step 3: Register in copilot-instructions.md

Add the skill to the "Installed Skills" section of `.github/copilot-instructions.md`:

```markdown
### My Custom Skill (`/my_custom_skill`)
- **Skill file:** `.vscode/skills/my_custom_skill.md`
- **What:** One-line description
- **Actions:** `default`, `action_name`
```

### Step 4: Test

1. Open Copilot Chat
2. Type `/my_custom_skill`
3. Verify it reads the right context and produces expected output
4. Iterate on the instructions based on results

---

## Skill Design Best Practices

### 1. Be Specific About Context
❌ "Read relevant files"
✅ "Read `Goals.md` for current OKRs, `Action_Items.md` for open tasks"

### 2. Define Output Format Explicitly
❌ "Write a summary"
✅ "Write a markdown summary with: ## Heading, 3-5 bullet points, a 'Next Steps' section"

### 3. Include Examples
Real input→output examples dramatically improve skill reliability.

### 4. Set Guardrails
State what the skill should NOT do:
- "Do not send emails without user confirmation"
- "Do not modify Goals.md unless explicitly asked"
- "Do not fabricate data — if information is missing, say so"

### 5. Layer Context Progressively
```
1. ALWAYS read: Goals.md (small, critical)
2. IF NEEDED: Action_Items.md (medium, task-specific)
3. IF TOPIC-SPECIFIC: Project Reference/ files (large, domain-specific)
```

### 6. Use Step-by-Step Instructions
Skills work best when they follow a numbered procedure rather than a vague description.

### 7. Specify Trust Level
Reference `Trust_Boundaries.md` and explicitly state:
- Read-Only: "This skill only reads and displays data"
- Write-Local: "This skill may create/update local markdown files"
- Write-External: "This skill prepares drafts — ALWAYS show for review before sending"

---

## Advanced Patterns

### Subagent Delegation
For complex skills, instruct Copilot to use subagents:
```markdown
## Processing
Use a subagent to:
1. Search all signal files for mentions of [topic]
2. Aggregate findings
3. Return summary to main context
```

### Multi-Source Synthesis
```markdown
## Context Gathering (Parallel)
Read these files simultaneously:
- signals/emails_YYYY-MM-DD.md
- signals/ado_YYYY-MM-DD.md
- signals/calendar_YYYY-MM-DD.md

Then synthesize into unified view.
```

### Template-Driven Output
```markdown
## Output Format
Use the template in `_Automation/prompt_templates/status_update.md`:
- Replace `{{date}}` with today's date
- Replace `{{signals_summary}}` with gathered context
- Replace `{{audience}}` with user-specified audience
```

---

## Troubleshooting Skills

| Problem | Cause | Fix |
|---------|-------|-----|
| Skill not recognized | Not registered in copilot-instructions.md | Add to "Installed Skills" section |
| Reads wrong context | Context sources too vague | Be explicit about file paths |
| Output format wrong | No format specification | Add explicit format + examples |
| Inconsistent results | Too much creativity | Add "Be precise. Do not improvise." |
| Skill too slow | Reading too many files | Layer context: critical → optional |
