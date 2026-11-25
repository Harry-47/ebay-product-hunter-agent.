<#
Final decision and daily report (CLAUDE.md s16-s20). See prompts/daily_hunt.md, step 11-13.

Reads the day's stage files (hunters, eBay verification, Profit Engine, seasonal classification)
and the research history (run tools/history.ps1 -Action Ingest first), then writes:
  data/daily/YYYY-MM-DD_candidates.csv     accepted products (SELECTED) + qualified surplus (kept, flagged)
  data/daily/YYYY-MM-DD_rejections.csv     every rejection (one row per failed criterion), duplicates, incomplete
  data/daily/YYYY-MM-DD_seasonal_plan.md   seasonal planning summary
  data/daily/YYYY-MM-DD_summary.md         daily report
Existing daily files are never overwritten: a second run the same day writes YYYY-MM-DD_run2_* (s19).

It never invents data (UNKNOWN stays UNKNOWN), never scores or ranks by quality, and never buys or lists anything.

Usage:
  .\tools\daily_report.ps1 -Date 2026-10-02
  .\tools\daily_report.ps1 -Date 2026-10-02 -Evergreen 0.4 -CurrentEvent 0.4 -NextEvent 0.2 -AllocationReason "..."
  .\tools\daily_report.ps1 -Date 2026-10-02 -RunNotes "SOURCE_BLOCKED: godropship_uk (login wall)"
  .\tools\daily_report.ps1 -Date 2026-10-03 -DetailsOnly   # add the Rejection Details workbook to an already finished run
The workbook has a "Rejection Details" sheet: one row per failed rule, with the source, eBay and profit details
and every stored link (user request 2026-10-03). Presentation only. -DetailsOnly writes that sheet as a separate
<prefix>_rejection_details.xlsx for a run that has already finished (its files are never overwritten).
#>
param(
    [string]$Date,
    [string]$Root,
    [Nullable[double]]$Evergreen,
    [Nullable[double]]$CurrentEvent,
    [Nullable[double]]$NextEvent,
    [string]$AllocationReason,
    [string]$RunNotes,
    [switch]$DetailsOnly   # write only <prefix>_rejection_details.xlsx for the latest finished run (no other file is written)
)
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$tz = [TimeZoneInfo]::FindSystemTimeZoneById('GMT Standard Time')
$nowUk = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz)
if (-not $Date) { $Date = $nowUk.ToString('yyyy-MM-dd') }

function Test-Val($v) { $s = "$v".Trim(); return ($s -ne '' -and $s -notmatch '^(UNKNOWN|N/A|NA|none)$') }
function Get-Col($row, [string]$n) { if ($null -ne $row -and $row.PSObject.Properties.Name -contains $n) { return $row.$n } return $null }
function V($x) { if (Test-Val $x) { return "$x" } elseif ("$x".Trim() -eq 'N/A') { return 'N/A' } return 'UNKNOWN' }
function PctTxt($x) { $s = V $x; if ($s -in 'N/A', 'UNKNOWN') { return $s } return "$s%" }
# roi_bypassed exists only in profit rows before formula v5 (the GBP 2 bypass was removed 2026-10-03).
function RoiBypass($pr) { if ($null -ne $pr -and $pr.PSObject.Properties.Name -contains 'roi_bypassed') { return (V $pr.roi_bypassed) } return 'N/A' }
function Read-Csv([string]$p) { if (Test-Path -LiteralPath $p) { return @(Import-Csv -LiteralPath $p) } return @() }
function Last-ById($rows) { $m = @{}; foreach ($x in $rows) { $m[$x.candidate_id] = $x }; return $m }
function Num($x) { $d = 0.0; if ([double]::TryParse("$x", [Globalization.NumberStyles]::Float, $inv, [ref]$d)) { return $d } return $null }

# --- Settings -----------------------------------------------------------------
$cfg = Get-Content -Raw -LiteralPath (Join-Path $Root 'config.yaml')
function Cfg([string]$pattern) { $m = [regex]::Match($cfg, $pattern); if ($m.Success) { return $m.Groups[1].Value } throw "config.yaml: $pattern not found" }
$PER_SOURCE = [int](Cfg '(?m)^daily_quota_per_source:\s*(\d+)')
$TOTAL = [int](Cfg '(?m)^total_daily_target:\s*(\d+)')
$defEv = [double]::Parse((Cfg '(?m)^\s+evergreen:\s*([\d.]+)'), $inv)
$defCur = [double]::Parse((Cfg '(?m)^\s+current_event:\s*([\d.]+)'), $inv)
$defNext = [double]::Parse((Cfg '(?m)^\s+next_event_preparation:\s*([\d.]+)'), $inv)
$mixEv = if ($null -ne $Evergreen) { $Evergreen } else { $defEv }
$mixCur = if ($null -ne $CurrentEvent) { $CurrentEvent } else { $defCur }
$mixNext = if ($null -ne $NextEvent) { $NextEvent } else { $defNext }
$mixChanged = ($mixEv -ne $defEv -or $mixCur -ne $defCur -or $mixNext -ne $defNext)
if ($mixChanged -and -not (Test-Val $AllocationReason)) { throw 'Allocation differs from the 50/30/20 default: -AllocationReason is required (CLAUDE.md s16).' }
if ([math]::Abs($mixEv + $mixCur + $mixNext - 1) -gt 0.001) { throw 'Allocation shares must add up to 1.' }
$tCur = [int][math]::Round($TOTAL * $mixCur); $tNext = [int][math]::Round($TOTAL * $mixNext); $tEv = $TOTAL - $tCur - $tNext
$bucketTarget = @{ evergreen = $tEv; current_event = $tCur; next_event_preparation = $tNext }

# --- Output paths (never overwrite, s19) --------------------------------------
$dailyDir = Join-Path $Root 'data\daily'
if (-not (Test-Path -LiteralPath $dailyDir)) { New-Item -ItemType Directory -Path $dailyDir | Out-Null }
function Get-WorkbookName([int]$k) { if ($k -eq 1) { "${Date}_ebay_product_hunt.xlsx" } else { "${Date}_ebay_product_hunt_run$k.xlsx" } }
$prefix = $Date; $n = 1
while ((Test-Path -LiteralPath (Join-Path $dailyDir "${prefix}_summary.md")) -or (Test-Path -LiteralPath (Join-Path $dailyDir (Get-WorkbookName $n)))) { $n++; $prefix = "${Date}_run$n" }
if ($DetailsOnly) {
    if ($n -eq 1) { throw "No finished run for ${Date}: run the full report first." }
    $n--; $prefix = if ($n -eq 1) { $Date } else { "${Date}_run$n" }
}
$fXlsx = Join-Path $dailyDir (Get-WorkbookName $n)
$fDet = Join-Path $dailyDir "${prefix}_rejection_details.xlsx"
if ($DetailsOnly -and (Test-Path -LiteralPath $fDet)) { throw "Already exists (never overwritten): $fDet" }
$fCand = Join-Path $dailyDir "${prefix}_candidates.csv"; $fRej = Join-Path $dailyDir "${prefix}_rejections.csv"
$fPlan = Join-Path $dailyDir "${prefix}_seasonal_plan.md"; $fSum = Join-Path $dailyDir "${prefix}_summary.md"

# --- Load stage data ------------------------------------------------------------
$SRC = [ordered]@{
    amazon_uk = @{ label = 'Amazon UK'; url = 'amazon_url'; price = 'amazon_price'; stock = 'stock_observed'; rating = 'amazon_rating'; sales = @('demand_amazon_label', 'demand_best_seller_rank'); delivery = 'delivery_days'; seller = 'seller_type'; vars = 'variations_count'; gtin = 'ean_gtin' }
    aliexpress_uk = @{ label = 'AliExpress UK'; url = 'aliexpress_url'; price = 'aliexpress_price'; stock = $null; rating = 'rating'; sales = @('sales_count_shown', 'sales_period_shown'); delivery = 'delivery_days_max'; seller = 'store_name'; vars = 'variations_listed_count'; gtin = $null }
    godropship_uk = @{ label = 'Go Dropship UK'; url = 'godropship_url'; price = 'source_price'; stock = 'stock_shown'; rating = $null; sales = @('sales_evidence_shown', 'sales_period_shown'); delivery = 'delivery_days'; seller = $null; vars = 'variations_count'; gtin = 'ean_gtin' }
    # Morrisons UK removed 2026-10-03 (dropshipping from Morrisons not allowed).
}
$hunter = [ordered]@{}; $huntCount = @{}
foreach ($s in $SRC.Keys) {
    $rows = Read-Csv (Join-Path $Root "data\sources\$s\${Date}_${s}_stage.csv")
    $huntCount[$s] = @{ evaluated = @($rows).Count; forwarded = @($rows | Where-Object { $_.proceed_to_ebay -ne 'NO' }).Count; file = (@($rows).Count -gt 0) }
    foreach ($r in $rows) { $hunter[$r.candidate_id] = @{ row = $r; src = $s } }
}
$ebay = Last-ById (Read-Csv (Join-Path $Root "data\ebay\${Date}_ebay_verification.csv"))
$prof = Last-ById (Read-Csv (Join-Path $Root "data\profit\${Date}_profit.csv"))
$seas = Last-ById (Read-Csv (Join-Path $Root "data\seasonal\${Date}_seasonal_classification.csv"))
$histLog = @(Read-Csv (Join-Path $Root 'data\history\status_log.csv'))
$histToday = Last-ById ($histLog | Where-Object { $_.research_date -eq $Date })
$histRej = @(Read-Csv (Join-Path $Root 'data\history\rejection_history.csv') | Where-Object { $_.rejected_on -eq $Date })
$historyMissing = ($histToday.Count -eq 0 -and $hunter.Count -gt 0)
$calendar = & (Join-Path $PSScriptRoot 'seasonal_dates.ps1') -Today $Date -PassThru

# --- Final decision per forwarded candidate -------------------------------------
$eligible = New-Object System.Collections.Generic.List[object]
$incomplete = New-Object System.Collections.Generic.List[object]
foreach ($cid in $hunter.Keys) {
    # NB: PowerShell names are case-insensitive; never name a variable $src (it would overwrite $SRC).
    $h = $hunter[$cid].row; $srcName = $hunter[$cid].src
    if ("$($h.proceed_to_ebay)" -eq 'NO') { continue }                      # rejected at source: in history rejections
    $er = $ebay[$cid]; $pr = $prof[$cid]; $sr = $seas[$cid]
    $final = 'UNKNOWN'; $why = ''
    if ($sr) { $final = "$($sr.overall_status)".ToUpper() }
    elseif ($pr) { $why = 'seasonal classification not run'; if ("$($pr.acceptance_status)" -eq 'FAIL') { $final = 'FAIL' } }
    elseif ($er) { if ("$($er.ebay_verification_status)" -eq 'FAIL' -or "$($er.proceed_to_profit)" -eq 'NO') { $final = 'FAIL' } else { $why = 'Profit Engine not run' } }
    else { $why = 'eBay verification not run' }
    if ($final -in 'PASS', 'EXCEPTION') {
        $pk = if ($histToday.ContainsKey($cid)) { $histToday[$cid].product_key } else { "UNLINKED:$cid" }
        $eligible.Add(@{ cid = $cid; src = $srcName; h = $h; er = $er; pr = $pr; sr = $sr; final = $final; pk = $pk
                bucket = $(if ($sr) { "$($sr.allocation_bucket)" } else { 'UNKNOWN' }); basis = $(if ($pr) { "$($pr.acceptance_basis)" } else { 'UNKNOWN' })
                profit = $(if ($pr) { Num $pr.profit } else { $null }) })
    } elseif ($final -ne 'FAIL') {
        $unk = @(); if ($pr -and (Test-Val $pr.unknown_inputs)) { $unk += "unknown inputs: $($pr.unknown_inputs)" }
        if ($sr -and "$($sr.timing_status)" -eq 'UNKNOWN') { $unk += 'seasonal timing UNKNOWN' }
        if ($why) { $unk += $why }
        $incomplete.Add(@{ cid = $cid; src = $srcName; h = $h; er = $er; reason = $(if ($unk.Count) { $unk -join '; ' } else { 'final status UNKNOWN' }) })
    }
}

# --- Cross-source duplicates (s18): keep the strongest option, flag the rest -----
$dupes = New-Object System.Collections.Generic.List[object]
$groups = $eligible | Group-Object { $_.pk }
$kept = New-Object System.Collections.Generic.List[object]
foreach ($g in $groups) {
    if ($g.Count -eq 1 -or "$($g.Name)" -like 'UNLINKED:*') { foreach ($x in $g.Group) { $kept.Add($x) }; continue }
    # Strongest = higher calculated profit (UNKNOWN lowest); VERIFIED basis before ESTIMATED on a tie.
    $sorted = @($g.Group | Sort-Object @{ Expression = { if ($null -ne $_.profit) { $_.profit } else { -1e9 } }; Descending = $true }, @{ Expression = { if ($_.basis -eq 'VERIFIED') { 0 } else { 1 } } })
    $kept.Add($sorted[0])
    foreach ($d in $sorted[1..($sorted.Count - 1)]) { $dupes.Add(@{ x = $d; keptCid = $sorted[0].cid; keptSrc = $sorted[0].src; keptProfit = $sorted[0].profit }) }
}

# --- Daily selection: max PER_SOURCE per source, filling the allocation buckets --
# Order inside a source: bucket still needed > VERIFIED before ESTIMATED > research order. No quality score is used.
$bucketLeft = @{} + $bucketTarget
$selected = @{}; foreach ($s in $SRC.Keys) { $selected[$s] = New-Object System.Collections.Generic.List[object] }
$surplus = New-Object System.Collections.Generic.List[object]
$ordered = @($kept | Sort-Object @{ Expression = { if ($_.basis -eq 'VERIFIED') { 0 } else { 1 } } }, @{ Expression = { $_.cid } })
foreach ($pass in 1, 2) {
    foreach ($x in $ordered) {
        if ($x.sel) { continue }
        if ($x.bucket -notin 'evergreen', 'current_event', 'next_event_preparation') { continue }
        if ($selected[$x.src].Count -ge $PER_SOURCE) { continue }
        if ($pass -eq 1 -and $bucketLeft[$x.bucket] -le 0) { continue }
        $x.sel = $(if ($pass -eq 1) { 'SELECTED' } else { 'SELECTED_OVER_BUCKET_TARGET' }); $bucketLeft[$x.bucket]--; $selected[$x.src].Add($x)
    }
}
foreach ($x in $ordered) {
    if ($x.sel) { continue }
    $x.sel = if ($x.bucket -notin 'evergreen', 'current_event', 'next_event_preparation') { 'SURPLUS_NOT_ALLOCATED' } else { 'SURPLUS_OVER_SOURCE_TARGET' }
    $surplus.Add($x)
}

# --- candidates.csv ------------------------------------------------------------
function New-CandRow($x) {
    $h = $x.h; $er = $x.er; $pr = $x.pr; $sr = $x.sr; $m = $SRC[$x.src]
    $sales = (@($m.sales | ForEach-Object { Get-Col $h $_ } | Where-Object { Test-Val $_ }) -join '; ')
    $ev = @((Get-Col $h $m.url), (Get-Col $er 'ebay_sold_search_url'), (Get-Col $er 'reference_seller_url')) | Where-Object { Test-Val $_ }
    $feeTxt = if ($pr -and (Test-Val $pr.ebay_fee_amount)) { "GBP $($pr.ebay_fee_amount) ($($pr.ebay_fee_rate_pct)% $($pr.ebay_fee_rate_status); fixed $($pr.ebay_fixed_fee) $($pr.ebay_fixed_fee_status))" } else { 'UNKNOWN' }
    $exc = @((Get-Col $h 'exceptions'), (Get-Col $er 'exceptions'), (Get-Col $pr 'exceptions'), (Get-Col $sr 'exceptions')) | Where-Object { (Test-Val $_) -and $_ -notmatch '^\s*(upstream:\s*)?none\s*$' } | Select-Object -Unique
    [pscustomobject][ordered]@{
        date_found = V (Get-Col $h 'date_found'); candidate_id = $x.cid; product_key = $x.pk; source = $m.label
        product_name = V $h.product_name; source_url = V (Get-Col $h $m.url); source_price = V (Get-Col $h $m.price)
        source_stock = $(if ($m.stock) { V (Get-Col $h $m.stock) } else { 'N/A' }); source_rating = $(if ($m.rating) { V (Get-Col $h $m.rating) } else { 'N/A' })
        source_sales = $(if ($sales) { $sales } else { 'UNKNOWN' }); source_delivery = V (Get-Col $h $m.delivery)
        source_seller_type = $(if ($m.seller) { V (Get-Col $h $m.seller) } else { 'N/A' })
        ebay_search_url = V (Get-Col $er 'ebay_sold_search_url'); ebay_example_seller = V (Get-Col $er 'reference_seller_name')
        ebay_seller_link = V (Get-Col $er 'reference_seller_url'); ebay_seller_price = V (Get-Col $er 'reference_seller_price')
        ebay_sold_price = V (Get-Col $er 'sold_price_total_median'); ebay_average_price = V (Get-Col $er 'sold_price_total_mean')
        ebay_sell_through_rate = "$(V (Get-Col $er 'str_value')) ($(V (Get-Col $er 'str_source')); $(V (Get-Col $er 'str_status')))"
        ebay_seller_count = V (Get-Col $er 'seller_count'); ebay_sales_last_30d = V (Get-Col $er 'sold_items_count')
        small_seller_evidence = "<=2k: $(V (Get-Col $er 'small_sellers_le_2k')); 2k-4k: $(V (Get-Col $er 'small_sellers_2k_to_4k')); status $(V (Get-Col $er 'small_sellers_status'))"
        ebay_fees = $feeTxt; ad_rate = "$(V (Get-Col $pr 'ad_rate_pct'))%"; estimated_total_cost = V (Get-Col $pr 'total_cost')
        minimum_listing_price = V (Get-Col $pr 'minimum_listing_price'); max_safe_cost = V (Get-Col $pr 'max_safe_cost'); cost_buffer_gate = V (Get-Col $pr 'cost_buffer_gate'); price_watch = V (Get-Col $pr 'price_watch'); thin_margin_flag = V (Get-Col $pr 'thin_margin_flag'); suggested_listing_price = V (Get-Col $pr 'listed_price')
        estimated_profit = V (Get-Col $pr 'profit'); profit_margin = "$(V (Get-Col $pr 'profit_pct'))%"; roi = "$(V (Get-Col $pr 'roi_pct'))%"
        roi_minimum = PctTxt (Get-Col $pr 'roi_min_pct'); roi_bypassed = RoiBypass $pr
        calculation_status = V (Get-Col $pr 'calculation_status')
        variations = V (Get-Col $h $m.vars); weight = V (Get-Col $h 'weight'); seasonality = V (Get-Col $sr 'seasonality')
        product_type = V (Get-Col $sr 'product_type'); target_event = V (Get-Col $sr 'target_event'); event_date = V (Get-Col $sr 'event_date')
        preferred_listing_start = V (Get-Col $sr 'preferred_listing_start'); minimum_listing_start = V (Get-Col $sr 'minimum_listing_start')
        days_until_event = V (Get-Col $sr 'days_until_event'); seasonal_phase = V (Get-Col $sr 'seasonal_phase')
        recommended_action = V (Get-Col $sr 'recommended_action'); seasonal_confidence = V (Get-Col $sr 'seasonal_confidence')
        allocation_bucket = $x.bucket; compliance_status = V (Get-Col $h 'compliance_status')
        acceptance_status = $(if ($x.final -eq 'EXCEPTION') { 'EXCEPTION' } elseif ($x.basis -eq 'ESTIMATED') { 'PASS (ESTIMATED)' } else { 'PASS' })
        criteria_relaxed = $(if (@($exc).Count) { "EXCEPTION: $(@($exc) -join ' | ')" } else { 'none' })
        rejection_risk = (@((Get-Col $er 'rejection_risk'), (Get-Col $h 'risks')) | Where-Object { Test-Val $_ }) -join ' | '
        evidence_urls = (@($ev) -join ' ; '); confidence = V (Get-Col $er 'confidence'); daily_selection = $x.sel
        history_status = $(if ($histToday.ContainsKey($x.cid)) { $histToday[$x.cid].status } else { 'UNKNOWN (history not ingested)' })
        notes = V (Get-Col $h 'notes')
    }
}
$allSel = @($SRC.Keys | ForEach-Object { $selected[$_] } | ForEach-Object { $_ })
$candRows = @($allSel | ForEach-Object { New-CandRow $_ }) + @($surplus | ForEach-Object { New-CandRow $_ })
if ($DetailsOnly) { } elseif ($candRows.Count) { $candRows | Export-Csv -LiteralPath $fCand -NoTypeInformation -Encoding UTF8 }
else { 'date_found,candidate_id,product_key,source,product_name,daily_selection,notes' | Set-Content -LiteralPath $fCand -Encoding UTF8 }

# --- rejections.csv ------------------------------------------------------------
$rejRows = New-Object System.Collections.Generic.List[object]
foreach ($r in $histRej) {
    $rejRows.Add([pscustomobject][ordered]@{
        date = $r.rejected_on; outcome = 'REJECTED'; candidate_id = $r.candidate_id; product_key = $r.product_key
        source = $(if ($SRC.Contains($r.source)) { $SRC[$r.source].label } else { $r.source }); product_name = $r.product_name; source_url = $r.source_url; ebay_url = $r.ebay_url
        failed_gate = "$($r.stage)/$($r.failed_criterion)"; observed_value = $r.observed_value; threshold = $r.threshold; rejection_reason = $r.rejection_reason
        evidence_urls = $r.evidence; failure_may_change = $r.failure_may_change; change_triggers = $r.change_triggers
        resulting_status = $r.resulting_status; recheck_due = $r.recheck_due; product_type = $r.product_type; seasonality = $r.seasonality
        target_event = $r.target_event; seasonal_phase = $r.seasonal_phase; notes = $r.notes })
}
foreach ($d in $dupes) {
    $x = $d.x
    $rejRows.Add([pscustomobject][ordered]@{
        date = $Date; outcome = 'DUPLICATE'; candidate_id = $x.cid; product_key = $x.pk; source = $SRC[$x.src].label; product_name = $x.h.product_name
        source_url = V (Get-Col $x.h $SRC[$x.src].url); ebay_url = V (Get-Col $x.er 'reference_seller_url'); failed_gate = 'DUPLICATE'
        observed_value = "profit $(V (Get-Col $x.pr 'profit'))"; threshold = "kept $($d.keptCid) ($($SRC[$d.keptSrc].label), profit $(if ($null -ne $d.keptProfit) { $d.keptProfit } else { 'UNKNOWN' }))"
        rejection_reason = 'Same product qualified from another source; strongest option kept (s18). Compare economics before discarding.'
        evidence_urls = V (Get-Col $x.h $SRC[$x.src].url); failure_may_change = 'YES'; change_triggers = 'kept option becomes unavailable or economics change'
        resulting_status = $(if ($histToday.ContainsKey($x.cid)) { $histToday[$x.cid].status } else { 'UNKNOWN' }); recheck_due = ''
        product_type = V (Get-Col $x.sr 'product_type'); seasonality = V (Get-Col $x.sr 'seasonality'); target_event = V (Get-Col $x.sr 'target_event')
        seasonal_phase = V (Get-Col $x.sr 'seasonal_phase'); notes = 'Qualified; not a quality failure.' })
}
foreach ($x in $incomplete) {
    $rejRows.Add([pscustomobject][ordered]@{
        date = $Date; outcome = 'NOT_ACCEPTED_UNKNOWN'; candidate_id = $x.cid; product_key = $(if ($histToday.ContainsKey($x.cid)) { $histToday[$x.cid].product_key } else { 'UNKNOWN' })
        source = $SRC[$x.src].label; product_name = $x.h.product_name; source_url = V (Get-Col $x.h $SRC[$x.src].url); ebay_url = V (Get-Col $x.er 'reference_seller_url')
        failed_gate = 'UNKNOWN_DATA'; observed_value = $x.reason; threshold = 'all gates must be verified or estimated'; rejection_reason = 'Not accepted: required data UNKNOWN (not a failure).'
        evidence_urls = V (Get-Col $x.h $SRC[$x.src].url); failure_may_change = 'YES'; change_triggers = 'missing data becomes available'
        resulting_status = $(if ($histToday.ContainsKey($x.cid)) { $histToday[$x.cid].status } else { 'UNKNOWN' }); recheck_due = $(if ($histToday.ContainsKey($x.cid)) { $histToday[$x.cid].recheck_due } else { '' })
        product_type = 'UNKNOWN'; seasonality = 'UNKNOWN'; target_event = 'UNKNOWN'; seasonal_phase = 'UNKNOWN'; notes = '' })
}
if ($DetailsOnly) { } elseif ($rejRows.Count) { $rejRows | Export-Csv -LiteralPath $fRej -NoTypeInformation -Encoding UTF8 }
else { 'date,outcome,candidate_id,source,product_name,failed_gate,notes' | Set-Content -LiteralPath $fRej -Encoding UTF8 }

# --- seasonal_plan.md ----------------------------------------------------------
$md = New-Object System.Text.StringBuilder
function L([string]$s = '') { [void]$md.AppendLine($s) }
L "# Seasonal planning summary - $Date"; L
L "Generated $($nowUk.ToString('yyyy-MM-dd HH:mm')) UK. Source: data/event_calendar.yaml via tools/seasonal_dates.ps1."; L
L '> The 60-day preferred and 30-day minimum listing lead times are the user''s **business planning assumption**, not an eBay requirement or ranking guarantee.'; L
L '| Event / season | Date or window | Days until | Preferred start | Minimum start | Phase | Days left in season | Priority | Role |'
L '|---|---|---|---|---|---|---|---|---|'
foreach ($c in $calendar) {
    $when = if ($c.type -eq 'window') { "$($c.window_start) to $($c.window_end) (anchor $($c.anchor_date))" } else { $c.event_date }
    L "| $($c.name) | $when | $($c.days_until) | $($c.preferred_listing_start) | $($c.minimum_listing_start) | $($c.phase) | $($c.days_remaining_in_season) | $($c.priority) | $($c.role) |"
}
L; L '## Allocation'
L "- Mix used: evergreen $([math]::Round($mixEv*100))% / current event $([math]::Round($mixCur*100))% / next-event preparation $([math]::Round($mixNext*100))% of $TOTAL = $tEv / $tCur / $tNext products."
L "- $(if ($mixChanged) { "ADJUSTED from the 50/30/20 default. Reason: $AllocationReason" } else { 'Default 50/30/20 mix (no adjustment).' })"
L "- Current events: $((@($calendar | Where-Object role -eq 'CURRENT_EVENT' | ForEach-Object { $_.name }) -join ', '))"
L "- Next-event preparation: $((@($calendar | Where-Object role -eq 'NEXT_EVENT_PREPARATION' | ForEach-Object { $_.name }) -join ', '))"
L '- Priority is shown only where explicitly set in data/event_calendar.yaml; otherwise "Not defined". It does not change the allocation.'
if (-not $DetailsOnly) { [IO.File]::WriteAllText($fPlan, $md.ToString(), (New-Object Text.UTF8Encoding($true))) }

# --- summary.md ----------------------------------------------------------------
$md = New-Object System.Text.StringBuilder
L "# Daily product hunt - $Date"; L
L "Report generated $($nowUk.ToString('yyyy-MM-dd HH:mm')) UK. Research files: data/sources, data/ebay, data/profit, data/seasonal ($Date)."
L 'Research only: nothing was purchased, listed or published. Retailer-sourced items stay COMPLIANCE_REVIEW until the user clears them (CLAUDE.md s22-s25).'; L
if ($historyMissing) { L '> WARNING: research history was not ingested for this date (run tools/history.ps1 -Action Ingest first). Product keys and statuses are UNKNOWN.'; L }
if (Test-Val $RunNotes) { L '## Run notes (blocked sources, conflicts, CHANGE_PROPOSALs)'; L "- $RunNotes"; L } else { L '## Run notes'; L '- No blocked sources, conflicts or CHANGE_PROPOSALs recorded for this run.'; L }

L '## Seasonal plan'
L "See $([IO.Path]::GetFileName($fPlan)). Mix: $tEv evergreen / $tCur current event / $tNext next-event preparation. $(if ($mixChanged) { "ADJUSTED: $AllocationReason" } else { 'Default 50/30/20.' })"; L

L "## Target vs actual (target $PER_SOURCE per source, $TOTAL total; a target, not a quota to fill)"
L '| Source | Evaluated | Forwarded to eBay | Qualified | Selected | Target | Shortfall |'
L '|---|---|---|---|---|---|---|'
$totSel = 0
foreach ($s in $SRC.Keys) {
    $q = @($kept | Where-Object { $_.src -eq $s }).Count; $sel = $selected[$s].Count; $totSel += $sel
    $ev = if ($huntCount[$s].file) { $huntCount[$s].evaluated } else { '0 (no stage file)' }
    L "| $($SRC[$s].label) | $ev | $($huntCount[$s].forwarded) | $q | $sel | $PER_SOURCE | $([math]::Max(0, $PER_SOURCE - $sel)) |"
}
L "| **Total** | | | $($kept.Count) | **$totSel** | $TOTAL | **$([math]::Max(0, $TOTAL - $totSel))** |"; L
L '| Allocation bucket | Target | Selected |'; L '|---|---|---|'
foreach ($b in 'evergreen', 'current_event', 'next_event_preparation') { L "| $b | $($bucketTarget[$b]) | $(@($allSel | Where-Object { $_.bucket -eq $b }).Count) |" }
$overB = @($allSel | Where-Object { $_.sel -eq 'SELECTED_OVER_BUCKET_TARGET' }).Count
if ($overB) { L; L "- $overB product(s) were selected above their bucket target because other buckets had no qualified products; the actual mix therefore differs from the target mix." }
L

L '## Shortfalls'
$any = $false
foreach ($s in $SRC.Keys) {
    $sel = $selected[$s].Count
    if ($sel -lt $PER_SOURCE) {
        $any = $true
        $reasons = @($histRej | Where-Object { $_.source -eq $s } | Group-Object failed_criterion | Sort-Object Count -Descending | Select-Object -First 3 | ForEach-Object { "$($_.Name) x$($_.Count)" })
        $inc = @($incomplete | Where-Object { $_.src -eq $s }).Count
        $why = @(); if (-not $huntCount[$s].file) { $why += 'no stage file (source not researched or blocked)' }
        if ($reasons.Count) { $why += "main rejections: $($reasons -join ', ')" }; if ($inc) { $why += "$inc incomplete (UNKNOWN data)" }
        L "- **$($SRC[$s].label)**: $sel of $PER_SOURCE ($($PER_SOURCE - $sel) short). $(if ($why.Count) { $why -join '; ' } else { 'not enough products qualified' }). Not padded."
    }
}
foreach ($b in 'evergreen', 'current_event', 'next_event_preparation') {
    $got = @($allSel | Where-Object { $_.bucket -eq $b }).Count
    if ($got -lt $bucketTarget[$b]) { $any = $true; L "- Bucket **$b**: $got of $($bucketTarget[$b])." }
}
if (-not $any) { L '- None.' }; L

L '## Accepted products (selected)'
if ($allSel.Count) {
    L 'Not scored: CLAUDE.md s18 defines score weights but no sub-score method, so no score is invented. Listed by source.'; L
    L '| Source | Product | Item cost | eBay price | Profit | Margin | ROI | Margin rule | Calc | Status | Bucket | Compliance |'
    L '|---|---|---|---|---|---|---|---|---|---|---|---|'
    foreach ($x in $allSel) {
        $pr = $x.pr
        $st = if ($x.final -eq 'EXCEPTION') { 'EXCEPTION' } elseif ($x.basis -eq 'ESTIMATED') { 'PASS (ESTIMATED)' } else { 'PASS' }
        # Margin rule (formula v8, 2026-10-08): under GBP 8 -> N/A; GBP 8+ -> 30% margin, or 20% ROI with a "margin under 30%" note.
        $mr = if ("$(Get-Col $pr 'notes')" -match 'less than 30%') { 'under 30%, passed on 20%+ ROI' } elseif (Test-Val (Get-Col $pr 'margin_gate')) { "$($pr.margin_gate) (min $(PctTxt $pr.margin_min_pct))" } elseif ("$(Get-Col $pr 'margin_gate')" -eq 'N/A') { 'N/A (under GBP 8)' } else { "older rule: ROI min $(PctTxt $pr.roi_min_pct)" }
        L "| $($SRC[$x.src].label) | $($x.h.product_name) | $(V (Get-Col $x.h $SRC[$x.src].price)) | $(V $pr.listed_price) | $(V $pr.profit) | $(V $pr.profit_pct)% | $(V $pr.roi_pct)% | $mr | $(V $pr.calculation_status) | $st | $($x.bucket) | $(V $x.h.compliance_status) |"
    }
} else { L '- None today.' }
L
if ($surplus.Count) {
    L '## Qualified but not selected (kept, not discarded)'
    foreach ($x in $surplus) { L "- $($SRC[$x.src].label): $($x.h.product_name) - $($x.sel)" }; L
}

L '## Main rejection reasons'
if ($histRej.Count) { foreach ($g in ($histRej | Group-Object { "$($_.stage)/$($_.failed_criterion)" } | Sort-Object Count -Descending)) { L "- $($g.Name): $($g.Count)" } } else { L '- None recorded.' }
L "- Duplicates flagged: $($dupes.Count); incomplete (UNKNOWN data, not accepted): $($incomplete.Count)"; L

L '## Compliance-review items'
$cr = @($allSel + $surplus | Where-Object { "$($_.h.compliance_status)" -ne 'PASS' })
if ($cr.Count) { foreach ($x in $cr) { L "- $($SRC[$x.src].label): $($x.h.product_name) - $(V $x.h.compliance_status) (user must clear before any action, s22-s23)" } } else { L '- None.' }; L

L '## ESTIMATED results and EXCEPTIONS'
$est = @($allSel | Where-Object { $_.basis -eq 'ESTIMATED' }); $exs = @($allSel | Where-Object { $_.final -eq 'EXCEPTION' })
L "- ESTIMATED (assumed inputs, not observed): $(if ($est.Count) { ($est | ForEach-Object { $_.h.product_name }) -join '; ' } else { 'none' })"
L "- EXCEPTION (user approval needed before any action): $(if ($exs.Count) { ($exs | ForEach-Object { $_.h.product_name }) -join '; ' } else { 'none' })"; L

L '## Lifecycle / status changes (research history)'
$chg = @($histLog | Where-Object { $_.research_date -eq $Date -and (Test-Val $_.previous_status) -and $_.previous_status -ne $_.status })
if ($chg.Count) { foreach ($c in $chg) { L "- $($c.product_name): $($c.previous_status) -> $($c.status) ($($c.reason))" } } else { L '- No status changes for previously researched products.' }
$attn = @($histLog | Where-Object { $_.research_date -eq $Date -and $_.status -in 'APPROVED', 'LISTING_READY', 'LISTED' -and $_.recommended_status -ne $_.status })
if ($attn.Count) { L; L '**Needs the user''s attention** (user status kept; agent recommends a change):'; foreach ($c in $attn) { L "- $($c.product_name): $($c.status) -> recommended $($c.recommended_status)" } }
L
L '## Files'
L "- Accepted: $([IO.Path]::GetFileName($fCand))"; L "- Rejected: $([IO.Path]::GetFileName($fRej))"; L "- Seasonal plan: $([IO.Path]::GetFileName($fPlan))"
if (-not $DetailsOnly) { [IO.File]::WriteAllText($fSum, $md.ToString(), (New-Object Text.UTF8Encoding($true))) }

# =============================================================================
# Excel review workbook (human review output). Presentation only: uses the decisions made above.
# =============================================================================
. (Join-Path $PSScriptRoot 'xlsx_writer.ps1')
$PLAIN = @{
    avoid_list = 'On the avoid list (CLAUDE.md s4)'; ip_risk = 'Brand / copyright / counterfeit risk'; brand_ip = 'Brand / copyright risk'; ip_vero = 'Brand / VeRO / copyright risk'
    stock = 'Stock too low or out of stock'; seller_type = 'Amazon offer is Amazon retail or has no free Prime delivery (FBM and FBA allowed from 2026-10-09)'; keepa = 'Keepa Buy Box history not stable for 3 months'; delivery = 'Delivery too slow'
    price_ceiling = 'Source cost too high for the GBP 2-35 eBay price range'; rating = 'Rating too low (Amazon under 4; AliExpress under 4.3)'; sales = 'Too few recent sales on the source site'; demand = 'Weak demand on the source site'
    weight = 'Too heavy without free delivery (Amazon 2 kg or more; Go Dropship 2 kg or more; AliExpress 5 kg or more); no weight limit with free delivery (2026-10-18)'; variations = 'Too many variations (more than 3)'; str = 'eBay sell-through below 40% (hand calculated since 2026-11-04)'; trend = 'eBay sales trend (informational only since 2026-10-14, not a gate)'
    total_sellers = 'Total sellers: no limit (gate removed 2026-10-23)'; price_range = 'eBay sold price outside GBP 2-35'; price = 'eBay listed price outside GBP 2-35'; profit = 'Profit below GBP 1'
    roi = 'ROI below 20% (item cost GBP 10 or more; rule before 2026-10-08)'; margin = 'Listing price GBP 8+: margin under 30% and ROI under 20%'; amazon_price_range = 'Amazon price outside GBP 2-40'; delivery_fee = 'Amazon delivery not free'; offer_sellers = 'Not 3-20 sellers on the Amazon listing'; choice_badge = 'Not an AliExpress Choice product'; store_positive_feedback = 'AliExpress store feedback below 90%'; warehouse_location = 'Not in a UK warehouse'; other_fees = 'Unexpected extra fees'; seasonal_timing = 'Cannot reach buyers before the event, or the event has passed'
    ebay_evidence_unavailable = 'eBay evidence could not be obtained (blocked or no comparable listing)'; source_check = 'Failed a source-site check'; ebay_verification = 'Failed eBay verification'
}
$selIds = @{}; foreach ($x in $allSel) { $selIds[$x.cid] = $x }
$surIds = @{}; foreach ($x in $surplus) { $surIds[$x.cid] = $x }
$dupIds = @{}; foreach ($d in $dupes) { $dupIds[$d.x.cid] = $d }
$incIds = @{}; foreach ($x in $incomplete) { $incIds[$x.cid] = $x }
$rejById = @{}; foreach ($r in $histRej) { if (-not $rejById.ContainsKey($r.candidate_id)) { $rejById[$r.candidate_id] = New-Object System.Collections.Generic.List[object] }; $rejById[$r.candidate_id].Add($r) }

function Get-AllUrls($rows) {
    $urls = New-Object System.Collections.Generic.List[string]
    foreach ($row in $rows) { if ($null -eq $row) { continue }
        foreach ($p in $row.PSObject.Properties) { if ($p.Name -match 'evidence|notes|_url$|risks') { foreach ($mm in [regex]::Matches("$($p.Value)", 'https?://[^\s;|,"<>]+')) { $u = $mm.Value.TrimEnd('.', ')', ']'); if (-not $urls.Contains($u)) { $urls.Add($u) } } } } }
    return $urls
}
function Lnk($url, [string]$text) { if ((Test-Val $url) -and "$url" -match '^https?://') { return @{ Url = "$url".Trim(); Text = $text } } return @{ Url = ''; Text = $text } }
function Est($v, [bool]$isEst) { if ($isEst -and (Test-Val $v)) { return @{ Value = $v; Estimated = $true } } return (V $v) }
function Frac($v) {
    $s = "$v".Trim(); if (-not (Test-Val $s)) { return (V $v) }
    $num = Num ($s.TrimEnd('%').Trim()); if ($null -eq $num) { return $s }
    if ($s.EndsWith('%') -or $num -gt 1) { return $num / 100 } return $num
}

function New-WbRecord([string]$cid) {
    $hh = $hunter[$cid]; $h = $hh.row; $srcKey = $hh.src; $m = $SRC[$srcKey]
    $er = $ebay[$cid]; $pr = $prof[$cid]; $sr = $seas[$cid]
    $calc = V (Get-Col $pr 'calculation_status'); $isEst = ($calc -eq 'ESTIMATED')
    $uSource = Get-Col $h $m.url; $uItem = Get-Col $er 'reference_seller_url'; $uSearch = Get-Col $er 'ebay_sold_search_url'; $uSeller = Get-Col $er 'reference_seller_store_url'
    $known = @($uSource, $uItem, $uSearch, $uSeller) | Where-Object { Test-Val $_ }
    $all = Get-AllUrls @($h, $er)
    $uKeepa = $all | Where-Object { $_ -match 'keepa\.com' } | Select-Object -First 1
    $uZik = $all | Where-Object { $_ -match 'zikanalytics|amzsuccesstools' } | Select-Object -First 1
    $uOther = $all | Where-Object { $_ -notin $known -and $_ -ne $uKeepa -and $_ -ne $uZik } | Select-Object -First 1
    # Decision (presentation of the decisions already made above)
    # Keep an array even for one row (PS 5.1: a single [pscustomobject] has no .Count; @(List) also fails, hence .ToArray()).
    $rejs = @(if ($rejById.ContainsKey($cid)) { $rejById[$cid].ToArray() })
    if ($selIds.ContainsKey($cid)) { $x = $selIds[$cid]; $cat = 'SELECTED'; $dec = "ACCEPTED - SELECTED ($(if ($x.final -eq 'EXCEPTION') { 'EXCEPTION' } elseif ($x.basis -eq 'ESTIMATED') { 'PASS - ESTIMATED' } else { 'PASS' }))" }
    elseif ($surIds.ContainsKey($cid)) { $cat = 'SURPLUS'; $dec = $(if ($surIds[$cid].sel -eq 'SURPLUS_NOT_ALLOCATED') { 'QUALIFIED - NOT SELECTED (event not current/next)' } else { 'QUALIFIED - NOT SELECTED (source target already met)' }) }
    elseif ($dupIds.ContainsKey($cid)) { $cat = 'DUPLICATE'; $dd = $dupIds[$cid]; $dec = "DUPLICATE - same product kept as $($dd.keptCid) ($($SRC[$dd.keptSrc].label))" }
    elseif ($incIds.ContainsKey($cid)) { $cat = 'UNKNOWN'; $dec = 'NOT ACCEPTED - DATA UNKNOWN' }
    elseif ($rejs.Count -and @($rejs | Where-Object { $_.failed_criterion -ne 'ebay_evidence_unavailable' }).Count -eq 0) { $cat = 'UNKNOWN'; $dec = 'NOT ACCEPTED - DATA UNKNOWN (eBay evidence unavailable)' }
    else { $cat = 'REJECTED'; $dec = 'REJECTED' }
    $reason = ''; $failed = ''
    if ($rejs.Count) {
        $reason = (@($rejs | ForEach-Object { $t = if ($PLAIN.ContainsKey($_.failed_criterion)) { $PLAIN[$_.failed_criterion] } else { $_.failed_criterion }; $seen = if ((Test-Val $_.observed_value) -and $_.observed_value -ne 'see evidence') { $_.observed_value } elseif (Test-Val $_.rejection_reason) { $_.rejection_reason } else { 'see evidence' }; "$t (seen: $seen; rule: $($_.threshold))" }) -join '. ')
        $failed = (@($rejs | ForEach-Object { "$($_.stage)/$($_.failed_criterion)" }) -join '; ')
    } elseif ($cat -eq 'UNKNOWN') { $reason = "Required data unknown: $($incIds[$cid].reason). Not a failure; will be rechecked."; $failed = 'UNKNOWN_DATA' }
    elseif ($cat -eq 'DUPLICATE') { $reason = 'Qualified, but the same product qualified from another source with stronger economics (CLAUDE.md s18).' }
    elseif ($cat -eq 'REJECTED') { $reason = V (Get-Col $h 'rejection_reason'); $failed = V (Get-Col $h 'failed_criteria') }
    $evid = @("Financials: $calc")
    if (Test-Val (Get-Col $pr 'estimated_inputs')) { $evid += "estimated: $($pr.estimated_inputs)" }
    if (Test-Val (Get-Col $pr 'unknown_inputs')) { $evid += "unknown: $($pr.unknown_inputs)" }
    if (Test-Val (Get-Col $er 'str_source')) { $evid += "sell-through source: $($er.str_source)" }
    if (-not $er) { $evid += 'no eBay verification' }
    $exc = @((Get-Col $h 'exceptions'), (Get-Col $er 'exceptions'), (Get-Col $pr 'exceptions'), (Get-Col $sr 'exceptions')) | Where-Object { (Test-Val $_) -and $_ -notmatch '^\s*(upstream:\s*)?none\s*$' } | Select-Object -Unique
    $evDate = if (Test-Val (Get-Col $sr 'event_date')) { $sr.event_date } else { Get-Col $sr 'anchor_date' }
    $hs = if ($histToday.ContainsKey($cid)) { $histToday[$cid] } else { $null }
    $hunterNo = ("$($h.proceed_to_ebay)" -eq 'NO')
    @{
        cat = $cat; id = $cid; name = V $h.product_name; source = $m.label
        lSource = Lnk $uSource 'Open Source'; lItem = Lnk $uItem 'Open eBay'; lSeller = Lnk $uSeller 'Open Seller'; lSearch = Lnk $uSearch 'Open eBay search'
        lKeepa = Lnk $uKeepa 'Open Keepa'; lZik = Lnk $uZik 'Open ZIK'; lOther = Lnk $uOther 'Open Evidence'
        seller = V (Get-Col $er 'reference_seller_name'); sourcePrice = V (Get-Col $h $m.price)
        buyFee = Est (Get-Col $pr 'sourcing_buying_fee') ("$(Get-Col $pr 'sourcing_buying_fee_status')" -eq 'ESTIMATED')
        ebayPrice = V (Get-Col $er 'reference_seller_price'); ebayFee = Est (Get-Col $pr 'ebay_fee_amount') $isEst
        adRate = $(if (Test-Val (Get-Col $pr 'ad_rate_pct')) { Frac "$($pr.ad_rate_pct)%" } else { 'UNKNOWN' }); minPrice = Est (Get-Col $pr 'minimum_listing_price') $isEst; listed = V (Get-Col $pr 'listed_price')
        profit = Est (Get-Col $pr 'profit') $isEst
        profitPct = $(if ($isEst -and (Test-Val (Get-Col $pr 'profit_pct'))) { @{ Value = (Frac "$($pr.profit_pct)%"); Estimated = $true } } elseif (Test-Val (Get-Col $pr 'profit_pct')) { Frac "$($pr.profit_pct)%" } else { 'UNKNOWN' })
        roi = $(if ($isEst -and (Test-Val (Get-Col $pr 'roi_pct'))) { @{ Value = (Frac "$($pr.roi_pct)%"); Estimated = $true } } elseif (Test-Val (Get-Col $pr 'roi_pct')) { Frac "$($pr.roi_pct)%" } else { 'UNKNOWN' })
        roiMin = $(if (Test-Val (Get-Col $pr 'roi_min_pct')) { Frac "$($pr.roi_min_pct)%" } else { V (Get-Col $pr 'roi_min_pct') }); roiBypass = RoiBypass $pr
        basis = $(if ($pr) { $calc } elseif ($hunterNo) { 'N/A (rejected at source)' } else { 'UNKNOWN' })
        str = Frac (Get-Col $er 'str_value'); strSource = V (Get-Col $er 'str_source'); sellers = V (Get-Col $er 'seller_count')
        compSales = $(if ($er) { "Matched sold in window: $(V $er.sold_items_count); top-20 sellers with 50+ sales/30d: $(V (Get-Col $er 'strong_seller_count')); small sellers (<=2k feedback, 10+ sales): $(V (Get-Col $er 'small_sellers_le_2k'))" } else { 'UNKNOWN' })
        variations = V (Get-Col $h $m.vars); weight = V (Get-Col $h 'weight')
        seasonal = $(if ($sr) { "$(V $sr.product_type) ($(V $sr.seasonality))" } elseif (Test-Val (Get-Col $h 'product_type')) { "$($h.product_type) (provisional)" } else { 'UNKNOWN' })
        target = $(if ($sr) { V $sr.target_event } else { V (Get-Col $h 'target_event') }); eventDate = V $evDate
        prefStart = V (Get-Col $sr 'preferred_listing_start'); minStart = V (Get-Col $sr 'minimum_listing_start'); daysUntil = V (Get-Col $sr 'days_until_event')
        phase = $(if ($sr) { V $sr.seasonal_phase } else { V (Get-Col $h 'seasonal_phase') }); seasConf = V (Get-Col $sr 'seasonal_confidence'); bucket = V (Get-Col $sr 'allocation_bucket')
        compliance = V (Get-Col $h 'compliance_status'); decision = $dec; evidence = ($evid -join '; ')
        exception = $(if (@($exc).Count) { "EXCEPTION: $(@($exc) -join ' | ')" } else { 'none' })
        reason = $(if ($reason) { $reason } else { '' }); failed = $failed
        mayChange = $(if ($rejs.Count) { (@($rejs | ForEach-Object { $_.failure_may_change }) | Select-Object -Unique) -join '/' } else { '' })
        history = $(if ($hs) { $hs.status } else { 'UNKNOWN (history not ingested)' }); recheck = $(if ($hs -and (Test-Val $hs.recheck_due)) { $hs.recheck_due } else { '' })
        notes = V (Get-Col $h 'notes')
    }
}

$C_MAIN = @(
    @{ H = 'Row # (not a rank)'; W = 9; T = 'int'; K = '#' }, @{ H = 'Product ID'; W = 16; T = 'text'; K = 'id' }, @{ H = 'Product name'; W = 34; T = 'wrap'; K = 'name' }
    @{ H = 'Source'; W = 14; T = 'text'; K = 'source' }, @{ H = 'Source product link'; W = 14; T = 'link'; K = 'lSource' }, @{ H = 'eBay product link'; W = 14; T = 'link'; K = 'lItem' }
    @{ H = 'eBay seller'; W = 18; T = 'text'; K = 'seller' }, @{ H = 'eBay seller link'; W = 14; T = 'link'; K = 'lSeller' }
    @{ H = 'Source price'; W = 12; T = 'currency'; K = 'sourcePrice' }, @{ H = 'Sourcing buying fee'; W = 12; T = 'currency'; K = 'buyFee' }
    @{ H = 'eBay price (competitor)'; W = 13; T = 'currency'; K = 'ebayPrice' }, @{ H = 'eBay fee'; W = 11; T = 'currency'; K = 'ebayFee' }, @{ H = 'Advertising rate'; W = 11; T = 'percent'; K = 'adRate' }
    @{ H = 'Minimum listing price'; W = 12; T = 'currency'; K = 'minPrice' }, @{ H = 'Listed price'; W = 11; T = 'currency'; K = 'listed' }
    @{ H = 'Profit'; W = 11; T = 'currency'; K = 'profit' }, @{ H = 'Profit %'; W = 10; T = 'percent'; K = 'profitPct' }, @{ H = 'ROI'; W = 10; T = 'percent'; K = 'roi' }
    @{ H = 'ROI minimum'; W = 10; T = 'percent'; K = 'roiMin' }, @{ H = 'ROI bypassed (profit >= GBP 2)'; W = 12; T = 'text'; K = 'roiBypass' }
    @{ H = 'Financial basis (VERIFIED / ESTIMATED / UNKNOWN)'; W = 16; T = 'text'; K = 'basis' }
    @{ H = 'Sell-through rate'; W = 11; T = 'percent'; K = 'str' }, @{ H = 'Sell-through source'; W = 16; T = 'text'; K = 'strSource' }, @{ H = 'eBay seller count'; W = 10; T = 'int'; K = 'sellers' }
    @{ H = 'Competitor sales evidence'; W = 40; T = 'wrap'; K = 'compSales' }, @{ H = 'Variations'; W = 10; T = 'text'; K = 'variations' }, @{ H = 'Weight'; W = 10; T = 'text'; K = 'weight' }
    @{ H = 'Seasonal classification'; W = 22; T = 'wrap'; K = 'seasonal' }, @{ H = 'Target event'; W = 16; T = 'text'; K = 'target' }, @{ H = 'Event date'; W = 13; T = 'date'; K = 'eventDate' }
    @{ H = 'Preferred listing start (60-day planning assumption)'; W = 15; T = 'date'; K = 'prefStart' }, @{ H = 'Minimum listing start (30-day planning assumption)'; W = 15; T = 'date'; K = 'minStart' }
    @{ H = 'Days until event'; W = 9; T = 'int'; K = 'daysUntil' }, @{ H = 'Seasonal phase'; W = 18; T = 'text'; K = 'phase' }, @{ H = 'Seasonal confidence'; W = 11; T = 'text'; K = 'seasConf' }
    @{ H = 'Allocation bucket'; W = 18; T = 'text'; K = 'bucket' }, @{ H = 'Compliance status'; W = 18; T = 'text'; K = 'compliance' }
    @{ H = 'Decision'; W = 30; T = 'wrap'; K = 'decision' }, @{ H = 'Evidence status'; W = 36; T = 'wrap'; K = 'evidence' }, @{ H = 'Exception'; W = 20; T = 'wrap'; K = 'exception' }
    @{ H = 'Keepa link'; W = 12; T = 'link'; K = 'lKeepa' }, @{ H = 'ZIK link'; W = 12; T = 'link'; K = 'lZik' }, @{ H = 'eBay sold search link'; W = 14; T = 'link'; K = 'lSearch' }
    @{ H = 'Other evidence link'; W = 14; T = 'link'; K = 'lOther' }, @{ H = 'Notes'; W = 30; T = 'wrap'; K = 'notes' }
)
$C_AUDIT = $C_MAIN[0..($C_MAIN.Count - 2)] + @(
    @{ H = 'Rejection / not-accepted reason'; W = 50; T = 'wrap'; K = 'reason' }, @{ H = 'Failed criterion'; W = 26; T = 'wrap'; K = 'failed' }
    @{ H = 'Could change later'; W = 10; T = 'text'; K = 'mayChange' }, @{ H = 'History status'; W = 14; T = 'text'; K = 'history' }, @{ H = 'Recheck due'; W = 13; T = 'date'; K = 'recheck' }
    @{ H = 'Notes'; W = 30; T = 'wrap'; K = 'notes' })
$C_REJ = @(
    @{ H = 'Row #'; W = 7; T = 'int'; K = '#' }, @{ H = 'Product ID'; W = 16; T = 'text'; K = 'id' }, @{ H = 'Product name'; W = 34; T = 'wrap'; K = 'name' }, @{ H = 'Source'; W = 14; T = 'text'; K = 'source' }
    @{ H = 'Source link'; W = 13; T = 'link'; K = 'lSource' }, @{ H = 'eBay link'; W = 13; T = 'link'; K = 'lItem' }, @{ H = 'Source price'; W = 12; T = 'currency'; K = 'sourcePrice' }
    @{ H = 'eBay price'; W = 12; T = 'currency'; K = 'ebayPrice' }, @{ H = 'Profit'; W = 11; T = 'currency'; K = 'profit' }, @{ H = 'Profit %'; W = 10; T = 'percent'; K = 'profitPct' }
    @{ H = 'ROI'; W = 10; T = 'percent'; K = 'roi' }, @{ H = 'Financial basis'; W = 16; T = 'text'; K = 'basis' }, @{ H = 'Decision'; W = 30; T = 'wrap'; K = 'decision' }
    @{ H = 'Rejection reason (plain English)'; W = 55; T = 'wrap'; K = 'reason' }, @{ H = 'Failed criterion'; W = 26; T = 'wrap'; K = 'failed' }, @{ H = 'Evidence status'; W = 32; T = 'wrap'; K = 'evidence' }
    @{ H = 'Seasonal classification'; W = 22; T = 'wrap'; K = 'seasonal' }, @{ H = 'Target event'; W = 16; T = 'text'; K = 'target' }, @{ H = 'Seasonal phase'; W = 18; T = 'text'; K = 'phase' }
    @{ H = 'Exception'; W = 18; T = 'wrap'; K = 'exception' }, @{ H = 'Could change later'; W = 10; T = 'text'; K = 'mayChange' }, @{ H = 'History status'; W = 14; T = 'text'; K = 'history' }
    @{ H = 'Recheck due'; W = 13; T = 'date'; K = 'recheck' }, @{ H = 'Notes'; W = 28; T = 'wrap'; K = 'notes' }
    @{ H = 'eBay sold search link'; W = 14; T = 'link'; K = 'lSearch' }, @{ H = 'Keepa link'; W = 12; T = 'link'; K = 'lKeepa' }, @{ H = 'Evidence link'; W = 13; T = 'link'; K = 'lOther' })

function New-Sheet([string]$name, $colsDef, $records) {
    $i = 0
    $rows = foreach ($rec in $records) { $i++; , @($colsDef | ForEach-Object { if ($_.K -eq '#') { $i } else { $rec[$_.K] } }) }
    @{ Name = $name; Columns = @($colsDef | ForEach-Object { @{ Header = $_.H; Width = $_.W; Type = $_.T } }); Rows = @($rows) }
}

$records = [ordered]@{}; foreach ($cid in $hunter.Keys) { $records[$cid] = New-WbRecord $cid }
$recSel = @($allSel | ForEach-Object { $records[$_.cid] })
$recRej = @($records.Values | Where-Object { $_.cat -in 'REJECTED', 'UNKNOWN' })
$order = @{ SELECTED = 1; SURPLUS = 2; DUPLICATE = 3; UNKNOWN = 4; REJECTED = 5 }
$recAll = @($records.Values | Sort-Object { $order[$_.cat] }, { $_.source }, { $_.id })

# Summary sheet
$blocked = @($SRC.Keys | Where-Object { -not $huntCount[$_].file } | ForEach-Object { "$($SRC[$_].label): no stage file (not researched or blocked)" })
if (Test-Val $RunNotes) { $blocked += "Run notes: $RunNotes" }
$selBy = @{}; foreach ($s in $SRC.Keys) { $selBy[$s] = $selected[$s].Count }
$bc = @{}; foreach ($b in 'evergreen', 'current_event', 'next_event_preparation') { $bc[$b] = @($allSel | Where-Object { $_.bucket -eq $b }).Count }
$mixTxt = if ($totSel) { "evergreen $([math]::Round(100*$bc.evergreen/$totSel))% / current event $([math]::Round(100*$bc.current_event/$totSel))% / next-event preparation $([math]::Round(100*$bc.next_event_preparation/$totSel))%" } else { 'no products selected' }
$sumRows = New-Object System.Collections.Generic.List[object]
function SR($item, $value, $note = '') { $sumRows.Add(@($item, $value, $note)) }
SR 'Date' $Date 'UK date of the research run'
SR 'Report generated (UK)' $nowUk.ToString('yyyy-MM-dd HH:mm') ''
SR 'Total products evaluated' $hunter.Count 'every product examined by the three hunters (see All Evaluated)'
foreach ($s in $SRC.Keys) { SR "$($SRC[$s].label) evaluated" $huntCount[$s].evaluated $(if (-not $huntCount[$s].file) { 'no stage file' } else { '' }) }
SR 'Accepted (qualified) products' $kept.Count 'passed every gate; includes qualified products not selected'
SR 'Selected for Daily 20' $totSel 'see Daily 20'
SR 'Qualified but not selected' $surplus.Count 'kept, not discarded (see All Evaluated)'
SR 'Rejected' @($records.Values | Where-Object { $_.cat -eq 'REJECTED' }).Count 'see Rejected'
SR 'UNKNOWN / incomplete (not accepted)' @($records.Values | Where-Object { $_.cat -eq 'UNKNOWN' }).Count 'missing data or eBay evidence unavailable; not a failure, rechecked later'
SR 'Duplicates' $dupes.Count 'same product qualified from another source; strongest kept'
foreach ($s in $SRC.Keys) { SR "$($SRC[$s].label) selected" $selBy[$s] "target $PER_SOURCE; shortfall $([math]::Max(0, $PER_SOURCE - $selBy[$s]))" }
SR 'Target per source' $PER_SOURCE 'a target, not a quota to fill'
foreach ($s in $SRC.Keys) { SR "$($SRC[$s].label) shortfall" ([math]::Max(0, $PER_SOURCE - $selBy[$s])) 'not padded with weak products' }
SR 'Total target' $TOTAL ''
SR 'Actual total selected' $totSel "shortfall $([math]::Max(0, $TOTAL - $totSel))"
SR 'Evergreen selected' $bc.evergreen "target $($bucketTarget.evergreen)"
SR 'Current-event selected' $bc.current_event "target $($bucketTarget.current_event)"
SR 'Next-event-preparation selected' $bc.next_event_preparation "target $($bucketTarget.next_event_preparation)"
SR 'Actual seasonal mix (selected)' $mixTxt "target mix $([math]::Round($mixEv*100))/$([math]::Round($mixCur*100))/$([math]::Round($mixNext*100))"
SR '50/30/20 allocation changed?' $(if ($mixChanged) { 'YES' } else { 'NO' }) ''
SR 'Reason for change' $(if ($mixChanged) { $AllocationReason } else { 'N/A' }) ''
SR 'Blocked / unavailable sources' $(if ($blocked.Count) { $blocked -join '; ' } else { 'none recorded' }) ''
SR 'ESTIMATED financial results (selected)' @($allSel | Where-Object { $_.basis -eq 'ESTIMATED' }).Count 'highlighted light yellow + italic; Financial basis column says ESTIMATED'
SR 'EXCEPTIONS (selected)' @($allSel | Where-Object { $_.final -eq 'EXCEPTION' }).Count 'need the user''s approval before any action'
SR 'Compliance review needed' @($allSel + $surplus | Where-Object { "$($_.h.compliance_status)" -ne 'PASS' }).Count 'retailer-sourced items stay COMPLIANCE_REVIEW until the user clears them'
SR 'Important notes' 'Research only: nothing was purchased, listed or published. Row numbers are not a quality rank; no score is calculated (CLAUDE.md s18 has no sub-score method). UNKNOWN means not observed.' ''
$sumSheet = @{ Name = 'Summary'; Columns = @(@{ Header = 'Item'; Width = 38; Type = 'wrap' }, @{ Header = 'Value'; Width = 46; Type = 'auto' }, @{ Header = 'Notes'; Width = 60; Type = 'wrap' }); Rows = $sumRows.ToArray() }

# Seasonal plan sheet
$planRows = foreach ($c in $calendar) {
    , @($Date, $c.name, $c.type, $(if ($c.type -eq 'window') { $c.anchor_date } else { $c.event_date }),
        $(if ($c.type -eq 'window') { $c.window_start } else { 'N/A' }), $(if ($c.type -eq 'window') { $c.window_end } else { 'N/A' }),
        $c.days_until, $c.preferred_listing_start, $c.minimum_listing_start, $c.phase, $c.days_remaining_in_season, $c.priority, $c.role,
        "Themes: $($c.themes -replace ';', ', '). Lead-time dates are the user's business planning assumption, not an eBay requirement.")
}
$planSheet = @{ Name = 'Seasonal Plan'; Rows = @($planRows); Columns = @(
        @{ Header = "Today's UK date"; Width = 13; Type = 'date' }, @{ Header = 'Event / season'; Width = 20; Type = 'text' }, @{ Header = 'Type'; Width = 8; Type = 'text' }
        @{ Header = 'Event date (or season anchor)'; Width = 14; Type = 'date' }, @{ Header = 'Season window start'; Width = 13; Type = 'date' }, @{ Header = 'Season window end'; Width = 13; Type = 'date' }
        @{ Header = 'Days until'; Width = 9; Type = 'int' }, @{ Header = 'Preferred listing start (60-day planning assumption)'; Width = 16; Type = 'date' }
        @{ Header = 'Minimum listing start (30-day planning assumption)'; Width = 16; Type = 'date' }, @{ Header = 'Current phase'; Width = 19; Type = 'text' }
        @{ Header = 'Days left in season'; Width = 10; Type = 'int' }, @{ Header = 'Calendar priority'; Width = 12; Type = 'text' }, @{ Header = 'Seasonal bucket'; Width = 24; Type = 'text' }
        @{ Header = 'Notes'; Width = 60; Type = 'wrap' }) }

# Rejection Details sheet (user request 2026-10-03): one row per failed rule, with full details and every link.
$detRows = foreach ($rec in $recRej) {
    $cid = $rec.id; $hh = $hunter[$cid]; $h = $hh.row; $m = $SRC[$hh.src]; $er = $ebay[$cid]; $pr = $prof[$cid]
    $isEst = ("$(Get-Col $pr 'calculation_status')" -eq 'ESTIMATED')
    $srcSales = (@($m.sales | ForEach-Object { Get-Col $h $_ } | Where-Object { Test-Val $_ }) -join '; ')
    $rules = @(if ($rejById.ContainsKey($cid)) { $rejById[$cid].ToArray() })
    if (-not $rules.Count) { $rules = @([pscustomobject]@{ stage = 'SOURCE'; failed_criterion = $rec.failed; observed_value = ''; threshold = ''; rejection_reason = $rec.reason; failure_may_change = $rec.mayChange; change_triggers = ''; resulting_status = $rec.history; recheck_due = $rec.recheck }) }
    foreach ($g in $rules) {
        $seen = if ((Test-Val $g.observed_value) -and $g.observed_value -ne 'see evidence') { $g.observed_value } else { $g.rejection_reason }
        @{ id = $cid; name = $rec.name; source = $rec.source; decision = $rec.decision
           rule = "$($g.stage)/$($g.failed_criterion)"; ruleText = $(if ($PLAIN.ContainsKey("$($g.failed_criterion)")) { $PLAIN["$($g.failed_criterion)"] } else { V $g.failed_criterion })
           seen = V $seen; limit = V $g.threshold; why = V $g.rejection_reason; mayChange = V $g.failure_may_change; triggers = V (Get-Col $g 'change_triggers')
           next = V (Get-Col $g 'resulting_status'); recheck = V $g.recheck_due
           lSource = $rec.lSource; lItem = $rec.lItem; lSeller = $rec.lSeller; lSearch = $rec.lSearch; lZik = $rec.lZik; lKeepa = $rec.lKeepa; lOther = $rec.lOther
           sourcePrice = $rec.sourcePrice; stock = $(if ($m.stock) { V (Get-Col $h $m.stock) } else { 'N/A' }); delivery = V (Get-Col $h $m.delivery); weight = $rec.weight; variations = $rec.variations
           srcSales = $(if ($srcSales) { $srcSales } else { 'UNKNOWN' }); srcSeller = $(if ($m.seller) { V (Get-Col $h $m.seller) } else { 'N/A' }); rating = $(if ($m.rating) { V (Get-Col $h $m.rating) } else { 'N/A' })
           seller = $rec.seller; ebayPrice = $rec.ebayPrice; str = $rec.str; strSource = $rec.strSource; soldWin = V (Get-Col $er 'sold_items_count'); active = V (Get-Col $er 'active_listings_count')
           sellers = $rec.sellers; shb = V (Get-Col $er 'sold_history_recent_sales'); match = V (Get-Col $er 'match_level')
           buyFee = $rec.buyFee; ebayFee = $rec.ebayFee; adCost = Est (Get-Col $pr 'ad_cost') $isEst; total = Est (Get-Col $pr 'total_cost') $isEst; profit = $rec.profit; profitPct = $rec.profitPct; roi = $rec.roi
           minAll = Est (Get-Col $pr 'min_price_all_gates') $isEst; basis = $rec.basis; seasonal = $rec.seasonal; compliance = $rec.compliance; notes = $rec.notes }
    }
}
$C_DET = @(
    @{ H = 'Row #'; W = 7; T = 'int'; K = '#' }, @{ H = 'Product ID'; W = 16; T = 'text'; K = 'id' }, @{ H = 'Product name'; W = 34; T = 'wrap'; K = 'name' }, @{ H = 'Source'; W = 14; T = 'text'; K = 'source' }
    @{ H = 'Rule failed'; W = 22; T = 'text'; K = 'rule' }, @{ H = 'Rule (plain English)'; W = 30; T = 'wrap'; K = 'ruleText' }, @{ H = 'What was seen'; W = 36; T = 'wrap'; K = 'seen' }, @{ H = 'Limit'; W = 22; T = 'wrap'; K = 'limit' }
    @{ H = 'Reason'; W = 44; T = 'wrap'; K = 'why' }, @{ H = 'Could change later'; W = 10; T = 'text'; K = 'mayChange' }, @{ H = 'What would change it'; W = 22; T = 'wrap'; K = 'triggers' }
    @{ H = 'Next status'; W = 13; T = 'text'; K = 'next' }, @{ H = 'Recheck due'; W = 12; T = 'date'; K = 'recheck' }
    @{ H = 'Source link'; W = 13; T = 'link'; K = 'lSource' }, @{ H = 'eBay competitor link'; W = 14; T = 'link'; K = 'lItem' }, @{ H = 'eBay seller shop link'; W = 14; T = 'link'; K = 'lSeller' }
    @{ H = 'eBay sold search link'; W = 14; T = 'link'; K = 'lSearch' }, @{ H = 'ZIK link'; W = 11; T = 'link'; K = 'lZik' }, @{ H = 'Keepa link'; W = 11; T = 'link'; K = 'lKeepa' }, @{ H = 'Other evidence link'; W = 14; T = 'link'; K = 'lOther' }
    @{ H = 'Item cost'; W = 10; T = 'currency'; K = 'sourcePrice' }, @{ H = 'Stock'; W = 12; T = 'wrap'; K = 'stock' }, @{ H = 'Delivery'; W = 16; T = 'wrap'; K = 'delivery' }, @{ H = 'Weight'; W = 10; T = 'text'; K = 'weight' }
    @{ H = 'Variations'; W = 12; T = 'wrap'; K = 'variations' }, @{ H = 'Source sales / demand'; W = 22; T = 'wrap'; K = 'srcSales' }, @{ H = 'Source seller / store'; W = 18; T = 'wrap'; K = 'srcSeller' }, @{ H = 'Source rating'; W = 9; T = 'text'; K = 'rating' }
    @{ H = 'eBay match'; W = 10; T = 'text'; K = 'match' }, @{ H = 'eBay competitor'; W = 20; T = 'wrap'; K = 'seller' }, @{ H = 'Competitor price'; W = 11; T = 'currency'; K = 'ebayPrice' }
    @{ H = 'Sell-through'; W = 11; T = 'percent'; K = 'str' }, @{ H = 'Sell-through source'; W = 18; T = 'wrap'; K = 'strSource' }, @{ H = 'Sold in window'; W = 10; T = 'text'; K = 'soldWin' }
    @{ H = 'Active listings'; W = 10; T = 'text'; K = 'active' }, @{ H = 'Seller count'; W = 14; T = 'text'; K = 'sellers' }, @{ H = 'Sold History (competitor)'; W = 30; T = 'wrap'; K = 'shb' }
    @{ H = 'Buying fee'; W = 10; T = 'currency'; K = 'buyFee' }, @{ H = 'eBay fees'; W = 10; T = 'currency'; K = 'ebayFee' }, @{ H = 'Ad cost'; W = 9; T = 'currency'; K = 'adCost' }, @{ H = 'Total cost'; W = 10; T = 'currency'; K = 'total' }
    @{ H = 'Profit'; W = 10; T = 'currency'; K = 'profit' }, @{ H = 'Margin'; W = 9; T = 'percent'; K = 'profitPct' }, @{ H = 'ROI'; W = 9; T = 'percent'; K = 'roi' }, @{ H = 'Minimum listing price'; W = 12; T = 'currency'; K = 'minAll' }
    @{ H = 'Financial basis'; W = 16; T = 'text'; K = 'basis' }, @{ H = 'Seasonality'; W = 20; T = 'wrap'; K = 'seasonal' }, @{ H = 'Compliance'; W = 18; T = 'text'; K = 'compliance' }
    @{ H = 'Decision'; W = 26; T = 'wrap'; K = 'decision' }, @{ H = 'Notes'; W = 34; T = 'wrap'; K = 'notes' })
$detSheet = New-Sheet 'Rejection Details' $C_DET @($detRows)

if ($DetailsOnly) {
    New-XlsxWorkbook -Path $fDet -Sheets @($detSheet)
    "Rejection details for $prefix ($(@($detRows).Count) row(s)): $fDet  (no other file written)"
    return
}
New-XlsxWorkbook -Path $fXlsx -Sheets @(
    (New-Sheet 'Daily 20' $C_MAIN $recSel),
    (New-Sheet 'Rejected' $C_REJ $recRej),
    $detSheet,
    (New-Sheet 'All Evaluated' $C_AUDIT $recAll),
    $sumSheet,
    $planSheet)

# --- Review data for the pinned daily page (tools/build_review_page.ps1). Presentation only. ---
$fJson = Join-Path $dailyDir "${prefix}_review.json"
$review = [ordered]@{
    date = $Date; run = $n; generated_uk = $nowUk.ToString('yyyy-MM-dd HH:mm')
    total_target = $TOTAL; per_source_target = $PER_SOURCE; total_selected = $totSel
    per_source = @(foreach ($s in $SRC.Keys) { [ordered]@{ source = $SRC[$s].label; evaluated = $huntCount[$s].evaluated; has_file = [bool]$huntCount[$s].file
            qualified = @($kept | Where-Object { $_.src -eq $s }).Count; selected = $selBy[$s]; shortfall = [math]::Max(0, $PER_SOURCE - $selBy[$s]) } })
    buckets = @(foreach ($b in 'evergreen', 'current_event', 'next_event_preparation') { [ordered]@{ bucket = $b; target = $bucketTarget[$b]; selected = $bc[$b] } })
    allocation_changed = $mixChanged; allocation_reason = $(if ($mixChanged) { $AllocationReason } else { '' })
    counts = [ordered]@{ evaluated = $hunter.Count; qualified = $kept.Count; surplus = $surplus.Count; duplicates = $dupes.Count
        rejected = @($records.Values | Where-Object { $_.cat -eq 'REJECTED' }).Count; unknown = @($records.Values | Where-Object { $_.cat -eq 'UNKNOWN' }).Count }
    blocked = @($blocked); run_notes = $(if (Test-Val $RunNotes) { $RunNotes } else { '' })
    calendar = @($calendar | ForEach-Object { [ordered]@{ name = $_.name; type = $_.type; event_date = $_.event_date; window_start = $_.window_start; window_end = $_.window_end
                anchor_date = $_.anchor_date; days_until = $_.days_until; preferred_listing_start = $_.preferred_listing_start; minimum_listing_start = $_.minimum_listing_start
                phase = $_.phase; days_remaining_in_season = $_.days_remaining_in_season; priority = $_.priority; role = $_.role } })
    selected = @($recSel); rejected = @($recRej); all = @($recAll)
}
[IO.File]::WriteAllText($fJson, ($review | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))

"Daily report ${Date}: selected $totSel of $TOTAL; surplus $($surplus.Count); rejection rows $($rejRows.Count) (incl. $($dupes.Count) duplicate, $($incomplete.Count) incomplete)."
"Written: $fXlsx  (human review workbook)"
"Written: $fJson  (data for the pinned review page)"
"Written: $fCand"; "Written: $fRej"; "Written: $fPlan"; "Written: $fSum"
