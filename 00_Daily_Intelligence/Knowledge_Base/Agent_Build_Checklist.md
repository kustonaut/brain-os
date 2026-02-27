# Agent Build Checklist

> Run this 10-question pre-mortem before building ANY new automation or agent.
> If you can't answer all 10, you're not ready to build.

## The Checklist

### 1. What is the trigger?
- [ ] Manual (user invokes)
- [ ] Scheduled (cron/Task Scheduler)
- [ ] Event-driven (file drop, webhook)
- [ ] **Answer:** ___

### 2. What data does it read?
- [ ] Local files (signals, KB, config)
- [ ] APIs (Graph, ADO, GitHub)
- [ ] User input (chat, form)
- [ ] **Sources:** ___

### 3. What does it produce?
- [ ] File output (.md, .docx, .pptx, .html)
- [ ] API call (send email, create ticket)
- [ ] State change (update file, move item)
- [ ] **Output:** ___

### 4. What is the trust level?
Reference: Trust_Boundaries.md

| Level | Allowed Actions |
|-------|----------------|
| Read-only | Read files, query APIs, display data |
| Write-local | Create/modify local files |
| Write-external | Send emails, create tickets, post messages |
| Destructive | Delete files, close tickets, cancel meetings |

- [ ] **This agent's trust level:** ___

### 5. What happens when it fails?
- [ ] Silent failure (log only)
- [ ] User notification
- [ ] Retry with backoff
- [ ] Fallback to manual
- [ ] **Failure mode:** ___

### 6. What PII does it touch?
- [ ] None
- [ ] Names/emails (contacts)
- [ ] Meeting content
- [ ] Customer data
- [ ] **PII handling:** ___

### 7. How long should it take?
- [ ] <5 seconds (interactive)
- [ ] <30 seconds (background)
- [ ] <5 minutes (batch)
- [ ] **Expected duration:** ___

### 8. Who reviews the output?
- [ ] Fully automated (no review)
- [ ] PM reviews before action
- [ ] Team reviews before shipping
- [ ] **Review gate:** ___

### 9. How do you know it's working?
- [ ] Log file with success/failure
- [ ] Output file existence check
- [ ] Metric/counter
- [ ] Manual spot-check
- [ ] **Verification method:** ___

### 10. What does v2 look like?
- [ ] More data sources
- [ ] Better formatting
- [ ] Automation of review step
- [ ] Integration with other agents
- [ ] **Evolution path:** ___

---

## Usage

Before building any new script or skill:
1. Copy this checklist
2. Fill in all 10 answers
3. If any answer is "I don't know" — research first, build second
4. Save the completed checklist as a comment in your script or as a doc in the relevant project folder

## Anti-Patterns

❌ Building without knowing the trigger → "When does this run?"
❌ Write-external without review gate → Sending emails automatically
❌ No failure handling → Silent data loss
❌ No PII awareness → Leaking sensitive data in logs
❌ No v2 vision → Building dead-end automation
