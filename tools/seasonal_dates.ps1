<#
Seasonal Planning Engine date calculator (CLAUDE.md §13–§16).
Implements data/event_calendar.yaml exactly as written; it does not change the calendar or the rules.

For every event/season it resolves the relevant occurrence and reports:
  date or window, anchor date (lead times count back from it), days until, preferred and
  minimum listing start, phase, days remaining in season (windows), priority, allocation role.

Lead times (config.yaml planning.*) are the USER'S BUSINESS PLANNING ASSUMPTIONS,
NOT eBay requirements or ranking guarantees.

Usage:
  .\tools\seasonal_dates.ps1                         # today's UK date, print table
  .\tools\seasonal_dates.ps1 -Today 2026-12-15       # test another date
  .\tools\seasonal_dates.ps1 -OutputFile data\seasonal\2026-10-02_calendar.csv
  .\tools\seasonal_dates.ps1 -PassThru               # return row objects (for other tools)
#>
param(
    [string]$Today,
    [string]$CalendarFile,
    [string]$ConfigFile,
    [string]$OutputFile,
    [switch]$PassThru
)
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
$root = Split-Path $PSScriptRoot -Parent
if (-not $CalendarFile) { $CalendarFile = Join-Path $root 'data\event_calendar.yaml' }
if (-not $ConfigFile) { $ConfigFile = Join-Path $root 'config.yaml' }

$tz = [TimeZoneInfo]::FindSystemTimeZoneById('GMT Standard Time')
if ($Today) { $t = [DateTime]::ParseExact($Today, 'yyyy-MM-dd', $inv) }
else { $t = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz).Date }

# --- Lead times from config.yaml (planning block) -----------------------------
$cfg = Get-Content -Raw -LiteralPath $ConfigFile
function Get-Planning([string]$key) {
    $m = [regex]::Match($cfg, "(?m)^\s+$key\s*:\s*(\d+)")
    if (-not $m.Success) { throw "config.yaml planning.$key not found" }
    return [int]$m.Groups[1].Value
}
$PREF = Get-Planning 'preferred_listing_lead_days'
$MIN = Get-Planning 'minimum_listing_lead_days'

# --- Parse event_calendar.yaml (simple list of flat entries) ------------------
$entries = New-Object System.Collections.Generic.List[hashtable]
$cur = $null
foreach ($line in Get-Content -LiteralPath $CalendarFile) {
    $l = ($line -replace '\s+#.*$', '')
    if ($l -match '^\s*-\s+name:\s*(.+?)\s*$') { $cur = @{ name = $Matches[1].Trim('"') }; $entries.Add($cur); continue }
    if ($cur -and $l -match '^\s+(type|rule|date|anchor|main_start|main_end|priority):\s*(.+?)\s*$') {
        $cur[$Matches[1]] = $Matches[2].Trim('"')
    }
    if ($cur -and $l -match '^\s+themes:\s*\[(.*)\]') { $cur['themes'] = ($Matches[1] -split ',' | ForEach-Object { $_.Trim() }) -join ';' }
}

# --- Date rules -------------------------------------------------------------
function Get-Easter([int]$y) {
    $a = $y % 19; $b = [math]::Floor($y / 100); $c = $y % 100; $d = [math]::Floor($b / 4); $e = $b % 4
    $f = [math]::Floor(($b + 8) / 25); $g = [math]::Floor(($b - $f + 1) / 3); $h = (19 * $a + $b - $d - $g + 15) % 30
    $i = [math]::Floor($c / 4); $k = $c % 4; $l = (32 + 2 * $e + 2 * $i - $h - $k) % 7; $m = [math]::Floor(($a + 11 * $h + 22 * $l) / 451)
    $mo = [math]::Floor(($h + $l - 7 * $m + 114) / 31); $da = (($h + $l - 7 * $m + 114) % 31) + 1
    return [DateTime]::new($y, $mo, $da)
}
function Get-NthWeekday([int]$y, [int]$month, [DayOfWeek]$dow, [int]$n) {
    $d = [DateTime]::new($y, $month, 1)
    while ($d.DayOfWeek -ne $dow) { $d = $d.AddDays(1) }
    return $d.AddDays(7 * ($n - 1))
}
function Get-MonthDay([int]$y, [string]$md) {
    $p = $md -split '-'
    if ($p[1] -eq 'end') { return [DateTime]::new($y, [int]$p[0], [DateTime]::DaysInMonth($y, [int]$p[0])) }
    return [DateTime]::new($y, [int]$p[0], [int]$p[1])
}
function Get-EventDate([hashtable]$e, [int]$y) {
    switch ($e.rule) {
        'fixed' { return Get-MonthDay $y $e.date }
        'western_easter_sunday' { return Get-Easter $y }
        'easter_minus_21_days' { return (Get-Easter $y).AddDays(-21) }
        'third_sunday_june' { return Get-NthWeekday $y 6 ([DayOfWeek]::Sunday) 3 }
        'day_after_fourth_thursday_november' { return (Get-NthWeekday $y 11 ([DayOfWeek]::Thursday) 4).AddDays(1) }
        'monday_after_black_friday' { return (Get-NthWeekday $y 11 ([DayOfWeek]::Thursday) 4).AddDays(4) }
        default { throw "Unsupported rule '$($e.rule)' for '$($e.name)'" }
    }
}
function Get-Phase([int]$days) {
    if ($days -gt 60) { 'PREPARE_EARLY' } elseif ($days -ge 30) { 'START_NOW' } elseif ($days -ge 0) { 'LATE_EVENT_WINDOW' } else { 'POST_EVENT' }
}
function D([DateTime]$x) { $x.ToString('yyyy-MM-dd') }

# --- Resolve each entry -------------------------------------------------------
$rows = foreach ($e in $entries) {
    $prio = if ($e.ContainsKey('priority') -and $e.priority) { $e.priority } else { 'Not defined' }
    if ($e.type -eq 'window') {
        $occ = $null
        foreach ($y in @(($t.Year - 1), $t.Year, ($t.Year + 1))) {
            $ms = Get-MonthDay $y $e.main_start
            $endYear = if ([int]($e.main_end -split '-')[0] -lt $ms.Month) { $y + 1 } else { $y }
            $me = Get-MonthDay $endYear $e.main_end
            $ancYear = if ([int]($e.anchor -split '-')[0] -lt $ms.Month) { $y + 1 } else { $y }
            $anc = Get-MonthDay $ancYear $e.anchor
            if ($me -ge $t) { $occ = @{ s = $ms; e = $me; a = $anc }; break }
        }
        $prev = @{ e = $occ.e.AddYears(-1) }
        $days = ($occ.a - $t).Days
        if ($t -ge $occ.s -and $t -le $occ.e) { $phase = 'IN_SEASON'; $remain = ($occ.e - $t).Days } else { $phase = Get-Phase $days; $remain = 'N/A' }
        [pscustomobject][ordered]@{
            name = $e.name; type = 'window'; themes = $e.themes; priority = $prio
            event_date = 'N/A'; window_start = D $occ.s; window_end = D $occ.e; anchor_date = D $occ.a
            days_until = $days; preferred_listing_start = D $occ.a.AddDays(-$PREF); minimum_listing_start = D $occ.a.AddDays(-$MIN)
            phase = $phase; days_remaining_in_season = $remain
            last_occurrence_end = D $prev.e; days_since_last = ($t - $prev.e).Days
            role = ''
        }
    } else {
        $dt = Get-EventDate $e $t.Year
        if ($dt -lt $t) { $last = $dt; $dt = Get-EventDate $e ($t.Year + 1) } else { $last = Get-EventDate $e ($t.Year - 1) }
        $days = ($dt - $t).Days
        [pscustomobject][ordered]@{
            name = $e.name; type = 'event'; themes = $e.themes; priority = $prio
            event_date = D $dt; window_start = 'N/A'; window_end = 'N/A'; anchor_date = D $dt
            days_until = $days; preferred_listing_start = D $dt.AddDays(-$PREF); minimum_listing_start = D $dt.AddDays(-$MIN)
            phase = Get-Phase $days; days_remaining_in_season = 'N/A'
            last_occurrence_end = D $last; days_since_last = ($t - $last).Days
            role = ''
        }
    }
}

# --- Allocation role (CLAUDE.md §13 step 7, §16) ------------------------------
# CURRENT_EVENT: IN_SEASON, START_NOW or LATE_EVENT_WINDOW.
# NEXT_EVENT_PREPARATION: the earliest upcoming PREPARE_EARLY event/season.
# NOT_ALLOCATED: everything else (no share of today's mix).
$nextDays = ($rows | Where-Object phase -eq 'PREPARE_EARLY' | Measure-Object days_until -Minimum).Minimum
foreach ($r in $rows) {
    $r.role = if ($r.phase -in @('IN_SEASON', 'START_NOW', 'LATE_EVENT_WINDOW')) { 'CURRENT_EVENT' }
              elseif ($r.phase -eq 'PREPARE_EARLY' -and $r.days_until -eq $nextDays) { 'NEXT_EVENT_PREPARATION' }
              else { 'NOT_ALLOCATED' }
}
$rows = $rows | Sort-Object days_until
if ($PassThru) { return $rows }

"Seasonal Planning Engine - today (UK): $(D $t); lead times $PREF/$MIN days (user business planning assumption, not an eBay rule)"
if ($OutputFile) {
    $dir = Split-Path $OutputFile -Parent
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    if (Test-Path -LiteralPath $OutputFile) { throw "Output exists (append-only history, CLAUDE.md section 19): $OutputFile" }
    $rows | Export-Csv -LiteralPath $OutputFile -NoTypeInformation -Encoding UTF8
    "Written: $OutputFile"
}
$rows | Format-Table name, event_date, window_start, window_end, anchor_date, days_until, preferred_listing_start, minimum_listing_start, phase, days_remaining_in_season, priority, role -AutoSize | Out-String -Width 250
