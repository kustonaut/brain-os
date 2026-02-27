<#
.SYNOPSIS
    Fetch Outlook emails from last 24h and write to signals file
.NOTES
    Supports Outlook COM (Windows) or Graph API (cross-platform).
    Set outlook.method = "graph" in config.json for Graph mode.
#>

$ROOT = Split-Path -Parent $PSScriptRoot
$CONFIG = Get-Content "$ROOT\_Automation\config.json" -Raw | ConvertFrom-Json
. "$PSScriptRoot\graph_helpers.ps1"
$SIGNALS = Join-Path $ROOT "00_Daily_Intelligence\Signals"
$TODAY = Get-Date -Format "yyyy-MM-dd"
$OUTPUT_FILE = Join-Path $SIGNALS "emails_$TODAY.md"
$LOOKBACK = (Get-Date).AddHours(-$CONFIG.outlook.lookback_hours)

if (-not (Test-Path $SIGNALS)) { New-Item -ItemType Directory -Path $SIGNALS -Force | Out-Null }

$results = @()
$results += "# Email Signals - $TODAY"
$results += ""
$results += "> Fetched at $(Get-Date -Format 'HH:mm:ss') | Lookback: $($CONFIG.outlook.lookback_hours)h"
$results += ""

$mailMethod = Get-MailMethod -Config $CONFIG

if ($mailMethod -eq "graph") {
    # ── Graph API mode ──
    try {
        $graphEmails = Get-GraphEmails -LookbackHours $CONFIG.outlook.lookback_hours -Keywords $CONFIG.outlook.keywords_filter -Folders $CONFIG.outlook.folders_to_scan -MaxEmails $CONFIG.outlook.max_emails
        $currentFolder = ""
        $count = 0
        foreach ($em in $graphEmails) {
            if ($em.Folder -ne $currentFolder) {
                $currentFolder = $em.Folder
                $results += "## $currentFolder"
                $results += ""
            }
            $received = ([datetime]::Parse($em.Time)).ToString("yyyy-MM-dd HH:mm")
            $results += "### [$received] $($em.Subject)"
            $results += "- **From:** $($em.Sender)"
            $results += "- **To:** $($em.To)"
            $priority = "⚪"
            if ($em.Subject -match 'urgent|action required|blocking') { $priority = "🔴" }
            elseif ($em.Subject -match 'review|follow.?up|please|remind|pending|update') { $priority = "🟡" }
            $results += "- **Priority:** $priority"
            $results += ""
            $results += '```'
            $results += $em.Preview
            $results += '```'
            $results += ""
            $count++
        }
        if ($count -eq 0) { $results += "*No matching emails found.*"; $results += "" }
        else { $results += "*$count relevant emails found via Graph API.*"; $results += "" }
    } catch {
        $results += "**ERROR:** Graph API failed: $_"
    }
} else {
    # ── Outlook COM mode (Windows only) ──
    try {
        $outlook = New-Object -ComObject Outlook.Application
        $namespace = $outlook.GetNamespace("MAPI")

        foreach ($folderName in $CONFIG.outlook.folders_to_scan) {
            $folder = switch ($folderName) {
                "Inbox"      { $namespace.GetDefaultFolder(6) }  # olFolderInbox
                "Sent Items" { $namespace.GetDefaultFolder(5) }  # olFolderSentMail
            }

            if (-not $folder) { continue }

            $results += "## $folderName"
            $results += ""

            $filterDate = $LOOKBACK.ToString("MM/dd/yyyy HH:mm")
            $filter = "[ReceivedTime] >= '$filterDate'"
            $items = $folder.Items.Restrict($filter)
            $items.Sort("[ReceivedTime]", $true)

            $count = 0
            $keywords = $CONFIG.outlook.keywords_filter

            foreach ($item in $items) {
                if ($count -ge $CONFIG.outlook.max_emails) { break }

                try {
                    $subject = $item.Subject
                    $sender = $item.SenderName
                    $received = $item.ReceivedTime.ToString("yyyy-MM-dd HH:mm")
                    $bodyPreview = $item.Body
                    if ($bodyPreview.Length -gt 500) { $bodyPreview = $bodyPreview.Substring(0, 500) + "..." }

                    $fullText = "$subject $($item.Body)"
                    $matched = $false
                    $matchedKeywords = @()
                    foreach ($kw in $keywords) {
                        if ($fullText -match [regex]::Escape($kw)) {
                            $matched = $true
                            $matchedKeywords += $kw
                        }
                    }

                    if ($matched -or $folderName -eq "Sent Items") {
                        $results += "### [$received] $subject"
                        $results += "- **From:** $sender"
                        $results += "- **To:** $($item.To)"
                        if ($matchedKeywords.Count -gt 0) {
                            $results += "- **Keywords:** $($matchedKeywords -join ', ')"
                        }
                        $priority = "⚪"
                        if ($subject -match 'urgent|URGENT|action required|Action Required|blocking|BLOCKING') { $priority = "🔴" }
                        elseif ($subject -match 'review|follow.?up|please|remind|pending|update') { $priority = "🟡" }
                        $results += "- **Priority:** $priority"
                        $results += ""
                        $results += '```'
                        $results += $bodyPreview
                        $results += '```'
                        $results += ""
                        $count++
                    }
                } catch {
                    # Skip unreadable items (meeting requests, etc)
                }
            }

            if ($count -eq 0) {
                $results += "*No matching emails found in $folderName.*"
                $results += ""
            } else {
                $results += "*$count relevant emails found.*"
                $results += ""
            }

            $results += "---"
            $results += ""
        }
    } catch {
        $results += "**ERROR:** Could not connect to Outlook. Is it running? Error: $_"
        $results += ""
        $results += "If Outlook is not available, set ``outlook.method`` to ``graph`` in config.json"
    }
}

$results | Set-Content $OUTPUT_FILE -Encoding UTF8
Write-Host "Email signals written to: $OUTPUT_FILE"
