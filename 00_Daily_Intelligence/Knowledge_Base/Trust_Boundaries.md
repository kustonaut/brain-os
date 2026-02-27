# Trust Boundaries

> What each script and skill is allowed to do. Review before granting new capabilities.

## Trust Levels

### Level 0: Read-Only
**Allowed:** Read local files, query APIs (GET only), display data in chat
**Not Allowed:** Create/modify/delete any files or external state

| Component | Trust Level | Justification |
|-----------|-------------|---------------|
| `fetch_emails.ps1` | Read-Only | Reads Outlook, writes only to local signals |
| `fetch_calendar.ps1` | Read-Only | Reads calendar, writes only to local signals |
| `fetch_ado.ps1` | Read-Only | Reads ADO work items, writes only to local signals |
| `fetch_chats.ps1` | Read-Only | Reads Teams chats, writes only to local signals |

### Level 1: Write-Local
**Allowed:** Everything in Level 0 + create/modify local files
**Not Allowed:** Send emails, create tickets, post messages, delete files

| Component | Trust Level | Justification |
|-----------|-------------|---------------|
| `generate_brief.ps1` | Write-Local | Creates daily brief markdown |
| `parse_inbox.ps1` | Write-Local | Routes files to charter folders |
| `cleanup.ps1` | Write-Local | Archives old signals/briefs |
| `weekly_snapshot.ps1` | Write-Local | Aggregates weekly signals |
| `serve_artifacts.py` | Write-Local | Serves files via HTTP (localhost only) |
| `/capture` skill | Write-Local | Updates Action_Items.md, KB files |
| `/eod` skill | Write-Local | Updates Goals.md, creates daily logs |

### Level 2: Write-External (Human Review Required)
**Allowed:** Everything in Level 1 + prepare external actions for review
**Not Allowed:** Auto-send without human confirmation

| Component | Trust Level | Justification |
|-----------|-------------|---------------|
| `block_calendar.ps1` | Write-External | Creates calendar events (review prompt) |
| `/m365_email_drafter` | Write-External | Drafts emails, requires send confirmation |
| `/m365_teams_comms` | Write-External | Drafts messages, requires send confirmation |
| `/m365_ado_reporter` | Write-External | Can create/update work items |

### Level 3: Destructive (Restricted)
**Allowed:** Delete files, cancel events, close tickets
**Guardrails:** Must log all actions, require explicit confirmation

| Component | Trust Level | Justification |
|-----------|-------------|---------------|
| None currently | — | No automation has destructive permissions |

---

## Data Classification

| Data Type | Sensitivity | Storage | Sharing |
|-----------|-------------|---------|---------|
| Signal files (emails, chats) | Internal | Local only, `.gitignore`d | Never committed |
| Daily briefs | Internal | Local only, `.gitignore`d | Team-shareable |
| Knowledge Base | Low | Committed to repo | Team-shareable |
| Config.json | Sensitive | `.gitignore`d, never committed | Never shared |
| Meeting recordings | Confidential | Local only | Per meeting policy |
| Transcripts | Confidential | Local only | Per meeting policy |

---

## Escalation Triggers

Escalate to human when:
1. **Any write-external action** — Always show draft before sending
2. **Unexpected data** — Signal file contains content outside normal patterns
3. **Auth scope expansion** — Script requests permissions beyond its trust level
4. **PII in output** — Automation generates content with personal data for broad distribution
5. **Bulk operations** — Any action affecting >10 items at once

---

## Adding New Components

When adding a new script or skill:
1. Classify its trust level using the table above
2. Add it to the appropriate section
3. If Level 2+, implement the review gate (show output, wait for confirmation)
4. Document in this file before deploying
5. Run the Agent Build Checklist (see `Agent_Build_Checklist.md`)
