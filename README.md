<p align="center">
  <img src="docs/brain-os-logo.svg" alt="Brain OS" width="80" />
</p>

<h1 align="center">Brain OS</h1>
<p align="center">
  <strong>An AI-powered daily operating system for Product Managers</strong><br/>
  Built on VS Code + GitHub Copilot
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#what-it-does">What It Does</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#skills">Skills</a> •
  <a href="docs/SETUP.md">Full Setup Guide</a>
</p>

---

## The Problem

Product Managers juggle emails, calendars, ADO boards, meeting notes, action items, partner comms, and strategic docs — across 5+ tools every day. Context is scattered. Priorities are buried. The first 45 minutes of every morning is spent *figuring out what to focus on*.

## The Solution

**Brain OS** is a local-first, AI-powered PM workspace that:

1. **Auto-fetches** your daily signals (emails, calendar, ADO, Teams chats)
2. **Generates** an intelligent daily brief with priorities, meeting prep, and action items
3. **Serves** a beautiful local Command Center dashboard at `localhost:8765`
4. **Integrates** with GitHub Copilot as your AI PM assistant via custom skills
5. **Learns** from your goals, knowledge base, and feedback loops

All data stays on your machine. No cloud dependency. No subscription.

---

## Quick Start

### Prerequisites

- **Windows 10/11** (macOS/Linux: partial support — see [Setup Guide](docs/SETUP.md))
- **VS Code** with GitHub Copilot extension
- **Python 3.10+**
- **PowerShell 5.1+** (built into Windows)
- **Azure CLI** (`az login`) — for email, calendar, and ADO signals

### 1. Clone & Setup

```bash
git clone https://github.com/YOUR_USERNAME/brain-os.git
cd brain-os
python -m venv .venv
.venv\Scripts\activate
pip install -r _Automation\requirements.txt
```

### 2. Configure Your Identity

```bash
copy _Automation\config.sample.json _Automation\config.json
```

Edit `_Automation/config.json` with your details — name, email, projects, ADO org. See the [Setup Guide](docs/SETUP.md) for a walkthrough.

### 3. Authenticate

```bash
az login
```

### 4. Run Your First Pipeline

```powershell
.\_Automation\daily_orchestrator.ps1 -Force
```

### 5. Launch the Command Center

```powershell
python _Automation\serve_artifacts.py
# Open http://localhost:8765
```

### 6. Open in VS Code

Open the `brain-os` folder in VS Code. GitHub Copilot will automatically load your skills and knowledge base from `copilot-instructions.md`.

---

## What It Does

### Daily Pipeline (runs automatically at 8:30 AM)

```
Step 0: Cleanup    → Archive old signals (>14d), briefs (>30d)
Step 1: Inbox      → Parse new files dropped in _Inbox/ folder
Step 2: Emails     → Fetch keyword-filtered emails from Outlook
Step 3: Chats      → Fetch Teams chat highlights via Graph API
Step 4: ADO        → Fetch Azure DevOps work item states
Step 5: Calendar   → Fetch today's meetings, free slots, conflicts
Step 6: Brief      → AI-generated daily intelligence brief
Step 7: (Custom)   → Your custom pipeline steps (optional)
Step 8: Calendar   → Block focus time for top priorities
Step 9: Sync       → Regenerate copilot-instructions.md from disk
```

### Command Center Portal (`localhost:8765`)

A Fluent 2-themed dark/light mode dashboard with:
- **KPI Strip** — Signal counts, pipeline status, action item urgency
- **Calendar View** — Today's meetings with free slots highlighted
- **Action Items** — Parsed from your `Action_Items.md` knowledge base
- **Project Tiles** — Quick access to each charter area's artifacts
- **Daily Brief** — AI-generated brief rendered as a web page
- **File Search** — Instant search across all workspace artifacts
- **Tools** — One-click pipeline execution, signal refresh, cleanup

### GitHub Copilot Skills

Custom skills that turn Copilot into your PM co-pilot:

| Skill | Trigger | What It Does |
|-------|---------|-------------|
| **Quick Capture** | `/capture` | Extract decisions, AIs, signals from meetings → route to correct files |
| **End of Day** | `/eod` | Interactive daily close-out → review tasks, log wins, seed tomorrow |
| **Meeting Prep** | `/m365_meeting_prep` | Auto-generate prep docs from calendar + signals + KB |
| **Email Drafter** | `/m365_email_drafter` | Draft professional emails with context from KB and signals |
| **ADO Reporter** | `/m365_ado_reporter` | Sprint health, epic burndown, stale item detection |
| **Teams Comms** | `/m365_teams_comms` | Draft standups, announcements, escalations for Teams |
| **Doc Generator** | `/m365_doc_generator` | Generate Word/PPT/Excel from templates and data |
| **Feedback Synthesis** | `/feedback_synthesis` | Cross-source feedback analysis → unified themes |
| **Insights to Spec** | `/insights_to_spec` | Convert signal patterns into structured feature specs |
| **Deep Review** | `/deep_review` | Adversarial code/doc review with 3 parallel perspectives |
| **PM OS Architect** | `/pm_os_architect` | Design and extend your own automation pipeline |
| **PM OS Eval** | `/pm_os_eval` | Score and regression-test your daily brief quality |
| **Workspace Kit** | `/pm_workspace_kit` | Setup wizard, portal launch, health check |

---

## Architecture

```
brain-os/
├── _Automation/           ← Pipeline scripts + config
│   ├── config.json        ← YOUR identity, projects, settings
│   ├── daily_orchestrator.ps1  ← Master pipeline (10 steps)
│   ├── generate_brief.ps1      ← AI brief generator (685 lines of PM intelligence)
│   ├── serve_artifacts.py      ← Command Center portal server
│   ├── fetch_emails.ps1        ← Outlook signal fetcher (COM + Graph)
│   ├── fetch_calendar.ps1      ← Calendar signal fetcher
│   ├── fetch_ado.ps1           ← ADO work item fetcher
│   ├── fetch_chats.ps1         ← Teams chat fetcher
│   ├── graph_helpers.ps1       ← MS Graph API helpers
│   ├── parse_inbox.ps1         ← File parser & router
│   ├── block_calendar.ps1      ← Focus time blocker
│   ├── cleanup.ps1             ← Signal/brief archival
│   ├── sync_instructions.ps1   ← Auto-sync copilot-instructions.md
│   └── weekly_snapshot.ps1     ← Weekly signal aggregation
│
├── .vscode/
│   ├── tasks.json         ← VS Code task shortcuts
│   └── skills/            ← 14 GitHub Copilot skills
│
├── 00_Daily_Intelligence/
│   ├── Knowledge_Base/    ← Goals, contacts, action items, processes
│   ├── Daily_Briefs/      ← AI-generated daily briefs
│   ├── Signals/           ← Raw signal files (emails, ADO, calendar, chats)
│   ├── Meeting_Prep/      ← Generated meeting prep docs
│   └── Weekly_Snapshots/  ← Friday aggregations
│
├── _Inbox/                ← Drop files here → auto-routed to projects
│
├── projects/              ← Your project folders (create per charter area)
│   ├── project-alpha/
│   ├── project-beta/
│   └── ...
│
└── docs/                  ← Setup guide, architecture, skill reference
```

### Design Principles

1. **Local-first** — All data on your machine. No cloud storage of personal data.
2. **Config-driven** — One JSON file defines your entire workspace identity.
3. **Dual-mode signals** — COM (Windows Outlook) with Graph API fallback.
4. **Skill-based AI** — Copilot skills loaded on-demand, not always in context.
5. **Trust boundaries** — Every script has a trust level (read-only → communicate).
6. **Eval-driven** — Brief quality is scored against a rubric. Prompt changes require regression tests.

---

## Knowledge Base

The `00_Daily_Intelligence/Knowledge_Base/` folder is your PM brain:

| File | Purpose |
|------|---------|
| `Goals.md` | OKRs, key results, metric targets, weekly reflection |
| `Action_Items.md` | Open tasks with urgency levels (🔴/🟡/⚪) |
| `Key_Contacts.md` | People, aliases, roles, relationships |
| `Charter_Areas.md` | Your project scope, features, architecture context |
| `Processes_Reference.md` | Team processes, playbooks, technical notes |
| `AI_PM_Skills.md` | Prompt techniques, temperature guide, model routing |
| `Trust_Boundaries.md` | What each automation is allowed to do |
| `Agent_Build_Checklist.md` | 10-question pre-mortem for new automations |
| `Agent_Failure_Playbook.md` | Failure taxonomy + recovery procedures |

**The more context you add, the smarter your daily brief becomes.**

---

## AI Engineering

Brain OS applies production AI engineering practices:

- **Temperature routing** — `config.json` maps task types to temperatures (0.1 for data, 0.5 for comms, 0.8 for creative)
- **CoT + Step-Back** — System prompts include chain-of-thought and step-back reasoning
- **Eval suite** — Golden test cases for brief generation with 5-dimension scoring
- **Failure taxonomy** — Dev / LLM / Production failure classification
- **Trust levels** — L0 (read) → L4 (external API) with escalation triggers
- **Pre-mortem gate** — Every new automation passes a 10-question checklist

---

## Customization

### Adding a New Project

1. Add to `config.json` → `projects[]`
2. Create a folder in `projects/` (e.g., `projects/my-project/`)
3. Add routing keywords to `config.json` → `charter_patterns[]`
4. Run `sync_instructions.ps1` to update Copilot context

### Creating a New Skill

1. Create `.vscode/skills/my_skill.md` with trigger, purpose, actions, context sources
2. Register in `.github/copilot-instructions.md`
3. Test with `/my_skill` in Copilot Chat

### Adding a Pipeline Step

1. Create your script in `_Automation/`
2. Add it to `daily_orchestrator.ps1` as a new step
3. Run the pre-mortem checklist: `Agent_Build_Checklist.md`

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE) — Use it, fork it, make it yours.

---

<p align="center">
  <strong>Built for PMs who believe their daily workflow deserves the same engineering rigor they demand from their products.</strong>
</p>
