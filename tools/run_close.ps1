<#
End-of-run check: proves the day is complete before it is reported as finished.
Usage: .\tools\run_close.ps1 -Date YYYY-MM-DD
#>
param([Parameter(Mandatory)][string]$Date, [string]$Root)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$script:bad = 0
function Say([bool]$ok, [string]$m) { if (-not $ok) { $script:bad++ }; "{0,-5} {1}" -f $(if ($ok) { 'OK' } else { 'FAIL' }), $m }
function Has([string]$p) { Test-Path -LiteralPath (Join-Path $Root $p) }
"Run close for $Date"
foreach ($f in "data\daily\${Date}_ebay_product_hunt.xlsx", "data\daily\${Date}_review.json", "data\daily\${Date}_candidates.csv", "data\daily\${Date}_rejections.csv", "data\daily\${Date}_seasonal_plan.md", "data\daily\${Date}_summary.md", "data\fees\${Date}_ebay_business_fees.csv") { Say (Has $f) $f }
$rj = Join-Path $Root "data\daily\${Date}_review.json"
if (Test-Path -LiteralPath $rj) {
    $j = [IO.File]::ReadAllText($rj, [Text.Encoding]::UTF8) | ConvertFrom-Json
    $eng = @{}; foreach ($pf in (Get-ChildItem -LiteralPath (Join-Path $Root 'data\profit') -Filter '*_profit.csv' | Sort-Object Name)) { foreach ($x in (Import-Csv -LiteralPath $pf.FullName)) { $eng["$($x.candidate_id)"] = $x } }
    $ps = ''; if (Has 'data\competitors\passing_sellers.csv') { $ps = [IO.File]::ReadAllText((Join-Path $Root 'data\competitors\passing_sellers.csv')) }
    $hist = @{}; if (Has 'data\history\status_log.csv') { foreach ($l in (Import-Csv -LiteralPath (Join-Path $Root 'data\history\status_log.csv'))) { if ($l.research_date -eq $Date) { $hist["$($l.candidate_id)"] = 1 } } }
    foreach ($s in @($j.selected)) {
        $e = $eng["$($s.id)"]
        Say ([bool]$e -and $e.acceptance_status -in 'PASS', 'EXCEPTION') "$($s.id): Profit Engine row is PASS or EXCEPTION"
        if ($e) { Say ($e.fee_category -ne 'UNKNOWN' -and "$($e.ebay_fee_rate_source)" -match [regex]::Escape($e.profit_date)) "$($s.id): fees were read on the calculation day ($($e.profit_date))" }
        if ($e -and "$($s.id)" -match '(20\d{2})(\d{2})(\d{2})') { Say ("$($Matches[1])-$($Matches[2])-$($Matches[3])" -le $e.profit_date) "$($s.id): not priced with fees older than the research day" }
        if ($Date -ge '2026-11-25') {
            $waived = ("$($s.source)" -eq 'AW Dropship' -and "$($s.exception)" -match '^EXCEPTION')
            Say ("$($s.lSource.Url)" -match '^https?://[^/]+/.{3,}') "$($s.id): sourcing product link"
            Say ($waived -or "$($s.lItem.Url)" -match 'ebay\.co\.uk/itm/') "$($s.id): eBay listing link"
            Say ([bool]"$($s.itemCode)" -and [bool]"$($s.variantCode)") "$($s.id): item code and variant code recorded (UNKNOWN counts as recorded)"
            foreach ($v in @($s.variants | Where-Object { $_ })) { Say ("$($v.result)" -match '^(PASS|EXCEPTION)') "$($v.vid) ($($v.vname)): variant passed the Profit Engine ($($v.result))" }
        }
        Say ($s.seller -and $ps.Contains(("$($s.seller)" -replace '\s*\(.*\)$', ''))) "$($s.id): reference seller saved in passing_sellers.csv ($($s.seller))"
    }
    Say (@($j.all | Where-Object { $_.cat -and -not $hist.ContainsKey("$($_.id)") -and "$($_.rule)" -notmatch '(?i)^duplicate' }).Count -eq 0) 'every evaluated product is in the product history'
}
$pg = Join-Path $Root 'data\review_page\ebay_daily_20.html'
Say ((Test-Path -LiteralPath $pg) -and [bool](Select-String -LiteralPath $pg -Pattern $Date -SimpleMatch -Quiet)) "review page includes $Date (publishing it is still a separate step)"
Say ((& (Join-Path $PSScriptRoot 'selftest.ps1') -Quiet -Root $Root) -eq 'PASS') 'regression tests pass'
if ($script:bad) { "RESULT: NOT COMPLETE ($($script:bad) item(s)). Fix them, or tell the user exactly which are missing." } else { 'RESULT: COMPLETE' }
