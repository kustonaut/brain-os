# Setup Guide

> Complete walkthrough to get Brain OS running on your machine.
> Estimated time: 30–45 minutes for first setup.

## Prerequisites

| Requirement | Version | Check Command |
|------------|---------|---------------|
| **Windows 10/11** | Any recent | `winver` |
| **VS Code** | 1.85+ | `code --version` |
| **GitHub Copilot** | Latest | VS Code Extensions panel |
| **Python** | 3.10+ | `python --version` |
| **PowerShell** | 5.1+ | `$PSVersionTable.PSVersion` |
| **Azure CLI** | 2.50+ | `az --version` |
| **Microsoft Outlook** | Desktop app | Required for COM automation |

### Optional (for full feature set)

| Requirement | Purpose |
|-------------|---------|
| **Azure DevOps access** | Work item tracking via `fetch_ado.ps1` |
| **Microsoft Graph API** | Cross-platform email/calendar (alternative to COM) |

---

## Step 1: Clone the Repository

```powershell
git clone https://github.com/YOUR_USERNAME/brain-os.git
cd brain-os
```

## Step 2: Set Up Python Environment

```powershell
# Create virtual environment
python -m venv .venv

# Activate it
& ".\.venv\Scripts\Activate.ps1"

# Install dependencies
pip install -r _Automation/requirements.txt
```

### Dependencies installed:
- `python-docx` — Word document generation
- `python-pptx` — PowerPoint deck generation
- `openpyxl` — Excel file generation
- `matplotlib` — Charts and visualizations
- `requests` — HTTP calls
- `beautifulsoup4` — HTML parsing

## Step 3: Configure Your Identity

### 3a. Create your config.json

```powershell
Copy-Item "_Automation/config.sample.json" "_Automation/config.json"
```

### 3b. Edit config.json with YOUR details

Open `_Automation/config.json` and fill in:

```json
{
  "pm_identity": {
    "name": "Your Full Name",
    "email": "you@company.com",
    "team": "Your Team Name",
    "org": "Your Organization"
  },
  "projects": [
    {
      "id": "project-alpha",
      "name": "My First Project",
      "charter_folder": "01_Project_Alpha",
      "description": "Main product area"
    }
  ]
}
```

**Key sections to customize:**
- `pm_identity` — Your name, email, team
- `projects` — Your project/charter areas (add as many as needed)
- `charter_keywords` — Keywords that route signals to the right project
- `ado_config` — Your Azure DevOps organization, project, and tracked work item IDs
- `ai_guidance` — Temperature settings per task type

### 3c. Set up Azure CLI authentication

```powershell
az login
```

This authenticates you for:
- Azure DevOps queries (`fetch_ado.ps1`)
- Microsoft Graph API (if using Graph mode for email/calendar)

## Step 4: Create Your Folder Structure

The repository comes with template folders. Rename them to match your projects:

```
01_Project_Alpha/          ← Your first project area
  Reference/               ← Background docs, transition materials
  Recordings/              ← Meeting recordings (.mp4)
  Transcripts/             ← Meeting transcript files
02_Project_Beta/           ← Your second project area
  Reference/
  Recordings/
  Transcripts/
```

Create your project folders:

```powershell
# Example: Create folders for your projects
$projects = @("01_Project_Alpha", "02_Project_Beta", "03_Project_Gamma")
foreach ($p in $projects) {
    New-Item -Path "$p/Reference" -ItemType Directory -Force
    New-Item -Path "$p/Recordings" -ItemType Directory -Force
    New-Item -Path "$p/Transcripts" -ItemType Directory -Force
}
```

## Step 5: Populate Your Knowledge Base

The most important step. Brain OS learns from YOUR context.

### Required files (in `00_Daily_Intelligence/Knowledge_Base/`):

| File | What to Add | Priority |
|------|-------------|----------|
| **Goals.md** | Your OKRs, key results, metric targets | 🔴 Do first |
| **Charter_Areas.md** | Your ownership areas, features, scope | 🔴 Do first |
| **Key_Contacts.md** | People you work with, their roles, emails | 🔴 Do first |
| **Action_Items.md** | Open tasks, recurring meetings | 🟡 Add as you go |
| **Partners.md** | External partner details | 🟡 If applicable |
| **Processes_Reference.md** | Team processes, architecture notes | 🟡 Add as you go |
| **AI_PM_Skills.md** | AI usage preferences | 🟢 Optional tuning |
| **Trust_Boundaries.md** | What automation can/can't do | 🟢 Review defaults |
| **Agent_Build_Checklist.md** | Pre-mortem for new automation | 🟢 Use when building |
| **Agent_Failure_Playbook.md** | Debugging guide | 🟢 Use when broken |

### Quick-start: Fill in the top 3

```powershell
# Open the critical files for editing
code "00_Daily_Intelligence/Knowledge_Base/Goals.md"
code "00_Daily_Intelligence/Knowledge_Base/Charter_Areas.md"
code "00_Daily_Intelligence/Knowledge_Base/Key_Contacts.md"
```

Each file has instructions and templates — just replace the placeholder content with your actual data.

## Step 6: Customize Copilot Instructions

Edit `.github/copilot-instructions.md` to personalize GitHub Copilot's behavior:

1. Replace `{{your_name}}` with your name
2. Replace `{{your_team}}` with your team
3. Update the folder map to match your project structure
4. Review the "Always Rules" and adjust to your preferences

## Step 7: Test the Pipeline

### Dry run first (no changes):
```powershell
& ".\_Automation\daily_orchestrator.ps1" -DryRun -Force
```

### Full run:
```powershell
& ".\_Automation\daily_orchestrator.ps1" -Force
```

### Expected output:
```
[Step 0] Running cleanup...
[Step 1] Parsing inbox...
[Step 2] Fetching emails...
[Step 3] Fetching chats...
[Step 4] Fetching ADO items...
[Step 5] Fetching calendar...
[Step 6] Generating daily brief...
[Step 7] Blocking focus time...
Pipeline complete!
```

### Check results:
```powershell
# Today's signals
Get-ChildItem "00_Daily_Intelligence/Signals/" -Filter "*$(Get-Date -Format 'yyyy-MM-dd')*"

# Today's brief
Get-ChildItem "00_Daily_Intelligence/Daily_Briefs/" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

## Step 8: Launch the Portal

```powershell
& ".\.venv\Scripts\python.exe" "_Automation/serve_artifacts.py"
```

Open http://localhost:8765 in your browser. You should see your dashboard with today's signals, calendar, and project overview.

## Step 9: Schedule Daily Automation (Optional)

### Windows Task Scheduler

```powershell
# Register the daily task (runs at 8:30 AM on weekdays)
& ".\_Automation\register_task.ps1"
```

Or manually:
1. Open Task Scheduler (`taskschd.msc`)
2. Create Basic Task → "Brain OS Daily Pipeline"
3. Trigger: Daily, 8:30 AM, weekdays only
4. Action: Start Program → `powershell.exe`
5. Arguments: `-ExecutionPolicy Bypass -File "C:\path\to\brain-os\_Automation\daily_orchestrator.ps1" -Force`

## Step 10: Use VS Code Tasks

Press `Ctrl+Shift+B` or `Terminal > Run Task...` to see available tasks:
- **Run Daily Pipeline** — Full orchestrator
- **Dry Run Pipeline** — Preview mode
- **Launch Portal** — Start the web dashboard
- **Fetch Signals Only** — Signals without calendar blocking

---

## Troubleshooting

### "az login" fails
- Ensure Azure CLI is installed: `winget install Microsoft.AzureCLI`
- Try `az login --use-device-code` if browser auth doesn't work

### Outlook COM errors
- Ensure Outlook desktop app is running (not just web)
- If you get "Cannot create object", run: `& outlook.exe /resetnavpane`

### Pipeline produces empty signals
- Check `_Automation/config.json` has valid keywords and project mappings
- Ensure `az login` session is active
- Check `_Automation/logs/` for error details

### Portal won't start
- Check if port 8765 is in use: `Get-NetTCPConnection -LocalPort 8765`
- Kill conflicting process or change port in `serve_artifacts.py`

### Python import errors
- Ensure venv is activated: `& ".\.venv\Scripts\Activate.ps1"`
- Reinstall: `pip install -r _Automation/requirements.txt`

---

## What's Next?

After setup:
1. **Run the pipeline daily** — Let signals accumulate for 3-5 days
2. **Populate Knowledge Base** — Add more context as you learn your projects
3. **Try the skills** — Use `/eod` for daily close-out, `/capture` for meeting notes
4. **Customize** — Add new skills, modify prompt templates, tune AI settings
5. **Share** — Show your team, contribute improvements back

See [ARCHITECTURE.md](ARCHITECTURE.md) for system design and [SKILLS_GUIDE.md](SKILLS_GUIDE.md) for creating custom skills.
