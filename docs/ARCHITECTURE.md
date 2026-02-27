# Architecture

> How Brain OS works — data flow, folder convention, component responsibilities.

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     BRAIN OS ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐ │
│  │  Outlook  │   │   ADO    │   │ Calendar │   │  Teams   │ │
│  │  (COM/    │   │  (REST)  │   │  (COM/   │   │ (Graph)  │ │
│  │  Graph)   │   │          │   │  Graph)  │   │          │ │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘ │
│       │              │              │              │        │
│       ▼              ▼              ▼              ▼        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              DAILY ORCHESTRATOR (PowerShell)          │   │
│  │  cleanup → inbox → email → chats → ADO → cal → brief│   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│                         ▼                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   SIGNALS (Markdown)                  │   │
│  │  emails_YYYY-MM-DD.md  │  ado_YYYY-MM-DD.md         │   │
│  │  calendar_YYYY-MM-DD.md│  chats_YYYY-MM-DD.md        │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│                         ▼                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              DAILY BRIEF (Markdown + AI)              │   │
│  │  Synthesizes all signals into actionable summary      │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│              ┌──────────┴──────────┐                        │
│              ▼                     ▼                        │
│  ┌─────────────────┐   ┌─────────────────┐                 │
│  │   WEB PORTAL    │   │  COPILOT SKILLS │                 │
│  │  (localhost:     │   │  (VS Code Chat) │                 │
│  │   8765)         │   │  /eod /capture  │                 │
│  └─────────────────┘   └─────────────────┘                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Morning Pipeline (Automated, ~60 seconds)

```
1. cleanup.ps1       → Archive old signals (>14d), briefs (>30d), logs (>30d)
2. parse_inbox.ps1   → Route new files from _Inbox/ to project folders
3. fetch_emails.ps1  → Pull 24h emails → signals/emails_YYYY-MM-DD.md
4. fetch_chats.ps1   → Pull Teams chats → signals/chats_YYYY-MM-DD.md
5. fetch_ado.ps1     → Pull ADO items → signals/ado_YYYY-MM-DD.md
6. fetch_calendar.ps1→ Pull calendar → signals/calendar_YYYY-MM-DD.md
7. generate_brief.ps1→ Synthesize all signals → Daily_Briefs/brief_YYYY-MM-DD.md
8. block_calendar.ps1→ Create focus time blocks on calendar
```

### Evening Close-Out (Manual via `/eod`)

```
1. Review Action_Items.md for completed tasks
2. Capture wins and learnings
3. Update Goals.md with progress
4. Write daily log
5. Flag stale items (>5 days no change)
```

## Folder Structure

```
brain-os/
├── .github/
│   └── copilot-instructions.md    ← Copilot behavior + workspace context
├── .vscode/
│   ├── tasks.json                 ← VS Code task definitions
│   └── skills/                    ← 17 Copilot skill files
├── _Automation/                   ← Pipeline scripts + config
│   ├── daily_orchestrator.ps1     ← Main entry point
│   ├── config.json                ← YOUR config (gitignored)
│   ├── config.sample.json         ← Template config (committed)
│   ├── serve_artifacts.py         ← Web portal server
│   ├── prompt_templates/          ← Versioned prompt files
│   └── logs/                      ← Execution logs (gitignored)
├── _Inbox/                        ← Drop zone for new files
├── 00_Daily_Intelligence/
│   ├── Knowledge_Base/            ← 10 context files (committed)
│   ├── Signals/                   ← Daily raw signals (gitignored)
│   ├── Daily_Briefs/              ← Synthesized briefs (gitignored)
│   └── Weekly_Snapshots/          ← Friday aggregations (gitignored)
├── 01_Project_Alpha/              ← Your project folders
│   ├── Reference/
│   ├── Recordings/
│   └── Transcripts/
├── docs/                          ← Documentation
└── 08_Archive/                    ← Archived materials
```

## Component Responsibilities

### Automation Scripts

| Script | Input | Output | Frequency |
|--------|-------|--------|-----------|
| `daily_orchestrator.ps1` | config.json | Orchestrates all steps | Daily 8:30 AM |
| `fetch_emails.ps1` | Outlook COM/Graph | `emails_YYYY-MM-DD.md` | Daily |
| `fetch_calendar.ps1` | Outlook COM/Graph | `calendar_YYYY-MM-DD.md` | Daily |
| `fetch_ado.ps1` | ADO REST API | `ado_YYYY-MM-DD.md` | Daily |
| `fetch_chats.ps1` | Teams Graph API | `chats_YYYY-MM-DD.md` | Daily |
| `generate_brief.ps1` | All signal files | `brief_YYYY-MM-DD.md` | Daily |
| `parse_inbox.ps1` | `_Inbox/` files | Routes to project folders | Daily |
| `block_calendar.ps1` | Calendar signals | Focus time events | Daily |
| `cleanup.ps1` | Old files | Archived files | Daily |
| `weekly_snapshot.ps1` | Week's signals | Weekly summary | Fridays |
| `sync_instructions.ps1` | Disk structure | Updated folder map | On demand |
| `serve_artifacts.py` | All workspace files | Web dashboard | On demand |

### Dual-Mode Signal Collection

Brain OS supports two modes for email and calendar access:

**COM Mode (Default, Windows)**
- Uses Outlook desktop COM automation
- Requires Outlook to be running
- Fastest, works offline with cached mail
- Set `signal_mode: "com"` in config.json

**Graph Mode (Cross-Platform)**
- Uses Microsoft Graph API via Azure CLI
- Requires `az login` with Graph permissions
- Works without Outlook desktop app
- Set `signal_mode: "graph"` in config.json

### Web Portal

The portal (`serve_artifacts.py`) provides:
- **Home Dashboard** — Today's KPIs, calendar, project status
- **Daily Brief** — Rendered markdown brief with syntax highlighting
- **Project Pages** — Per-project file browser and status
- **Tools** — Quick links to common actions
- **Search** — Full-text search across all workspace files
- **Auto-refresh** — Pages reload every 5 minutes

### Skills System

Skills are markdown files in `.vscode/skills/` that teach GitHub Copilot domain-specific behaviors. Each skill defines:
- **Trigger** — How to invoke (`/skill_name`)
- **Actions** — Available commands within the skill
- **Context sources** — What files the skill reads
- **Output** — What the skill produces

See [SKILLS_GUIDE.md](SKILLS_GUIDE.md) for details.

## Knowledge Base Files

These files provide persistent context that Copilot reads to give informed responses:

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `Goals.md` | OKRs, metric targets, weekly reflection | Weekly |
| `Charter_Areas.md` | Project scope, features, architecture | Monthly |
| `Key_Contacts.md` | People directory with roles | As needed |
| `Action_Items.md` | Tasks, deadlines, recurring meetings | Daily |
| `Partners.md` | External partner details | As needed |
| `Processes_Reference.md` | Team processes, technical notes | As needed |
| `AI_PM_Skills.md` | AI usage preferences | Rarely |
| `Trust_Boundaries.md` | What automation can/can't do | When adding features |
| `Agent_Build_Checklist.md` | Pre-mortem for new automation | When building |
| `Agent_Failure_Playbook.md` | Debugging taxonomy | When troubleshooting |

## Security Model

1. **No stored credentials** — All auth via `az login` (session tokens)
2. **Config is gitignored** — `config.json` never committed
3. **Signals are gitignored** — Raw email/chat content stays local
4. **Trust levels** — Each component has defined boundaries (see `Trust_Boundaries.md`)
5. **Human review gates** — External actions (email, calendar) require confirmation
6. **Local-first** — Portal runs on localhost only, no external exposure

## Design Principles

1. **Signal → Intelligence → Action** — Raw data becomes actionable insight
2. **Convention over configuration** — Folder names and file patterns are the API
3. **Markdown as data format** — Human-readable, version-controllable, AI-parseable
4. **Fail gracefully** — Missing signals produce empty sections, not crashes
5. **Additive, not destructive** — New data appends; old data archives
