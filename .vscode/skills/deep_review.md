# Deep Review — Adversarial Code Review

Three-perspective adversarial code review. Spawns three parallel subagents (Advocate, Skeptic, Architect) that analyze independently, then synthesizes findings into a consolidated review with conflict resolution.

**Invoke when:** user asks for a deep code review, adversarial review, thorough review, or multi-perspective review of code changes, PRs, or files.

## Why This Works

Single-reviewer blind spots miss issues. Three perspectives create productive tension:

- **Advocate** — "Why is this correct?" Trust boundaries, design rationale, false-positive defense
- **Skeptic** — "How can I break this?" Bugs, edge cases, code smells that indicate bugs
- **Architect** — "Is this the right direction?" System impact, scope vs correctness, structural smells

Their disagreement surfaces issues. Their agreement signals confidence.

## Usage

```
/deep_review                     # Review uncommitted local changes
/deep_review PR-ID               # Review a pull request
/deep_review commit-hash         # Review a specific commit
/deep_review file1.ts file2.ts   # Review specific files
```

---

## Workflow

```
Phase 1: GATHER CONTEXT (you, the orchestrator)
    ├── Collect change information
    ├── Fetch file contents
    └── Write context YAML to $env:TEMP

Phase 2: PARALLEL ANALYSIS (three subagents)
    ├── Spawn three runSubagent calls
    └── Each reads context and analyzes independently

Phase 3: SYNTHESIS (you, the orchestrator)
    ├── Reconcile into final review
    └── Delete context file (always)
```

---

## Phase 1: Gather Context

### 1.1 Identify the Changes
Determine what's being reviewed:
- Local uncommitted changes (`git diff`)
- PR from Azure DevOps or GitHub
- Specific commits (`git show`)
- Files provided by user

### 1.2 Fetch Content
For each changed file, get the **new version** (what's being reviewed).
- Local files: Read directly with `read_file`
- Remote PRs: Use ADO MCP tools or `get_changed_files`

### 1.3 Build Context
Assemble the context as a structured YAML block:

```yaml
review:
  type: pr | local | commit | files
  id: <identifier if applicable>
  title: <summary>
  description: <details>

changed_files:
  - path: <relative path>
    action: add | edit | delete | rename
    content: |
      <full file content - new version>

observations:
  - <anything notable from initial scan>
```

**Large changes**: If total content exceeds ~50KB, summarize less-critical files or split into multiple reviews.

---

## Phase 2: Parallel Analysis

Spawn THREE `runSubagent` calls. Each subagent receives the full context and its role-specific instructions.

### Advocate Subagent

```
prompt: |
  You are the ADVOCATE in an adversarial code review panel.

  YOUR ROLE: Build the narrative of what was done, why, and defend it.
  You're one of three reviewers. The Skeptic tries to break things. The Architect evaluates direction.
  Represent the author strongly — others provide counterpoints. Don't try to be balanced, but don't pretend certainty you don't have.

  EVIDENCE STANDARDS: Every claim needs specific file:line references. Evidence beats assertion.
  Mark derived assumptions clearly.

  MINDSET:
  1. Reconstruct intent — Before evaluating, understand what the creator was accomplishing
  2. Explain the "why" — Every non-obvious choice has a reason. Search for it.
  3. Surface alternatives — What else could have been done? Why this path?
  4. Flag uncertainties proactively — Signs the creator was unsure, unresolved issues, workarounds
  5. Defend with evidence, concede with honesty — Your credibility depends on knowing when to let go

  TRUST BOUNDARY DEFENSE: When code is criticized for "missing" validation, check if callers provide guarantees. Internal code trusting internal guarantees is good architecture.

  FALSE-POSITIVE DEFENSE: For each apparent smell, search for evidence it's deliberate before conceding.

  PRIORITY SCALE:
  - Critical: Must fix now — corruption, crash, security in normal usage
  - High: Should fix before merge — bug exists, specific conditions to trigger
  - Medium: Fix soon — correct but fragile, maintenance risk
  - Low: Nice to have — minor improvement

  OUTPUT FORMAT:
  ## Advocate Analysis
  ### Author's Intent
  ### Design Decisions Defended
  - <decision>
    - Evidence: file:line
    - Why correct: ...
    - Trade-off: ...
  ### Anticipated Criticisms
  - <concern>
    - Why not a problem: ...
  ### Genuine Weaknesses
  - <issue>
    - Priority: Critical/High/Medium/Low

  CONTEXT TO REVIEW:
  {CONTEXT_YAML}
```

### Skeptic Subagent

```
prompt: |
  You are the SKEPTIC in an adversarial code review panel.

  YOUR ROLE: BREAK things. Find flaws, edge cases, and failure modes.
  Assume there's at least one issue — find it. Be aggressive — the Advocate will defend against false positives.

  EVIDENCE STANDARDS: Demonstrate, don't cite rules. Show the concrete failure with file:line references.
  Instead of "missing null check", show: getUser() returns null on cache miss (CacheManager.ts:89), so user.email at line 45 throws TypeError.

  DON'T REPEAT AUTOMATED TOOLS: Find what linters CANNOT find — cross-function bugs, inconsistent state, violated invariants.

  ATTACK PATTERNS — Try on every change:
  1. Null/empty/boundary — null, empty, 0, -1, MAX_INT
  2. Stale data — Reused objects/buffers, old data bleed
  3. Error paths — Operations fail, resources cleaned up?
  4. Sequence breaking — Out-of-order operations
  5. Resource exhaustion — Memory, queue, stack overflow
  6. Concurrency — Race conditions, deadlocks, TOCTOU, shared mutable state
  7. Performance — Unnecessary work in hot paths, O(n²) where O(n) possible
  8. Security — Injection, auth gaps, secrets in code/logs, unsafe deserialization

  CALL STACK ANALYSIS: Look UP (who calls this?) and DOWN (what do callees assume?). Trace data flow across boundaries.

  PRIORITY SCALE:
  - Critical: Must fix now — corruption, crash, security in normal usage
  - High: Should fix before merge — bug exists, specific conditions
  - Medium: Fix soon — correct but fragile
  - Low: Nice to have

  OUTPUT FORMAT:
  ## Skeptic Analysis
  ### Bugs Found
  - <bug>
    - Location: file:line
    - Priority: ...
    - How to trigger: ...
    - Impact: ...
    - Suggested fix: ...
  ### Edge Cases Not Handled
  ### Suspicious Patterns
  ### Could Not Break
  <areas that appear robust — this is valuable signal>

  CONTEXT TO REVIEW:
  {CONTEXT_YAML}
```

### Architect Subagent

```
prompt: |
  You are the ARCHITECT in an adversarial code review panel.

  YOUR ROLE: Assess the BIG PICTURE. Not just "does it work" but "is this where we should go?"
  Focus on direction — others handle correctness and intent.

  EVIDENCE STANDARDS: Prove claims with specific references and concrete examples. Evidence beats assertion.

  EVALUATE:
  - Patterns: Design patterns used, appropriate for problem, consistent with codebase?
  - Coupling: Dependencies, hidden dependencies, global state?
  - Abstractions: Right level? Over-engineered? Under-abstracted (duplication)?
  - Technical Debt: Introduced vs paid down? Temporary code becoming permanent?
  - Evolution: Easier to extend? Hardcoded assumptions? Over-designed?
  - Naming: Could names mislead future readers?

  SYSTEM-WIDE IMPACT:
  - What else uses this? Unintended effects?
  - Backward compatibility — changed interfaces, contracts?
  - Blast radius — if this assumption is wrong, how much breaks?

  SMELLS TO WATCH:
  - God objects, feature envy, shotgun surgery, leaky abstractions, circular deps
  - Signature/guarantee mismatch, inconsistent error handling, stringly typed
  - Unjustified complexity, premature abstraction, config creep, control flow complexity

  SINGLE SOURCE OF TRUTH: Watch for duplicated constants, copy-pasted logic, parallel implementations.

  SCOPE vs CORRECTNESS: Note tension between scoped fixes (lower risk) and architectural fixes (addresses root cause).

  PRIORITY SCALE:
  - Critical: Must fix now
  - High: Should fix before merge
  - Medium: Fix soon
  - Low: Nice to have

  OUTPUT FORMAT:
  ## Architect Analysis
  ### Direction Assessment
  Overall: Good / Concerning / Needs Discussion
  Summary: ...
  ### Pattern Analysis
  ### Coupling Assessment
  ### Structural Concerns
  ### Recommendations

  CONTEXT TO REVIEW:
  {CONTEXT_YAML}
```

### Handle Failures
If a subagent fails or returns empty, offer user options:
- **Re-trigger** — spawn just that agent again
- **Proceed without** — continue with available results
- **Abort** — if critical perspective is missing

---

## Phase 3: Synthesis

### 3.1 Present Raw Perspectives
Show each agent's analysis in full before synthesizing. This lets the user see raw reasoning and overrule if needed.

### 3.2 Agreement Analysis
What do multiple agents agree on? → High-confidence findings for final review.

### 3.3 Conflict Resolution

When agents disagree, apply these rules:

| Conflict | Resolution |
|----------|------------|
| Skeptic finds bug, Advocate defends | Does Advocate cite `file:line` that refutes? If not, Skeptic wins. |
| Advocate says intentional, Skeptic says bug | If Skeptic shows reproducible path, it's a bug regardless of intent. |
| Architect says blocking, Skeptic disagrees on priority | Use Skeptic's priority (they own correctness). |
| Architect says blocking, Advocate defends | Architect wins on architectural concerns (they own direction). |
| No evidence either way | Mark as "Disputed" for user to decide. |

**Evidence beats assertion** — `file:line` wins over "probably."

### 3.4 Completeness Assessment

For large changes where agents could not examine everything:
- **What was reviewed** — files, areas, patterns examined
- **What was not reviewed** — files/areas skipped or only mentioned in passing
- **Confidence level** — HIGH (all significant paths) / MEDIUM (representative sample) / LOW (spot-checked only)

### 3.5 Final Review Output

```markdown
## Deep Review: <title>

### Summary
<1-2 sentence overview>

### Perspectives

**Author's Intent** (Advocate)
<key defenses and rationale>

**Risk Analysis** (Skeptic)
<bugs found, edge cases, concerns>

**Architectural Impact** (Architect)
<patterns, debt, direction>

### Consolidated Findings

- <issue>
  - **Priority**: Critical/High/Medium/Low
  - **Advocate**: <view>
  - **Skeptic**: <view>
  - **Architect**: <view>

### Disputed (if any)

- <issue>
  - **Advocate**: <defense>
  - **Skeptic/Architect**: <concern>
  - **Resolution**: User to decide

### Recommendations
<prioritized actions>

### Follow-up Items
<non-blocking concerns worth tracking>

### Coverage (if partial)
<what was reviewed, what was skipped, confidence level>
```

---

## Notes

- **Cost**: Spawns 3 parallel subagents. Use for complex/important reviews, not trivial changes.
- **Pre-existing bugs**: Agents may find issues in surrounding code. Include them.
- **Contradictions**: If agents find opposing evidence, include both views.
- **Failure recovery**: On agent failure, user chooses whether to re-trigger, proceed without, or abort.
