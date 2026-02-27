# Dashboard Generator — Interactive HTML & Data Dashboards

## Trigger
`/dashboard_generator` or when user says "create a dashboard", "build a dashboard", "generate report dashboard", "HTML dashboard", "metrics dashboard", "Power BI", "KPI tracker", "data visualization"

## Purpose
Generate interactive, professional dashboards from workspace data, ADO metrics, Kusto/ADX queries, or any structured data. Supports HTML (self-contained, sharable), Excel pivot dashboards, and Power BI dataset preparation. Dashboards are designed for stakeholder reviews, leadership updates, and team health monitoring.

## Actions

### `html` (default)
Generate a self-contained HTML dashboard:

1. **Identify data source:**
   - User-provided data (tables, CSVs, JSON)
   - ADO work items (via MCP or `ado_*.md` signals)
   - Kusto/ADX query results (via Kusto MCP if available)
   - GitHub issue metrics (from cached data or API)
   - Knowledge Base files (Action_Items.md, Goals.md)
   - Any structured markdown tables in the workspace

2. **Determine dashboard type:**
   - **Status Dashboard** — KPI cards + trend charts + status table
   - **Sprint Health** — Burndown, velocity, work item breakdown
   - **Issue Funnel** — Pipeline stages, aging, resolution rates
   - **Metrics Tracker** — Time-series charts with targets
   - **Team Scorecard** — Per-person or per-area performance grid
   - **Custom** — User-defined layout

3. **Generate Python script:**
   ```python
   # Save as _Automation/create_dashboard_[name].py
   import sys, os, tempfile
   sys.path.insert(0, os.path.join(tempfile.gettempdir(), "pydocx_lib"))
   import json
   from datetime import datetime
   ```

4. **HTML template features:**
   - **Fluent 2 Design System** — Clean, modern Microsoft-inspired UI
   - **Dark/Light theme toggle** — Default dark theme with toggle
   - **Responsive grid** — CSS Grid layout, works on any screen
   - **KPI cards** — Metric name, value, trend arrow, sparkline
   - **Charts** — Use inline SVG or Chart.js CDN for interactive charts
   - **Auto-refresh meta tag** — `<meta http-equiv="refresh" content="300">`
   - **No external dependencies** — Single self-contained HTML file
   - **Print-friendly** — `@media print` styles for clean PDF export

5. **Save and open:**
   - Save to relevant project folder or `docs/`
   - `Start-Process "[path]"` to open in browser

### `kusto`
Generate a dashboard from Kusto/ADX query results:

1. Accept KQL query or use pre-built templates
2. Execute via Kusto MCP (`mcp_azure_mcp_kusto`) if available
3. Parse results into dashboard data model
4. Generate HTML dashboard with query metadata
5. Include "Last Refreshed" timestamp and query text for reproducibility

### `excel`
Generate an Excel dashboard with pivot tables and charts:

1. Create multi-sheet workbook:
   - **Dashboard** sheet — Summary charts and KPI cells
   - **Data** sheet — Raw data with filters
   - **Pivot** sheet — Pivot table configurations
2. Use `openpyxl` for generation
3. Add conditional formatting, data bars, and sparklines
4. Include named ranges for easy Power BI import

### `powerbi`
Prepare data for Power BI consumption:

1. Export structured data as:
   - CSV files with consistent schemas
   - JSON data model definition
   - Suggested DAX measures
   - Recommended visuals and layout
2. Generate a `powerbi_import_guide.md` with setup instructions
3. Note: Does not create .pbix files directly (requires Power BI Desktop)

### `refresh`
Refresh an existing dashboard with latest data:

1. Find the dashboard's generation script in `_Automation/`
2. Re-run with current data
3. Overwrite the output file
4. Open in browser

## Context Sources
1. `00_Daily_Intelligence/Knowledge_Base/Goals.md` — KPI targets and OKRs
2. `00_Daily_Intelligence/Signals/ado_*.md` — ADO work item data
3. `00_Daily_Intelligence/Signals/` — All signal files for metrics
4. `00_Daily_Intelligence/Knowledge_Base/Action_Items.md` — Task status
5. Project folders — Project-specific data files

## HTML Dashboard Template Structure
```html
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>[Dashboard Title] — Brain OS</title>
  <style>
    /* Fluent 2 inspired design tokens */
    :root[data-theme="dark"] {
      --bg-primary: #1a1a2e;
      --bg-card: #16213e;
      --text-primary: #e8e8e8;
      --accent: #0078d4;
      --success: #34d399;
      --warning: #fbbf24;
      --danger: #ef4444;
    }
    :root[data-theme="light"] {
      --bg-primary: #f5f5f5;
      --bg-card: #ffffff;
      --text-primary: #333333;
    }
    /* Responsive grid, KPI cards, charts, tables */
  </style>
</head>
<body>
  <header><!-- Title + theme toggle + timestamp --></header>
  <section class="kpi-grid"><!-- KPI cards --></section>
  <section class="charts"><!-- Chart containers --></section>
  <section class="data-table"><!-- Sortable data table --></section>
  <footer><!-- Generated by Brain OS + timestamp --></footer>
</body>
</html>
```

## MCP Integration
- **Kusto MCP** (`mcp_azure_mcp_kusto`) — Execute KQL queries for telemetry dashboards
- **Azure DevOps MCP** — Pull sprint data, work items, burndown metrics
- **GitHub MCP** — Pull issue/PR metrics for engineering dashboards

## Anti-Patterns
- ❌ Don't use external CDN links unless explicitly requested — dashboards should be self-contained
- ❌ Don't generate dashboards without data — always have a data source identified
- ❌ Don't create overly complex layouts — max 4 KPI cards, 2 charts, 1 table per view
- ❌ Don't hardcode data — always parameterize so dashboards can be refreshed
- ❌ Don't skip the "Last Refreshed" timestamp — every dashboard needs it

## Cross-Skill References
| Need | Skill |
|------|-------|
| Pull ADO data for dashboard | `/m365_ado_reporter` |
| Generate formal report from dashboard data | `/m365_doc_generator` |
| Email dashboard link to stakeholders | `/m365_email_drafter` |
| Analyze feedback trends for dashboard | `/feedback_synthesis` |
| Query Kusto for raw data | Kusto MCP tools |

## Time Saved
~2-4 hours per dashboard (manual data gathering + formatting + chart creation)
