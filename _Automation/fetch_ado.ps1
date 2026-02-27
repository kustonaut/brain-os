<#
.SYNOPSIS
    Fetch ADO work item updates and write to signals file
.NOTES
    Uses Azure CLI (az boards). Requires: az login + az devops configure
#>

$ROOT = Split-Path -Parent $PSScriptRoot
$CONFIG = Get-Content "$ROOT\_Automation\config.json" -Raw | ConvertFrom-Json
$SIGNALS = Join-Path $ROOT "00_Daily_Intelligence\Signals"
$TODAY = Get-Date -Format "yyyy-MM-dd"
$OUTPUT_FILE = Join-Path $SIGNALS "ado_$TODAY.md"

if (-not (Test-Path $SIGNALS)) { New-Item -ItemType Directory -Path $SIGNALS -Force | Out-Null }

$results = @()
$results += "# ADO Work Item Signals - $TODAY"
$results += ""
$results += "> Fetched at $(Get-Date -Format 'HH:mm:ss')"
$results += ""

$azAvailable = $false
try {
    $azVer = az --version 2>$null | Select-Object -First 1
    if ($azVer) { $azAvailable = $true }
} catch {}

# Build ADO base URL from config
$adoBaseUrl = "$($CONFIG.ado.organization)/$($CONFIG.ado.project)"
$adoAreaPath = if ($CONFIG.ado.area_path) { $CONFIG.ado.area_path } else { $CONFIG.ado.project }

if ($azAvailable) {
    # Configure defaults
    az devops configure --defaults organization=$($CONFIG.ado.organization) project=$($CONFIG.ado.project) 2>$null

    # Section 1: Tracked work items - current state
    $results += "## Tracked Work Items"
    $results += ""
    $results += "| ID | Title | State | Assigned | Changed |"
    $results += "|---|---|---|---|---|"

    foreach ($id in $CONFIG.ado.tracked_ids) {
        try {
            $itemJson = az boards work-item show --id $id --output json 2>$null
            if ($itemJson) {
                $item = $itemJson | ConvertFrom-Json
                $fields = $item.fields
                $title = $fields.'System.Title'
                if ($title.Length -gt 50) { $title = $title.Substring(0, 47) + "..." }
                $state = $fields.'System.State'
                $assigned = if ($fields.'System.AssignedTo') { $fields.'System.AssignedTo'.displayName } else { "Unassigned" }
                $changed = ([datetime]$fields.'System.ChangedDate').ToString("yyyy-MM-dd")

                $results += "| [$id]($adoBaseUrl/_workitems/edit/$id) | $title | $state | $assigned | $changed |"
            }
        } catch {
            $results += "| $id | [Error fetching] | - | - | - |"
        }
    }

    $results += ""

    # Section 2: Items assigned to me
    $results += "## My Active Items"
    $results += ""

    try {
        $myItemsJson = az boards query --wiql "SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo], [System.ChangedDate] FROM workitems WHERE [System.AssignedTo] = @Me AND [System.State] <> 'Closed' AND [System.State] <> 'Removed' ORDER BY [System.ChangedDate] DESC" --output json 2>$null

        if ($myItemsJson) {
            $myItems = $myItemsJson | ConvertFrom-Json

            if ($myItems.Count -gt 0) {
                $results += "| ID | Title | State | Changed |"
                $results += "|---|---|---|---|"

                foreach ($item in $myItems | Select-Object -First 20) {
                    $id = $item.id
                    $fullJson = az boards work-item show --id $id --output json 2>$null
                    if ($fullJson) {
                        $full = $fullJson | ConvertFrom-Json
                        $title = $full.fields.'System.Title'
                        $state = $full.fields.'System.State'
                        $changed = ([datetime]$full.fields.'System.ChangedDate').ToString("yyyy-MM-dd")
                        $results += "| [$id]($adoBaseUrl/_workitems/edit/$id) | $title | $state | $changed |"
                    }
                }
            } else {
                $results += "*No active items assigned to you.*"
            }
        }
    } catch {
        $results += "*Could not query assigned items: $_*"
    }

    $results += ""

    # Section 3: Recent changes in your area (last 24h)
    $results += "## Recent Changes in Team Area (last 24h)"
    $results += ""

    try {
        $yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
        $recentJson = az boards query --wiql "SELECT [System.Id], [System.Title], [System.State], [System.ChangedBy], [System.ChangedDate] FROM workitems WHERE [System.ChangedDate] >= '$yesterday' AND [System.AreaPath] UNDER '$adoAreaPath' ORDER BY [System.ChangedDate] DESC" --output json 2>$null

        if ($recentJson) {
            $recent = $recentJson | ConvertFrom-Json

            if ($recent.Count -gt 0) {
                $results += "| ID | Title | State | Changed By |"
                $results += "|---|---|---|---|"

                foreach ($item in $recent | Select-Object -First 15) {
                    $id = $item.id
                    $fullJson = az boards work-item show --id $id --output json 2>$null
                    if ($fullJson) {
                        $full = $fullJson | ConvertFrom-Json
                        $title = $full.fields.'System.Title'
                        if ($title.Length -gt 50) { $title = $title.Substring(0, 47) + "..." }
                        $state = $full.fields.'System.State'
                        $changedBy = $full.fields.'System.ChangedBy'.displayName
                        $results += "| $id | $title | $state | $changedBy |"
                    }
                }
            } else {
                $results += "*No changes in team area in last 24h.*"
            }
        }
    } catch {
        $results += "*Could not query recent area changes: $_*"
    }

} else {
    $results += "## [WARN] Azure CLI Not Available"
    $results += ""
    $results += "ADO fetch requires Azure CLI. To set up:"
    $results += "1. Install: ``winget install Microsoft.AzureCLI``"
    $results += "2. Login: ``az login``"
    $results += "3. Install DevOps extension: ``az extension add --name azure-devops``"
    $results += "4. Configure defaults in config.json (ado.organization, ado.project)"
    $results += ""
    $results += "Tracked IDs (check manually): $($CONFIG.ado.tracked_ids -join ', ')"
}

$results | Set-Content $OUTPUT_FILE -Encoding UTF8
Write-Host "ADO signals written to: $OUTPUT_FILE"
