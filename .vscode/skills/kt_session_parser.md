# KT Session Parser — Knowledge Transfer & Learning Session Processor

## Trigger
`/kt_session_parser` or when user says "parse KT", "knowledge transfer", "parse learning session", "training notes", "onboarding session", "parse transcript", "extract learnings", "session notes", "brown bag summary"

## Purpose
Process knowledge transfer sessions, training recordings, brown bags, and learning meetings — extracting structured knowledge artifacts from transcripts or notes. Converts raw session content into searchable, referenceable knowledge base entries. Designed for onboarding acceleration, team knowledge sharing, and institutional memory preservation.

## Actions

### `parse` (default)
Parse a KT/learning session transcript or notes:

1. **Identify source:**
   - Transcript file (`.txt`, `.vtt`, `.md`) from `*/Transcripts/`
   - User-pasted session notes
   - Recording reference (extract from filename for metadata)

2. **Extract knowledge artifacts:**
   - **Session metadata** — Title, date, presenter, audience, duration
   - **Key topics** — Numbered list of topics covered with time markers if available
   - **Concepts explained** — New terms, acronyms, architectural patterns defined
   - **Process walkthroughs** — Step-by-step procedures demonstrated
   - **Tools & systems** — Software, dashboards, APIs referenced
   - **Tips & gotchas** — Presenter's expert tips, common mistakes, warnings
   - **Links & resources** — URLs, documents, repos, wikis mentioned
   - **Q&A pairs** — Questions asked and answers given
   - **Knowledge gaps** — Topics mentioned but not fully explained (needs follow-up)

3. **Generate structured output:**
   - KT Summary document (markdown)
   - Glossary entries for new terms
   - Process runbooks for procedures demonstrated
   - Q&A reference document

4. **Route to Knowledge Base:**
   - Save to `projects/[area]/Reference/KT_[Topic]_[Date].md`
   - Extract new terms → relevant glossary or `Processes_Reference.md`
   - Extract contacts → `Key_Contacts.md`
   - Flag follow-up items → `Action_Items.md`

### `series`
Process a multi-session KT series:

1. Accept multiple transcript files or a folder path
2. Parse each session individually
3. Generate a series index with:
   - Session timeline
   - Topic coverage map (what's covered, what's missing)
   - Cross-session glossary
   - Cumulative Q&A document
   - Knowledge gap analysis across all sessions
4. Save as `KT_Series_[Topic]_Index.md`

### `quiz`
Generate a knowledge check from parsed session content:

1. Read a previously parsed KT summary
2. Generate 10-15 questions covering key concepts
3. Include answers with references to source content
4. Format as a self-assessment checklist
5. Useful for onboarding verification

### `onboard`
Generate an onboarding guide from KT materials:

1. Scan all KT documents in a project's `Reference/` folder
2. Order by dependency (foundational concepts first)
3. Generate a structured onboarding guide:
   - Pre-requisites checklist
   - Reading order with time estimates
   - Hands-on exercises derived from process walkthroughs
   - Who to ask for each topic area
   - 30/60/90 day milestones
4. Save as `Onboarding_Guide_[Area].md`

## Output Format

### KT Session Summary
```markdown
# KT Session: [Title]

## Session Details

| Field | Value |
|-------|-------|
| **Date** | [Date] |
| **Presenter** | [Name, Role] |
| **Audience** | [Team/Individuals] |
| **Duration** | [Duration] |
| **Recording** | [Link/Path if available] |
| **Transcript** | [Path to transcript file] |

---

## Topics Covered

### 1. [Topic Title]
**Summary:** [2-3 sentence explanation]

**Key Concepts:**
- **[Term]** — [Definition in plain language]
- **[Term]** — [Definition]

**Process/Walkthrough:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

> 💡 **Pro Tip from Presenter:** "[Direct quote or paraphrased expert advice]"

> ⚠️ **Gotcha:** "[Common mistake or pitfall mentioned]"

### 2. [Topic Title]
[Same structure]

---

## Tools & Systems Referenced

| Tool | Purpose | Access |
|------|---------|--------|
| [Tool Name] | [What it does] | [How to access] |

## Resources & Links
- [Document/Wiki title](URL or path)
- [Repository name](URL or path)

## Q&A

| # | Question | Answer | Asked By |
|---|----------|--------|----------|
| 1 | [Question] | [Answer] | [Name] |
| 2 | [Question] | [Answer] | [Name] |

## Knowledge Gaps (Follow-Up Needed)
- ❓ [Topic not fully covered — who to ask]
- ❓ [Concept mentioned but not explained — resource needed]

## Action Items from Session

| # | Action | Owner | Deadline |
|---|--------|-------|----------|
| 1 | [Follow-up task] | [Who] | [When] |

---
*Parsed by Brain OS `/kt_session_parser` — verify with presenter for accuracy*
```

## Context Sources
1. `*/Transcripts/` folders — Raw transcript files
2. `*/Recordings/` folders — Recording metadata (filenames, dates)
3. `00_Daily_Intelligence/Knowledge_Base/Key_Contacts.md` — Resolve presenter/attendee names
4. `00_Daily_Intelligence/Knowledge_Base/Charter_Areas.md` — Route to correct project area
5. `00_Daily_Intelligence/Knowledge_Base/Processes_Reference.md` — Cross-reference existing processes

## Rules
1. **Preserve speaker attribution** — Always note who said what for key decisions/insights
2. **Don't fabricate content** — If transcript is unclear, mark with ⚠️ instead of guessing
3. **Extract actionable items** — Every KT session should produce at least one follow-up action
4. **Cross-reference existing KB** — Check if concepts already documented; update rather than duplicate
5. **Estimate time markers** — If transcript has timestamps, include approximate time markers for each topic
6. **Respect confidentiality** — Flag if session contains sensitive architectural details or security information

## Anti-Patterns
- ❌ Don't dump the entire transcript — synthesize into structured knowledge
- ❌ Don't skip the Q&A section — questions reveal what the audience found confusing
- ❌ Don't ignore "gotchas" — presenter warnings are the most valuable content
- ❌ Don't create orphan documents — always link back to the project area and KB
- ❌ Don't assume one parse is final — knowledge gaps should trigger follow-up sessions

## Cross-Skill References
| Need | Skill |
|------|-------|
| Capture meeting decisions | `/capture` |
| Generate meeting minutes | `/mom` |
| Create ADO items from follow-ups | `/delegate_ado` |
| Write formal documentation from KT | `/ai_ready_docs` |
| Email session summary to team | `/m365_email_drafter` |
| Create onboarding deck from KT series | `/m365_doc_generator ppt` |
| Synthesize feedback from multiple sessions | `/feedback_synthesis` |

## Time Saved
~1-2 hours per session (manual note-taking + formatting + distribution + KB updates)
