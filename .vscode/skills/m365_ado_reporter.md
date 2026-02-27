---
name: m365_ado_reporter
description: Advanced Azure DevOps reporting — sprint health, epic burndown, work item summaries, and dashboards. Generates formatted reports from ADO data with charts and trend analysis.
---

# /m365_ado_reporter - Azure DevOps Analytics & Reporting

Advanced ADO reporting with sprint health, epic burndown, work item summaries, and visual dashboards.

## Usage

```
/m365_ado_reporter <action> | [options]
```

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `status` | Current state of tracked work items | `/m365_ado_reporter status` |
| `sprint` | Sprint health report | `/m365_ado_reporter sprint` |
| `epic` | Epic burndown & progress | `/m365_ado_reporter epic \| project-alpha 12345678` |
| `query` | Run a custom WIQL query | `/m365_ado_reporter query \| assigned to me active` |
| `report` | Generate full HTML/Word report | `/m365_ado_reporter report \| weekly` |
| `stale` | Find stale/aging items | `/m365_ado_reporter stale \| 30 days` |
| `search` | Search work items by keyword | `/m365_ado_reporter search \| project-alpha regression` |

## Examples

```
/m365_ado_reporter status
/m365_ado_reporter epic | project-alpha 12345678
/m365_ado_reporter sprint | current
/m365_ado_reporter stale | 60 days under project-alpha
/m365_ado_reporter report | weekly for your manager
/m365_ado_reporter search | feature labels
/m365_ado_reporter query | bugs assigned to teammate state active
```

## Instructions

### For `status` action:

1. **Get assigned work items:**
   ```
   Use mcp_azure-devops_wit_my_work_items with project parameter
   ```

2. **Get tracked ADO items from config:**
   - Read `_Automation/config.json` for `tracked_ado_ids`
   - Use `mcp_azure-devops_wit_get_work_items_batch_by_ids` to fetch current state

3. **Check recent ADO signals:**
   - Read `00_Daily_Intelligence/Signals/ado_YYYY-MM-DD.md` for today's changes

4. **Present status summary:**
   ```markdown
   ## ADO Status — [Date]
   
   ### 📊 My Items ([count])
   | ID | Title | Type | State | Changed |
   |----|-------|------|-------|---------|
   
   ### 🔴 Items Needing Attention
   [Items with state changes, approaching deadlines, or blocked]
   
   ### 📈 State Changes Today
   [Items that changed state since last check]
   ```

### For `sprint` action:

1. **Get current iteration:**
   - Use ADO API to get current sprint/iteration for the team
   - Use `mcp_azure-devops_wit_get_work_items_for_iteration` 

2. **Calculate sprint health metrics:**
   - Total items in sprint
   - Completed vs remaining
   - Items by state (New, Active, Resolved, Closed)
   - Items by assignee
   - Items added/removed mid-sprint
   - Blocked items

3. **Generate sprint health card:**
   ```markdown
   ## Sprint Health: [Sprint Name]
   **Dates:** [start] → [end] | **Day [X] of [Y]**
   
   ### 📊 Burndown
   | Metric | Count | % |
   |--------|-------|---|
   | Total | [n] | 100% |
   | Completed | [n] | [%] |
   | In Progress | [n] | [%] |
   | Not Started | [n] | [%] |
   | Blocked | [n] | [%] |
   
   ### 🚦 Health: [✅ On Track | 🟡 At Risk | 🔴 Behind]
   [1-sentence assessment]
   
   ### 👥 By Assignee
   | Person | Assigned | Done | Remaining |
   |--------|----------|------|-----------|
   
   ### ⚠️ Risks
   - [Items not started past midpoint]
   - [Blocked items]
   - [Scope creep: items added after sprint start]
   ```

### For `epic` action:

1. **Parse epic ID from input** (e.g., `project-alpha 12345678` → ID 12345678)

2. **Fetch epic and all children:**
   - Use `mcp_azure-devops_wit_get_work_items_batch_by_ids` for epic
   - Use Work IQ or ADO API to get child items (Features → PBIs → Tasks)

3. **Calculate epic metrics:**
   - Total child items at each level
   - State distribution (New/Active/Resolved/Closed)
   - Completion percentage
   - Aging: oldest unresolved item, average age
   - Owner distribution

4. **Generate epic report:**
   ```markdown
   ## Epic Report: [Epic Title] (#[ID])
   **Owner:** [name] | **State:** [state] | **Created:** [date]
   
   ### 📊 Progress
   [Completion bar: ████░░░░░░ 40%]
   
   | Level | Total | Done | Active | New |
   |-------|-------|------|--------|-----|
   | Features | [n] | [n] | [n] | [n] |
   | PBIs | [n] | [n] | [n] | [n] |
   | Tasks | [n] | [n] | [n] | [n] |
   
   ### 🏗️ Feature Breakdown
   | Feature | ID | Owner | State | PBIs Done/Total |
   |---------|-----|-------|-------|-----------------|
   
   ### ⏱️ Aging
   - Oldest unresolved: [item] ([X] days)
   - Average age of active items: [X] days
   
   ### 🎯 Forecast
   - At current velocity: [estimated completion]
   - At risk items: [list]
   ```

### For `stale` action:

1. **Parse threshold** (default 30 days)
2. **Search for aging items:**
   ```
   Use mcp_azure-devops_search_workitem with filters:
   - state: Active, New
   - Look for items not updated in > threshold days
   ```

3. **Cross-reference with Action_Items.md for context**

4. **Generate stale report:**
   ```markdown
   ## Stale Items Report (>[X] days unchanged)
   
   ### 🔴 Critical (>[90] days)
   | ID | Title | State | Last Updated | Owner | Days Stale |
   
   ### 🟡 Warning (>[60] days)
   ...
   
   ### 🟢 Monitor (>[30] days)
   ...
   
   ### 📊 Summary
   - Total stale: [n]
   - By owner: [breakdown]
   - Recommendation: [triage/close/reassign]
   ```

### For `search` action:

1. Use `mcp_azure-devops_search_workitem` with the search text
2. Format results with filtering options
3. Cross-reference with workspace knowledge for added context

### For `report` action:

1. **Aggregate all data** (status + sprint + epic + stale)
2. **Generate HTML or Word report** using python-docx:
   ```python
   # Use the workspace Python environment
   # sys.path.insert(0, os.path.join(tempfile.gettempdir(), "pydocx_lib"))
   # import docx
   ```
3. **Save to:** `projects/project-alpha/ADO_Report_YYYY-MM-DD.docx` (or `.html`)
4. **Optionally email** using the m365_email_drafter skill workflow

## Tracked Items (from config.json)

The automation config tracks these ADO IDs:

| Category | IDs | Context |
|----------|-----|---------|
| Project Epic | 12345678 | Parent project engineering epic |
| Project Features | 12345001, 12345002 | Security Framework, Validation |
| Project PBIs | 12345003, 12345004 | Incident Fixes, Bug Fixes |
| Project Tasks | 12345005 | Release Signoff |

## Key ADO Area Paths

| Area | Scope |
|------|-------|
| `Org\Team\Area\In-Market Health` | Team automation bugs |
| `Org\Team\Area\*` | Broader team area |

## Output Formats

- **Markdown** — displayed in chat (default)
- **HTML** — rich report with collapsible sections (use `report` action)
- **Word (.docx)** — formal report for sharing (use `report | word` option)
- **Table** — quick data dump for pasting

## Error Handling

- **ADO auth failed:** Check `az login` and PAT token
- **Item not found:** Verify project name and item ID
- **No items in sprint:** Check iteration path configuration
- **Query timeout:** Reduce scope or paginate results

## Cross-Skill References

| When You Need To... | Use This Skill | How |
|---------------------|---------------|-----|
| Email the ADO report | `/m365_email_drafter send` | Embed status summary or attach Word report |
| Generate a formal Word/PPT report | `/m365_doc_generator report` | Use ADO data as input for formatted deliverable |
| Include ADO status in meeting prep | `/m365_meeting_prep prep` | Meeting prep auto-checks ADO signals |
| Post sprint update in Teams | `/m365_teams_comms status` | Format sprint health as Teams broadcast |

## Time Saved

~15-25 minutes per report (manual ADO querying, cross-referencing, formatting)
