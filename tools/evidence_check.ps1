<#
Evidence check for browser research (prompts/stages/browser_research.md s5, s7; CLAUDE.md s26).

Before history ingest and the daily report, every important research value written to a stage file
must be backed by a row in data/evidence/YYYY-MM-DD_evidence_log.csv (same candidate_id + field,
access_status OK, status VERIFIED or ESTIMATED). This tool reports:
  UNEVIDENCED  value present in a stage file but no usable evidence row  -> evidence it or set it to UNKNOWN
  MISMATCH     stage value differs from the logged observed_value        -> correct the stage file
and summarises each site's access status (OK / LOGIN_REQUIRED / CAPTCHA / BLOCKED / ...).
It never edits any file and never browses. Exit code 1 if any UNEVIDENCED or MISMATCH is found.

Usage:  .\tools\evidence_check.ps1 -Date 2026-10-02 [-Root <project>]
#>
param([string]$Date, [string]$Root)
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
if (-not $Date) { $Date = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, [TimeZoneInfo]::FindSystemTimeZoneById('GMT Standard Time')).ToString('yyyy-MM-dd') }

function Test-Val($v) { $s = "$v".Trim(); return ($s -ne '' -and $s -notmatch '^(UNKNOWN|N/A|NA|none)$') }
function Norm($v) {
    $s = "$v".Trim() -replace ([string][char]0x00A3), '' -replace '^GBP\s*', ''
    $d = 0.0; if ([double]::TryParse($s.TrimEnd('%'), [Globalization.NumberStyles]::Float, $inv, [ref]$d)) { return $d.ToString('R', $inv) + $(if ($s.EndsWith('%')) { '%' } else { '' }) }
    return $s.ToLower()
}

# Key research fields per stage file (stage-file column names = evidence-log `field` values)
$FIELDS = [ordered]@{
    'data\sources\amazon_uk\{0}_amazon_uk_stage.csv' = @('amazon_price', 'amazon_current_price', 'keepa_max_held_price', 'keepa_max_held_days', 'top_fbm_seller', 'top_fbm_inventory', 'fbm_inventory_total', 'top_inventory_holder', 'top_inventory_holder_qty', 'stock_observed', 'sold_by', 'dispatched_from', 'seller_type', 'demand_amazon_label', 'demand_best_seller_rank', 'keepa_window_days', 'keepa_longest_gap_days', 'delivery_fastest_date', 'weight', 'variations_count', 'delivery_fee', 'offer_sellers', 'amazon_rating')
    'data\sources\aliexpress_uk\{0}_aliexpress_uk_stage.csv' = @('aliexpress_price', 'uk_shipping_cost', 'sales_count_shown', 'rating', 'review_count', 'delivery_estimate_shown', 'store_name', 'weight', 'variations_total_offered', 'choice_badge', 'store_positive_feedback', 'ship_from', 'other_fees')
    'data\sources\godropship_uk\{0}_godropship_uk_stage.csv' = @('source_price', 'per_order_fee', 'sales_evidence_shown', 'stock_shown', 'delivery_days', 'delivery_charge', 'weight', 'warehouse_location')
    'data\ebay\{0}_ebay_verification.csv' = @('sold_items_count', 'active_listings_count', 'str_value', 'seller_count', 'sold_price_total_median', 'reference_seller_name', 'reference_seller_url', 'reference_seller_store_url', 'reference_seller_price', 'fee_final_value_rate', 'fee_fixed_per_order', 'strong_seller_count', 'small_sellers_le_2k', 'sold_history_recent_sales')
}

$logPath = Join-Path $Root "data\evidence\${Date}_evidence_log.csv"
$log = if (Test-Path -LiteralPath $logPath) { @(Import-Csv -LiteralPath $logPath) } else { @() }
$ev = @{}
foreach ($e in $log) {
    if ("$($e.access_status)" -ne 'OK' -or "$($e.status)" -notin 'VERIFIED', 'ESTIMATED') { continue }
    $ev["$($e.candidate_id)|$($e.field)"] = $e      # last usable row for a field wins
}

$issues = New-Object System.Collections.Generic.List[object]
$checked = 0; $files = 0
foreach ($pattern in $FIELDS.Keys) {
    $p = Join-Path $Root ($pattern -f $Date)
    if (-not (Test-Path -LiteralPath $p)) { continue }
    $files++
    # Append-only files (CLAUDE.md s19): a later row for the same candidate is a dated correction and
    # supersedes earlier rows, so only the latest row per candidate is checked against the evidence log.
    $latest = [ordered]@{}; foreach ($r0 in Import-Csv -LiteralPath $p) { $latest["$($r0.candidate_id)"] = $r0 }
    foreach ($row in $latest.Values) {
        foreach ($f in $FIELDS[$pattern]) {
            if ($row.PSObject.Properties.Name -notcontains $f) { continue }
            $val = $row.$f
            if (-not (Test-Val $val)) { continue }      # UNKNOWN / N/A needs no evidence
            $checked++
            $k = "$($row.candidate_id)|$f"
            if (-not $ev.ContainsKey($k)) {
                $issues.Add([pscustomobject]@{ issue = 'UNEVIDENCED'; file = [IO.Path]::GetFileName($p); candidate_id = $row.candidate_id; field = $f; stage_value = $val; logged_value = ''; action = 'add evidence or set to UNKNOWN' })
            } elseif ((Norm $ev[$k].observed_value) -ne (Norm $val)) {
                $issues.Add([pscustomobject]@{ issue = 'MISMATCH'; file = [IO.Path]::GetFileName($p); candidate_id = $row.candidate_id; field = $f; stage_value = $val; logged_value = $ev[$k].observed_value; action = "correct stage value (evidence $($ev[$k].evidence_id))" })
            }
        }
    }
}

"Evidence check $Date : $files stage file(s), $checked evidenced-field value(s) checked, evidence log rows: $($log.Count)$(if (-not $log.Count) { ' (NO EVIDENCE LOG: browser research not recorded)' })"
if ($log.Count) {
    "Site access summary (from the evidence log):"
    $log | Group-Object site, access_status | Sort-Object Name | ForEach-Object { "  $($_.Name): $($_.Count)" }
}
if ($issues.Count) {
    $issues | Format-Table issue, file, candidate_id, field, stage_value, logged_value, action -AutoSize | Out-String -Width 250
    "RESULT: $(@($issues | Where-Object issue -eq 'UNEVIDENCED').Count) UNEVIDENCED, $(@($issues | Where-Object issue -eq 'MISMATCH').Count) MISMATCH - fix before history ingest and the daily report."
    exit 1
}
"RESULT: every checked value is backed by evidence."
exit 0
