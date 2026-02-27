<#
.SYNOPSIS
    Fetch Teams chat messages - exports recent relevant chats to signals file
.NOTES
    Teams doesn't have a COM API. This script:
    1. Tries Microsoft Graph via `az rest` (requires az login with Graph permissions)
    2. Falls back to checking Teams cache/export if available
    3. Logs guidance if neither works
#>

$ROOT = Split-Path -Parent $PSScriptRoot
$SIGNALS = Join-Path $ROOT "00_Daily_Intelligence\Signals"
$TODAY = Get-Date -Format "yyyy-MM-dd"
$OUTPUT_FILE = Join-Path $SIGNALS "chats_$TODAY.md"

if (-not (Test-Path $SIGNALS)) { New-Item -ItemType Directory -Path $SIGNALS -Force | Out-Null }

$results = @()
$results += "# Teams Chat Signals - $TODAY"
$results += ""
$results += "> Fetched at $(Get-Date -Format 'HH:mm:ss')"
$results += ""

# Try Microsoft Graph API via az rest
$graphAvailable = $false
try {
    $lookback = (Get-Date).AddHours(-24).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    $chatsJson = az rest --method GET --url "https://graph.microsoft.com/v1.0/me/chats?`$top=20&`$orderby=lastMessagePreview/createdDateTime desc" 2>$null

    if ($LASTEXITCODE -eq 0 -and $chatsJson) {
        $graphAvailable = $true
        $chats = $chatsJson | ConvertFrom-Json

        $results += "## Recent Chats (via Graph API)"
        $results += ""

        $chatCount = 0
        foreach ($chat in $chats.value) {
            if ($chatCount -ge 15) { break }

            try {
                $messagesJson = az rest --method GET --url "https://graph.microsoft.com/v1.0/me/chats/$($chat.id)/messages?`$top=10&`$orderby=createdDateTime desc&`$filter=createdDateTime ge $lookback" 2>$null

                if ($messagesJson) {
                    $messages = $messagesJson | ConvertFrom-Json

                    if ($messages.value.Count -gt 0) {
                        $chatTopic = if ($chat.topic) { $chat.topic } else { "1:1 Chat" }
                        $results += "### $chatTopic"

                        foreach ($msg in $messages.value | Select-Object -First 5) {
                            $sender = $msg.from.user.displayName
                            $time = ([datetime]$msg.createdDateTime).ToLocalTime().ToString("HH:mm")
                            $body = $msg.body.content -replace '<[^>]+>',''
                            if ($body.Length -gt 300) { $body = $body.Substring(0, 300) + "..." }

                            $results += "- **[$time] ${sender}:** $body"
                        }
                        $results += ""
                        $chatCount++
                    }
                }
            } catch {}
        }

        if ($chatCount -eq 0) {
            $results += "*No relevant chat messages in last 24h.*"
        }
    }
} catch {}

if (-not $graphAvailable) {
    $results += "## [WARN] Teams Chat Fetch - Limited Access"
    $results += ""
    $results += "Graph API not available. To enable automatic Teams chat fetching:"
    $results += ""
    $results += "1. Run ``az login`` with an account that has Chat.Read permissions"
    $results += "2. Or manually export important chats:"
    $results += "   - In Teams, right-click chat > Copy message"
    $results += "   - Paste into a .txt file > Save to ``_Inbox/``"
    $results += "   - The inbox parser will pick it up automatically"
    $results += ""
    $results += "### Alternative: Quick Chat Dump"
    $results += "At end of day, tell Copilot: *'Here are today's important chats: ...'*"
    $results += "Copilot will update your Knowledge Base directly."
}

$results | Set-Content $OUTPUT_FILE -Encoding UTF8
Write-Host "Chat signals written to: $OUTPUT_FILE"
