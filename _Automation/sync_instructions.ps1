<#
.SYNOPSIS
    Syncs copilot-instructions.md with the actual workspace folder structure
.DESCRIPTION
    Scans the workspace directory tree and regenerates the "Folder Map" section
    and automation/script inventory in .github/copilot-instructions.md.
    Runs as the final step of the daily orchestrator so the file is always current.
#>

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"
$ROOT = Split-Path -Parent $PSScriptRoot
$INSTRUCTIONS_FILE = Join-Path $ROOT ".github\copilot-instructions.md"

if (-not (Test-Path $INSTRUCTIONS_FILE)) {
    Write-Host "copilot-instructions.md not found at $INSTRUCTIONS_FILE"
    return
}

# ── Scan workspace structure ─────────────────────────────────────────────────
$skipDirs = @('.venv', '.git', 'node_modules', '__pycache__', 'logs')

function Get-FolderSummary {
    param([string]$Path, [int]$Depth = 0, [int]$MaxDepth = 2)

    $lines = @()
    $indent = "  " * $Depth
    $dirName = Split-Path $Path -Leaf

    $files = Get-ChildItem $Path -File -ErrorAction SilentlyContinue
    $fileCount = $files.Count
    $dirs = Get-ChildItem $Path -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notin $skipDirs }

    $subdirNames = ($dirs | ForEach-Object { $_.Name }) -join ", "

    $annotation = ""
    if ($fileCount -gt 0 -and $subdirNames) {
        $annotation = "# ${fileCount} files + ${subdirNames}"
    } elseif ($fileCount -gt 0) {
        $annotation = "# ${fileCount} files"
    } elseif ($subdirNames) {
        $annotation = "# ${subdirNames}"
    }

    $padWidth = 34 - ($Depth * 2)
    if ($padWidth -lt 4) { $padWidth = 4 }
    $displayName = "${dirName}/"
    $paddedName = $displayName.PadRight($padWidth)

    $lines += "${indent}${paddedName}${annotation}"

    if ($Depth -lt $MaxDepth) {
        foreach ($d in ($dirs | Sort-Object Name)) {
            $lines += Get-FolderSummary -Path $d.FullName -Depth ($Depth + 1) -MaxDepth $MaxDepth
        }
    }

    return $lines
}

# Top-level folders to include (sorted)
$topDirs = Get-ChildItem $ROOT -Directory |
           Where-Object { $_.Name -notin @('.venv', '.git', 'node_modules', '__pycache__') } |
           Sort-Object Name

$folderMapLines = @()
foreach ($d in $topDirs) {
    $folderMapLines += Get-FolderSummary -Path $d.FullName -Depth 0 -MaxDepth 1
}

$newFolderMap = $folderMapLines -join "`n"

# ── Count automation scripts ────────────────────────────────────────────────
$automationDir = Join-Path $ROOT "_Automation"
$ps1Scripts = (Get-ChildItem $automationDir -File -Filter "*.ps1" -ErrorAction SilentlyContinue).Count
$pyScripts = (Get-ChildItem $automationDir -File -Filter "*.py" -ErrorAction SilentlyContinue).Count
$totalScripts = $ps1Scripts + $pyScripts

# ── Count VS Code tasks ────────────────────────────────────────────────────
$tasksFile = Join-Path $ROOT ".vscode\tasks.json"
$taskCount = 0
if (Test-Path $tasksFile) {
    $tasksJson = Get-Content $tasksFile -Raw | ConvertFrom-Json
    $taskCount = $tasksJson.tasks.Count
}

# ── Count skills ────────────────────────────────────────────────────────────
$skillsDir = Join-Path $ROOT ".vscode\skills"
$skillCount = 0
if (Test-Path $skillsDir) {
    $skillCount = (Get-ChildItem $skillsDir -File -Filter "*.md" -ErrorAction SilentlyContinue).Count
}

# ── Read current instructions ───────────────────────────────────────────────
$content = Get-Content $INSTRUCTIONS_FILE -Raw

# ── Replace Folder Map section ──────────────────────────────────────────────
$folderMapPattern = '(?s)(### Folder Map\r?\n```\r?\n).+?(\r?\n```)'
$newFolderMapBlock = "`${1}${newFolderMap}`${2}"
$updated = $content -replace $folderMapPattern, $newFolderMapBlock

# ── Replace automation script count ─────────────────────────────────────────
$updated = $updated -replace 'Daily orchestrator \+ \d+ pipeline scripts', "Daily orchestrator + $($totalScripts - 1) pipeline scripts"

# ── Add auto-sync timestamp at the bottom ───────────────────────────────────
$timestampLine = "`n<!-- Auto-synced: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') by sync_instructions.ps1 -->"
$updated = $updated -replace '\r?\n<!-- Auto-synced:.*?-->', ''
$updated = $updated.TrimEnd() + $timestampLine + "`n"

# ── Write or preview ────────────────────────────────────────────────────────
if ($DryRun) {
    Write-Host "=== FOLDER MAP (would write) ==="
    Write-Host $newFolderMap
    Write-Host ""
    Write-Host "Scripts: $totalScripts | Tasks: $taskCount | Skills: $skillCount"
    Write-Host "[DRY RUN] No changes written."
} else {
    $updated | Out-File -FilePath $INSTRUCTIONS_FILE -Encoding utf8 -NoNewline
    Write-Host "copilot-instructions.md synced: $($topDirs.Count) top-level dirs, $totalScripts scripts, $taskCount tasks, $skillCount skills"
}
