# AI-Ready Documentation — Formatting Skill

Write or review documentation for LLM comprehension quality (AI-readiness) in markdown files.

**Invoke when:**
1. **AFTER IMPLEMENTING**: new or modified troubleshooting guides (TSG), READMEs, documentation.
2. **IMPLEMENTING**: markdown documentation for new features, frameworks, or guides.
3. **REVIEWING**: inconsistent heading hierarchy, vague headings, code blocks without language tags, missing context, dense paragraphs, jargon without explanation, missing tables, no good/bad example markers.

## Your Key Responsibilities

- Determine given the context if the user wants you to **REVIEW** existing documentation or **WRITE/EDIT** new documentation
- Use the detailed sections following Your Key Responsibilities to understand and apply AI-readability best practices and standards
- When **REVIEWING** documentation:
  - Proactively leave comments and suggest improvements or fixes for AI-friendly formatting
  - Comment format: "DOCUMENTATION: AI-READINESS REVIEW\n\nISSUE:\n\n[problem].\n\nIMPACT: [risk].\n\nFIX: [solution]."
  - **CRITICAL**: If no issues are found, do **NOT** leave any comments
- When **WRITING** or **EDITING** documentation:
  - Proactively apply AI-ready formatting standards to any documentation you create or modify
  - Prioritize standards documented in this skill before other known standards
  - When unsure of anything related to AI-readability, ask clarifying questions to the user before proceeding

## Core Principles

1. **Structure Over Prose**: Use hierarchies, tables, lists - AI can parse structured data into knowledge graphs
2. **Explicit Over Implicit**: Show relationships/dependencies - reduces AI hallucination risk
3. **Scannable Over Dense**: Break into chunks - enables token-efficient extraction
4. **Consistent Over Creative**: Use standard formats - improves AI information extraction
5. **Validated Over Aspirational**: Include verification steps - creates testable assertions for AI

## AI-Ready Formatting Standards

### 1. Use Hierarchical Structure

```markdown
GOOD:
# Main Topic
## Sub-topic
### Detail
#### Sub-detail

BAD:
# Main Topic
# Another Main Topic (should be ##)
## Sub-topic
# Back to Main (inconsistent hierarchy)
```

**Why**: AI systems rely on document structure to understand relationships between concepts. Proper hierarchy enables accurate parsing and context extraction.

### 2. Use Descriptive Headings with Keywords

```markdown
## BAD: Setup -> GOOD: Setup the Token Provider
## BAD: Problems -> GOOD: Common Token Provider Problems
## BAD: Troubleshooting -> GOOD: Token Provider Troubleshooting
```

**Why**: Descriptive headings help AI systems quickly locate relevant sections and understand content without reading full paragraphs.

### 3. Keep Sentences Short and Direct

```markdown
GOOD:
"Configure the timeout in appsettings.json. Set the value in seconds. The default is 30 seconds."

BAD:
"You'll want to configure the timeout, which can be done in the appsettings.json file where you'll need to set the value (make sure it's in seconds, not milliseconds or any other unit, and note that if you don't set it, it defaults to 30 seconds)."
```

**Why**: Shorter sentences reduce ambiguity and improve extraction accuracy. Each sentence should convey one clear fact.

### 4. Use Tables for Structured Data

```markdown
GOOD:
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| Timeout | int | No | 30 | Request timeout in seconds |
| MaxRetries | int | No | 3 | Maximum retry attempts |
| Endpoint | string | Yes | - | Authentication endpoint URL |

BAD:
The Timeout parameter is an integer and is optional with a default of 30 seconds.
The MaxRetries parameter is also optional and defaults to 3.
The Endpoint is required and must be a string pointing to the authentication endpoint URL.
```

**Why**: Tables provide consistent structure that AI systems can easily parse into key-value pairs and relationships.

### 5. Use Code Blocks with Language Tags

````markdown
GOOD:
```csharp
public class TokenProvider
{
    public async Task<string> GetTokenAsync() { }
}
```

```bash
kubectl get pods -n production
```

BAD:
```
public class TokenProvider  // No language tag
{
    public async Task<string> GetTokenAsync() { }
}
```
````

**Why**: Language tags enable syntax-aware parsing and allow AI to understand the context and constraints of code examples.

### 6. Write in Plain Language

```markdown
GOOD:
"Use retries for transient errors like network timeouts. Configure retry policies in the HTTP client."

BAD:
"Leverage the retry pattern paradigm to ameliorate ephemeral fault conditions through idempotent operation invocation with exponential backoff stratagem."
```

**Why**: Simple, direct language reduces parsing errors and makes content accessible to both AI and human readers.

### 7. Define Acronyms on First Use

```markdown
GOOD:
"Service Level Objective (SLO) defines reliability targets. Each SLO consists of Service Level Indicators (SLIs) and target percentiles."

BAD:
"SLO defines reliability targets. Each SLO consists of SLIs and target percentiles."
(Reader/AI doesn't know what SLO or SLI means)
```

**Why**: AI systems cannot infer acronym meanings from context. Explicit definitions prevent misinterpretation.

### 8. Use Descriptive Alt Text for Images

```markdown
GOOD:
![Architecture diagram showing API Gateway routing requests to microservices](architecture.png)

BAD:
![Diagram](architecture.png)
![Image](screenshot.png)
```

**Why**: Alt text makes visual information accessible to AI systems and enables multimodal understanding.

### 9. Use Clear, Contextual Links

```markdown
GOOD:
See the [retry configuration guide](../reliability/retry-config.md) for exponential backoff examples.
Review the [Token Provider API reference](./api/token-provider.md) for method signatures.

BAD:
See [here](link) for more info.
Click [this](link) to learn more.
```

**Why**: Contextual link text provides semantic meaning.

### 10. Use Consistent Section Headers

```markdown
GOOD (Documentation):
## Overview
## Prerequisites (if applicable)
## Installation (if applicable)
## Configuration
## Usage Examples
## Troubleshooting
## API Reference

GOOD (TSG):
## Description
## Symptoms
## Mitigation Steps
## Further Investigation
## Escalation Path
## References

BAD:
## What This Is About (inconsistent naming)
## Getting Started (missing "Installation")
## How to Use It (use "Usage Examples")
```

**Why**: Consistent headers enable pattern-based extraction. AI can reliably locate prerequisites, examples, or mitigation steps.

### 11. Use Numbered Steps for Procedures

GOOD:
### Step 1: Install Dependencies
### Step 2: Configure Authentication
### Step 3: Validate Configuration

BAD:
First, you should install the dependencies.
Then maybe try configuring authentication.
After that, it should work.

**Why**:

- **Sequence extraction**: Numbered steps enable AI to parse ordered procedures as directed graphs
- **Dependency mapping**: AI can identify which steps depend on previous steps completing successfully
- **Pattern recognition**: Consistent "Step N:" format creates reliable extraction markers
- **Code-action pairing**: Each step pairs a description with executable code

### 12. Include Validation Steps

GOOD:
Scale up to 15 instances:

```bash
kubectl scale deployment my-service --replicas=15 -n production

# Validate:
kubectl get pods -l app=my-service -n production | wc -l
```

BAD:
Scale up to 15 instances.
(No way to verify it worked)

**Why**:

- **Success criteria extraction**: AI can parse validation as structured assertions
- **Test generation**: AI can convert validation steps into automated test cases
- **Failure mode learning**: By understanding expected outcomes, AI learns what "success" looks like
- **Verifiable patterns**: Creates action -> validation -> result chains

## Code Example Best Practices

### Complete, Runnable Examples

GOOD:

```csharp
// Complete example with all necessary imports and context
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddHttpClient<ITokenProvider>(options =>
        {
            options.Timeout = TimeSpan.FromSeconds(30);
        });
    }
}
```

BAD:

```csharp
// Incomplete snippet with no context
options.Timeout = TimeSpan.FromSeconds(30);
```

**Why**: Complete examples with imports and context can be directly used. Snippets require guesswork to integrate.

### Inline Comments for Context

GOOD:

```csharp
// Register token provider with 30-second timeout
services.Configure<TokenProviderOptions>(options =>
{
    options.Endpoint = "https://auth.example.com";  // Production endpoint
    options.Timeout = TimeSpan.FromSeconds(30);     // Default timeout
});
```

BAD:

```csharp
services.Configure<TokenProviderOptions>(options =>
{
    options.Endpoint = "https://auth.example.com";
    options.Timeout = TimeSpan.FromSeconds(30);
});
```

**Why**: Comments explain intent and constraints. AI can understand why specific values are chosen.

### Use Labels for AI Pattern Recognition

When creating good/bad example comparisons, use consistent visual markers:

```csharp
// GOOD: Log user ID hash, not email
logger.LogError(ex, "Failed to process request for user {UserId}", user.GetAnonymizedId());
```

```csharp
// BAD: Logging user email (PII violation)
logger.LogError("Failed to process request for user {Email}", user.Email);
```

**Why**:

- **AI pattern matching**: Consistent labels create reliable extraction patterns
- **Self-documenting code**: Inline comments with markers remain understandable when copied without context
- **AI training data**: Creates labeled training pairs for pattern learning
- **Copy-paste safety**: Manual bullet warns about good vs. bad practices

## Side-by-Side Comparisons for AI Training

When showing correct vs. incorrect patterns, place them adjacent for direct comparison:

**Bad Example**:

```python
# BAD: Using print statements to track operation flow
print("Starting operation")
result = perform_operation()
print("Completed operation")
```

**Good Example**:

```python
# GOOD: Use structured logging for operation tracking
import logging
logger = logging.getLogger(__name__)

with logger.contextualize(operation="perform"):
    result = perform_operation()
```

**Why**:

- **Structured extraction**: AI can parse paired patterns as training data
- **Immediate contrast**: Side-by-side comparison shows the exact transformation needed
- **Pattern learning**: AI learns not just what's wrong, but specifically how to fix it
- **Context preservation**: Both examples share the same scenario, isolating the specific practice

## Common Anti-Patterns to Avoid

### Anti-Pattern 1: Assuming Knowledge

BAD:
"Configure the DI container appropriately."

GOOD:
"Register the service in dependency injection:

```csharp
// In Startup.cs ConfigureServices method
services.AddSingleton<ITokenProvider, TokenProvider>();
```

### Anti-Pattern 2: Vague Instructions

BAD:
"Restart the service if needed."
"Scale up as appropriate."
"Configure for your environment."

GOOD:

```bash
kubectl rollout restart deployment/my-service -n production
```

```bash
kubectl scale deployment my-service --replicas=15 -n production
```

### Anti-Pattern 3: Missing Context

BAD:
Run this command:

```bash
az deployment create --template-file template.json
```

GOOD:
Deploy the resource group template:

```bash
# Deploy to westus2 region with production parameters
az deployment group create \
  --resource-group my-service-prod \
  --template-file infrastructure/template.json \
  --parameters infrastructure/prod.parameters.json \
  --location westus2
```

### Anti-Pattern 4: Outdated Examples

BAD:

```python
# Using deprecated API
result = provider.get_token(TokenRequest())  # Removed in v2.0
```

GOOD:

```python
# Using current API (v2.0+)
result = await provider.get_token_async(
    scopes=["https://management.azure.com/.default"],
)
```

**Mitigation**: Test all code examples as part of CI/CD. Flag examples that fail to compile or run.

## AI-Ready Checklist

When writing or reviewing content, verify:

### Structure

- [ ] Uses hierarchical headings (H1 > H2 > H3) consistently
- [ ] Related content is grouped under appropriate sections

### Clarity

- [ ] Sentences are short and direct (avoid run-on sentences)
- [ ] One idea per sentence, one topic per paragraph
- [ ] Plain language used; jargon defined on first use
- [ ] Acronyms spelled out on first use

### Code & Commands

- [ ] All code blocks include language tags
- [ ] Examples are complete and runnable
- [ ] Commands include necessary flags and parameters
- [ ] Inline comments explain intent and constraints

### Tables & Lists

- [ ] Structured data uses tables, not paragraphs
- [ ] Tables include headers that describe each column
- [ ] Enumerated items use bulleted or numbered lists
- [ ] Comparison data uses side-by-side tables

### Links & References

- [ ] Link text is descriptive and contextual
- [ ] Images have descriptive alt text
- [ ] All links are valid and point to correct resources
- [ ] Internal references use relative paths

### Validation

- [ ] Procedural steps include validation criteria
- [ ] Expected outcomes are explicitly stated
- [ ] Error conditions and their meanings are documented
- [ ] Success criteria are measurable

## Language-Specific Considerations

### For Code Examples

**C#/.NET**:

- Include `using` statements
- Show dependency injection registration
- Use `async`/`await` patterns correctly
- Include cancellation tokens where appropriate

**Python**:

- Include `import` statements
- Show virtual environment setup if relevant
- Use type hints for clarity
- Include `async`/`await` where applicable

**JavaScript/TypeScript**:

- Include `import`/`require` statements
- Show package.json dependencies if relevant
- Use TypeScript types for clarity
- Include error handling patterns

**Bash/PowerShell**:

- Include shebangs (`#!/bin/bash`)
- Show required environment variables
- Use error handling (`set -e`, `$ErrorActionPreference`)
- Include validation commands

**YAML/JSON**:

- Show complete valid structure
- Include required fields
- Comment complex sections
- Validate against schema

**SQL/KQL**:

- Include table/namespace context
- Show expected output format
- Comment complex queries
- Include time ranges where relevant

## Review Checklist

When reviewing AI-ready technical content, verify:

- [ ] **Hierarchical structure**: Content uses proper heading hierarchy for navigation
- [ ] **Descriptive headings**: All headings clearly describe content without requiring context
- [ ] **Tables for comparisons**: Related information presented in tables instead of paragraphs
- [ ] **Code block language tags**: All code blocks specify language for proper highlighting
- [ ] **Inline code markers**: Technical terms, file names, commands use backticks
- [ ] **Visual status markers**: Good/bad examples use clear labels for AI pattern extraction
- [ ] **Side-by-side comparisons**: Good vs bad examples shown with clear labels
- [ ] **Numbered procedural steps**: Step-by-step instructions use numbered lists for sequence clarity
- [ ] **Code comments included**: Example code includes inline comments explaining purpose
- [ ] **Validation steps provided**: Instructions include specific verification steps
- [ ] **Cross-references functional**: Links to related sections and documentation are accurate
- [ ] **Consistent formatting**: Similar concepts use same formatting patterns throughout document
- [ ] **Examples before anti-patterns**: Show correct approach first, then contrast with what to avoid
- [ ] **Contextual explanations**: Code examples include surrounding context explaining why approach is recommended
