"""Convert markdown demo files to self-contained HTML pages for GitHub Pages."""
import os
import sys
import markdown

TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title} — Brain OS Demo</title>
<style>
:root {{
  --bg: #11111b;
  --surface: #1e1e2e;
  --border: #313244;
  --text: #cdd6f4;
  --muted: #6c7086;
  --cyan: #22d3ee;
  --yellow: #fbbf24;
  --green: #34d399;
  --red: #f87171;
  --purple: #a78bfa;
  --pink: #f472b6;
  --blue: #60a5fa;
}}
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{
  background: var(--bg);
  color: var(--text);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  line-height: 1.7;
  padding: 0;
}}
.nav {{
  background: var(--surface);
  border-bottom: 1px solid var(--border);
  padding: 12px 24px;
  display: flex;
  align-items: center;
  gap: 16px;
  position: sticky;
  top: 0;
  z-index: 100;
}}
.nav a {{
  color: var(--cyan);
  text-decoration: none;
  font-size: 14px;
  font-weight: 500;
}}
.nav a:hover {{ text-decoration: underline; }}
.nav .sep {{ color: var(--muted); }}
.nav .title {{ color: var(--text); font-weight: 600; }}
.badge {{
  display: inline-block;
  background: var(--cyan);
  color: var(--bg);
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}}
.content {{
  max-width: 860px;
  margin: 40px auto;
  padding: 0 24px;
}}
h1 {{
  font-size: 28px;
  color: var(--text);
  margin-bottom: 8px;
  padding-bottom: 12px;
  border-bottom: 2px solid var(--border);
}}
h2 {{
  font-size: 20px;
  color: var(--cyan);
  margin-top: 32px;
  margin-bottom: 12px;
  padding-bottom: 6px;
  border-bottom: 1px solid var(--border);
}}
h3 {{
  font-size: 16px;
  color: var(--yellow);
  margin-top: 24px;
  margin-bottom: 8px;
}}
p {{ margin-bottom: 12px; }}
strong {{ color: #f0f0f0; }}
em {{ color: var(--muted); font-style: italic; }}
a {{ color: var(--cyan); text-decoration: none; }}
a:hover {{ text-decoration: underline; }}
ul, ol {{
  margin: 8px 0 16px 24px;
}}
li {{ margin-bottom: 4px; }}
li input[type="checkbox"] {{
  margin-right: 6px;
  accent-color: var(--cyan);
}}
table {{
  width: 100%;
  border-collapse: collapse;
  margin: 12px 0 20px;
  font-size: 14px;
}}
th {{
  background: var(--surface);
  color: var(--cyan);
  text-align: left;
  padding: 10px 12px;
  border: 1px solid var(--border);
  font-weight: 600;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}}
td {{
  padding: 8px 12px;
  border: 1px solid var(--border);
  vertical-align: top;
}}
tr:nth-child(even) {{ background: rgba(30, 30, 46, 0.5); }}
blockquote {{
  border-left: 3px solid var(--yellow);
  background: rgba(251, 191, 36, 0.05);
  padding: 12px 16px;
  margin: 12px 0;
  border-radius: 0 6px 6px 0;
}}
blockquote p {{ margin-bottom: 0; }}
code {{
  background: var(--surface);
  color: var(--green);
  padding: 2px 6px;
  border-radius: 4px;
  font-family: 'Cascadia Code', 'Fira Code', monospace;
  font-size: 13px;
}}
pre {{
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 16px;
  overflow-x: auto;
  margin: 12px 0;
}}
pre code {{
  background: none;
  padding: 0;
  color: var(--text);
}}
hr {{
  border: none;
  border-top: 1px solid var(--border);
  margin: 24px 0;
}}
.footer {{
  text-align: center;
  padding: 32px;
  color: var(--muted);
  font-size: 13px;
  border-top: 1px solid var(--border);
  margin-top: 48px;
}}
.footer a {{ color: var(--cyan); }}
</style>
</head>
<body>
<div class="nav">
  <a href="../">← Brain OS Demos</a>
  <span class="sep">·</span>
  <span class="title">{nav_title}</span>
  <span class="sep">·</span>
  <span class="badge">{badge}</span>
</div>
<div class="content">
{html_content}
</div>
<div class="footer">
  <a href="https://github.com/kustonaut/brain-os">Brain OS</a> — AI-powered PM operating system
</div>
</body>
</html>"""

DEMOS = [
    {
        "md": "demo_daily_brief.md",
        "html": "demo_daily_brief.html",  # new file, different from existing
        "title": "Daily Brief — Thursday, Feb 27",
        "nav_title": "Daily Brief",
        "badge": "Pipeline Output",
    },
    {
        "md": "demo_mom_sprint_planning.md",
        "html": "demo_mom_sprint_planning.html",  # new file
        "nav_title": "Minutes of Meeting",
        "title": "MOM: Sprint 14 Planning",
        "badge": "/mom skill",
    },
    {
        "md": "demo_prd_notification_center.md",
        "html": "demo_prd_notification_center.html",  # new file
        "nav_title": "Product Requirements Document",
        "title": "PRD: Notification Center",
        "badge": "/prd_writer skill",
    },
]

def convert(demos_dir):
    md_ext = markdown.Markdown(extensions=["tables", "fenced_code", "nl2br"])
    for demo in DEMOS:
        md_path = os.path.join(demos_dir, demo["md"])
        html_path = os.path.join(demos_dir, demo["html"])
        
        # Skip if HTML already exists (don't overwrite existing demos)
        if os.path.exists(html_path) and demo["md"] != demo["html"].replace(".html", ".md"):
            print(f"SKIP {html_path} (already exists)")
            continue
        
        with open(md_path, "r", encoding="utf-8") as f:
            md_content = f.read()
        
        # Convert checkbox syntax
        md_content = md_content.replace("- [ ]", "- <input type='checkbox' disabled>")
        md_content = md_content.replace("- [x]", "- <input type='checkbox' checked disabled>")
        
        md_ext.reset()
        html_body = md_ext.convert(md_content)
        
        full_html = TEMPLATE.format(
            title=demo["title"],
            nav_title=demo["nav_title"],
            badge=demo["badge"],
            html_content=html_body,
        )
        
        with open(html_path, "w", encoding="utf-8") as f:
            f.write(full_html)
        print(f"OK   {html_path}")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    demos_dir = os.path.join(repo_root, "docs", "demos")
    convert(demos_dir)
