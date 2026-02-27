<#
.SYNOPSIS
    Microsoft Graph API helpers — cross-platform alternative to Outlook COM
.DESCRIPTION
    Provides functions to read emails, calendar, and create events via Graph API
    using 'az rest'. Requires: az login with appropriate scopes.
    
    Usage: source this file, then call functions:
      . "$PSScriptRoot\graph_helpers.ps1"
      $emails = Get-GraphEmails -LookbackHours 24 -Keywords @("keyword1")
      $events = Get-GraphCalendar -Date "2026-02-13"
      New-GraphCalendarEvent -Subject "Focus" -Start "2026-02-13T09:00:00" -DurationMinutes 60
#>

function Test-GraphAccess {
    <# Returns $true if az CLI is logged in with Graph access #>
    try {
        $result = az account show 2>$null | ConvertFrom-Json
        return ($null -ne $result)
    } catch { return $false }
}

function Get-GraphEmails {
    param(
        [int]$LookbackHours = 24,
        [string[]]$Keywords = @(),
        [string[]]$Folders = @("Inbox"),
        [int]$MaxEmails = 50
    )
    $since = (Get-Date).AddHours(-$LookbackHours).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $results = @()
    
    foreach ($folder in $Folders) {
        $folderPath = switch ($folder) {
            "Inbox"      { "inbox" }
            "Sent Items" { "sentitems" }
            default      { $folder.ToLower() }
        }
        try {
            $url = "https://graph.microsoft.com/v1.0/me/mailFolders/$folderPath/messages?`$filter=receivedDateTime ge $since&`$top=$MaxEmails&`$select=subject,from,receivedDateTime,bodyPreview,toRecipients&`$orderby=receivedDateTime desc"
            $response = az rest --method GET --url $url 2>$null | ConvertFrom-Json
            if ($response.value) {
                foreach ($msg in $response.value) {
                    $subject = $msg.subject
                    $matched = $false
                    if ($Keywords.Count -eq 0) { $matched = $true }
                    else {
                        foreach ($kw in $Keywords) {
                            if ($subject -match [regex]::Escape($kw) -or $msg.bodyPreview -match [regex]::Escape($kw)) {
                                $matched = $true; break
                            }
                        }
                    }
                    if ($matched) {
                        $results += @{
                            Subject  = $subject
                            Sender   = $msg.from.emailAddress.name
                            Email    = $msg.from.emailAddress.address
                            Time     = $msg.receivedDateTime
                            Preview  = $msg.bodyPreview
                            To       = ($msg.toRecipients | ForEach-Object { $_.emailAddress.name }) -join "; "
                            Folder   = $folder
                        }
                    }
                }
            }
        } catch {
            Write-Warning "Graph email fetch failed for $folder`: $_"
        }
    }
    return $results
}

function Get-GraphCalendar {
    param(
        [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
        [int]$DaysAhead = 2
    )
    $startDT = "${Date}T00:00:00"
    $endDT = ([datetime]::Parse($Date)).AddDays($DaysAhead).ToString("yyyy-MM-ddT23:59:59")
    $tz = [System.TimeZoneInfo]::Local.Id
    
    try {
        $url = "https://graph.microsoft.com/v1.0/me/calendarView?startDateTime=$startDT&endDateTime=$endDT&`$select=subject,start,end,organizer,attendees,isAllDay,showAs,location,isCancelled&`$orderby=start/dateTime&`$top=100"
        $headers = "Prefer=outlook.timezone=`"$tz`""
        $response = az rest --method GET --url $url --headers $headers 2>$null | ConvertFrom-Json
        $events = @()
        if ($response.value) {
            foreach ($evt in $response.value) {
                if ($evt.isCancelled) { continue }
                $start = [datetime]::Parse($evt.start.dateTime)
                $end   = [datetime]::Parse($evt.end.dateTime)
                $duration = [math]::Round(($end - $start).TotalMinutes)
                $events += @{
                    Subject   = $evt.subject
                    Start     = $start
                    End       = $end
                    Duration  = $duration
                    Organizer = $evt.organizer.emailAddress.name
                    Location  = $evt.location.displayName
                    ShowAs    = $evt.showAs
                    IsAllDay  = $evt.isAllDay
                    Attendees = ($evt.attendees | ForEach-Object { $_.emailAddress.name }) -join "; "
                }
            }
        }
        return $events
    } catch {
        Write-Warning "Graph calendar fetch failed: $_"
        return @()
    }
}

function New-GraphCalendarEvent {
    param(
        [Parameter(Mandatory)][string]$Subject,
        [Parameter(Mandatory)][string]$Start,
        [int]$DurationMinutes = 60,
        [string]$Body = "",
        [string]$Category = "Focus Time",
        [int]$ShowAs = 2,
        [int]$ReminderMinutes = 5
    )
    $tz = [System.TimeZoneInfo]::Local.Id
    $endDT = ([datetime]::Parse($Start)).AddMinutes($DurationMinutes).ToString("yyyy-MM-ddTHH:mm:ss")
    
    $eventBody = @{
        subject = $Subject
        start = @{ dateTime = $Start; timeZone = $tz }
        end   = @{ dateTime = $endDT; timeZone = $tz }
        showAs = switch ($ShowAs) { 0 { "free" } 1 { "tentative" } 2 { "busy" } 3 { "oof" } default { "busy" } }
        reminderMinutesBeforeStart = $ReminderMinutes
        categories = @($Category)
        isReminderOn = $true
    }
    if ($Body) {
        $eventBody["body"] = @{ contentType = "text"; content = $Body }
    }
    
    $jsonPayload = $eventBody | ConvertTo-Json -Depth 5 -Compress
    try {
        $result = az rest --method POST --url "https://graph.microsoft.com/v1.0/me/events" --body $jsonPayload --headers "Content-Type=application/json" 2>$null | ConvertFrom-Json
        return @{ Success = $true; Id = $result.id; Subject = $result.subject }
    } catch {
        Write-Warning "Graph event creation failed: $_"
        return @{ Success = $false; Error = $_.ToString() }
    }
}

function Get-MailMethod {
    <# Returns 'graph' or 'com' based on config and platform availability #>
    param([PSCustomObject]$Config)
    $method = "com"
    if ($Config.outlook -and $Config.outlook.method) { $method = $Config.outlook.method }
    # Force graph on non-Windows
    if ($env:OS -ne "Windows_NT" -and $method -eq "com") { $method = "graph" }
    # Verify COM availability on Windows
    if ($method -eq "com") {
        try {
            $null = New-Object -ComObject Outlook.Application -ErrorAction Stop
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($_) | Out-Null
        } catch {
            Write-Warning "Outlook COM not available, falling back to Graph API"
            $method = "graph"
        }
    }
    return $method
}
