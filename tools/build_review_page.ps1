<#
Builds the pinned "eBay Daily 20" review page from every data/daily/*_review.json written by tools/daily_report.ps1.
Output (derived view, rebuilt each time): data/review_page/ebay_daily_20.html
Publish it to the same pinned Artifact URL stored in config.yaml (review_page.url). See prompts/daily_hunt.md, step 14.
Presentation only: it never changes any research file or decision.
Each product also gets a "Full details and links" block (every failed rule with seen vs limit, source, eBay, profit,
lifecycle and all stored links), joined read-only from that day's stage/eBay/profit/seasonal/rejection files.
#>
param([string]$Root, [string]$OutputFile, [int]$MaxDays = 120)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
if (-not $OutputFile) { $OutputFile = Join-Path $Root 'data\review_page\ebay_daily_20.html' }
$template = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'review_page_template.html'))
$marker = '/*__HUNT_DATA__*/[]'
if (-not $template.Contains($marker)) { throw "Template marker not found in review_page_template.html" }

$files = @(Get-ChildItem -Path (Join-Path $Root 'data\daily') -Filter '*_review.json' -File -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First $MaxDays)

# --- Full detail per product (user request 2026-10-03) ---------------------------------
# Joined at build time from that day's stage, eBay, profit, seasonal and rejection files by candidate_id.
# Read-only: no daily or stage file is changed; values are shown exactly as recorded (UNKNOWN stays UNKNOWN).
function Read-ById([string]$path) {
    $m = @{}; if (Test-Path -LiteralPath $path) { foreach ($r in Import-Csv -LiteralPath $path) { $m[$r.candidate_id] = $r } }; return $m
}
function Get-Urls([string[]]$texts) {
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($t in $texts) { foreach ($mm in [regex]::Matches("$t", 'https?://[^\s|;,"<>]+')) { $u = $mm.Value.TrimEnd('.', ')', ']'); if (-not $out.Contains($u)) { $out.Add($u) } } }
    return $out
}
function Clean-Url([string]$u) { if ($u -match '^https?://') { return $u.TrimEnd('.', ')', ']') }; return $u }
# Label / column pairs shown in the Source section, by stage file
$SRCF = [ordered]@{
    amazon_uk     = @(@('Item cost used (Amazon)', 'amazon_price'), @('Price today', 'amazon_current_price'), @('Keepa max held price', 'keepa_max_held_price'), @('Sourcing cost basis', 'sourcing_cost_basis'),
                      @('Sold by', 'sold_by'), @('Dispatched from', 'dispatched_from'), @('Seller type', 'seller_type'), @('Top FBM seller', 'top_fbm_seller'), @('Top FBM inventory', 'top_fbm_inventory'), @('Stock seen', 'stock_observed'),
                      @('Demand label', 'demand_amazon_label'), @('Best Seller Rank', 'demand_best_seller_rank'), @('Rating', 'amazon_rating'), @('Fastest delivery', 'delivery_fastest_date'), @('Delivery days', 'delivery_days'),
                      @('Weight', 'weight'), @('Variations', 'variations_count'), @('Risks', 'risks'), @('Unknown fields', 'unknown_fields'), @('Exceptions', 'exceptions'))
    aliexpress_uk = @(@('Price (SKU)', 'aliexpress_price'), @('Regular price', 'regular_price'), @('Promotion', 'promo_price_flag'), @('UK shipping', 'uk_shipping_cost'), @('Sold count', 'sales_count_shown'), @('Sales period', 'sales_period_shown'),
                      @('Rating', 'rating'), @('Reviews', 'review_count'), @('Delivery shown', 'delivery_estimate_shown'), @('Delivery days (max)', 'delivery_days_max'), @('Store', 'store_name'), @('SKU', 'sku_selected'),
                      @('Weight', 'weight'), @('Variations offered', 'variations_total_offered'), @('Risks', 'risks'), @('Unknown fields', 'unknown_fields'), @('Exceptions', 'exceptions'))
    godropship_uk = @(@('Supplier SKU', 'supplier_sku'), @('Price', 'source_price'), @('Price note', 'price_evidence'), @('Sales evidence', 'sales_evidence_shown'), @('Sales period', 'sales_period_shown'), @('UK stock', 'stock_shown'),
                      @('Delivery service', 'delivery_service'), @('Delivery days', 'delivery_days'), @('Delivery charge', 'delivery_charge'), @('Weight', 'weight'), @('Dimensions', 'dimensions'), @('Variations', 'variations_count'),
                      @('Access', 'account_access_used'), @('Risks', 'risks'), @('Unknown fields', 'unknown_fields'), @('Exceptions', 'exceptions'))
}
$EBF = @(@('Match', 'match_level'), @('Match notes', 'match_notes'), @('Competitor (reference)', 'reference_seller_name'), @('Competitor price (item + postage)', 'reference_seller_price'), @('Sell-through', 'str_value'), @('Sell-through source', 'str_source'),
         @('Sell-through status', 'str_status'), @('Sold in window', 'sold_items_count'), @('Window', 'research_window_start'), @('Active listings', 'active_listings_count'), @('Seller count', 'seller_count'),
         @('Sold History (competitor)', 'sold_history_recent_sales'), @('Trend', 'trend_direction'), @('Top-20 sellers with 50+ sales/30d', 'strong_seller_count'), @('Small sellers (<=2k fb, 10+ sales)', 'small_sellers_le_2k'),
         @('Top 10 sellers', 'top10_sellers_detail'), @('Item price sample (median)', 'sold_price_item_median'), @('Shipping', 'shipping_evidence'), @('Category', 'ebay_category_path'), @('IP / VeRO', 'ip_vero_notes'),
         @('Hard gates', 'hard_gate_summary'), @('Preferences', 'preference_summary'), @('eBay result', 'ebay_verification_status'), @('Risk', 'rejection_risk'), @('Reason', 'rejection_reason'))
$PFF = @(@('Listed price (competitor)', 'listed_price'), @('Item cost', 'source_price'), @('Buying fee', 'sourcing_buying_fee'), @('Source delivery', 'source_delivery_charge'), @('eBay fee rate %', 'ebay_fee_rate_pct'),
         @('Fixed per-order fee', 'ebay_fixed_fee'), @('Insertion fee', 'insertion_fee'), @('eBay fees total', 'ebay_fee_amount'), @('Ad rate %', 'ad_rate_pct'), @('Ad cost', 'ad_cost'), @('Total cost', 'total_cost'),
         @('Profit', 'profit'), @('Margin %', 'profit_pct'), @('ROI %', 'roi_pct'), @('Pricing tier', 'pricing_tier'), @('Minimum listing price', 'min_price_all_gates'), @('Price gate', 'price_gate'),
         @('Profit gate', 'profit_gate'), @('ROI gate', 'roi_gate'), @('Basis', 'calculation_status'), @('Estimated inputs', 'estimated_inputs'), @('Notes', 'notes'))
function Items($row, $pairs) {
    $l = New-Object System.Collections.Generic.List[object]
    if (-not $row) { return , @() }
    foreach ($p in $pairs) { if ($row.PSObject.Properties.Name -contains $p[1]) { $v = "$($row.($p[1]))"; if ($p[1] -eq 'research_window_start') { $v = "$v to $($row.research_window_end)" }; $l.Add([ordered]@{ k = $p[0]; v = $(if ($v) { $v } else { 'UNKNOWN' }) }) } }
    return , $l.ToArray()
}

$parts = foreach ($f in $files) {
    $t = [IO.File]::ReadAllText($f.FullName).Trim()
    $day = $t | ConvertFrom-Json   # validate; throws on a broken file
    $prefix = $f.Name -replace '_review\.json$', ''; $date = $prefix.Substring(0, 10)
    $rejByCid = @{}
    $rejPath = Join-Path $Root "data\daily\${prefix}_rejections.csv"
    if (Test-Path -LiteralPath $rejPath) { foreach ($r in Import-Csv -LiteralPath $rejPath) { if (-not $rejByCid.ContainsKey($r.candidate_id)) { $rejByCid[$r.candidate_id] = New-Object System.Collections.Generic.List[object] }; $rejByCid[$r.candidate_id].Add($r) } }
    $stage = @{}; $stageSrc = @{}
    foreach ($k in $SRCF.Keys) { $m = Read-ById (Join-Path $Root "data\sources\$k\${date}_${k}_stage.csv"); foreach ($id in $m.Keys) { $stage[$id] = $m[$id]; $stageSrc[$id] = $k } }
    $eb = Read-ById (Join-Path $Root "data\ebay\${date}_ebay_verification.csv")
    $pf = Read-ById (Join-Path $Root "data\profit\${date}_profit.csv")
    $se = Read-ById (Join-Path $Root "data\seasonal\${date}_seasonal_classification.csv")
    foreach ($listName in 'selected', 'rejected', 'all') {
        foreach ($rec in @($day.$listName)) {
            if (-not $rec) { continue }
            foreach ($ln in 'lSource', 'lItem', 'lSeller', 'lSearch', 'lKeepa', 'lZik', 'lOther') { if ($rec.$ln -and $rec.$ln.Url) { $rec.$ln.Url = Clean-Url $rec.$ln.Url } }
            $id = $rec.id; $h = $stage[$id]; $er = $eb[$id]; $pr = $pf[$id]; $sr = $se[$id]
            $gates = @(if ($rejByCid.ContainsKey($id)) { foreach ($g in $rejByCid[$id]) {
                [ordered]@{ gate = $g.failed_gate; seen = $(if ($g.observed_value -and $g.observed_value -ne 'see evidence') { $g.observed_value } else { $g.rejection_reason }); rule = $g.threshold; why = $g.rejection_reason
                            mayChange = $g.failure_may_change; triggers = $g.change_triggers; status = $g.resulting_status; recheck = $g.recheck_due } } })
            if (-not $gates.Count -and $h -and "$($h.proceed_to_ebay)" -eq 'NO') { $gates = @([ordered]@{ gate = "SOURCE/$($h.failed_criteria)"; seen = $h.rejection_reason; rule = ''; why = $h.rejection_reason; mayChange = ''; triggers = ''; status = ''; recheck = '' }) }
            $sections = New-Object System.Collections.Generic.List[object]
            if ($h) { $sections.Add([ordered]@{ title = "Source: $($rec.source)"; items = (Items $h $SRCF[$stageSrc[$id]]) }) }
            if ($er) { $sections.Add([ordered]@{ title = 'eBay verification'; items = (Items $er $EBF) }) } else { $sections.Add([ordered]@{ title = 'eBay verification'; items = @([ordered]@{ k = 'Status'; v = 'Not verified on eBay (stopped at an earlier stage)' }) }) }
            if ($pr) { $sections.Add([ordered]@{ title = 'Profit (CLAUDE.md s10)'; items = (Items $pr $PFF) }) }
            $life = @([ordered]@{ k = 'History status'; v = "$($rec.history)" }, [ordered]@{ k = 'Recheck due'; v = $(if ($rec.recheck) { "$($rec.recheck)" } else { 'N/A' }) },
                      [ordered]@{ k = 'Failure may change'; v = $(if ($rec.mayChange) { "$($rec.mayChange)" } else { 'N/A' }) }, [ordered]@{ k = 'Compliance'; v = "$($rec.compliance)" },
                      [ordered]@{ k = 'Seasonality'; v = "$($rec.seasonal)" }, [ordered]@{ k = 'Target event'; v = "$($rec.target)" })
            if ($sr) { $life += [ordered]@{ k = 'Seasonal result'; v = "$($sr.overall_status) (timing $($sr.timing_status))" } }
            $life += [ordered]@{ k = 'Notes'; v = "$($rec.notes)" }
            $sections.Add([ordered]@{ title = 'Lifecycle and notes'; items = $life })
            $urlTexts = @()
            if ($h) { $urlTexts += @($h.PSObject.Properties | ForEach-Object { "$($_.Value)" }) }
            if ($er) { $urlTexts += @('reference_seller_url', 'reference_seller_store_url', 'ebay_sold_search_url', 'ebay_active_search_url', 'matched_listings_sample', 'str_evidence', 'sold_items_evidence', 'sold_history_evidence', 'shipping_evidence', 'fee_evidence' | ForEach-Object { "$($er.$_)" }) }
            if ($rejByCid.ContainsKey($id)) { $urlTexts += @($rejByCid[$id] | ForEach-Object { "$($_.source_url) $($_.ebay_url) $($_.evidence_urls)" }) }
            $links = @(foreach ($u in (Get-Urls $urlTexts)) {
                $lab = switch -Regex ($u) { 'godropship\.co\.uk/shipping' { 'Go Dropship shipping terms'; break } 'godropship\.co\.uk/weekly' { 'Go Dropship Weekly Top'; break } 'godropship' { 'Go Dropship product'; break }
                    'amazon\.co\.uk/gp/bestsellers' { 'Amazon Best Sellers list'; break } 'amazon\.co\.uk' { 'Amazon product'; break } 'aliexpress' { 'AliExpress product'; break } 'ebay\.co\.uk/itm' { 'eBay listing'; break } 'ebay\.co\.uk/str' { 'eBay seller shop'; break }
                    'ebay\.co\.uk/sch.*LH_Sold' { 'eBay sold search'; break } 'ebay\.co\.uk/sch' { 'eBay active search'; break } 'ebay\.co\.uk/help' { 'eBay fee page'; break } 'zik|amzsuccesstools' { 'ZIK research'; break } 'keepa' { 'Keepa'; break } default { 'Link' } }
                [ordered]@{ label = $lab; url = $u } })
            $rec | Add-Member -NotePropertyName detail -NotePropertyValue ([ordered]@{ gates = @($gates); sections = $sections.ToArray(); links = @($links) }) -Force
        }
    }
    $day | ConvertTo-Json -Depth 12 -Compress
}
$json = '[' + (@($parts) -join ',') + ']'
$json = $json.Replace('</', '<\/')   # keep the data inside its <script> element
$html = $template.Replace($marker, $json)

$dir = Split-Path $OutputFile -Parent
if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[IO.File]::WriteAllText($OutputFile, $html, (New-Object Text.UTF8Encoding($false)))
"Review page built from $($files.Count) daily file(s): $OutputFile ($([math]::Round((Get-Item -LiteralPath $OutputFile).Length / 1KB, 1)) KB)"
