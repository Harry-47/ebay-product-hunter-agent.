<#
Writes the four required daily files (CLAUDE.md s18) for a hand-researched day from data/daily/<Date>_review.json:
candidates.csv, rejections.csv, seasonal_plan.md, summary.md. Existing files are never overwritten. Missing values stay UNKNOWN.
Usage: .\tools\manual_daily_files.ps1 -Date YYYY-MM-DD
#>
param([Parameter(Mandatory)][string]$Date, [string]$Root)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$d = Join-Path $Root 'data\daily'
$j = [IO.File]::ReadAllText((Join-Path $d "${Date}_review.json"), [Text.Encoding]::UTF8) | ConvertFrom-Json
function V($x) { if ($null -ne $x -and $x -is [pscustomobject] -and $x.PSObject.Properties['Value']) { $x = $x.Value }; $s = "$x".Trim(); if ($s) { $s } else { 'UNKNOWN' } }
function Put([string]$name, [string[]]$lines) { $p = Join-Path $d "${Date}_$name"; if (Test-Path -LiteralPath $p) { "kept   $name (already exists)" } else { [IO.File]::WriteAllLines($p, $lines, (New-Object Text.UTF8Encoding($true))); "wrote  $name" } }
$cols = 'date_found,candidate_id,source,product_name,source_url,source_item_code,source_variant_code,ebay_listing_url,ebay_item_number,selected_variants,source_price,source_stock,source_rating,source_sales,source_delivery,source_seller_type,ebay_search_url,ebay_example_seller,ebay_sold_price,ebay_average_price,ebay_sell_through_rate,ebay_seller_count,ebay_sales_last_30d,small_seller_evidence,ebay_fees,ad_rate,estimated_total_cost,minimum_listing_price,suggested_listing_price,estimated_profit,profit_margin,roi,variations,weight,seasonality,compliance_status,criteria_relaxed,rejection_risk,evidence_urls,confidence,notes,product_type,target_event,event_date,preferred_listing_start,minimum_listing_start,days_until_event,recommended_action,seasonal_confidence,trend_description' -split ','
$cand = foreach ($s in @($j.selected)) {
    $m = @{ date_found = $Date; candidate_id = $s.id; source = $s.source; product_name = $s.name; source_url = $s.lSource.Url; source_item_code = $s.itemCode; source_variant_code = $s.variantCode; ebay_listing_url = $s.lItem.Url; ebay_item_number = $s.ebayNo; selected_variants = $s.variantList; source_price = $s.sourcePrice; source_stock = $s.stock; source_rating = $s.rating; source_sales = $s.srcSales; source_delivery = $s.delivery; source_seller_type = $s.srcSeller
        ebay_search_url = $s.lSearch.Url; ebay_example_seller = $s.seller; ebay_sold_price = $s.ebayPrice; ebay_sell_through_rate = $s.str; ebay_seller_count = $s.sellers; ebay_sales_last_30d = $s.compSales; small_seller_evidence = $s.s50; ebay_fees = $s.ebayFee; ad_rate = $s.adRate; estimated_total_cost = $s.total
        minimum_listing_price = $s.minPrice; suggested_listing_price = $s.listed; estimated_profit = $s.profit; profit_margin = $s.profitPct; roi = $s.roi; variations = $s.variations; weight = $s.weight; seasonality = $s.seasonal; compliance_status = $s.compliance; criteria_relaxed = $s.exception
        evidence_urls = (@($s.lSource.Url, $s.lItem.Url, $s.lSearch.Url, $s.lSeller.Url) | Where-Object { $_ }) -join ' '; notes = $s.notes; target_event = $s.target; event_date = $s.eventDate; preferred_listing_start = $s.prefStart; minimum_listing_start = $s.minStart; days_until_event = $s.daysUntil; recommended_action = $s.recAction; seasonal_confidence = $s.seasConf; trend_description = $s.trend }
    $o = [ordered]@{}; foreach ($c in $cols) { $o[$c] = V $m[$c] }; [pscustomobject]$o
}
$rej = foreach ($r in @($j.rejected)) { [pscustomobject][ordered]@{ date = $Date; candidate_id = V $r.id; source = V $r.source; product_name = V $r.name; source_url = V $r.lSource.Url; failed_gate = V $r.rule; observed_value = V $r.seen; threshold = V $r.limit; evidence_urls = V $r.lSearch.Url; resulting_status = V $r.history; notes = V $r.notes } }
if (@($cand).Count) { Put 'candidates.csv' @($cand | ConvertTo-Csv -NoTypeInformation) } else { Put 'candidates.csv' @(($cols | ForEach-Object { '"' + $_ + '"' }) -join ',') }
if (@($rej).Count) { Put 'rejections.csv' @($rej | ConvertTo-Csv -NoTypeInformation) } else { Put 'rejections.csv' @('"date","candidate_id","source","product_name","source_url","failed_gate","observed_value","threshold","evidence_urls","resulting_status","notes"') }
$vars = foreach ($s in @($j.selected)) { foreach ($v in @($s.variants | Where-Object { $_ })) { $o = [ordered]@{ date_found = $Date }
        foreach ($p in 'pid', 'vid', 'pname', 'vno', 'vname', 'source', 'lSource', 'itemCode', 'variantCode', 'lItem', 'ebayNo', 'ebayVariant', 'seller', 'sold30', 'soldEvidence', 'cost', 'landed', 'stock', 'delivery', 'weight', 'ebayPrice', 'ebayFee', 'adCost', 'total', 'minPrice', 'profit', 'margin', 'roi', 'bufProfit', 'safe', 'result', 'notes') { $o[$p] = if ($p -in 'lSource', 'lItem') { V $v.$p.Url } else { V $v.$p } }
        [pscustomobject]$o } }
if (@($vars).Count) { Put 'variants.csv' @($vars | ConvertTo-Csv -NoTypeInformation) }
$plan = @("# Seasonal plan $Date", '', "Lead times are the user's business planning assumption, not an eBay rule.", '', '| Event | Date | Days until | Preferred start | Minimum start | Phase | Role |', '|---|---|---|---|---|---|---|')
foreach ($c in @($j.calendar)) { $plan += "| $($c.name) | $(if ($c.type -eq 'window') { "$($c.window_start) to $($c.window_end)" } else { $c.event_date }) | $($c.days_until) | $($c.preferred_listing_start) | $($c.minimum_listing_start) | $($c.phase) | $($c.role) |" }
Put 'seasonal_plan.md' $plan
$sum = @("# Daily summary $Date (hand-researched day, built from review.json)", '', "Selected $($j.total_selected) of $($j.total_target). Row order is not a ranking.", '', '| Source | Evaluated | Selected | Shortfall |', '|---|---|---|---|')
foreach ($p in @($j.per_source)) { $sum += "| $($p.source) | $($p.evaluated) | $($p.selected) | $($p.shortfall) |" }
$sum += @('', '## Selected', '', '| ID | Product | Cost | eBay | Profit | ROI | Basis | Exception |', '|---|---|---|---|---|---|---|---|')
foreach ($s in @($j.selected)) { $sum += "| $($s.id) | $($s.name) | $(V $s.sourcePrice) | $(V $s.ebayPrice) | $(V $s.profit) | $(V $s.roi) | $(V $s.basis) | $(V $s.exception) |" }
$sum += @('', '## Main rejection reasons', ''); foreach ($g in (@($j.rejected) | Group-Object rule | Sort-Object Count -Descending)) { $sum += "- $($g.Name): $($g.Count)" }
$sum += @('', "Compliance review needed: $(@($j.selected | Where-Object { $_.compliance -ne 'PASS' }).Count) of $(@($j.selected).Count) selected.", "Run notes: $(V $j.run_notes)")
Put 'summary.md' $sum
