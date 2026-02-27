# Agent Failure Playbook

> When automation breaks, classify the failure FIRST, then fix.
> Don't guess — use taxonomy.

## Failure Taxonomy

### Category 1: Dev Failures (Your Code)

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Script won't start | Missing dependency, bad path | Check `pip list`, verify paths |
| Wrong output format | Template changed, schema drift | Compare against expected schema |
| Partial output | Early exit, unhandled exception | Add try/catch, check logs |
| Stale data | Cache not refreshed, old file read | Clear cache, check timestamps |

**Debug Steps:**
1. Check the log file in `_Automation/logs/`
2. Run the script manually with verbose output
3. Verify config.json has correct values
4. Check file permissions and paths

### Category 2: LLM Failures (AI Behavior)

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Hallucinated data | No grounding context provided | Add source files to prompt |
| Wrong tone/format | Temperature too high, no examples | Lower temperature, add few-shot |
| Ignored instructions | Prompt too long, buried instructions | Move critical rules to top |
| Inconsistent output | Non-deterministic generation | Set temperature=0.1, add format spec |

**Debug Steps:**
1. Review the prompt template in `_Automation/prompt_templates/`
2. Check if context files exist and have content
3. Test with a simpler prompt to isolate the issue
4. Add explicit format examples to the prompt

### Category 3: Production Failures (Environment)

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Auth failure | Token expired, `az login` needed | Run `az login` |
| API rate limit | Too many calls too fast | Add backoff/retry logic |
| Port in use | Another process on same port | Kill process or change port |
| File locked | OneDrive sync, another app | Save to temp first, then copy |
| Scheduled task didn't run | Task Scheduler disabled, PC asleep | Check Task Scheduler, wake settings |

**Debug Steps:**
1. Check Windows Task Scheduler history
2. Verify `az account show` returns valid subscription
3. Check `netstat -ano | findstr :PORT` for port conflicts
4. Check OneDrive sync status for file lock issues

---

## Recovery Procedures

### Quick Recovery (< 2 minutes)
```powershell
# Re-authenticate
az login

# Kill stuck process on port
Get-Process -Id (Get-NetTCPConnection -LocalPort 8765 -ErrorAction SilentlyContinue).OwningProcess | Stop-Process -Force

# Clear and re-run pipeline
Remove-Item "_Automation/logs/*.log" -ErrorAction SilentlyContinue
& ".\_Automation\daily_orchestrator.ps1" -Force
```

### Data Recovery
```powershell
# Signals are date-stamped — check previous day
Get-ChildItem "00_Daily_Intelligence/Signals/" -Filter "*$(Get-Date -Format 'yyyy-MM-dd')*"

# Briefs have backups in archive
Get-ChildItem "08_Archive/Briefs/" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

### Escalation Triggers
Escalate (ask for human help) when:
- ❌ Auth failure persists after re-login
- ❌ Data appears corrupted (not just missing)
- ❌ Same failure 3+ times in a row
- ❌ Failure affects external communications (sent wrong email, wrong data)

---

## Post-Failure Checklist

After resolving any failure:
- [ ] Root cause identified and documented
- [ ] Fix applied and tested
- [ ] Added error handling to prevent recurrence
- [ ] Updated this playbook if it's a new failure type
- [ ] Verified next scheduled run succeeds
