# Delegate ADO — Work Item Delegation Skill

Create and assign Azure DevOps work items to GitHub Copilot from a plan. Use when asked to delegate or remotely execute a plan via ADO/Copilot.

**Invoke when:** user says "delegate", "create ADO task for Copilot", "assign to GitHub Copilot", or wants to convert a plan into an ADO work item for automated execution.

## Prerequisites

This skill uses Azure DevOps MCP tools. Load them via `tool_search_tool_regex` with pattern `azure-devops` before first use.

Key tools needed:
- `mcp_azure-devops_wit_create_work_item` — Create work items
- `mcp_azure-devops_repo_get_repo_by_name_or_id` — Get repo details

## Workflow

### 1. Locate the Plan

- Read from the plan file in the current session if available
- Or use the plan discussed in the conversation
- If unclear, ask the user where the plan is located

### 2. Convert the Plan

Extract and format:
- **Title**: Short, action-oriented summary
- **Problem statement**: What needs to be solved
- **Approach**: How it will be addressed
- **Workplan**: Bulleted list of tasks
- **Validation**: Bulleted list of validation steps

### 3. Determine Azure DevOps Context

Before creating the work item, determine the project and repository context:

**Project name**:
- Check if mentioned in conversation
- Try `git config --get remote.origin.url` to extract from repository URL
- Ask the user if unclear

**Repository linking** (exactly ONE repository must be linked using ONE method):

The skill uses the **repository tag method**: `copilot:repo=<orgName>/<projectName>/<repoName>@<branchName>`

Gather the following information:
- **Organization**: Extract from git remote (e.g., `https://dev.azure.com/<org>/...`)
- **Project**: Use the project name determined above
- **Repository**: Extract from git remote or current directory name
- **Branch** (REQUIRED — branch name is mandatory):
  - Ask the user which branch to target (common: main, master, or feature branch)
  - If not specified, try `git symbolic-ref refs/remotes/origin/HEAD` to get default branch
  - DO NOT assume the current branch is the correct target branch

**Note**: Cross-organization scenarios are supported via repository tags.

If git is not available or commands fail, ask the user for the repository details.

### 4. Create Azure DevOps Work Item

Use `mcp_azure-devops_wit_create_work_item` to create the work item:

- **Project**: The project name from step 3
- **Work Item Type**: Task (or another appropriate type based on context)
- **System.Title**: The summary title from step 2
- **System.Description**: HTML formatted body containing:
  - Problem statement
  - Approach
  - Workplan
  - Validation
- **System.Tags**: `copilot:repo=<orgName>/<projectName>/<repoName>@<branchName>` (REQUIRED)
  - Format must exactly match: `copilot:repo=<orgName>/<projectName>/<repoName>@<branchName>`
  - Branch name after `@` is mandatory
  - Use only this tag method (do not combine with artifact links)
- **System.AssignedTo**: `GitHub Copilot` (REQUIRED — this is the assignee name)

**Critical requirements**:
- Exactly ONE repository must be linked (via the tag)
- Work item must have a clear task description
- Assignee must be set to "GitHub Copilot"

### 5. Return Results

Provide:
- Created work item ID
- Direct link to the work item in Azure DevOps

## Rules

- Do not create new documentation for the feature unless specifically required in the plan
- If the plan is incomplete or missing, ask the user before creating the work item
- Work item must always be assigned to "GitHub Copilot"
- Exactly ONE repository must be linked using the repository tag method
- The branch name in the tag is mandatory and cannot be omitted
- Do not combine repository tag with artifact links (use only one linking method)
- Ensure the work item has a clear, actionable task description
