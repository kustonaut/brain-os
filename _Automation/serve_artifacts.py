"""
Brain OS — PM Intelligence Portal
A one-page command center for your daily PM operating system.
Run: python serve_artifacts.py → http://localhost:8765
"""
import http.server, os, re, json, html as html_mod
import urllib.parse, subprocess, time as _time
import threading
from pathlib import Path
from datetime import datetime, timedelta

# ═══════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════
PORT = 8765
ROOT = str(Path(__file__).resolve().parent.parent)
AUTO = os.path.join(ROOT, "_Automation")
SIG  = os.path.join(ROOT, "00_Daily_Intelligence", "Signals")
KB   = os.path.join(ROOT, "00_Daily_Intelligence", "Knowledge_Base")

_CONFIG_PATH = os.path.join(AUTO, "config.json")
def _load_config():
    try:
        with open(_CONFIG_PATH, 'r', encoding='utf-8-sig') as f:
            return json.load(f)
    except Exception:
        return {}

_CFG = _load_config()
PORTAL_NAME = _CFG.get('branding', {}).get('portal_name', 'Brain')
PORTAL_SUBTITLE = _CFG.get('branding', {}).get('portal_subtitle', 'Daily OS')
PM_NAME = _CFG.get('pm_identity', {}).get('name', 'PM')
TEAM_MEMBERS = _CFG.get('team_members', [])

# Build projects from config
def _build_projects(cfg):
    projects = {}
    for p in cfg.get('projects', []):
        projects[p['slug']] = {
            'name': p['name'], 'full': p.get('full_name', p['name']),
            'folder': p['folder'], 'icon': p.get('icon', 'folder'),
            'color': p.get('color', '#888'),
            'desc': p.get('description', ''),
            'status': p.get('status', ''),
            'team': p.get('team', ''),
            'metrics': [tuple(m) for m in p.get('metrics', [])],
            'charters': p.get('charter_keywords', []),
        }
    return projects

CHARTER_RE = [(cp['label'], cp['regex']) for cp in _CFG.get('charter_patterns', [])]
PROJECTS = _build_projects(_CFG)

EXTS = {'.docx','.doc','.pptx','.ppt','.xlsx','.xls','.pdf','.html','.md','.png','.jpg','.jpeg','.gif','.mp4'}
SKIP = {'.venv','.git','node_modules','__pycache__','.vscode','.claude'}
ALL_FOLDERS = {p['folder'] for p in PROJECTS.values()} | {'00_Daily_Intelligence','08_Archive','_Automation'}

# ═══════════════════════════════════════════════════════════════════════════
# CACHE
# ═══════════════════════════════════════════════════════════════════════════
_cache = {}
_cache_lock = threading.Lock()
def _cached(key, fn, ttl=60):
    with _cache_lock:
        if key in _cache and (_time.time() - _cache[key][0]) < ttl:
            return _cache[key][1]
    result = fn()
    with _cache_lock:
        _cache[key] = (_time.time(), result)
    return result

# ═══════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════
def esc(s):
    return html_mod.escape(str(s))

def charter_of(text):
    for name, pat in CHARTER_RE:
        if re.search(pat, text, re.I):
            return name
    return None

_FABRIC_CDN = 'https://res-1.cdn.office.net/files/fabric-cdn-prod_20251008.001/assets/item-types/48'
_FTYPE_MAP = {
    '.docx': 'docx', '.doc': 'docx', '.pptx': 'pptx', '.ppt': 'pptx',
    '.xlsx': 'xlsx', '.xls': 'xlsx', '.pdf': 'pdf', '.html': 'html', '.htm': 'html',
    '.md': 'txt', '.json': 'code', '.xml': 'code', '.kql': 'code',
    '.ps1': 'code', '.py': 'code', '.txt': 'txt',
    '.mp4': 'video', '.mp3': 'audio', '.zip': 'zip',
    '.png': 'photo', '.jpg': 'photo', '.jpeg': 'photo', '.gif': 'photo',
}
def file_icon(ext, size=16):
    ftype = _FTYPE_MAP.get(ext, 'genericfile')
    return f'<img src="{_FABRIC_CDN}/{ftype}.svg" width="{size}" height="{size}" alt="" style="vertical-align:-3px">'

# Fluent 2 icons (SVG viewBox 0 0 20 20)
FI = {
    'home':     'M10.7 3.28a1 1 0 0 0-1.4 0L3 9.12V16.5A1.5 1.5 0 0 0 4.5 18H8v-4.5a.5.5 0 0 1 .5-.5h3a.5.5 0 0 1 .5.5V18h3.5a1.5 1.5 0 0 0 1.5-1.5V9.12l-6.3-5.84Z',
    'document': 'M6 2a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V7.41a1 1 0 0 0-.3-.71l-3.4-3.4A1 1 0 0 0 11.59 3H6Zm1 8.5a.5.5 0 0 1 .5-.5h5a.5.5 0 0 1 0 1h-5a.5.5 0 0 1-.5-.5Zm.5 2.5a.5.5 0 0 0 0 1h5a.5.5 0 0 0 0-1h-5Z',
    'wrench':   'M11.15 4.3a4 4 0 0 0-5.11 5.2l-.03.03-2.58 2.58a1.5 1.5 0 0 0 0 2.12l1.34 1.34a1.5 1.5 0 0 0 2.12 0L9.47 13a4 4 0 0 0 5.23-5.15l-2.14 2.14a1.5 1.5 0 0 1-2.12 0 1.5 1.5 0 0 1 0-2.12l2.14-2.14-.43-.43Z',
    'target':   'M10 2a8 8 0 1 0 0 16 8 8 0 0 0 0-16Zm0 2a6 6 0 1 1 0 12 6 6 0 0 1 0-12Zm0 2a4 4 0 1 0 0 8 4 4 0 0 0 0-8Zm0 2a2 2 0 1 1 0 4 2 2 0 0 1 0-4Z',
    'calendar': 'M14.5 3A2.5 2.5 0 0 1 17 5.5v9a2.5 2.5 0 0 1-2.5 2.5h-9A2.5 2.5 0 0 1 3 14.5v-9A2.5 2.5 0 0 1 5.5 3h9ZM16 7H4v7.5c0 .83.67 1.5 1.5 1.5h9c.83 0 1.5-.67 1.5-1.5V7Zm-1.5-3h-9C4.67 4 4 4.67 4 5.5V6h12v-.5c0-.83-.67-1.5-1.5-1.5Z',
    'trending': 'M3 14.5a.5.5 0 0 0 .85.35l3.65-3.65 2.65 2.65a.5.5 0 0 0 .7 0L17 7.71V10.5a.5.5 0 0 0 1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 0 0 1h2.79l-5.79 5.79-2.65-2.65a.5.5 0 0 0-.7 0l-4 4a.5.5 0 0 0-.15.36Z',
    'lock':     'M10 2a4 4 0 0 0-4 4v2H5a1 1 0 0 0-1 1v7a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V9a1 1 0 0 0-1-1h-1V6a4 4 0 0 0-4-4Zm2 6V6a2 2 0 1 0-4 0v2h4Z',
    'code':     'M7.28 4.22a.75.75 0 0 1 0 1.06L4.06 8.5l3.22 3.22a.75.75 0 0 1-1.06 1.06l-3.75-3.75a.75.75 0 0 1 0-1.06l3.75-3.75a.75.75 0 0 1 1.06 0Zm5.44 0a.75.75 0 0 1 1.06 0l3.75 3.75a.75.75 0 0 1 0 1.06l-3.75 3.75a.75.75 0 0 1-1.06-1.06l3.22-3.22-3.22-3.22a.75.75 0 0 1 0-1.06Z',
    'building': 'M6 2a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H6Zm1 3.5a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 0 1h-1a.5.5 0 0 1-.5-.5Zm4-.5a.5.5 0 0 0 0 1h1a.5.5 0 0 0 0-1h-1ZM7 8.5a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 0 1h-1a.5.5 0 0 1-.5-.5Zm4-.5a.5.5 0 0 0 0 1h1a.5.5 0 0 0 0-1h-1Zm-2 6h2v4H9v-4Z',
    'clipboard':'M7.09 2c-.15 0-.3.01-.44.04A2 2 0 0 0 5 4v12a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2V4a2 2 0 0 0-1.65-1.96A1.5 1.5 0 0 0 12.91 2H7.09ZM8.5 3a.5.5 0 0 0 0 1h3a.5.5 0 0 0 0-1h-3Z',
    'book':     'M4 4.5A2.5 2.5 0 0 1 6.5 2h7A2.5 2.5 0 0 1 16 4.5v11a2.5 2.5 0 0 1-2.5 2.5h-7A2.5 2.5 0 0 1 4 15.5v-11ZM6.5 3A1.5 1.5 0 0 0 5 4.5v11A1.5 1.5 0 0 0 6.5 17h7a1.5 1.5 0 0 0 1.5-1.5v-11A1.5 1.5 0 0 0 13.5 3h-7Z',
    'alert':    'M10 2a1 1 0 0 1 .87.5l7 12.25A1 1 0 0 1 17 16H3a1 1 0 0 1-.87-1.25l7-12.25A1 1 0 0 1 10 2Zm0 5a.75.75 0 0 0-.75.75v3.5a.75.75 0 0 0 1.5 0v-3.5A.75.75 0 0 0 10 7Zm0 7a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5Z',
    'search':   'M8.5 3a5.5 5.5 0 0 1 4.23 9.02l4.12 4.13a.75.75 0 0 1-1.06 1.06l-4.13-4.12A5.5 5.5 0 1 1 8.5 3Zm0 1.5a4 4 0 1 0 0 8 4 4 0 0 0 0-8Z',
    'sun':      'M10 2a.75.75 0 0 1 .75.75v1.5a.75.75 0 0 1-1.5 0v-1.5A.75.75 0 0 1 10 2Zm0 4.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7ZM5.34 4.34a.75.75 0 0 1 1.06 0l1.06 1.06a.75.75 0 1 1-1.06 1.06L5.34 5.4a.75.75 0 0 1 0-1.06Zm10.38 1.06a.75.75 0 0 0-1.06-1.06l-1.06 1.06a.75.75 0 0 0 1.06 1.06l1.06-1.06ZM2 10c0-.41.34-.75.75-.75h1.5a.75.75 0 0 1 0 1.5h-1.5A.75.75 0 0 1 2 10Zm13 0c0-.41.34-.75.75-.75h1.5a.75.75 0 0 1 0 1.5h-1.5A.75.75 0 0 1 15 10ZM6.4 14.6a.75.75 0 0 1 0 1.06l-1.06 1.06a.75.75 0 0 1-1.06-1.06l1.06-1.06a.75.75 0 0 1 1.06 0Zm8.26 1.06a.75.75 0 1 0-1.06-1.06l-1.06 1.06a.75.75 0 0 0 1.06 1.06l1.06-1.06ZM10 15c.41 0 .75.34.75.75v1.5a.75.75 0 0 1-1.5 0v-1.5c0-.41.34-.75.75-.75Z',
    'moon':     'M10.67 3.07a.75.75 0 0 0-.87.87A5.5 5.5 0 0 0 16 10.5c0 .98-.21 1.91-.6 2.74a.75.75 0 0 0 .97.97A7.5 7.5 0 0 0 10.67 3.07Z',
    'bolt':     'M11.3 1.3A1 1 0 0 1 12 2v5h4.5a1 1 0 0 1 .8 1.6l-7.3 9.7A1 1 0 0 1 8 17.5V13H3.5a1 1 0 0 1-.8-1.6l7.3-9.7a1 1 0 0 1 1.3-.4Z',
    'folder':   'M2 5.5A1.5 1.5 0 0 1 3.5 4h4.38a1.5 1.5 0 0 1 1.12.5L10 5.74h6.5A1.5 1.5 0 0 1 18 7.24V14.5a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 2 14.5v-9Z',
    'people':   'M8 6a2 2 0 1 1-4 0 2 2 0 0 1 4 0Zm8 0a2 2 0 1 1-4 0 2 2 0 0 1 4 0ZM3.5 10A2.5 2.5 0 0 0 1 12.5v.5a2 2 0 0 0 2 2h4a2 2 0 0 0 2-2v-.5A2.5 2.5 0 0 0 6.5 10h-3Zm8 0A2.5 2.5 0 0 0 9 12.5v.5a2 2 0 0 0 2 2h4a2 2 0 0 0 2-2v-.5a2.5 2.5 0 0 0-2.5-2.5h-3Z',
    'mail':     'M2 5.5A2.5 2.5 0 0 1 4.5 3h11A2.5 2.5 0 0 1 18 5.5v9a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 2 14.5v-9Zm2.5-1A1 1 0 0 0 3.5 5.5v.26l6.5 4.06 6.5-4.06V5.5a1 1 0 0 0-1-1h-11ZM16.5 7.4l-6.07 3.79a1 1 0 0 1-1.06 0L3.5 7.4V14.5a1 1 0 0 0 1 1h11a1 1 0 0 0 1-1V7.4Z',
    'play':     'M5 3.99A1 1 0 0 1 6.53 3.1l9.06 5.01a1 1 0 0 1 0 1.78l-9.06 5.01A1 1 0 0 1 5 14.01V3.99Z',
    'signal':   'M10 7a3 3 0 1 0 0 6 3 3 0 0 0 0-6Zm0 1.5a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM5.05 3.05a.75.75 0 0 0-1.06 0 8.5 8.5 0 0 0 0 12.02.75.75 0 0 0 1.06-1.06 7 7 0 0 1 0-9.9.75.75 0 0 0 0-1.06Zm10.96 0a.75.75 0 0 0-1.06 1.06 7 7 0 0 1 0 9.9.75.75 0 0 0 1.06 1.06 8.5 8.5 0 0 0 0-12.02Z',
    'chevron':  'M7.22 4.22a.75.75 0 0 1 1.06 0l5.25 5.25a.75.75 0 0 1 0 1.06l-5.25 5.25a.75.75 0 0 1-1.06-1.06L11.94 10 7.22 5.28a.75.75 0 0 1 0-1.06Z',
    'grid':     'M3 6a3 3 0 0 1 3-3h2a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V6Zm8-2a1 1 0 0 1 1-1h2a3 3 0 0 1 3 3v2a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1V4ZM3 12a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1H6a3 3 0 0 1-3-3v-2Zm8 0a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2a3 3 0 0 1-3 3h-2a1 1 0 0 1-1-1v-4Z',
    'open':     'M6.25 4.5A1.75 1.75 0 0 0 4.5 6.25v7.5c0 .97.78 1.75 1.75 1.75h7.5A1.75 1.75 0 0 0 15.5 13.75V11a.75.75 0 0 1 1.5 0v2.75A3.25 3.25 0 0 1 13.75 17h-7.5A3.25 3.25 0 0 1 3 13.75v-7.5A3.25 3.25 0 0 1 6.25 3H9a.75.75 0 0 1 0 1.5H6.25Zm5.25-.5a.75.75 0 0 1 .75-.75h4a.75.75 0 0 1 .75.75v4a.75.75 0 0 1-1.5 0V5.56l-4.22 4.22a.75.75 0 1 1-1.06-1.06L14.44 4.5H12.25a.75.75 0 0 1-.75-.75V4Z',
}
def icon(name, size=16):
    p = FI.get(name, FI['document'])
    return f'<svg width="{size}" height="{size}" viewBox="0 0 20 20" fill="currentColor" style="vertical-align:-3px"><path d="{p}"/></svg>'

# ═══════════════════════════════════════════════════════════════════════════
# DATA PARSERS
# ═══════════════════════════════════════════════════════════════════════════

def scan_artifacts(folder=None):
    """Scan workspace for document artifacts."""
    arts = []
    for r, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP]
        for f in files:
            ext = Path(f).suffix.lower()
            if ext not in EXTS:
                continue
            fp = os.path.join(r, f)
            rel = os.path.relpath(fp, ROOT).replace('\\', '/')
            if folder and not rel.startswith(folder):
                continue
            parts = rel.split('/')
            cat = parts[0] if parts[0] in ALL_FOLDERS else None
            try:
                st = os.stat(fp)
            except OSError:
                continue
            sz = st.st_size / 1024
            arts.append({
                'name': f, 'path': rel, 'full': fp, 'cat': cat,
                'ext': ext, 'icon': file_icon(ext),
                'modified': datetime.fromtimestamp(st.st_mtime).strftime('%Y-%m-%d %H:%M'),
                'ts': st.st_mtime,
                'size': f"{sz:.0f} KB" if sz < 1024 else f"{sz/1024:.1f} MB",
            })
    arts.sort(key=lambda x: x['ts'], reverse=True)
    return arts

def parse_actions():
    """Parse Action_Items.md → {urgent, medium, other}."""
    path = os.path.join(KB, 'Action_Items.md')
    if not os.path.exists(path):
        return {'urgent': [], 'medium': [], 'other': []}
    with open(path, encoding='utf-8') as f:
        txt = f.read()
    urg, med, oth = [], [], []
    sec = ""
    for line in txt.split('\n'):
        s = line.strip()
        m = re.match(r'^#{2,3}\s+(.+)', s)
        if m:
            sec = m.group(1)
            continue
        if '|' not in s:
            continue
        if not re.search(r'TODO|🔴|🟡|ONGOING|In progress|Pending|BLOCKED', s, re.I):
            continue
        if '✅' in s or 'DONE' in s or '~~' in s:
            continue
        cells = [c.strip() for c in s.split('|') if c.strip()]
        if not cells:
            continue
        t = re.sub(r'\*\*', '', cells[0]).strip()
        if len(t) < 6:
            continue
        ch = charter_of(t) or charter_of(sec) or 'General'
        owner = re.sub(r'\*\*', '', cells[1]).strip() if len(cells) > 1 else ''
        item = {'text': t, 'section': sec, 'charter': ch, 'owner': owner}
        if '🔴' in s:
            urg.append(item)
        elif '🟡' in s:
            med.append(item)
        else:
            oth.append(item)
    return {'urgent': urg, 'medium': med, 'other': oth}

def parse_signal_counts(date_str=None):
    """Count items in each signal file for today."""
    if not date_str:
        date_str = datetime.now().strftime('%Y-%m-%d')
    counts = {}
    for sig_type in ['emails', 'ado', 'chats', 'calendar', 'inbox_parsed']:
        sp = os.path.join(SIG, f'{sig_type}_{date_str}.md')
        if os.path.exists(sp):
            with open(sp, encoding='utf-8') as f:
                txt = f.read()
            rows = len(re.findall(r'^\|[^-|]', txt, re.M))
            bullets = len(re.findall(r'^- ', txt, re.M))
            counts[sig_type] = max(rows, bullets)
        else:
            counts[sig_type] = 0
    return counts

def parse_calendar(date_str=None):
    """Parse calendar signal → {meetings, free, conflicts}."""
    if not date_str:
        date_str = datetime.now().strftime('%Y-%m-%d')
    p = os.path.join(SIG, f'calendar_{date_str}.md')
    if not os.path.exists(p):
        return {'meetings': [], 'free': [], 'conflicts': []}
    with open(p, encoding='utf-8') as f:
        txt = f.read()
    m = re.search(r'## Today.*?(?=## Tomorrow|\Z)', txt, re.S)
    sec = m.group(0) if m else txt
    meetings = []
    pm_name = _CFG.get('pm_identity', {}).get('name', '')
    for r in re.finditer(r'\|\s*(\d{2}:\d{2}[^|]+?\d{2}:\d{2})\s*\|\s*(\d+m)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(\w+)\s*\|', sec):
        ti, du, tl, og, st = [g.strip() for g in r.groups()]
        if tl == 'Sleep':
            continue
        tp = 'focus' if '🎯 Focus:' in tl else ('self' if pm_name and pm_name in og else 'external')
        meetings.append({'time': ti, 'dur': du, 'title': tl, 'org': og, 'status': st, 'type': tp})
    free = [{'time': m.group(1).strip(), 'dur': m.group(2).strip()}
            for m in re.finditer(r'-\s*(\d{2}:\d{2}[^(]+?\d{2}:\d{2})\s*\((\d+m)\)', txt)]
    conf = [{'m1': m.group(1), 't1': m.group(2), 'm2': m.group(3), 't2': m.group(4)}
            for m in re.finditer(r'\*\*(.+?)\*\*\s*\((.+?)\)\s*overlaps\s*\*\*(.+?)\*\*\s*\((.+?)\)', txt)]
    return {'meetings': meetings, 'free': free, 'conflicts': conf}

def parse_emails(date_str=None):
    """Parse email signal → list of emails."""
    if not date_str:
        date_str = datetime.now().strftime('%Y-%m-%d')
    p = os.path.join(SIG, f'emails_{date_str}.md')
    if not os.path.exists(p):
        return {'emails': [], 'fetched': None}
    with open(p, encoding='utf-8') as f:
        txt = f.read()
    tm_m = re.search(r'Fetched at (\d{2}:\d{2}:\d{2})', txt)
    fetched = tm_m.group(1) if tm_m else None
    if 'No matching emails' in txt:
        return {'emails': [], 'fetched': fetched}
    emails = []
    for blk in re.finditer(r'###\s+\[([^\]]+)\]\s+(.+?)\n(.*?)(?=###\s+\[|\Z)', txt, re.S):
        time_str, subject, body = blk.group(1).strip(), blk.group(2).strip(), blk.group(3)
        sender = ''
        sm = re.search(r'\*\*From:\*\*\s*(.+?)(?:\s*<[^>]+>)?\s*\n', body)
        if sm:
            sender = sm.group(1).strip()
        ch = charter_of(subject) or ''
        emails.append({'time': time_str, 'subject': subject, 'sender': sender, 'charter': ch})
    return {'emails': emails, 'fetched': fetched}

def parse_brief_md(date_str=None):
    """Read daily brief markdown."""
    if not date_str:
        date_str = datetime.now().strftime('%Y-%m-%d')
    bp = os.path.join(ROOT, '00_Daily_Intelligence', 'Daily_Briefs', f'{date_str}_Brief.md')
    if not os.path.exists(bp):
        return None
    with open(bp, encoding='utf-8') as f:
        return f.read()

# ═══════════════════════════════════════════════════════════════════════════
# CSS — Fluent 2 Dark Theme (with light mode toggle)
# ═══════════════════════════════════════════════════════════════════════════
CSS = """
:root {
  --bg: #1a1a2e; --bg2: #16213e; --bg3: #0f3460;
  --surface: #1e2a4a; --surface2: #253556;
  --text: #e4e6eb; --text2: #a8b2c1; --text3: #6b7a8d;
  --accent: #0078D4; --accent2: #2b88d8;
  --red: #f25c54; --orange: #ffa726; --green: #66bb6a; --purple: #ab47bc; --cyan: #00bcd4;
  --border: rgba(255,255,255,0.08);
  --radius: 10px; --radius-sm: 6px;
  --shadow: 0 2px 8px rgba(0,0,0,0.3);
  --font: 'Segoe UI Variable', 'Segoe UI', system-ui, sans-serif;
}
[data-theme="light"] {
  --bg: #f5f5f5; --bg2: #ffffff; --bg3: #e8eef4;
  --surface: #ffffff; --surface2: #f0f2f5;
  --text: #1b2a4a; --text2: #404040; --text3: #6b7a8d;
  --border: rgba(0,0,0,0.08);
  --shadow: 0 2px 8px rgba(0,0,0,0.08);
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: var(--font); background: var(--bg); color: var(--text); line-height: 1.5; }
.app { display: flex; min-height: 100vh; }
a { color: var(--accent2); text-decoration: none; }
a:hover { text-decoration: underline; }

/* Sidebar */
.sidebar {
  width: 220px; min-width: 220px; background: var(--bg2);
  border-right: 1px solid var(--border); padding: 16px 0;
  display: flex; flex-direction: column; position: sticky; top: 0; height: 100vh;
  overflow-y: auto;
}
.sidebar-brand { padding: 0 16px 16px; border-bottom: 1px solid var(--border); margin-bottom: 8px; }
.sidebar-brand h2 { font-size: 15px; font-weight: 600; color: var(--text); display: flex; align-items: center; gap: 8px; }
.sidebar-brand small { font-size: 11px; color: var(--text3); display: block; margin-top: 2px; }
.nav-item {
  display: flex; align-items: center; gap: 10px; padding: 8px 16px;
  color: var(--text2); font-size: 13px; font-weight: 500;
  border-radius: 0; cursor: pointer; transition: all 0.15s;
  text-decoration: none;
}
.nav-item:hover { background: var(--surface); color: var(--text); text-decoration: none; }
.nav-item.active { background: var(--surface); color: var(--accent2); border-left: 3px solid var(--accent); }
.nav-section { font-size: 10px; font-weight: 600; color: var(--text3); padding: 12px 16px 4px; text-transform: uppercase; letter-spacing: 0.5px; }
.sidebar-footer { margin-top: auto; padding: 12px 16px; border-top: 1px solid var(--border); }
.sidebar-footer .btn-sm {
  display: block; width: 100%; padding: 6px 10px; margin-bottom: 4px;
  background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius-sm);
  color: var(--text2); font-size: 12px; cursor: pointer; text-align: left;
}
.sidebar-footer .btn-sm:hover { background: var(--surface2); color: var(--text); }
.badge { background: var(--red); color: #fff; font-size: 10px; padding: 1px 6px; border-radius: 10px; margin-left: auto; }

/* Main */
main { flex: 1; padding: 24px 32px; max-width: 1200px; overflow-y: auto; }
.page-header { margin-bottom: 24px; }
.page-header h1 { font-size: 22px; font-weight: 600; color: var(--text); }
.page-header .subtitle { font-size: 13px; color: var(--text3); margin-top: 2px; }

/* Section */
.section { margin-bottom: 28px; }
.section-title {
  font-size: 13px; font-weight: 600; color: var(--text3); text-transform: uppercase;
  letter-spacing: 0.5px; margin-bottom: 12px; display: flex; align-items: center; gap: 8px;
}

/* KPI Strip */
.kpi-strip { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 12px; }
.kpi-card {
  background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
  padding: 14px 16px; position: relative; overflow: hidden;
}
.kpi-card .kpi-label { font-size: 11px; color: var(--text3); text-transform: uppercase; letter-spacing: 0.3px; }
.kpi-card .kpi-value { font-size: 22px; font-weight: 700; margin-top: 4px; }
.kpi-card .kpi-sub { font-size: 11px; color: var(--text3); margin-top: 2px; }
.kpi-card::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 3px; }
.kpi-accent::before { background: var(--accent); }
.kpi-red::before { background: var(--red); }
.kpi-green::before { background: var(--green); }
.kpi-orange::before { background: var(--orange); }
.kpi-purple::before { background: var(--purple); }
.kpi-cyan::before { background: var(--cyan); }

/* Meeting rows */
.mtg-list { display: flex; flex-direction: column; gap: 6px; }
.mtg-row {
  display: flex; align-items: center; gap: 12px; padding: 8px 12px;
  background: var(--surface); border-radius: var(--radius-sm); font-size: 13px;
}
.mtg-time { color: var(--accent2); font-weight: 600; min-width: 110px; font-variant-numeric: tabular-nums; }
.mtg-title { flex: 1; color: var(--text); }
.mtg-dur { color: var(--text3); font-size: 12px; }
.mtg-focus { border-left: 3px solid var(--green); }
.mtg-ext { border-left: 3px solid var(--accent); }
.mtg-self { border-left: 3px solid var(--purple); }

/* Action items */
.action-list { display: flex; flex-direction: column; gap: 6px; }
.action-item {
  display: flex; align-items: flex-start; gap: 10px; padding: 10px 14px;
  background: var(--surface); border-radius: var(--radius-sm); font-size: 13px;
}
.action-item .a-dot { width: 8px; height: 8px; border-radius: 50%; margin-top: 5px; flex-shrink: 0; }
.dot-red { background: var(--red); }
.dot-yellow { background: var(--orange); }
.action-item .a-text { flex: 1; color: var(--text); }
.action-item .a-charter { font-size: 11px; color: var(--text3); background: var(--surface2); padding: 1px 8px; border-radius: 10px; white-space: nowrap; }
.action-item .a-owner { font-size: 11px; color: var(--text3); white-space: nowrap; }

/* Project tiles */
.proj-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 12px; }
.proj-tile {
  background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
  padding: 16px; cursor: pointer; transition: all 0.2s; text-decoration: none; color: var(--text);
  display: block;
}
.proj-tile:hover { border-color: var(--accent); transform: translateY(-1px); box-shadow: var(--shadow); text-decoration: none; }
.proj-tile h4 { font-size: 14px; font-weight: 600; margin-bottom: 4px; }
.proj-tile .proj-full { font-size: 11px; color: var(--text3); margin-bottom: 8px; }
.proj-tile .proj-status { font-size: 12px; color: var(--text2); }
.proj-tile .proj-bar { height: 3px; border-radius: 2px; margin-top: 10px; }

/* Email rows */
.email-row {
  display: flex; align-items: center; gap: 12px; padding: 8px 12px;
  background: var(--surface); border-radius: var(--radius-sm); font-size: 13px;
}
.email-time { color: var(--text3); font-size: 12px; min-width: 50px; }
.email-sender { color: var(--accent2); min-width: 120px; font-weight: 500; }
.email-subject { flex: 1; color: var(--text); }
.email-charter { font-size: 11px; color: var(--text3); background: var(--surface2); padding: 1px 8px; border-radius: 10px; }

/* Brief page */
.brief-body { background: var(--surface); border-radius: var(--radius); padding: 24px; line-height: 1.7; }
.brief-body h1 { font-size: 20px; margin-bottom: 12px; }
.brief-body h2 { font-size: 16px; margin: 20px 0 8px; color: var(--accent2); }
.brief-body h3 { font-size: 14px; margin: 14px 0 6px; }
.brief-body ul, .brief-body ol { padding-left: 20px; margin: 6px 0; }
.brief-body li { margin: 4px 0; }
.brief-body table { width: 100%; border-collapse: collapse; margin: 12px 0; font-size: 13px; }
.brief-body th { background: var(--surface2); padding: 8px 12px; text-align: left; font-weight: 600; font-size: 12px; }
.brief-body td { padding: 6px 12px; border-bottom: 1px solid var(--border); }
.brief-body code { background: var(--surface2); padding: 1px 6px; border-radius: 4px; font-size: 12px; }

/* Project detail */
.proj-detail { background: var(--surface); border-radius: var(--radius); padding: 24px; }
.proj-detail h2 { font-size: 18px; margin-bottom: 16px; }
.proj-detail .metric-row { display: flex; gap: 16px; flex-wrap: wrap; margin-bottom: 16px; }
.proj-detail .metric-card {
  background: var(--surface2); border-radius: var(--radius-sm); padding: 10px 16px; text-align: center;
}
.proj-detail .metric-card .m-label { font-size: 11px; color: var(--text3); }
.proj-detail .metric-card .m-val { font-size: 18px; font-weight: 700; }
.proj-detail .metric-card .m-target { font-size: 11px; color: var(--text3); }
.artifact-row {
  display: flex; align-items: center; gap: 10px; padding: 8px 10px; font-size: 13px;
  border-bottom: 1px solid var(--border);
}
.artifact-row:hover { background: var(--surface2); }
.artifact-row .a-name { flex: 1; }
.artifact-row .a-date { color: var(--text3); font-size: 12px; min-width: 120px; }
.artifact-row .a-size { color: var(--text3); font-size: 12px; min-width: 60px; text-align: right; }

/* Tools */
.tool-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 12px; }
.tool-card {
  background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
  padding: 16px; transition: all 0.2s;
}
.tool-card:hover { border-color: var(--accent); }
.tool-card h4 { font-size: 14px; font-weight: 600; margin-bottom: 4px; }
.tool-card p { font-size: 12px; color: var(--text3); margin-bottom: 10px; }
.tool-card .tool-btn {
  display: inline-block; padding: 5px 14px; background: var(--accent); color: #fff;
  border-radius: var(--radius-sm); font-size: 12px; font-weight: 600; cursor: pointer;
  text-decoration: none;
}
.tool-card .tool-btn:hover { background: var(--accent2); text-decoration: none; }

/* Footer */
.footer { margin-top: 40px; padding: 12px 0; font-size: 11px; color: var(--text3); text-align: center; }

/* Responsive */
@media (max-width: 900px) {
  .sidebar { display: none; }
  main { padding: 16px; }
  .kpi-strip { grid-template-columns: repeat(2, 1fr); }
}
@media print {
  .sidebar, .sidebar-footer, .footer { display: none !important; }
  main { padding: 12px !important; }
  body { background: #fff !important; color: #000 !important; }
  .app { display: block !important; }
}
"""

# ═══════════════════════════════════════════════════════════════════════════
# JAVASCRIPT
# ═══════════════════════════════════════════════════════════════════════════
GLOBAL_JS = """<script>
(function(){
  // Theme toggle
  const saved = localStorage.getItem('brain-theme');
  if (saved) document.documentElement.setAttribute('data-theme', saved);
  window.toggleTheme = function() {
    const cur = document.documentElement.getAttribute('data-theme');
    const next = cur === 'light' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('brain-theme', next);
    const btn = document.getElementById('theme-btn');
    if (btn) btn.textContent = next === 'light' ? '🌙 Dark' : '☀️ Light';
  };

  // Search
  const si = document.getElementById('search-input');
  const sd = document.getElementById('search-dropdown');
  if (si && sd) {
    let debounce;
    si.addEventListener('input', function() {
      clearTimeout(debounce);
      const q = si.value.trim();
      if (q.length < 2) { sd.style.display = 'none'; return; }
      debounce = setTimeout(function() {
        fetch('/api/search?q=' + encodeURIComponent(q))
          .then(r => r.json())
          .then(items => {
            if (!items.length) { sd.style.display = 'none'; return; }
            sd.innerHTML = items.slice(0, 8).map(i =>
              '<a href="/open?path=' + encodeURIComponent(i.path) + '" style="display:block;padding:6px 10px;font-size:12px;color:var(--text);border-bottom:1px solid var(--border)">' +
              i.icon + ' ' + i.name + '</a>'
            ).join('');
            sd.style.display = 'block';
          });
      }, 300);
    });
    document.addEventListener('click', function(e) {
      if (!si.contains(e.target) && !sd.contains(e.target)) sd.style.display = 'none';
    });
  }

  // Auto-refresh every 5 min
  if (location.pathname === '/' || location.pathname === '/brief') {
    setTimeout(function() { location.reload(); }, 300000);
  }

  // Collapsible sections
  document.querySelectorAll('.section-toggle').forEach(function(btn) {
    btn.addEventListener('click', function() {
      const target = document.getElementById(btn.getAttribute('data-target'));
      if (target) {
        target.style.display = target.style.display === 'none' ? 'block' : 'none';
        btn.textContent = target.style.display === 'none' ? '▶' : '▼';
      }
    });
  });

  // Last updated
  const lu = document.getElementById('last-updated');
  if (lu) lu.textContent = 'Updated: ' + new Date().toLocaleTimeString();
})();
</script>"""

# ═══════════════════════════════════════════════════════════════════════════
# HTML RENDERING
# ═══════════════════════════════════════════════════════════════════════════

def nav_html(active='home'):
    """Render sidebar navigation."""
    actions = parse_actions()
    urg_count = len(actions.get('urgent', []))
    badge = f'<span class="badge">{urg_count}</span>' if urg_count > 0 else ''

    items = [
        ('home', '/', 'home', 'Command Center', ''),
        ('brief', '/brief', 'document', 'Daily Brief', badge),
        ('tools', '/tools', 'wrench', 'Tools & Files', ''),
    ]

    # Generic brain icon
    brain_icon = icon('target', 16)

    nav = f'''<nav class="sidebar">
    <div class="sidebar-brand">
      <h2>{brain_icon} {esc(PORTAL_NAME)}</h2>
      <small>{esc(PORTAL_SUBTITLE)}</small>
    </div>
    <div style="padding:8px 12px;position:relative">
      <input id="search-input" type="text" placeholder="Search files..." style="width:100%;padding:6px 10px;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-sm);color:var(--text);font-size:12px;outline:none">
      <div id="search-dropdown" style="display:none;position:absolute;top:100%;left:12px;right:12px;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-sm);max-height:280px;overflow-y:auto;z-index:100;box-shadow:var(--shadow)"></div>
    </div>
    <div class="nav-section">Navigation</div>'''

    for key, href, ic, label, extra in items:
        cls = 'nav-item active' if active == key else 'nav-item'
        nav += f'\n    <a class="{cls}" href="{href}">{icon(ic, 16)} {label}{extra}</a>'

    # Project sub-items under Home
    if active == 'home' or active.startswith('project_'):
        for slug, proj in PROJECTS.items():
            pcls = 'nav-item active' if active == f'project_{slug}' else 'nav-item'
            nav += f'\n    <a class="{pcls}" href="/project/{slug}" style="padding-left:32px;font-size:12px">{icon(proj["icon"], 14)} {proj["name"]}</a>'

    nav += f'''
    <div class="sidebar-footer">
      <button class="btn-sm" onclick="location.href='/action?cmd=pipeline'">{icon('play', 14)} Run Pipeline</button>
      <button class="btn-sm" id="theme-btn" onclick="toggleTheme()">☀️ Light</button>
    </div>
  </nav>'''
    return nav

def html_page(title, body, active='home'):
    """Wrap body in full HTML page."""
    # Generic favicon (target/bullseye icon)
    favicon = '<link rel="icon" href="data:image/svg+xml,<svg xmlns=\'http://www.w3.org/2000/svg\' viewBox=\'0 0 20 20\'><circle cx=\'10\' cy=\'10\' r=\'8\' fill=\'none\' stroke=\'%230078D4\' stroke-width=\'2\'/><circle cx=\'10\' cy=\'10\' r=\'4\' fill=\'%230078D4\'/></svg>">'
    footer = '<div class="footer"><span id="last-updated"></span> · Auto-refreshes every 5 min</div>'
    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
{favicon}<title>{esc(title)} — {PORTAL_NAME}</title><style>{CSS}</style></head>
<body><div class="app">{nav_html(active)}<main>{body}{footer}</main></div>{GLOBAL_JS}</body></html>"""

# ───────────────────────────────────────────────────────────────────────────
# HOME — The one-page command center
# ───────────────────────────────────────────────────────────────────────────
def render_home():
    """The single command center page. Everything a PM needs at a glance."""
    today = datetime.now()
    date_str = today.strftime('%Y-%m-%d')
    day_str = today.strftime('%A, %B %d, %Y')

    # Gather all data
    cal = _cached('cal', parse_calendar, ttl=120)
    actions = _cached('actions', parse_actions, ttl=120)
    emails_data = _cached('emails', parse_emails, ttl=120)
    sig_counts = _cached('sig_counts', parse_signal_counts, ttl=120)

    # Pipeline status
    log_path = os.path.join(AUTO, 'logs', f'{date_str}.log')
    pipeline_ran = os.path.exists(log_path)
    pipeline_badge = '<span style="color:var(--green)">● Ran today</span>' if pipeline_ran else '<span style="color:var(--orange)">○ Not yet</span>'

    greeting = 'morning' if today.hour < 12 else 'afternoon' if today.hour < 17 else 'evening'

    html = f'''
    <div class="page-header">
      <h1>Good {greeting}, {esc(PM_NAME)}</h1>
      <div class="subtitle">{day_str} · Pipeline {pipeline_badge}</div>
    </div>'''

    # ── SECTION 1: KPI Summary ──
    total_signals = sum(sig_counts.values())
    urgent_count = len(actions.get('urgent', []))
    meeting_count = len(cal.get('meetings', []))
    email_count = len(emails_data.get('emails', []))

    html += f'''
    <div class="section">
      <div class="section-title">{icon('trending', 14)} Today at a Glance</div>
      <div class="kpi-strip">
        <div class="kpi-card kpi-accent">
          <div class="kpi-label">Meetings</div>
          <div class="kpi-value">{meeting_count}</div>
          <div class="kpi-sub">Scheduled today</div>
        </div>
        <div class="kpi-card kpi-red">
          <div class="kpi-label">Urgent Items</div>
          <div class="kpi-value" style="color:var(--red)">{urgent_count}</div>
          <div class="kpi-sub">Needs attention</div>
        </div>
        <div class="kpi-card kpi-green">
          <div class="kpi-label">Emails</div>
          <div class="kpi-value">{email_count}</div>
          <div class="kpi-sub">Matched filters</div>
        </div>
        <div class="kpi-card kpi-purple">
          <div class="kpi-label">Signals</div>
          <div class="kpi-value">{total_signals}</div>
          <div class="kpi-sub">Captured today</div>
        </div>
        <div class="kpi-card kpi-cyan">
          <div class="kpi-label">Projects</div>
          <div class="kpi-value">{len(PROJECTS)}</div>
          <div class="kpi-sub">Active areas</div>
        </div>
      </div>
    </div>'''

    # ── SECTION 2: Today's Calendar ──
    meetings = cal.get('meetings', [])
    free_slots = cal.get('free', [])
    ext_count = sum(1 for m in meetings if m['type'] == 'external')
    focus_count = sum(1 for m in meetings if m['type'] == 'focus')

    html += f'''
    <div class="section">
      <div class="section-title">{icon('calendar', 14)} Today's Calendar
        <span style="font-size:11px;font-weight:400;color:var(--text2);text-transform:none">{len(meetings)} meetings · {ext_count} external · {focus_count} focus · {len(free_slots)} free slots</span>
      </div>
      <div class="mtg-list">'''

    if meetings:
        for m in meetings[:12]:
            cls = 'mtg-focus' if m['type'] == 'focus' else ('mtg-self' if m['type'] == 'self' else 'mtg-ext')
            title = esc(m['title'][:60])
            html += f'''
        <div class="mtg-row {cls}">
          <span class="mtg-time">{esc(m["time"])}</span>
          <span class="mtg-title">{title}</span>
          <span class="mtg-dur">{esc(m["dur"])}</span>
        </div>'''
    else:
        html += '<div style="padding:12px;color:var(--text3);font-size:13px">No calendar data. <a href="/action?cmd=fetch-calendar">Fetch now</a></div>'

    html += '</div></div>'

    # ── SECTION 3: Action Items ──
    urgent = actions.get('urgent', [])
    medium = actions.get('medium', [])

    if urgent or medium:
        html += f'''
    <div class="section">
      <div class="section-title">{icon('bolt', 14)} Action Items
        <span style="font-size:11px;font-weight:400;color:var(--text2);text-transform:none">{len(urgent)} urgent · {len(medium)} medium</span>
      </div>
      <div class="action-list">'''

        for item in urgent[:8]:
            html += f'''
        <div class="action-item">
          <span class="a-dot dot-red"></span>
          <span class="a-text">{esc(item["text"][:120])}</span>
          <span class="a-charter">{esc(item["charter"])}</span>
          <span class="a-owner">{esc(item["owner"][:30])}</span>
        </div>'''

        for item in medium[:5]:
            html += f'''
        <div class="action-item">
          <span class="a-dot dot-yellow"></span>
          <span class="a-text">{esc(item["text"][:120])}</span>
          <span class="a-charter">{esc(item["charter"])}</span>
          <span class="a-owner">{esc(item["owner"][:30])}</span>
        </div>'''

        html += '</div></div>'

    # ── SECTION 4: Charter Areas ──
    if PROJECTS:
        html += f'''
    <div class="section">
      <div class="section-title">{icon('grid', 14)} Charter Areas</div>
      <div class="proj-grid">'''

        for slug, proj in PROJECTS.items():
            html += f'''
        <a class="proj-tile" href="/project/{slug}">
          <h4 style="color:{proj['color']}">{esc(proj['name'])}</h4>
          <div class="proj-full">{esc(proj['full'])}</div>
          <div class="proj-status">{esc(proj['status'])}</div>
          <div class="proj-bar" style="background:{proj['color']};opacity:0.4"></div>
        </a>'''

        html += '</div></div>'

    # ── SECTION 5: Recent Emails (collapsible) ──
    em = emails_data
    if em.get('emails'):
        html += f'''
    <div class="section">
      <div class="section-title">{icon('mail', 14)} Emails Today
        <span style="font-size:11px;font-weight:400;color:var(--text2);text-transform:none">{len(em["emails"])} items · Fetched {em.get("fetched","")}</span>
        <button class="section-toggle" data-target="email-section" style="margin-left:auto;background:none;border:none;color:var(--text3);cursor:pointer;font-size:12px">▼</button>
      </div>
      <div id="email-section" style="display:flex;flex-direction:column;gap:4px">'''

        for e in em['emails'][:10]:
            ch_badge = f'<span class="email-charter">{esc(e["charter"])}</span>' if e.get('charter') else ''
            html += f'''
        <div class="email-row">
          <span class="email-time">{esc(e["time"])}</span>
          <span class="email-sender">{esc(e["sender"][:25])}</span>
          <span class="email-subject">{esc(e["subject"][:60])}</span>
          {ch_badge}
        </div>'''

        html += '</div></div>'

    # ── SECTION 6: Signal Counts (compact) ──
    if total_signals > 0:
        parts = []
        for k, v in sig_counts.items():
            if v > 0:
                parts.append(f'{k.replace("_", " ").title()}: {v}')
        html += f'''
    <div class="section">
      <div class="section-title">{icon('signal', 14)} Today's Signals
        <span style="font-size:11px;font-weight:400;color:var(--text2);text-transform:none">{" · ".join(parts)}</span>
      </div>
    </div>'''

    return html_page('Command Center', html, 'home')

# ───────────────────────────────────────────────────────────────────────────
# DAILY BRIEF
# ───────────────────────────────────────────────────────────────────────────
def render_brief(date_str=None):
    """Render the daily intelligence brief."""
    if not date_str:
        date_str = datetime.now().strftime('%Y-%m-%d')

    brief_md = parse_brief_md(date_str)
    if not brief_md:
        # Try previous days
        for i in range(1, 4):
            alt = (datetime.now() - timedelta(days=i)).strftime('%Y-%m-%d')
            brief_md = parse_brief_md(alt)
            if brief_md:
                date_str = alt
                break

    if not brief_md:
        body = '''<div class="page-header"><h1>Daily Brief</h1></div>
        <div style="padding:20px;background:var(--surface);border-radius:var(--radius);color:var(--text3)">
          No brief found. <a href="/action?cmd=pipeline">Run pipeline</a> to generate.
        </div>'''
        return html_page('Daily Brief', body, 'brief')

    # Convert markdown to simple HTML
    brief_html = md_to_html(brief_md)

    # Date navigation
    prev_date = (datetime.strptime(date_str, '%Y-%m-%d') - timedelta(days=1)).strftime('%Y-%m-%d')
    next_date = (datetime.strptime(date_str, '%Y-%m-%d') + timedelta(days=1)).strftime('%Y-%m-%d')

    body = f'''
    <div class="page-header">
      <h1>Daily Brief</h1>
      <div class="subtitle">
        <a href="/brief?date={prev_date}">← Prev</a> · {date_str} · <a href="/brief?date={next_date}">Next →</a>
      </div>
    </div>
    <div class="brief-body">{brief_html}</div>'''

    return html_page('Daily Brief', body, 'brief')

def md_to_html(md):
    """Simple markdown to HTML converter."""
    lines = md.split('\n')
    html_parts = []
    in_table = False
    in_list = False
    in_code = False

    for line in lines:
        s = line.rstrip()

        # Code blocks
        if s.startswith('```'):
            if in_code:
                html_parts.append('</code></pre>')
                in_code = False
            else:
                in_code = True
                html_parts.append('<pre><code>')
            continue
        if in_code:
            html_parts.append(esc(s))
            continue

        # Close list if not a list line
        if in_list and not s.startswith('- ') and not s.startswith('* ') and not re.match(r'^\d+\.', s):
            html_parts.append('</ul>')
            in_list = False

        # Close table
        if in_table and '|' not in s:
            html_parts.append('</table>')
            in_table = False

        # Headers
        m = re.match(r'^(#{1,4})\s+(.+)', s)
        if m:
            level = len(m.group(1))
            html_parts.append(f'<h{level}>{esc(m.group(2))}</h{level}>')
            continue

        # Table
        if '|' in s and s.strip().startswith('|'):
            cells = [c.strip() for c in s.split('|')[1:-1]]
            if all(re.match(r'^[-:]+$', c) for c in cells if c):
                continue  # separator row
            if not in_table:
                html_parts.append('<table>')
                in_table = True
                html_parts.append('<tr>' + ''.join(f'<th>{esc(c)}</th>' for c in cells) + '</tr>')
            else:
                html_parts.append('<tr>' + ''.join(f'<td>{_inline_md(c)}</td>' for c in cells) + '</tr>')
            continue

        # Lists
        if s.startswith('- ') or s.startswith('* '):
            if not in_list:
                html_parts.append('<ul>')
                in_list = True
            html_parts.append(f'<li>{_inline_md(s[2:])}</li>')
            continue

        mn = re.match(r'^(\d+)\.\s+(.+)', s)
        if mn:
            if not in_list:
                html_parts.append('<ul>')
                in_list = True
            html_parts.append(f'<li>{_inline_md(mn.group(2))}</li>')
            continue

        # Blockquote
        if s.startswith('>'):
            html_parts.append(f'<blockquote style="border-left:3px solid var(--accent);padding-left:12px;color:var(--text2);margin:8px 0">{_inline_md(s[1:].strip())}</blockquote>')
            continue

        # Horizontal rule
        if re.match(r'^[-*_]{3,}$', s):
            html_parts.append('<hr style="border:none;border-top:1px solid var(--border);margin:16px 0">')
            continue

        # Paragraph
        if s.strip():
            html_parts.append(f'<p>{_inline_md(s)}</p>')

    if in_table:
        html_parts.append('</table>')
    if in_list:
        html_parts.append('</ul>')
    if in_code:
        html_parts.append('</code></pre>')

    return '\n'.join(html_parts)

def _inline_md(text):
    """Convert inline markdown (bold, italic, code, links)."""
    text = esc(text)
    text = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', text)
    text = re.sub(r'\*(.+?)\*', r'<em>\1</em>', text)
    text = re.sub(r'`(.+?)`', r'<code>\1</code>', text)
    text = re.sub(r'~~(.+?)~~', r'<del>\1</del>', text)
    return text

# ───────────────────────────────────────────────────────────────────────────
# PROJECT DETAIL
# ───────────────────────────────────────────────────────────────────────────
def render_project(slug):
    """Render a charter project detail page."""
    proj = PROJECTS.get(slug)
    if not proj:
        return html_page('Not Found', '<h1>Project not found</h1>')

    arts = _cached(f'arts_{slug}', lambda: scan_artifacts(proj['folder']), ttl=120)

    # Metrics
    metrics_html = ''
    if proj['metrics']:
        metrics_html = '<div class="metric-row">'
        for m in proj['metrics']:
            name, val, target, status = m[0], m[1], m[2] if len(m) > 2 else '', m[3] if len(m) > 3 else ''
            color_map = {'r': 'var(--red)', 'y': 'var(--orange)', 'g': 'var(--green)'}
            color = color_map.get(status, 'var(--text)')
            metrics_html += f'''
          <div class="metric-card">
            <div class="m-label">{esc(name)}</div>
            <div class="m-val" style="color:{color}">{esc(val)}</div>
            <div class="m-target">Target: {esc(target)}</div>
          </div>'''
        metrics_html += '</div>'

    # Artifacts
    arts_html = ''
    if arts:
        arts_html = '<h3 style="font-size:14px;margin:16px 0 8px">Artifacts</h3>'
        for a in arts[:20]:
            arts_html += f'''
          <a class="artifact-row" href="/open?path={urllib.parse.quote(a['path'])}" style="text-decoration:none;color:var(--text)">
            {a['icon']}
            <span class="a-name">{esc(a['name'])}</span>
            <span class="a-date">{a['modified']}</span>
            <span class="a-size">{a['size']}</span>
          </a>'''

    body = f'''
    <div class="page-header">
      <h1 style="color:{proj['color']}">{esc(proj['full'])}</h1>
      <div class="subtitle">{esc(proj['desc'])}</div>
    </div>
    <div class="proj-detail">
      <div style="margin-bottom:12px">
        <span style="font-size:12px;color:var(--text3)">Status:</span>
        <span style="font-size:13px">{esc(proj['status'])}</span>
        <span style="margin-left:20px;font-size:12px;color:var(--text3)">Team:</span>
        <span style="font-size:13px">{esc(proj['team'])}</span>
      </div>
      {metrics_html}
      {arts_html}
    </div>'''

    return html_page(proj['name'], body, f'project_{slug}')

# ───────────────────────────────────────────────────────────────────────────
# TOOLS & FILES
# ───────────────────────────────────────────────────────────────────────────
def render_tools():
    """Tools, generators, and file browser."""
    tools = [
        ('Run Full Pipeline', 'Execute daily orchestrator (cleanup → signals → brief → calendar)', 'pipeline', icon('play', 14)),
        ('Calculate Metrics', 'Recalculate project metrics', 'gen-metrics', icon('trending', 14)),
        ('Fetch Emails', 'Pull latest email signals from Outlook', 'fetch-emails', icon('mail', 14)),
        ('Fetch Calendar', 'Pull today\'s calendar from Outlook', 'fetch-calendar', icon('calendar', 14)),
        ('Weekly Snapshot', 'Generate weekly aggregation', 'snapshot', icon('document', 14)),
        ('Run Cleanup', 'Archive old signals/briefs/logs', 'cleanup', icon('folder', 14)),
        ('Sync Instructions', 'Rebuild copilot-instructions.md', 'sync-instructions', icon('document', 14)),
        ('Dry Run', 'Preview pipeline without changes', 'dryrun', icon('search', 14)),
    ]

    html = f'''
    <div class="page-header">
      <h1>Tools & Files</h1>
    </div>

    <div class="section">
      <div class="section-title">{icon('wrench', 14)} Tools</div>
      <div class="tool-grid">'''

    for name, desc, cmd, ic in tools:
        html += f'''
        <div class="tool-card">
          <h4>{ic} {name}</h4>
          <p>{desc}</p>
          <a class="tool-btn" href="/action?cmd={cmd}">Run</a>
        </div>'''

    html += '</div></div>'

    # File browser
    arts = _cached('all_arts', scan_artifacts, ttl=120)
    html += f'''
    <div class="section">
      <div class="section-title">{icon('folder', 14)} Recent Files <span style="font-size:11px;font-weight:400;color:var(--text2);text-transform:none">{len(arts)} artifacts</span></div>
      <div style="max-height:500px;overflow-y:auto">'''

    for a in arts[:40]:
        html += f'''
        <a class="artifact-row" href="/open?path={urllib.parse.quote(a['path'])}" style="text-decoration:none;color:var(--text)">
          {a['icon']}
          <span class="a-name">{esc(a['name'])}</span>
          <span class="a-date">{a['modified']}</span>
          <span class="a-size">{a['size']}</span>
        </a>'''

    html += '</div></div>'

    return html_page('Tools & Files', html, 'tools')

# ═══════════════════════════════════════════════════════════════════════════
# HTTP SERVER
# ═══════════════════════════════════════════════════════════════════════════

class BrainHandler(http.server.BaseHTTPRequestHandler):
    """Handles all HTTP requests for Brain OS."""

    def log_message(self, format, *args):
        pass  # Suppress default access logs

    def _send_html(self, html_content, code=200):
        self.send_response(code)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()
        self.wfile.write(html_content.encode('utf-8'))

    def _send_json(self, data, code=200):
        self.send_response(code)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def _redirect(self, url):
        self.send_response(302)
        self.send_header('Location', url)
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip('/')
        qs = urllib.parse.parse_qs(parsed.query)

        # ── Pages ──
        if path == '' or path == '/':
            self._send_html(render_home())
            return

        if path == '/brief':
            date = qs.get('date', [None])[0]
            self._send_html(render_brief(date))
            return

        if path == '/tools':
            self._send_html(render_tools())
            return

        if path.startswith('/project/'):
            slug = path.split('/project/', 1)[1]
            self._send_html(render_project(slug))
            return

        # ── API ──
        if path == '/api/search':
            q = qs.get('q', [''])[0].lower()
            if len(q) < 2:
                self._send_json([])
                return
            arts = _cached('all_arts', scan_artifacts, ttl=120)
            results = [{'name': a['name'], 'path': a['path'], 'icon': a['icon']}
                       for a in arts if q in a['name'].lower() or q in a['path'].lower()]
            self._send_json(results[:10])
            return

        # ── File open ──
        if path == '/open':
            fpath = qs.get('path', [''])[0]
            full = os.path.join(ROOT, fpath)
            if os.path.exists(full):
                try:
                    os.startfile(full)
                except Exception:
                    pass
            self._redirect('/')
            return

        # ── Actions ──
        if path == '/action':
            cmd = qs.get('cmd', [''])[0]
            self._handle_action(cmd)
            return

        # 404
        self._send_html(html_page('Not Found', '<h1>404 — Page not found</h1><p><a href="/">Go home</a></p>'), 404)

    def _handle_action(self, cmd):
        """Execute commands and redirect."""
        py_exe = os.path.join(ROOT, '.venv', 'Scripts', 'python.exe')
        if not os.path.exists(py_exe):
            py_exe = 'python'

        actions = {
            'pipeline': {
                'cmd': ['powershell', '-NoProfile', '-File', os.path.join(AUTO, 'daily_orchestrator.ps1'), '-Force'],
                'redirect': '/'
            },
            'cleanup': {
                'cmd': ['powershell', '-NoProfile', '-File', os.path.join(AUTO, 'cleanup.ps1')],
                'redirect': '/'
            },
            'snapshot': {
                'cmd': ['powershell', '-NoProfile', '-File', os.path.join(AUTO, 'weekly_snapshot.ps1')],
                'redirect': '/'
            },
            'gen-metrics': {
                'cmd': [py_exe, os.path.join(AUTO, 'calculate_metrics.py')],
                'redirect': '/tools'
            },
            'fetch-emails': {
                'cmd': ['powershell', '-NoProfile', '-File', os.path.join(AUTO, 'fetch_emails.ps1')],
                'redirect': '/'
            },
            'fetch-calendar': {
                'cmd': ['powershell', '-NoProfile', '-File', os.path.join(AUTO, 'fetch_calendar.ps1')],
                'redirect': '/'
            },
            'sync-instructions': {
                'cmd': ['powershell', '-NoProfile', '-File', os.path.join(AUTO, 'sync_instructions.ps1')],
                'redirect': '/tools'
            },
            'dryrun': {
                'cmd': ['powershell', '-NoProfile', '-File', os.path.join(AUTO, 'daily_orchestrator.ps1'), '-DryRun', '-Force'],
                'redirect': '/tools'
            },
        }

        if cmd == 'brief':
            self._redirect('/brief')
            return

        action = actions.get(cmd)
        if not action:
            self._redirect('/')
            return

        if 'cmd' in action:
            # Clear relevant cache
            with _cache_lock:
                _cache.clear()
            try:
                subprocess.Popen(
                    action['cmd'], cwd=ROOT,
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                    creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0,
                )
            except Exception as e:
                print(f'  [Action] {cmd} failed: {e}')

        self._redirect(action.get('redirect', '/'))


def main():
    """Start the Brain OS server."""
    print(f'\n  ╔═══════════════════════════════════════╗')
    print(f'  ║  {PORTAL_NAME} — {PORTAL_SUBTITLE:<24s}  ║')
    print(f'  ║  http://localhost:{PORT}                ║')
    print(f'  ╚═══════════════════════════════════════╝\n')

    server = http.server.HTTPServer(('', PORT), BrainHandler)
    print(f'  [{PORTAL_NAME}] Serving on port {PORT}')

    # Handle Ctrl+C gracefully
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print(f'\n  [{PORTAL_NAME}] Shutting down...')
        server.shutdown()


if __name__ == '__main__':
    main()
