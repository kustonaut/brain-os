# TSG Writer — Troubleshooting Guide Skill

Write or review troubleshooting guides (TSGs) for operational excellence.

**Invoke when:**
1. **AFTER IMPLEMENTING**: new major metrics, failure modes/error codes, external dependencies, new feature flags, failover scenarios or critical features.
2. **IMPLEMENTING**: fixes to incidents, repair items, outages, availability, failover or mitigation guides.
3. **REVIEWING**: markdown files with TSG naming patterns (e.g., troubleshooting, tsg, runbook) or any major changes.

Ensure documentation is AI-ready. CONSIDER: Use `ai_ready_docs` skill for comprehensive AI-ready standards.

## Your Key Responsibilities

- Determine given the context if the user wants you to **REVIEW** existing TSGs or **WRITE/EDIT** new TSGs
- Use the detailed sections following Your Key Responsibilities to understand and apply TSG best practices and standards
- When **REVIEWING** TSGs:
  - Proactively leave comments and suggest improvements or fixes for TSG standards
  - Comment format: "DOCUMENTATION: TSG REVIEW\n\nISSUE:\n\n[problem].\n\nIMPACT: [risk].\n\nFIX: [solution]."
  - **CRITICAL**: If no issues are found, do **NOT** leave any comments
- When **WRITING** or **EDITING** TSGs:
  - Proactively apply TSG standards to any troubleshooting guide you create or modify
  - Prioritize standards documented in this skill before other known standards
  - When unsure of anything related to TSGs, ask clarifying questions to the user before proceeding

## Quick Reference: When TSGs are Required

| Change Type | TSG Required? | Why |
|-------------|---------------|-----|
| New **major** metric | Yes | Ops needs to understand what it measures |
| New failure mode/error code | Yes | Ops needs troubleshooting steps |
| New external dependency | Yes | Ops needs to troubleshoot connectivity issues |
| New **major** feature | Yes | Ops needs to understand failure scenarios |
| Refactoring (no new behavior) | No | Same failure modes as before |
| Test changes | No | No operational impact |
| Documentation updates | No | Not an operational concern |

## When to Create or Update TSGs

### Requires TSG

#### 1. New Major Metrics
When metrics are added, ops teams need to understand what triggers them and how to investigate.

**Example**:

```csharp
// This requires a TSG
logger.LogMetric(
    "TokenProviderLatency",
    dimensions,
    latencyMs);
```

**Required in TSG**:

- What the metric measures
- Expected baseline values
- What causes high values
- How to investigate and mitigate

**How to identify if metric is major**:

- Metrics that are alerted on in monitoring systems
- Metrics that indicate user-impacting issues
- Metrics that reflect core functionality or business scenarios
- Metrics documented in SLA/SLO definitions
- Metrics that track critical dependencies

#### 2. New Failure Conditions or Error Codes
When new exceptions, error codes, or failure scenarios are introduced.

**Example**:

```csharp
// This requires TSG update
if (response.StatusCode == HttpStatusCode.TooManyRequests)
{
    throw new RateLimitExceededException("Rate limit exceeded");
}
```

**Required in TSG**:

- When this error occurs
- What it indicates
- Immediate mitigation steps
- Investigation procedures

#### 3. New External Dependencies
When integrating with external services, databases, or APIs.

**Required in TSG**:

- How to verify connectivity
- Common failure scenarios
- Authentication troubleshooting
- Performance investigation

#### 4. New Major Features
Features that impact system behavior, performance, or reliability.

**Required in TSG**:

- How feature failures manifest
- Related metrics and alerts
- Mitigation steps
- Rollback procedures

### Does NOT Require TSG

- Internal refactoring with same behavior
- Adding unit tests
- Code formatting changes
- Performance optimizations (unless they introduce new failure modes)
- Bug fixes that don't change observable behavior

## TSG Structure (Required Sections)

Every TSG must follow this structure, though section names can vary slightly as long as the intent is clear.

```markdown
# [Clear, Descriptive Title]

## Description
Brief overview of the problem this TSG addresses.

## Symptoms
Observable signs that indicate this issue (around 2-5 bullets).

## Mitigation Steps
Immediate actions to restore service (prioritize user impact reduction). Include verification steps.

## Further Investigation
Steps for root cause analysis after mitigation.

## Escalation Path
When and how to escalate. Always include this section - even if team ownership is obvious, specify the team/contact and escalation method.

## References
Links to dashboards, runbooks, related docs.
```

### Section-by-Section Guidelines

#### 1. Title
**Requirements**:

- Clear and specific
- Describes the problem, not the solution
- Includes key context (component, error type, or symptom)

```markdown
GOOD:
# Troubleshooting High Latency in Token Provider

BAD:
# Token Provider Issues (too vague)
# How to Fix Latency (focuses on solution, not problem)
```

#### 2. Description
**Requirements**:

- 1-3 sentences
- Explains what the TSG covers
- Sets context for the troubleshooting steps

**Good Example:**
This TSG guides you through diagnosing and mitigating high latency issues in the Token Provider service. High latency typically manifests as slow authentication responses and can impact all downstream services.

#### 3. Symptoms
**Requirements**:

- Observable indicators (what you see in monitoring/alerts)
- Specific error messages or log patterns
- Dashboard anomalies
- Automated incident titles

**Good Example:**
You may observe one or more of the following:

- **Alert**: "TokenProviderLatency exceeds 5000ms" fires in your incident management system
- **Dashboard**: Token Provider P95 latency spike on monitoring dashboard
- **Logs**: Frequent timeout errors: "Token request timed out after 30s"
- **User Reports**: Slow login times reported by users
- **Metrics**: `TokenProviderLatency` metric > 5000ms for >5 minutes

#### 4. Mitigation Steps (CRITICAL)
**Requirements**:

- **Mitigation comes BEFORE investigation**
- Focus on restoring service health
- Numbered, sequential steps
- Each step must be actionable and specific
- Include validation after each step

**Good Example:**

```markdown
## Example Mitigation Steps

### Step 1: Verify and Scale Token Provider Instances

**Action**: Check current instance count and scale if needed.

- Command to check instances: `kubectl get pods -l app=token-provider -n production`
- Command to scale up: `kubectl scale deployment token-provider --replicas=15 -n production`

**Validation**:

- Verify new pods are running: `kubectl get pods -l app=token-provider`
- Check latency metric: Should decrease within 2-3 minutes

**Expected Result**: Latency returns to <1000ms within 5 minutes.

### Step 2: Enable Circuit Breaker if Cascading Failures Detected

**Action**: If downstream dependencies are failing, enable circuit breaker.

- Command to enable circuit breaker in config map: `kubectl edit configmap token-provider-config -n production`

**Validation**:

- Check logs: "Circuit breaker enabled" message
- Monitor fallback metric: `TokenProviderFallback` should increase

**Expected Result**: Service degrades gracefully, error rate decreases.

### Step 3: Restart Unhealthy Pods

**Action**: Identify and restart pods with high memory or CPU usage.
 - Command to list pods by resource usage: `kubectl top pods -l app=token-provider -n production`
 - Command to delete pod to trigger restart (Kubernetes will recreate): `kubectl delete pod <pod-name> -n production`

**Validation**:

- New pod starts successfully
- Latency for that pod normalizes

**Expected Result**: Overall latency improves.
```

**Key Principles for Mitigation**:

- Each step must be safe (no data loss)
- Include pre-checks before destructive actions
- Provide validation criteria
- Include expected timeframes
- Don't say "restart the service" without specific commands
- Don't skip validation steps
- Don't assume "it should work" - verify

#### 5. Further Investigation
**Requirements**:

- Root cause analysis steps
- Diagnostic queries
- Log analysis patterns
- Correlation with other events

**Good Example:**

```markdown
## Further Investigation

After service is stable, investigate root cause:

### Check Service Dependencies

1. **Verify downstream service health**:
   ```kql
   requests
   | where timestamp > ago(1h)
   | where name contains "TokenProvider"
   | summarize FailureRate = countif(success == false) * 100.0 / count() by dependency_name
   | where FailureRate > 5
   ```

2. **Analyze database query performance**:
   ```bash
   # Check database metrics
   az monitor metrics list --resource <db-resource-id> --metric "QueryDuration"
   ```

### Review Recent Deployments

Check if latency spike correlates with a deployment:

- Review deployment history in CI/CD pipelines
- Check for configuration changes
- Review feature flag changes in past 2 hours

### Common Root Causes

- **Database connection pool exhaustion**: Check connection pool metrics
- **Downstream service degradation**: Check dependency health
- **Memory leak**: Review memory usage trends
- **Network issues**: Check inter-service latency
```

#### 6. Escalation Path
**Requirements**:

- Clear criteria for when to escalate
- Who to contact (by role, not name)
- How to engage (incident system, Teams, email)
- What information to provide

**Good Example:**

```markdown
### When to Escalate

Escalate if:

- Mitigation steps don't reduce latency to <2000ms within 15 minutes
- Error rate remains >5% after 20 minutes
- User-facing impact continues for >30 minutes
- Underlying cause is not clear after investigation

### Who to Contact

1. **Team DRI**: Token Provider team on-call
2. **Database Team**: If database is identified as root cause
3. **Platform Team**: If infrastructure or networking issue suspected
```

#### 7. References
**Requirements**:

- Links to monitoring dashboards
- Related TSGs
- Runbooks
- Architecture documentation

**Good Example:**

```markdown
## References

### Dashboards

- [Token Provider Monitoring Dashboard](https://monitoring.example.com/token-provider)
- [Token Provider Application Insights](https://portal.azure.com/...)

### Related TSGs

- [Troubleshooting Token Provider Authentication Failures](./tsg-token-auth-failures.md)
- [Database Connection Issues](./tsg-db-connectivity.md)

### Runbooks

- [Token Provider Deployment Runbook](../runbooks/token-provider-deploy.md)
- [Emergency Rollback Procedure](../runbooks/emergency-rollback.md)

### Documentation

- [Token Provider Architecture](../docs/token-provider-architecture.md)
- [Dependency Map](../docs/service-dependencies.md)

### Metrics

- Metric Name: `TokenProviderLatency`
- Namespace: `Platform/Authentication`
- Alert Threshold: >5000ms for >5 minutes
```

## TSG Best Practices

### 1. Task-Focused (Not Teaching)

```markdown
GOOD:
"Run: `kubectl get pods -l app=token-provider`"

BAD:
"Kubernetes is a container orchestration platform. To view pods, you use kubectl..."
```

### 2. Mitigation Before Investigation

```markdown
GOOD:
## Mitigation Steps
[Immediate actions]

## Further Investigation
[Root cause analysis]

BAD:
## Investigation Steps
[Long analysis procedures before any mitigation]
```

### 3. Specific Commands, Not Vague Instructions

```markdown
GOOD:
kubectl scale deployment token-provider --replicas=15 -n production

BAD:
"Scale up the service" (how? by how much? which environment?)
```

### 4. Include Validation

```markdown
GOOD:
**Validation**: Run `kubectl get pods` and verify 15 pods are in "Running" state.

BAD:
[No validation step - just hope it worked]
```

### 5. Safety Pre-Checks
GOOD:
**Pre-check**: Verify no deployment is in progress before restarting pods.

```bash
kubectl rollout status deployment/token-provider
```

BAD:
"Restart all pods" (without checking if it's safe)

## Review Checklist

When reviewing TSGs, verify:

- [ ] **Title**: Clear, specific, problem-focused
- [ ] **All Required Sections**: Description, Symptoms, Mitigation, Investigation, Escalation, References
- [ ] **Mitigation First**: Mitigation steps come before investigation
- [ ] **Actionable Steps**: Each step has specific commands or actions
- [ ] **Validation**: Each mitigation step includes validation criteria
- [ ] **Safety**: Pre-checks exist for destructive operations
- [ ] **Specificity**: No vague instructions like "restart service" without details
- [ ] **AI-Ready**: Consistent formatting, code blocks with language tags
- [ ] **Links Work**: All dashboard and documentation links are valid
- [ ] **Up-to-Date**: Commands use current CLI versions and flags

## What NOT to Do

- Don't accept vague mitigation steps without specific commands
- Don't skip validation steps
- Don't put investigation before mitigation
- Don't assume readers know internal tool names or procedures
- Don't ignore outdated CLI flags or deprecated commands
- Don't overlook missing safety pre-checks for destructive operations
- Don't forget escalation criteria and contact information
