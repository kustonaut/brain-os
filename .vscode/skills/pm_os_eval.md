# Skill: PM OS Eval Runner (`/pm_os_eval`)

## What This Skill Does
Run the brief generation eval suite against golden test cases. Check prompt quality, spot regressions, and score output.

## When to Invoke
- "Run the eval suite"
- "Did my change to generate_brief break anything?"
- "Score today's brief"
- "Run test case 04 (escalation)"

## Eval Suite Location
`_Automation/evals/brief_eval_suite.md`

## Actions

### `run_all`
Run all 10 golden test cases. Report pass/fail per case, overall score.

### `run_case N`
Run single test case. Feed its input signals into the brief generator and score output.

### `score_today`
Score today's already-generated brief against the 5-dimension rubric.

### `regression`
Compare today's brief against yesterday's on the same rubric. Flag any dimension that dropped >1 point.

## Scoring Rubric (quick reference)
| Dimension | Weight | What to check |
|---|---|---|
| Factual accuracy | 2 pts | No data not in signals |
| Priority identification | 2 pts | Clear #1 with owner + deadline |
| Meeting prep quality | 2 pts | Specific talking points |
| Action item capture | 2 pts | All KB open items surfaced |
| Conciseness | 2 pts | 200-500 words |

**Pass: ≥7/10. Fail: <7/10 triggers investigation.**

## How to Use

```
# Score today's brief:
/pm_os_eval score_today

# Expected output:
Brief: 2026-02-26_Brief.md
Factual accuracy: 2/2 ✅
Priority identification: 2/2 ✅  
Meeting prep: 1/2 ⚠️ (no prep for Stakeholder 1:1)
Action item capture: 2/2 ✅
Conciseness: 1/2 ⚠️ (562 words — slightly over)
Total: 8/10 PASS
```

## Failure Response
If brief scores <7/10:
1. Check `Agent_Failure_Playbook.md` for root cause taxonomy
2. Update prompt template in `_Automation/prompt_templates/daily_brief.md`
3. Re-run eval to verify improvement
4. If >2 test cases fail → run full regression suite before next scheduled run
