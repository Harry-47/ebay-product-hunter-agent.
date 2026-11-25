<#
Start-of-run check. FAIL = fix before researching. WARN = carry on, but know about it.
Usage: .\tools\preflight.ps1 [-Date YYYY-MM-DD]
#>
param([string]$Date, [string]$Root)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$tz = [TimeZoneInfo]::FindSystemTimeZoneById('GMT Standard Time')
if (-not $Date) { $Date = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz).ToString('yyyy-MM-dd') }
$script:fails = 0
function Say([string]$lvl, [string]$m) { if ($lvl -eq 'FAIL') { $script:fails++ }; "{0,-5} {1}" -f $lvl, $m }
"Preflight for $Date (UK)"
$r = & (Join-Path $PSScriptRoot 'selftest.ps1') -Quiet -Root $Root
if ($r -eq 'PASS') { Say 'OK' 'all regression tests pass' } else { Say 'FAIL' 'a regression test fails: run tools\selftest.ps1, fix the script before using it' }
foreach ($x in @(@("data\fees\${Date}_ebay_business_fees.csv", 'eBay fee table (daily_hunt Step 5b)'), @("data\fees\${Date}_aliexpress_cost_factors.csv", 'AliExpress cost factors (Step 5a2)'), @("data\seasonal\${Date}_calendar.csv", 'seasonal calendar (Step 2)'))) {
    if (Test-Path -LiteralPath (Join-Path $Root $x[0])) { Say 'OK' $x[1] } else { Say 'FAIL' "$($x[1]) not recorded yet: $($x[0])" }
}
$os = Get-CimInstance Win32_OperatingSystem; $free = [math]::Round($os.FreePhysicalMemory / 1MB, 2); $commit = [math]::Round($os.FreeVirtualMemory / 1MB, 2)
if ($free -lt 0.5 -or $commit -lt 0.5) { Say 'WARN' "low memory: $free GB RAM free, $commit GB commit free. Use ONE tab, text reads instead of screenshots; tools\chrome_restart.ps1 if it freezes" }
else { Say 'OK' "memory: $free GB RAM free, $commit GB commit free" }
$gl = Join-Path $Root 'data\evidence\browser_guard_log.csv'
if (Test-Path -LiteralPath $gl) { $mem = @(Import-Csv -LiteralPath $gl | Select-Object -Last 400 | Where-Object { "$($_.PSObject.Properties.Value)" -match 'OutOfMemory|paging file' }).Count; if ($mem) { Say 'WARN' "$mem recent browser-guard errors were memory errors: the server needs more memory or a larger paging file (user action)" } }
$last = ''; $sl = Join-Path $Root 'data\history\status_log.csv'
if (Test-Path -LiteralPath $sl) { $last = (Import-Csv -LiteralPath $sl | Sort-Object research_date | Select-Object -Last 1).research_date }
foreach ($j in (Get-ChildItem -LiteralPath (Join-Path $Root 'data\daily') -Filter '*_review.json' | Where-Object { $_.Name -match '^(\d{4}-\d{2}-\d{2})_review' -and $Matches[1] -gt $last })) { Say 'FAIL' "$($j.Name) is not in the product history: tools\history.ps1 -Action IngestReview -Date $($j.Name.Substring(0,10))" }
& (Join-Path $PSScriptRoot 'lessons.ps1') -Action Open -Root $Root
if ($script:fails) { "RESULT: FAIL ($($script:fails) item(s) to fix first)" } else { 'RESULT: READY' }
