# PM Workspace Kit

> `/pm_workspace_kit` — Manage your PM intelligence workspace

## Metadata
- **Version:** 1.0.0
- **Author:** Your Name (you@company.com)
- **Audience:** Any developer or program manager
- **Prerequisites:** PowerShell 5.1+, Python 3.10+, Azure CLI (`az login`)

## Description
A self-contained PM workspace with automated daily intelligence signals, a local Command Center portal, and AI-assistant integration. Tracks multiple project areas, auto-fetches emails/calendar/ADO/chats, generates daily briefs, and blocks focus time.

## Actions

### `setup` — Run Setup Wizard
Initialize a new workspace with interactive prompts for identity, projects, ADO, and email method.

```
/pm_workspace_kit setup
```

**Steps:**
1. Run `pwsh _skill_core/setup_wizard.ps1` in terminal
2. Follow the 6-step wizard prompts
3. Review generated `_Automation/config.json`

### `portal` — Launch Command Center
Start the web portal at http://localhost:8765.

```
/pm_workspace_kit portal
```

**Command:** `python _Automation/serve_artifacts.py`

### `pipeline` — Run Daily Pipeline
Execute the full daily orchestrator (signals + brief + calendar blocking).

```
/pm_workspace_kit pipeline
```

**Command:** `_Automation/daily_orchestrator.ps1 -Force`

### `brief` — View Today's Brief
Read and summarize today's daily brief from `00_Daily_Intelligence/Daily_Briefs/`.

### `signals` — Check Latest Signals
Read today's signal files from `00_Daily_Intelligence/Signals/` and summarize key highlights.

### `config` — Edit Configuration
Open and help edit `_Automation/config.json` — add projects, update ADO queries, change email method, etc.

### `status` — Workspace Health Check
Verify prerequisites (Python, az CLI, Outlook), check config.json validity, report last pipeline run.

## Context Sources
When answering questions, check in priority order:
1. Signal files (most recent) — `00_Daily_Intelligence/Signals/`
2. Knowledge Base — `00_Daily_Intelligence/Knowledge_Base/`
3. Daily Briefs — `00_Daily_Intelligence/Daily_Briefs/`

Always read `_Automation/config.json` for current workspace configuration.

## Full Documentation
See `_skill_core/PM_WORKSPACE_KIT.md` for complete architecture, folder conventions, and cross-platform details.
