---
name: m365_doc_generator
description: Generate professional Word (.docx), PowerPoint (.pptx), and Excel (.xlsx) documents from templates and M365 data. Handles reports, decks, trackers, and briefs.
---

# /m365_doc_generator - Office Document Generator

Generate professional Word, PowerPoint, and Excel documents from workspace data, M365 intelligence, and templates.

## Usage

```
/m365_doc_generator <action> | [options]
```

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `word` | Generate a Word document | `/m365_doc_generator word \| project-alpha status report` |
| `ppt` | Generate a PowerPoint deck | `/m365_doc_generator ppt \| partner briefing 10 slides` |
| `excel` | Generate an Excel tracker | `/m365_doc_generator excel \| bug tracking dashboard` |
| `brief` | Generate a 1-page brief (Word) | `/m365_doc_generator brief \| GitHub issue analysis` |
| `templates` | List available document templates | `/m365_doc_generator templates` |

## Examples

```
/m365_doc_generator word | weekly status report for all charter areas
/m365_doc_generator ppt | project-alpha funnel analysis 15 slides dark theme
/m365_doc_generator excel | project-alpha 14 metrics tracker with formulas
/m365_doc_generator brief | partner risk assessment for Partner Corp
/m365_doc_generator word | meeting minutes from EM sync
```

## Instructions

### Technical Environment

**CRITICAL — Always use this setup before generating documents:**

```python
import sys, os, tempfile
sys.path.insert(0, os.path.join(tempfile.gettempdir(), "pydocx_lib"))
```

**Python executable:** `.venv/Scripts/python.exe`

**Available libraries:**
- `python-docx` — Word document generation
- `python-pptx` — PowerPoint presentation generation
- `openpyxl` — Excel spreadsheet generation
- `matplotlib` — Charts and visualizations (for embedding in docs)

**Script location:** Always create generation scripts in `_Automation/` directory
**Output location:** Save outputs to relevant project folder (e.g., `projects/project-alpha/`, `projects/project-beta/`)

### For `word` action:

1. **Parse the request:** Identify document type, content scope, audience
2. **Gather content:**
   - Check workspace knowledge base for relevant data
   - Check signals for current state
   - Use Work IQ for M365 data if needed
   - Use ADO tools for work item data if needed

3. **Create Python generation script:**
   ```python
   # Save as _Automation/create_[descriptive_name].py
   import sys, os, tempfile
   sys.path.insert(0, os.path.join(tempfile.gettempdir(), "pydocx_lib"))
   from docx import Document
   from docx.shared import Inches, Pt, Cm, RGBColor
   from docx.enum.text import WD_ALIGN_PARAGRAPH
   from docx.enum.table import WD_TABLE_ALIGNMENT
   
   doc = Document()
   
   # Style setup
   style = doc.styles['Normal']
   font = style.font
   font.name = 'Calibri'
   font.size = Pt(11)
   font.color.rgb = RGBColor(0x33, 0x33, 0x33)
   
   # Heading colors
   for level in range(1, 4):
       h = doc.styles[f'Heading {level}']
       h.font.name = 'Calibri'
       h.font.color.rgb = RGBColor(0x0B, 0x55, 0x94)
   
   # ... content generation ...
   
   doc.save(output_path)
   ```

4. **Execute the script:** Run with workspace Python venv
5. **Open the document:** `Start-Process "[output_path]"`

### For `ppt` action:

1. **Parse request:** Slide count, theme (light/dark), content scope
2. **Gather content** (same as word)
3. **Create Python generation script:**
   ```python
   # Save as _Automation/create_[descriptive_name]_ppt.py
   import sys, os, tempfile
   sys.path.insert(0, os.path.join(tempfile.gettempdir(), "pydocx_lib"))
   from pptx import Presentation
   from pptx.util import Inches, Pt, Emu
   from pptx.dml.color import RGBColor
   from pptx.enum.text import PP_ALIGN
   
   prs = Presentation()
   prs.slide_width = Inches(13.333)  # Widescreen
   prs.slide_height = Inches(7.5)
   
   # Theme colors (Default Theme)
   DARK_BG = RGBColor(0x1B, 0x2A, 0x4A)  # Dark Navy
   WHITE = RGBColor(0xFF, 0xFF, 0xFF)
   ACCENT = RGBColor(0x00, 0x78, 0xD4)   # Blue
   
   # ... slide generation ...
   
   prs.save(output_path)
   ```

4. **Execute and open**

### For `excel` action:

1. **Parse request:** Tracker type, data scope, formulas needed
2. **Gather data** for pre-population
3. **Create Python generation script:**
   ```python
   # Save as _Automation/create_[descriptive_name]_xlsx.py
   import sys, os, tempfile
   sys.path.insert(0, os.path.join(tempfile.gettempdir(), "pydocx_lib"))
   from openpyxl import Workbook
   from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
   from openpyxl.chart import BarChart, LineChart, Reference
   from openpyxl.utils import get_column_letter
   
   wb = Workbook()
   ws = wb.active
   ws.title = "Dashboard"
   
   # Header style
   header_fill = PatternFill(start_color="0B5594", end_color="0B5594", fill_type="solid")
   header_font = Font(name='Calibri', bold=True, color="FFFFFF", size=11)
   
   # ... data population, formulas, charts ...
   
   wb.save(output_path)
   ```

4. **Execute and open**

### For `brief` action:

1. **Generate 1-page Word doc** with condensed format:
   ```
   [Title Bar — colored header]
   
   Date: | Author: | For: | Classification:
   
   TL;DR (3 bullets max)
   
   Key Data (compact table)
   
   Recommendation (2-3 sentences)
   
   Next Steps (numbered, with owners)
   ```

2. **Strict 1-page constraint** — adjust font sizes and margins if needed

### For `templates` action:

Display available templates:

#### Word Templates
| Template | Use Case | Approx Pages |
|----------|----------|-------------|
| `status_report` | Weekly/monthly charter status | 3-5 |
| `analysis_report` | Deep-dive analysis | 10-25 |
| `brief` | 1-page executive brief | 1 |
| `partner_brief` | External partner communication | 2-3 |
| `meeting_minutes` | Post-meeting documentation | 1-3 |
| `spec_doc` | Feature/process spec | 5-15 |
| `okr_report` | Quarterly OKR progress | 3-5 |

#### PowerPoint Templates
| Template | Use Case | Slides |
|----------|----------|--------|
| `crisis_brief` | Urgent issue briefing | 8-12 |
| `status_deck` | Status review presentation | 10-15 |
| `partner_deck` | External partner presentation | 8-12 |
| `analysis_deck` | Deep analysis with data | 15-25 |
| `all_hands` | Team/org all-hands content | 10-20 |

#### Excel Templates
| Template | Use Case | Sheets |
|----------|----------|--------|
| `metric_tracker` | Project metric tracking | 3 (Dashboard, Data, Reference) |
| `bug_tracker` | Bug/issue tracking | 2 (Tracker, Charts) |
| `sprint_dashboard` | Sprint health dashboard | 2 (Sprint, Burndown) |
| `risk_register` | Risk tracking & mitigation | 1 |
| `partner_tracker` | Partner status tracking | 2 (Status, History) |

## Document Styling Standards

### Word Documents
- **Font:** Calibri 11pt body, headings in blue (#0B5594)
- **Heading 1:** 22pt bold blue
- **Heading 2:** 16pt bold blue
- **Heading 3:** 13pt bold blue
- **Tables:** Medium Shading 1 Accent 1 style, 10pt font
- **Margins:** Normal (1 inch)
- **Line spacing:** 1.15

### PowerPoint Decks
- **Default theme:** Dark (BG: Dark Navy #1B2A4A, Text: White)
- **Light theme:** White BG, Dark Navy text (#1B2A4A)
- **Slide size:** Widescreen (13.333" x 7.5")
- **Title font:** Segoe UI Semibold 32pt bold, White
- **Subtitle font:** Segoe UI Light 18pt, Light Gray (#D0D0D0)
- **Body font:** Segoe UI 14-18pt
- **Primary accent:** Blue (#0078D4)
- **Supporting accents:** Teal (#008080), Steel Blue (#4682B4), Success Green (#2E7D32), Warning Amber (#F57C00)
- **NEVER use:** Orange as primary, neon/saturated colors, more than 3 accent colors per slide

### Excel Spreadsheets
- **Header:** Blue fill (#0B5594), white bold text
- **Data font:** Calibri 11pt
- **Alternating rows:** Light grey
- **Charts:** Company-style colors
- **Frozen panes:** Headers always visible
- **Auto-filter:** Enabled on all data columns

## PPTX Design Principles

### Layout Patterns
- **Title slides:** Full-width colored bar or dark background. Title centered, subtitle below.
- **Content slides:** Left-aligned heading, body content in 2/3 width, optional sidebar or icon column on right.
- **Data slides:** Chart/table takes 60-70% of slide area. Source note at bottom in 10pt gray.
- **Section dividers:** Dark Navy full-bleed with white text, section number in large font.
- **Conclusion slides:** Summarize 3-5 key takeaways as numbered or bulleted items.

### Typography Rules
- Maintain **visual hierarchy**: Title (32pt) > Subtitle (18pt) > Body (14-16pt) > Caption (10-12pt)
- Use **Segoe UI Semibold** for headings, **Segoe UI** for body, **Segoe UI Light** for subtitles
- Never use more than 3 font sizes on a single slide
- Minimum font size: 12pt (nothing smaller is readable in presentations)

### Spacing & Alignment
- Use consistent margins: 0.5" from slide edges for all content
- Maintain 0.3" minimum gap between elements
- Align text boxes and shapes to an invisible grid (left-edge alignment is default)
- Tables: header row in Dark Navy with white text, data rows alternate white/#F2F2F2

### Common Mistakes to Avoid
- Overcrowded slides (>7 bullet points = split into two slides)
- Inconsistent colors across slides (define palette once, reuse everywhere)
- Missing slide numbers (always add, except on title slide)
- Orphan slides with no section grouping
- Using clip art or low-res images

## Artifact QA Checklist

After generating any document, verify before delivery:

### All Formats
- [ ] File opens without errors
- [ ] File size is non-zero and reasonable
- [ ] Correct names used (verify all references; TSG, not TSD)
- [ ] Default theme colors applied consistently
- [ ] No placeholder text remaining (e.g., `[TODO]`, `[FILL IN]`)
- [ ] Opened with `Start-Process` for user review

### Word (.docx)
- [ ] Page count matches expected length
- [ ] Heading hierarchy correct (H1 > H2 > H3)
- [ ] Tables have header rows and are not overflowing margins
- [ ] Font is Calibri throughout

### PowerPoint (.pptx)
- [ ] Slide count matches requested range
- [ ] Section dividers present for logical grouping
- [ ] All slides have consistent footer/slide numbers
- [ ] No text overflow (truncated text boxes)
- [ ] Design principles above are followed

### Excel (.xlsx)
- [ ] Formulas calculate correctly (spot-check 2-3)
- [ ] Auto-filters enabled
- [ ] Header row frozen
- [ ] Column widths accommodate content

## Cross-Skill References

| When You Need To... | Use This Skill | How |
|---------------------|---------------|-----|
| Email the generated report | `/m365_email_drafter send` | Attach or embed the doc in an email |
| Prep a meeting using this doc | `/m365_meeting_prep prep` | Reference the artifact as pre-read |
| Include ADO data in the doc | `/m365_ado_reporter query` | Fetch live ADO data to populate tables |
| Post about this doc in Teams | `/m365_teams_comms announce` | Share artifact link with summary |

## Script Naming Convention

```
_Automation/create_[content]_[format].py

Examples:
_Automation/create_project_alpha_status_report.py
_Automation/create_partner_brief_ppt.py
_Automation/create_metric_tracker_xlsx.py
```

## Error Handling

- **Library not found:** Re-install to `$env:TEMP\pydocx_lib`
- **Script syntax error:** Use standalone `.py` file (not inline), test in terminal
- **File locked:** Close existing document before regenerating
- **Large content:** Split into sections, generate incrementally

## Time Saved

~30-60 minutes per document (formatting, data gathering, layout, styling)
