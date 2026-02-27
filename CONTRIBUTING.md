# Contributing to Brain OS

Thank you for your interest in Brain OS! This project exists to help Product Managers work smarter with AI-powered automation.

## How to Contribute

### Report a Bug

1. Open an issue with the `bug` label
2. Include: what you expected, what happened, your OS, Python version
3. If it's a pipeline issue, include the log file from `_Automation/logs/`

### Suggest a Feature

1. Open an issue with the `enhancement` label
2. Describe the PM workflow this would improve
3. If you have a design, include it

### Submit a New Skill

Skills are the most impactful contribution. A good skill:

1. Solves a **specific** PM workflow problem
2. Has clear trigger words and actions
3. Lists its context sources (what KB files it reads)
4. Includes error handling guidance
5. References cross-skill workflows

**Template:** See [docs/SKILLS_GUIDE.md](docs/SKILLS_GUIDE.md) for the skill format.

### Submit a Pipeline Enhancement

1. Follow the pre-mortem checklist in `00_Daily_Intelligence/Knowledge_Base/Agent_Build_Checklist.md`
2. Ensure your script reads config from `config.json` (never hardcode paths or identity)
3. Add error handling with `try/catch` and logging
4. Test with `-DryRun` if applicable

## Code Standards

- **PowerShell:** Use `Write-Log` for output, `-Encoding UTF8` for all file operations
- **Python:** Use `encoding='utf-8'` for all file reads, handle missing files gracefully
- **Config:** All personalization must come from `config.json`, not hardcoded values
- **Trust:** Classify your script's trust level (see `Trust_Boundaries.md`)

## Pull Request Process

1. Fork the repo and create a feature branch
2. Make your changes with clear commit messages
3. Test locally — run the pipeline with your changes
4. Submit PR with a description of what you changed and why
5. Link any related issues

## Code of Conduct

Be respectful. Be helpful. Build tools that make PMs' lives better.
