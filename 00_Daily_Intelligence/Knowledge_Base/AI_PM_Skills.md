# AI PM Skills Reference

> How to use AI effectively as a PM. Prompt techniques, model routing, temperature guidance.
> This file teaches the AI assistant how YOU want to work with AI tools.

## Temperature by Task Type

| Task Type | Temperature | Rationale |
|-----------|-------------|-----------|
| Data extraction / briefs | 0.1 | Factual accuracy, no creativity needed |
| Status updates / reports | 0.3 | Structured but readable |
| Email drafting / comms | 0.5 | Professional tone with some personality |
| Brainstorming / ideation | 0.7 | Creative exploration |
| Creative writing / narratives | 0.8 | Maximum creativity |

> **Note:** Temperature settings are guidance for prompt templates and manual AI interactions.
> GitHub Copilot Chat uses its own temperature settings.

## Prompt Technique Ladder

Use increasingly sophisticated techniques as task complexity grows:

### Level 1: Direct Instruction
```
Summarize this email in 3 bullet points.
```

### Level 2: Role + Context
```
You are a PM writing a status update. Given these signals: [data].
Write a concise update for leadership.
```

### Level 3: Chain of Thought (CoT)
```
Think step by step:
1. What are the key metrics this week?
2. What changed from last week?
3. What risks need escalation?
Now write the status update.
```

### Level 4: Step-Back + CoT
```
Before answering, ask: What general principle applies here?
What is the PM most likely missing?
Then think step by step to answer: [question]
```

### Level 5: Multi-Agent Review
```
Generate three perspectives:
1. Advocate: Why this feature should ship
2. Skeptic: What could go wrong
3. Architect: Technical trade-offs
Then synthesize into a recommendation.
```

## Model Routing Guide

| Use Case | Recommended Model | Why |
|----------|-------------------|-----|
| Quick factual lookups | Fast/small model | Speed over depth |
| Code generation | Copilot default | Optimized for code |
| Long document analysis | Large context model | Needs full document |
| Strategic planning | Reasoning model | Complex multi-step logic |
| Creative content | Creative model | Tone and narrative |

## Prompt Templates

Store reusable prompts in `_Automation/prompt_templates/` as `.md` files with `{{variable}}` placeholders:

```markdown
# Template: Status Update
Temperature: 0.3

Given the following signals from {{date}}:
{{signals_summary}}

Write a status update for {{audience}} covering:
1. Key accomplishments
2. Risks and blockers
3. Next week priorities

Format: 5-7 bullet points, professional tone.
```

## AI Safety Boundaries

1. **Never auto-send** — All emails/messages require human review before sending
2. **Never fabricate data** — If metrics aren't available, say so
3. **Never guess contacts** — Use Key_Contacts.md, don't invent email addresses
4. **Always cite sources** — Reference which signal file or document informed the output
5. **Flag uncertainty** — If confidence is low, say "I'm not certain about X"
