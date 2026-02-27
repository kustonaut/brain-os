# Skill: PM OS Architect (`/pm_os_architect`)

## What This Skill Does
Design, debug, and extend your PM Operating System — scripts, skills, automations, and KB files. Applies AI engineering best practices from `Knowledge_Base/AI_PM_Skills.md`.

## When to Invoke
- "Add a new automation step to the pipeline"
- "Create a new skill for [workflow]"
- "Debug why [script] is failing"
- "Improve the brief prompt"
- "Review my automation against the pre-mortem checklist"

## Pre-Mortem Gate
Before building anything new, automatically run through `Agent_Build_Checklist.md`:
1. State the goal in one sentence
2. Classify all actions by trust level (see `Trust_Boundaries.md`)
3. Define the golden test case
4. Confirm the build-vs-manual calculus

## Design Patterns

### Temperature Assignment
Look up task type in `config.json → ai_guidance.temperature_by_task` before any prompt design.

### Model Routing
Classify task complexity:
- Simple parse/format → fast_cheap
- Email/brief/meeting → balanced  
- Architecture/deep analysis → deep_reasoning

### CoT + Step-Back Template
```
STEP BACK: What general principle applies to this type of PM automation?
COT: 
  1. What is the one clear goal?
  2. What data does it read?
  3. What actions does it take (and are they reversible)?
  4. What's the worst realistic failure?
  5. How does it fail gracefully?
```

### ReAct Pattern for Debug
```
REASON: [What the script is supposed to do]
ACT: Run the script with test input
OBSERVE: Check output vs expected (eval suite)
REASON: What changed? What's the root cause?
ACT: Apply the fix
OBSERVE: Rerun eval suite — did score improve?
```

## Output Formats
- New scripts → `_Automation/` folder
- New skills → `.vscode/skills/`  
- New KB entries → `00_Daily_Intelligence/Knowledge_Base/`
- New prompt templates → `_Automation/prompt_templates/`
- Eval test cases → `_Automation/evals/`

## Reference Files
- `Knowledge_Base/AI_PM_Skills.md` — full tech stack and technique ladder
