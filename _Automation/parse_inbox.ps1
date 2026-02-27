<#
.SYNOPSIS
    Parse files in _Inbox landing zone, extract text, route to charter folders
#>
param([switch]$DryRun)

$ROOT = Split-Path -Parent $PSScriptRoot
$CONFIG = Get-Content "$ROOT\_Automation\config.json" -Raw | ConvertFrom-Json
$INBOX = Join-Path $ROOT "_Inbox"
$SIGNALS = Join-Path $ROOT "00_Daily_Intelligence\Signals"
$TODAY = Get-Date -Format "yyyy-MM-dd"
$OUTPUT_FILE = Join-Path $SIGNALS "inbox_parsed_$TODAY.md"

# Get files (exclude README, subfolders with explicit routing, archive)
$files = Get-ChildItem $INBOX -File -Recurse | Where-Object {
    $_.Name -ne "README.md" -and
    $_.FullName -notmatch "_archived" -and
    $_.FullName -notmatch "_PROCESSED" -and
    $_.Extension -in @('.docx','.doc','.pptx','.ppt','.txt','.md','.xlsx','.msg')
}

if ($files.Count -eq 0) {
    "# Inbox Parse - $TODAY`n`nNo new files found in _Inbox." | Set-Content $OUTPUT_FILE -Encoding UTF8
    Write-Host "No new files in _Inbox."
    return
}

$results = @()
$results += "# Inbox Parse - $TODAY"
$results += ""
$results += "> Parsed at $(Get-Date -Format 'HH:mm:ss') | Files found: $($files.Count)"
$results += ""

# COM objects (lazy init)
$wordApp = $null
$pptApp = $null

foreach ($file in $files) {
    $ext = $file.Extension.ToLower()
    $text = ""

    Write-Host "Parsing: $($file.Name)..."

    try {
        switch -Wildcard ($ext) {
            ".txt" { $text = Get-Content $file.FullName -Raw -ErrorAction Stop }
            ".md"  { $text = Get-Content $file.FullName -Raw -ErrorAction Stop }
            { $_ -in ".docx",".doc" } {
                if (-not $wordApp) { $wordApp = New-Object -ComObject Word.Application; $wordApp.Visible = $false }
                $doc = $wordApp.Documents.Open($file.FullName, $false, $true)
                $text = $doc.Content.Text
                $doc.Close($false)
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
            }
            { $_ -in ".pptx",".ppt" } {
                if (-not $pptApp) { $pptApp = New-Object -ComObject PowerPoint.Application }
                $pres = $pptApp.Presentations.Open($file.FullName, $true, $false, $false)
                $slideTexts = @()
                foreach ($slide in $pres.Slides) {
                    foreach ($shape in $slide.Shapes) {
                        if ($shape.HasTextFrame) { $slideTexts += $shape.TextFrame.TextRange.Text }
                    }
                }
                $text = $slideTexts -join "`n"
                $pres.Close()
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($pres) | Out-Null
            }
            ".xlsx" {
                $text = "[Excel file - manual review needed: $($file.Name)]"
            }
            ".msg" {
                $outlook = New-Object -ComObject Outlook.Application
                $msg = $outlook.Session.OpenSharedItem($file.FullName)
                $text = "FROM: $($msg.SenderName)`nTO: $($msg.To)`nSUBJECT: $($msg.Subject)`nDATE: $($msg.ReceivedTime)`n`n$($msg.Body)"
                $msg.Close(0)
            }
        }
    } catch {
        $text = "[PARSE ERROR: $_]"
        Write-Host "  Error: $_" -ForegroundColor Red
    }

    # Truncate for signal file (first 2000 chars)
    $preview = if ($text.Length -gt 2000) { $text.Substring(0, 2000) + "`n... [TRUNCATED]" } else { $text }

    # Auto-classify based on keywords
    $targetFolder = $null
    $routingMap = $CONFIG.inbox.routing_keywords

    # Check if file is in a subfolder that indicates routing
    $relPath = $file.DirectoryName.Replace($INBOX, "").TrimStart('\')
    if ($relPath -match '^\d\d_') {
        $targetFolder = $relPath.Split('\')[0]
    } else {
        # Keyword-based classification
        $bestScore = 0
        foreach ($folder in $routingMap.PSObject.Properties) {
            $score = 0
            foreach ($keyword in $folder.Value) {
                if ($text -match [regex]::Escape($keyword)) { $score++ }
            }
            if ($score -gt $bestScore) {
                $bestScore = $score
                $targetFolder = $folder.Name
            }
        }
        if ($bestScore -lt 2) { $targetFolder = $null }
    }

    $results += "## $($file.Name)"
    $results += "- **Size:** $([math]::Round($file.Length/1024, 1)) KB"
    $results += "- **Modified:** $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))"
    $results += "- **Classified as:** $(if ($targetFolder) { $targetFolder } else { '? UNCLASSIFIED - needs manual routing' })"
    $results += ""
    $results += '```'
    $results += $preview
    $results += '```'
    $results += ""

    # Move file to target folder (unless DryRun)
    if (-not $DryRun -and $targetFolder) {
        $dest = Join-Path $ROOT "$targetFolder\Reference\$($file.Name)"
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        try {
            Move-Item $file.FullName $dest -Force
            $results += "> [OK] Moved to ``$targetFolder\Reference\``"
        } catch {
            $results += "> [WARN] Move failed: $_"
        }
    } elseif (-not $DryRun -and -not $targetFolder) {
        $newName = "_NEEDS_ROUTING_$($file.Name)"
        Rename-Item $file.FullName $newName -ErrorAction SilentlyContinue
        $results += "> [WARN] Could not auto-classify. Renamed to ``$newName``"
    } else {
        $results += "> [DRY RUN - no files moved]"
    }
    $results += ""
    $results += "---"
    $results += ""
}

# Cleanup COM
if ($wordApp) { $wordApp.Quit(); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wordApp) | Out-Null }
if ($pptApp) { $pptApp.Quit(); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($pptApp) | Out-Null }

# Write signal file
$results | Set-Content $OUTPUT_FILE -Encoding UTF8
Write-Host "Inbox parse results written to: $OUTPUT_FILE"
