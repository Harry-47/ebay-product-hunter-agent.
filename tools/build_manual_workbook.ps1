<#
Build the full 6-sheet review workbook for a hand-researched day (no stage files).
Same sheets as tools/daily_report.ps1: Daily 20, Rejected, Rejection Details, All Evaluated, Summary, Seasonal Plan.
Input : data/daily/<Date>_records.psv   (pipe-delimited, one row per evaluated product)
        data/daily/<Date>_summary_rows.psv  (item|value|note)  optional extra Summary rows
Output: data/daily/<Date>_ebay_product_hunt_full.xlsx   (never overwrites an existing file)
Economics are recomputed here (ESTIMATED): item cost + FX/buying fee, eBay fee by category, ads, fixed fees, profit, margin, ROI,
minimum listing price (CLAUDE.md s10). Presentation only; no rule is changed.
Usage: .\tools\build_manual_workbook.ps1 -Date 2026-10-24
#>
param([Parameter(Mandatory)][string]$Date, [switch]$ReviewJson, [string]$RunNotes = '', [string]$Blocked = '', [string]$AllocationReason = '')
# -ReviewJson also writes data/daily/<Date>_review.json for tools/build_review_page.ps1 (never overwrites; presentation only)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$daily = Join-Path $root 'data\daily'
. (Join-Path $PSScriptRoot 'xlsx_writer.ps1')
$inv = [Globalization.CultureInfo]::InvariantCulture
$P = [string][char]0x00A3

function Tv($v) { $s = "$v".Trim(); return ($s -ne '' -and $s -notmatch '^(UNKNOWN|N/A|NA|none)$') }
function V($v) { if (Tv $v) { return "$v".Trim() } return 'UNKNOWN' }
function Nm($x) { $d = 0.0; if ([double]::TryParse("$x".Trim(), [Globalization.NumberStyles]::Float, $inv, [ref]$d)) { return $d } return $null }
function Lnk($url, [string]$text) { if ((Tv $url) -and "$url" -match '^https?://') { return @{ Url = "$url".Trim(); Text = $text } } return @{ Url = ''; Text = $text } }
function R2($x) { return [math]::Round([double]$x, 2) }

# ---------------- calendar ----------------
$calCsv = Join-Path $root "data\seasonal\${Date}_calendar.csv"
$calendar = @()
if (Test-Path -LiteralPath $calCsv) { $calendar = @(Import-Csv -LiteralPath $calCsv) }
else {
    $rj = Join-Path $daily "${Date}_review.json"
    $j = Get-Content -LiteralPath $rj -Raw | ConvertFrom-Json
    $calendar = @($j.calendar | ForEach-Object { [pscustomobject]@{ name = $_.name; type = $_.type; themes = ''; priority = $_.priority; event_date = $_.event_date; window_start = $_.window_start; window_end = $_.window_end
                anchor_date = $_.anchor_date; days_until = $_.days_until; preferred_listing_start = $_.preferred_listing_start; minimum_listing_start = $_.minimum_listing_start; phase = $_.phase
                days_remaining_in_season = $_.days_remaining_in_season; role = $_.role } })
}
function Get-Cal([string]$name) { return ($calendar | Where-Object { $_.name -eq $name } | Select-Object -First 1) }

# ---------------- economics ----------------
$FVF = @{ home = 0.147; hb = 0.135; mob = 0.123; cl = 0.147; gar = 0.135 }            # (final value fee + 0.35% regulatory) x 1.20 VAT, ESTIMATED categories
# INC-005: the Profit Engine is the source of truth. Its latest row for the product (same cost and price) replaces the
# estimate above; the table is only used for products that never reached the Profit Engine.
$ENGINE_ROWS = @{}
foreach ($pf in (Get-ChildItem -LiteralPath (Join-Path $root 'data\profit') -Filter '*_profit.csv' | Sort-Object Name)) { foreach ($x in (Import-Csv -LiteralPath $pf.FullName)) { $ENGINE_ROWS["$($x.candidate_id)"] = $x } }
function Use-Engine($e, $row) {
    $n = { param($v) Nm $v }
    $e.landed = (& $n $row.source_price) + (& $n $row.source_delivery_charge) + (& $n $row.sourcing_buying_fee); $e.fx = & $n $row.sourcing_buying_fee; $e.buy = 0
    $e.ebayFee = & $n $row.ebay_fee_amount; $e.adCost = & $n $row.ad_cost; $e.ad = (& $n $row.ad_rate_incl_vat_pct) / 100; $e.total = & $n $row.total_cost
    $e.profit = & $n $row.profit; $e.margin = (& $n $row.profit_pct) / 100; $e.roi = (& $n $row.roi_pct) / 100; $e.min = & $n $row.minimum_listing_price
    $e.bufProfit = & $n $row.profit_at_cost_buffer; $e.engine = $true; $e.status = $row.calculation_status
    return $e
}
function Get-Fixed([string]$key, [double]$price) { $order = if ($key -eq 'home' -and $price -le 10) { 0.12 } elseif ($price -le 10) { 0.36 } else { 0.48 }; return $order + 0.36 }
function Get-AdRate([string]$kind, [double]$price) { if ($kind -eq 'amz') { return 0.036 } if ($price -lt 8) { return 0.036 } return 0.06 }
function Calc-Econ($kind, $cost, $price, $key) {
    $fx = if ($kind -eq 'ali') { 0.04 } else { 0 }; $buy = if ($kind -eq 'gd') { 0.05 } else { 0 }
    $buf = if ($kind -eq 'ali') { 0.06 } else { 0 }
    $item = $cost; $landed = $item * (1 + $fx + $buy)
    $fvf = $FVF[$key]; $fixed = Get-Fixed $key $price; $ad = Get-AdRate $kind $price
    $ebayFee = $fvf * $price + $fixed; $adCost = $ad * $price; $total = $landed + $ebayFee + $adCost
    $profit = $price - $total
    $o = @{ landed = $landed; fx = $fx * $item; buy = $buy * $item; ebayFee = $ebayFee; adCost = $adCost; ad = $ad; total = $total; profit = $profit; margin = $profit / $price; roi = $profit / $landed }
    # minimum listing price (s10)
    $fx1 = Get-Fixed $key 7.99; $p1 = ($landed + 1 + $fx1) / (1 - $fvf - 0.036)
    if ($p1 -lt 8) { $min = $p1 }
    else { $fx2 = Get-Fixed $key 10; $pp = ($landed + 1 + $fx2) / (1 - $fvf - 0.06); $pm = ($landed + $fx2) / (1 - $fvf - 0.06 - 0.30); $pr = ($landed * 1.2 + $fx2) / (1 - $fvf - 0.06); $min = [math]::Max(8, [math]::Max($pp, [math]::Min($pm, $pr))) }
    $o.min = $min
    if ($buf -gt 0) { $o.bufProfit = $price - $landed * (1 + $buf) - $ebayFee - $adCost } elseif ($kind -eq 'amz') { $o.bufProfit = $price - $landed * 1.04 - $ebayFee - $adCost } else { $o.bufProfit = $null }
    return $o
}

# ---------------- links, item codes and variants (user rule 2026-11-25) ----------------
# Record keys: ebayItemUrl (the eBay listing), itemCode (supplier item code / SKU), variantCode (or 'none'), hasVariations ($true/$false),
# variants = @( @{ name; variantCode; cost; stock; ebayPrice; sold30; ... }, ... )  best-selling first, 1 to 3 (maximum 3).
# The first variant uses the product's own Profit Engine id; the others use <id>-V2, <id>-V3 ...
$RULE_FROM = '2026-11-25'
function Test-ItemUrl($u) { return ("$u" -match '^https?://[^/]+/[^\s?#]{3,}') }
function Get-EbayItemNo($u) { if ("$u" -match 'ebay\.co\.uk/itm/(?:[^/\s?]+/)?(\d{9,})') { return $Matches[1] } return 'UNKNOWN' }
function Assert-Listing($r) {
    $m = @(); $awWaived = ($r.kind -eq 'aw' -and (Tv $r.exception) -and "$($r.ebayItemUrl)" -eq 'UNKNOWN')
    if (-not (Test-ItemUrl $r.srcUrl)) { $m += 'srcUrl must be the product page of the sourcing site (not its homepage)' }
    if (-not $awWaived -and (Get-EbayItemNo $r.ebayItemUrl) -eq 'UNKNOWN') { $m += 'ebayItemUrl must be the eBay listing (ebay.co.uk/itm/<number>)' }
    if (-not "$($r.itemCode)".Trim()) { $m += 'itemCode is required (UNKNOWN if the site shows none)' }
    if (-not "$($r.variantCode)".Trim()) { $m += "variantCode is required ('none' if there are no variations, UNKNOWN if not shown)" }
    if ($r.hasVariations -isnot [bool]) { $m += 'hasVariations must be $true or $false' }
    elseif ($r.hasVariations) {
        $vs = @($r.variants | Where-Object { $_ })
        if ($vs.Count -gt 3) { $m += "$($vs.Count) variants given: the maximum is 3" }
        if (-not $vs.Count) { $m += 'no variants given' }
        $i = 0; foreach ($v in $vs) { $i++; foreach ($k in 'name', 'variantCode', 'cost', 'stock', 'ebayPrice', 'sold30') { if (-not "$($v[$k])".Trim()) { $m += "variant ${i}: '$k' is required (UNKNOWN if not shown)" } } }
        if ($vs.Count -and ((Nm $vs[0].cost) -ne (Nm $r.cost) -or (Nm $vs[0].ebayPrice) -ne (Nm $r.ebayPrice))) { $m += 'variant 1 (best seller) must have the same cost and eBay price as the product row' }
    }
    if ($m.Count) { throw "$($r.id): $($m -join '; ')" }
}
function Get-Variants($r, $kind, $key) {
    $i = 0
    foreach ($v in @($r.variants | Where-Object { $_ })) {
        $i++; $vid = if ($i -eq 1) { "$($r.id)" } else { "$($r.id)-V$i" }
        $c = Nm $v.cost; $p = Nm $v.ebayPrice; $x = $null; $res = 'NOT PRICED by the Profit Engine'; $safe = 'UNKNOWN'
        if ($null -ne $c -and $null -ne $p -and $kind -ne 'none') { $x = Calc-Econ $kind $c $p $key }
        $g = $ENGINE_ROWS[$vid]
        if ($x -and $g -and $g.calculation_status -ne 'UNKNOWN' -and [math]::Abs((Nm $g.source_price) - $c) -lt 0.006 -and [math]::Abs((Nm $g.listed_price) - $p) -lt 0.006) { $x = Use-Engine $x $g; $res = "$($g.acceptance_status) ($($g.calculation_status))"; $safe = V $g.max_safe_cost }
        $est = { param($n) if ($null -eq $x -or $null -eq $n) { 'UNKNOWN' } else { @{ Value = (R2 $n); Estimated = (-not $x.engine -or $x.status -ne 'VERIFIED') } } }
        $pct = { param($n) if ($null -eq $x) { 'UNKNOWN' } else { @{ Value = [math]::Round($n, 4); Estimated = (-not $x.engine -or $x.status -ne 'VERIFIED') } } }
        $su = if (Tv $v.srcUrl) { $v.srcUrl } else { $r.srcUrl }; $eu = if (Tv $v.ebayItemUrl) { $v.ebayItemUrl } else { $r.ebayItemUrl }
        @{ pid = $r.id; vid = $vid; pname = V $r.name; vno = $i; vname = V $v.name; source = $srcLabel[$kind]; lSource = Lnk $su 'Open Source'; lItem = Lnk $eu 'Open eBay'
            itemCode = $(if (Tv $v.itemCode) { $v.itemCode } else { V $r.itemCode }); variantCode = V $v.variantCode; ebayNo = Get-EbayItemNo $eu; ebayVariant = V $v.ebayVariant; seller = $(if (Tv $v.seller) { $v.seller } else { V $r.seller })
            sold30 = V $v.sold30; soldEvidence = V $v.soldEvidence; cost = $(if ($null -ne $c) { $c } else { 'UNKNOWN' }); stock = V $v.stock; weight = $(if (Tv $v.weight) { $v.weight } else { V $r.weight }); delivery = $(if (Tv $v.delivery) { $v.delivery } else { V $r.delivery })
            landed = (& $est $x.landed); ebayPrice = $(if ($null -ne $p) { $p } else { 'UNKNOWN' }); ebayFee = (& $est $x.ebayFee); adCost = (& $est $x.adCost); total = (& $est $x.total); minPrice = (& $est $x.min)
            profit = (& $est $x.profit); margin = (& $pct $x.margin); roi = (& $pct $x.roi); bufProfit = $(if ($x -and $null -ne $x.bufProfit) { (& $est $x.bufProfit) } else { 'N/A' }); safe = $safe; result = $res; notes = V $v.notes }
    }
}

# ---------------- records ----------------
$script:RECS = New-Object System.Collections.Generic.List[object]
function Rec([hashtable]$h) { $script:RECS.Add([pscustomobject]$h) }
. (Join-Path $daily "${Date}_records_data.ps1")      # defines the day's products with Rec @{ ... }
$rows = $script:RECS.ToArray()   # PS 5.1: @(List) fails
$srcLabel = @{ ali = 'AliExpress UK'; gd = 'Go Dropship UK'; amz = 'Amazon UK'; aw = 'AW Dropship'; none = 'eBay/ZIK screen (no source reached)'; sy = 'Saleyee' }
$records = New-Object System.Collections.Generic.List[object]
foreach ($r in $rows) {
    $kind = if (Tv $r.kind) { $r.kind } else { 'none' }
    $cost = Nm $r.cost; $price = Nm $r.ebayPrice; $key = if (Tv $r.fvf) { $r.fvf } else { 'home' }
    if (-not $FVF.ContainsKey($key)) { throw "$($r.id): unknown fee key '$key' (use $($FVF.Keys -join ', ')). It used to count as a 0% fee." }
    if ($r.cat -eq 'SELECTED' -and $Date -ge $RULE_FROM) { Assert-Listing $r }
    $e = $null; if ($null -ne $cost -and $null -ne $price -and $kind -ne 'none') { $e = Calc-Econ $kind $cost $price $key }
    $eng = $ENGINE_ROWS["$($r.id)"]
    if ($e -and $eng -and $eng.calculation_status -ne 'UNKNOWN' -and [math]::Abs((Nm $eng.source_price) - $cost) -lt 0.006 -and [math]::Abs((Nm $eng.listed_price) - $price) -lt 0.006) { $e = Use-Engine $e $eng }
    $cal = $null; $tgt = if (Tv $r.target) { $r.target } else { 'NONE' }
    if ($tgt -ne 'NONE') { $cal = Get-Cal $tgt }
    $seasonality = if (Tv $r.seasonality) { $r.seasonality } else { 'evergreen' }
    $bucket = 'evergreen'; if ($cal) { $bucket = if ($cal.role -eq 'CURRENT_EVENT') { 'current_event' } elseif ($cal.role -eq 'NEXT_EVENT_PREPARATION') { 'next_event_preparation' } else { 'evergreen' } }
    $cat = $r.cat
    $decision = switch ($cat) {
        'SELECTED' { "ACCEPTED - SELECTED ($($r.decisionNote))" }
        'WATCH' { "NOT ACCEPTED - WATCH ($($r.decisionNote))" }
        default { 'REJECTED' } }
    $searchUrl = ''; if (Tv $r.searchQ) { $searchUrl = 'https://www.ebay.co.uk/sch/i.html?_nkw=' + ([uri]::EscapeDataString($r.searchQ)) + '&LH_BIN=1&LH_ItemCondition=1000&LH_PrefLoc=1' }
    $sellerUrl = ''; if ((Tv $r.seller) -and $r.seller -match '^[A-Za-z0-9._\-]+$') { $sellerUrl = "https://www.ebay.co.uk/usr/$($r.seller)" }
    $isEst = ($null -ne $e)
    function Est2($v) { if ($isEst) { return @{ Value = (R2 $v); Estimated = $true } } return 'UNKNOWN' }
    $comp = @()
    if (Tv $r.s50) { $comp += "top-20 sellers with 30+ sales/30d: $($r.s50)" }
    if (Tv $r.s500) { $comp += "sellers with 500+ total sold: $($r.s500)" }
    if (Tv $r.listings) { $comp += "listings (info only): $($r.listings)" }
    if (Tv $r.refNote) { $comp += $r.refNote }
    $evid = @(); if ($isEst -and $e.engine) { $evid += "Financials: Profit Engine ($($e.status))" } elseif ($isEst) { $evid += 'Financials: ESTIMATED (fee category assumed, hand calculation)' } else { $evid += 'Financials: not calculated (rejected before profit stage)' }
    if (Tv $r.strSource) { $evid += "sell-through source: $($r.strSource)" }
    $profitVal = if ($isEst) { R2 $e.profit } else { $null }
    $pass = ($cat -eq 'SELECTED')
    $rec = @{
        cat = $cat; id = $r.id; name = V $r.name; source = $(if ($srcLabel.ContainsKey($kind)) { $srcLabel[$kind] } else { $kind })
        lSource = Lnk $r.srcUrl 'Open Source'; lItem = Lnk $r.ebayItemUrl 'Open eBay'; lSeller = Lnk $sellerUrl 'Open Seller'; lSearch = Lnk $searchUrl 'Open eBay search'
        lKeepa = Lnk '' 'Open Keepa'; lZik = Lnk 'https://zik2.amzsuccesstools.com/product-research' 'Open ZIK'; lOther = Lnk '' 'Open Evidence'
        itemCode = V $r.itemCode; variantCode = V $r.variantCode; ebayNo = Get-EbayItemNo $r.ebayItemUrl; variantsNote = V $r.variantsNote
        variants = @(Get-Variants $r $kind $key)
        seller = V $r.seller; sourcePrice = $(if ($null -ne $cost) { @{ Value = $cost; Estimated = $false } } else { 'UNKNOWN' })
        landed = $(if ($isEst) { Est2 $e.landed } else { 'UNKNOWN' }); costNote = V $r.costNote
        buyFee = $(if ($isEst) { Est2 ($e.fx + $e.buy) } else { 'UNKNOWN' })
        ebayPrice = $(if ($null -ne $price) { $price } else { 'UNKNOWN' }); ebayFee = $(if ($isEst) { Est2 $e.ebayFee } else { 'UNKNOWN' })
        adRate = $(if ($isEst) { $e.ad } else { 'UNKNOWN' }); adCost = $(if ($isEst) { Est2 $e.adCost } else { 'UNKNOWN' }); total = $(if ($isEst) { Est2 $e.total } else { 'UNKNOWN' })
        minPrice = $(if ($isEst) { Est2 $e.min } else { 'UNKNOWN' }); listed = $(if ($null -ne $price) { $price } else { 'UNKNOWN' })
        profit = $(if ($isEst) { Est2 $e.profit } else { 'UNKNOWN' })
        profitPct = $(if ($isEst) { @{ Value = [math]::Round($e.margin, 4); Estimated = $true } } else { 'UNKNOWN' })
        roi = $(if ($isEst) { @{ Value = [math]::Round($e.roi, 4); Estimated = $true } } else { 'UNKNOWN' })
        bufProfit = $(if ($isEst -and $null -ne $e.bufProfit) { Est2 $e.bufProfit } else { 'N/A' })
        basis = $(if ($isEst) { 'ESTIMATED' } else { 'N/A (not calculated)' })
        str = $(if ((Tv $r.str) -and $null -ne (Nm ($r.str -replace '%', ''))) { (Nm ($r.str -replace '%', '')) / 100 } else { V $r.str }); strSource = V $r.strSource
        s50 = V $r.s50; s500 = V $r.s500; sellers = V $r.listings; compSales = $(if ($comp.Count) { $comp -join '; ' } else { 'UNKNOWN' })
        stock = V $r.stock; delivery = V $r.delivery; rating = V $r.rating; srcSales = V $r.srcSales; srcSeller = V $r.srcSeller
        variations = V $r.variations; weight = V $r.weight
        seasonal = "$(if ($seasonality -eq 'evergreen') { 'evergreen' } else { 'seasonal' }) ($seasonality)"; target = $tgt
        eventDate = $(if ($cal) { $(if ($cal.event_date -match '^\d') { $cal.event_date } else { $cal.anchor_date }) } else { 'N/A' })
        prefStart = $(if ($cal) { $cal.preferred_listing_start } else { 'N/A' }); minStart = $(if ($cal) { $cal.minimum_listing_start } else { 'N/A' })
        daysUntil = $(if ($cal) { $cal.days_until } else { 'N/A' }); phase = $(if ($cal) { $cal.phase } else { 'N/A' })
        seasConf = $(if ($cal) { 'MEDIUM' } else { 'N/A' }); bucket = $bucket
        recAction = $(if ($cal -and $pass) { $(if ($cal.phase -eq 'PREPARE_EARLY') { 'PREPARE_EARLY: list by preferred start; recheck at event minus 30 and minus 14 days' } else { $cal.phase }) } elseif ($pass) { 'KEEP: evergreen, list when approved' } else { 'N/A' })
        compliance = V $r.compliance; decision = $decision; evidence = ($evid -join '; ')
        exception = $(if ((Tv $r.exception)) { "EXCEPTION: $($r.exception)" } else { 'none' })
        rule = V $r.failedRule; seen = V $r.seen; limit = V $r.limit; reason = $(if (Tv $r.reason) { $r.reason } else { '' }); failed = V $r.failedRule
        mayChange = V $r.mayChange; history = V $r.status; recheck = V $r.recheck; trend = V $r.trend; notes = V $r.notes; costBasis = V $r.costNote
    }
    $rec.variantList = $(if ($rec.variants.Count) { (@($rec.variants | ForEach-Object { "$($_.vname) [$($_.variantCode)]" }) -join '; ') } else { 'none' })
    $records.Add($rec)
}
$order = @{ SELECTED = 1; WATCH = 2; REJECTED = 3 }
$recAll = @($records | Sort-Object { $order[$_.cat] }, { $_.source }, { $_.id })
$recSel = @($records | Where-Object { $_.cat -eq 'SELECTED' })
$recRej = @($records | Where-Object { $_.cat -in 'REJECTED', 'WATCH' })

# ---------------- column definitions ----------------
$PLAIN = @{ stock = 'Stock too low (AliExpress/Go Dropship: 20+ normal, 50+ seasonal)'; strong_sellers = 'Strong-seller gate: 3+ top-20 sellers with 30+ sales in 30 days AND 2+ with 500+ total sold'; sell_through = 'eBay sell-through below 40% (hand calculated)'
    profit = 'Profit below GBP 1 / margin or ROI rule not met'; price = 'Cost too high against the eBay reference price'; cost_basis = 'Cost basis could not be established'; no_source = 'No like-for-like source found'; avoid = 'On the avoid list (CLAUDE.md s4)'; demand = 'No eBay demand (0 sold in 30 days)' }
$C_MAIN = @(
    @{ H = 'Row # (not a rank)'; W = 9; T = 'int'; K = '#' }, @{ H = 'Product ID'; W = 16; T = 'text'; K = 'id' }, @{ H = 'Product name'; W = 36; T = 'wrap'; K = 'name' }
    @{ H = 'Source'; W = 14; T = 'text'; K = 'source' }, @{ H = 'eBay listing link'; W = 14; T = 'link'; K = 'lItem' }, @{ H = 'eBay item number'; W = 16; T = 'text'; K = 'ebayNo' }, @{ H = 'Source product link'; W = 14; T = 'link'; K = 'lSource' }
    @{ H = 'Source item code'; W = 20; T = 'text'; K = 'itemCode' }, @{ H = 'Source variant code'; W = 20; T = 'text'; K = 'variantCode' }, @{ H = 'Selected variants (details on the Variants sheet)'; W = 34; T = 'wrap'; K = 'variantList' }, @{ H = 'eBay search link'; W = 14; T = 'link'; K = 'lSearch' }
    @{ H = 'eBay reference seller'; W = 18; T = 'text'; K = 'seller' }, @{ H = 'eBay seller link'; W = 14; T = 'link'; K = 'lSeller' }
    @{ H = 'Source item price (SKU)'; W = 12; T = 'currency'; K = 'sourcePrice' }, @{ H = 'Cost basis used'; W = 30; T = 'wrap'; K = 'costNote' }
    @{ H = 'Landed cost (item + FX / buying fee)'; W = 13; T = 'currency'; K = 'landed' }, @{ H = 'FX / buying fee'; W = 11; T = 'currency'; K = 'buyFee' }
    @{ H = 'Source stock'; W = 12; T = 'text'; K = 'stock' }, @{ H = 'Source delivery'; W = 18; T = 'wrap'; K = 'delivery' }, @{ H = 'Source rating'; W = 9; T = 'text'; K = 'rating' }
    @{ H = 'Source sales / demand'; W = 22; T = 'wrap'; K = 'srcSales' }, @{ H = 'Source seller / store'; W = 18; T = 'wrap'; K = 'srcSeller' }
    @{ H = 'eBay price (reference)'; W = 12; T = 'currency'; K = 'ebayPrice' }, @{ H = 'eBay fee (incl fixed fees)'; W = 12; T = 'currency'; K = 'ebayFee' }
    @{ H = 'Advertising rate'; W = 10; T = 'percent'; K = 'adRate' }, @{ H = 'Ad cost'; W = 9; T = 'currency'; K = 'adCost' }, @{ H = 'Total cost'; W = 10; T = 'currency'; K = 'total' }
    @{ H = 'Minimum listing price'; W = 12; T = 'currency'; K = 'minPrice' }, @{ H = 'Listed price'; W = 10; T = 'currency'; K = 'listed' }
    @{ H = 'Profit'; W = 10; T = 'currency'; K = 'profit' }, @{ H = 'Profit % (margin)'; W = 10; T = 'percent'; K = 'profitPct' }, @{ H = 'ROI'; W = 10; T = 'percent'; K = 'roi' }
    @{ H = 'Profit with cost buffer (AliExpress 6% / Amazon 4%)'; W = 14; T = 'currency'; K = 'bufProfit' }
    @{ H = 'Financial basis'; W = 16; T = 'text'; K = 'basis' }
    @{ H = 'Sell-through rate'; W = 11; T = 'percent'; K = 'str' }, @{ H = 'Sell-through source'; W = 14; T = 'text'; K = 'strSource' }
    @{ H = 'Sellers with 30+ sales / 30d'; W = 14; T = 'wrap'; K = 's50' }, @{ H = 'Sellers with 500+ total sold'; W = 14; T = 'wrap'; K = 's500' }
    @{ H = 'eBay listings (info only)'; W = 12; T = 'text'; K = 'sellers' }, @{ H = 'Competitor / demand evidence'; W = 44; T = 'wrap'; K = 'compSales' }
    @{ H = 'Trend description'; W = 22; T = 'wrap'; K = 'trend' }, @{ H = 'Variations'; W = 12; T = 'wrap'; K = 'variations' }, @{ H = 'Weight'; W = 10; T = 'text'; K = 'weight' }
    @{ H = 'Seasonal classification'; W = 22; T = 'wrap'; K = 'seasonal' }, @{ H = 'Target event'; W = 14; T = 'text'; K = 'target' }, @{ H = 'Event date'; W = 12; T = 'date'; K = 'eventDate' }
    @{ H = 'Preferred listing start (60-day planning assumption)'; W = 15; T = 'date'; K = 'prefStart' }, @{ H = 'Minimum listing start (30-day planning assumption)'; W = 15; T = 'date'; K = 'minStart' }
    @{ H = 'Days until event'; W = 9; T = 'int'; K = 'daysUntil' }, @{ H = 'Seasonal phase'; W = 17; T = 'text'; K = 'phase' }, @{ H = 'Recommended action'; W = 34; T = 'wrap'; K = 'recAction' }
    @{ H = 'Allocation bucket'; W = 18; T = 'text'; K = 'bucket' }, @{ H = 'Compliance status'; W = 18; T = 'text'; K = 'compliance' }
    @{ H = 'Decision'; W = 30; T = 'wrap'; K = 'decision' }, @{ H = 'Evidence status'; W = 34; T = 'wrap'; K = 'evidence' }, @{ H = 'Exception / relaxed rule'; W = 28; T = 'wrap'; K = 'exception' }
    @{ H = 'ZIK link'; W = 11; T = 'link'; K = 'lZik' }, @{ H = 'Notes'; W = 50; T = 'wrap'; K = 'notes' })
$C_AUDIT = $C_MAIN[0..($C_MAIN.Count - 2)] + @(
    @{ H = 'Rejection / not-accepted reason'; W = 50; T = 'wrap'; K = 'reason' }, @{ H = 'Failed criterion'; W = 26; T = 'wrap'; K = 'failed' }
    @{ H = 'Could change later'; W = 10; T = 'text'; K = 'mayChange' }, @{ H = 'History status'; W = 14; T = 'text'; K = 'history' }, @{ H = 'Recheck due'; W = 13; T = 'text'; K = 'recheck' }
    @{ H = 'Notes'; W = 50; T = 'wrap'; K = 'notes' })
$C_REJ = @(
    @{ H = 'Row #'; W = 7; T = 'int'; K = '#' }, @{ H = 'Product ID'; W = 16; T = 'text'; K = 'id' }, @{ H = 'Product name'; W = 36; T = 'wrap'; K = 'name' }, @{ H = 'Source'; W = 14; T = 'text'; K = 'source' }
    @{ H = 'Source link'; W = 13; T = 'link'; K = 'lSource' }, @{ H = 'Source item code'; W = 18; T = 'text'; K = 'itemCode' }, @{ H = 'eBay listing link'; W = 13; T = 'link'; K = 'lItem' }, @{ H = 'Source item price'; W = 11; T = 'currency'; K = 'sourcePrice' }, @{ H = 'Source stock'; W = 11; T = 'text'; K = 'stock' }
    @{ H = 'eBay reference price'; W = 12; T = 'currency'; K = 'ebayPrice' }, @{ H = 'Minimum listing price'; W = 12; T = 'currency'; K = 'minPrice' }, @{ H = 'Profit (est.)'; W = 11; T = 'currency'; K = 'profit' }
    @{ H = 'Profit %'; W = 10; T = 'percent'; K = 'profitPct' }, @{ H = 'ROI'; W = 10; T = 'percent'; K = 'roi' }, @{ H = 'Sell-through'; W = 11; T = 'percent'; K = 'str' }
    @{ H = 'Sellers 30+/30d'; W = 14; T = 'wrap'; K = 's50' }, @{ H = 'Sellers 500+ total'; W = 14; T = 'wrap'; K = 's500' }
    @{ H = 'Decision'; W = 28; T = 'wrap'; K = 'decision' }, @{ H = 'Rejection reason (plain English)'; W = 55; T = 'wrap'; K = 'reason' }, @{ H = 'Failed criterion'; W = 24; T = 'wrap'; K = 'failed' }
    @{ H = 'What was seen'; W = 34; T = 'wrap'; K = 'seen' }, @{ H = 'Limit'; W = 22; T = 'wrap'; K = 'limit' }
    @{ H = 'Seasonal classification'; W = 22; T = 'wrap'; K = 'seasonal' }, @{ H = 'Could change later'; W = 10; T = 'text'; K = 'mayChange' }, @{ H = 'History status'; W = 14; T = 'text'; K = 'history' }
    @{ H = 'Recheck due'; W = 13; T = 'text'; K = 'recheck' }, @{ H = 'eBay search link'; W = 14; T = 'link'; K = 'lSearch' }, @{ H = 'Notes'; W = 50; T = 'wrap'; K = 'notes' })
$C_DET = @(
    @{ H = 'Row #'; W = 7; T = 'int'; K = '#' }, @{ H = 'Product ID'; W = 16; T = 'text'; K = 'id' }, @{ H = 'Product name'; W = 36; T = 'wrap'; K = 'name' }, @{ H = 'Source'; W = 14; T = 'text'; K = 'source' }
    @{ H = 'Rule failed'; W = 24; T = 'wrap'; K = 'rule' }, @{ H = 'What was seen'; W = 40; T = 'wrap'; K = 'seen' }, @{ H = 'Limit'; W = 24; T = 'wrap'; K = 'limit' }
    @{ H = 'Reason'; W = 50; T = 'wrap'; K = 'reason' }, @{ H = 'Could change later'; W = 10; T = 'text'; K = 'mayChange' }, @{ H = 'Next status'; W = 14; T = 'text'; K = 'history' }, @{ H = 'Recheck due'; W = 13; T = 'text'; K = 'recheck' }
    @{ H = 'Source link'; W = 13; T = 'link'; K = 'lSource' }, @{ H = 'Source item code'; W = 18; T = 'text'; K = 'itemCode' }, @{ H = 'eBay listing link'; W = 13; T = 'link'; K = 'lItem' }, @{ H = 'eBay search link'; W = 14; T = 'link'; K = 'lSearch' }, @{ H = 'eBay reference seller link'; W = 14; T = 'link'; K = 'lSeller' }, @{ H = 'ZIK link'; W = 11; T = 'link'; K = 'lZik' }
    @{ H = 'Item cost'; W = 10; T = 'currency'; K = 'sourcePrice' }, @{ H = 'Cost basis'; W = 26; T = 'wrap'; K = 'costNote' }, @{ H = 'Stock'; W = 11; T = 'text'; K = 'stock' }, @{ H = 'Delivery'; W = 16; T = 'wrap'; K = 'delivery' }
    @{ H = 'Weight'; W = 9; T = 'text'; K = 'weight' }, @{ H = 'Variations'; W = 11; T = 'wrap'; K = 'variations' }, @{ H = 'Source sales / demand'; W = 20; T = 'wrap'; K = 'srcSales' }, @{ H = 'Source rating'; W = 9; T = 'text'; K = 'rating' }
    @{ H = 'eBay reference seller'; W = 18; T = 'text'; K = 'seller' }, @{ H = 'eBay reference price'; W = 11; T = 'currency'; K = 'ebayPrice' }, @{ H = 'Sell-through'; W = 11; T = 'percent'; K = 'str' }, @{ H = 'Sell-through source'; W = 14; T = 'text'; K = 'strSource' }
    @{ H = 'Sellers 30+/30d'; W = 14; T = 'wrap'; K = 's50' }, @{ H = 'Sellers 500+ total'; W = 14; T = 'wrap'; K = 's500' }, @{ H = 'eBay listings (info)'; W = 11; T = 'text'; K = 'sellers' }
    @{ H = 'Landed cost'; W = 10; T = 'currency'; K = 'landed' }, @{ H = 'eBay fees'; W = 10; T = 'currency'; K = 'ebayFee' }, @{ H = 'Ad cost'; W = 9; T = 'currency'; K = 'adCost' }, @{ H = 'Total cost'; W = 10; T = 'currency'; K = 'total' }
    @{ H = 'Profit'; W = 10; T = 'currency'; K = 'profit' }, @{ H = 'Margin'; W = 9; T = 'percent'; K = 'profitPct' }, @{ H = 'ROI'; W = 9; T = 'percent'; K = 'roi' }, @{ H = 'Minimum listing price'; W = 12; T = 'currency'; K = 'minPrice' }
    @{ H = 'Financial basis'; W = 16; T = 'text'; K = 'basis' }, @{ H = 'Seasonality'; W = 20; T = 'wrap'; K = 'seasonal' }, @{ H = 'Compliance'; W = 18; T = 'text'; K = 'compliance' }
    @{ H = 'Decision'; W = 28; T = 'wrap'; K = 'decision' }, @{ H = 'Notes'; W = 44; T = 'wrap'; K = 'notes' })
$C_VAR = @(
    @{ H = 'Row #'; W = 7; T = 'int'; K = '#' }, @{ H = 'Product ID'; W = 16; T = 'text'; K = 'pid' }, @{ H = 'Product name'; W = 34; T = 'wrap'; K = 'pname' }, @{ H = 'Variant no. (1 = best seller)'; W = 9; T = 'int'; K = 'vno' }
    @{ H = 'Variant'; W = 22; T = 'wrap'; K = 'vname' }, @{ H = 'Source'; W = 14; T = 'text'; K = 'source' }, @{ H = 'Source link'; W = 13; T = 'link'; K = 'lSource' }, @{ H = 'Source item code'; W = 20; T = 'text'; K = 'itemCode' }
    @{ H = 'Source variant code'; W = 22; T = 'text'; K = 'variantCode' }, @{ H = 'eBay listing link'; W = 13; T = 'link'; K = 'lItem' }, @{ H = 'eBay item number'; W = 16; T = 'text'; K = 'ebayNo' }, @{ H = 'eBay variant name'; W = 20; T = 'wrap'; K = 'ebayVariant' }
    @{ H = 'eBay seller'; W = 18; T = 'text'; K = 'seller' }, @{ H = 'Sold in 30 days (this variant)'; W = 12; T = 'text'; K = 'sold30' }, @{ H = 'Sales evidence'; W = 30; T = 'wrap'; K = 'soldEvidence' }
    @{ H = 'Source price'; W = 10; T = 'currency'; K = 'cost' }, @{ H = 'Landed cost'; W = 10; T = 'currency'; K = 'landed' }, @{ H = 'Source stock'; W = 11; T = 'text'; K = 'stock' }, @{ H = 'Delivery'; W = 16; T = 'wrap'; K = 'delivery' }, @{ H = 'Weight'; W = 10; T = 'text'; K = 'weight' }
    @{ H = 'eBay price'; W = 10; T = 'currency'; K = 'ebayPrice' }, @{ H = 'eBay fees'; W = 10; T = 'currency'; K = 'ebayFee' }, @{ H = 'Ad cost'; W = 9; T = 'currency'; K = 'adCost' }, @{ H = 'Total cost'; W = 10; T = 'currency'; K = 'total' }, @{ H = 'Minimum listing price'; W = 11; T = 'currency'; K = 'minPrice' }
    @{ H = 'Profit'; W = 9; T = 'currency'; K = 'profit' }, @{ H = 'Margin'; W = 9; T = 'percent'; K = 'margin' }, @{ H = 'ROI'; W = 9; T = 'percent'; K = 'roi' }, @{ H = 'Profit with cost buffer'; W = 11; T = 'currency'; K = 'bufProfit' }, @{ H = 'Max safe cost'; W = 10; T = 'currency'; K = 'safe' }
    @{ H = 'Profit Engine result'; W = 24; T = 'wrap'; K = 'result' }, @{ H = 'Notes'; W = 44; T = 'wrap'; K = 'notes' })
function New-Sheet([string]$name, $colsDef, $recs) {
    $i = 0
    $rowsOut = foreach ($rec in $recs) { $i++; , @($colsDef | ForEach-Object { if ($_.K -eq '#') { $i } else { $rec[$_.K] } }) }
    @{ Name = $name; Columns = @($colsDef | ForEach-Object { @{ Header = $_.H; Width = $_.W; Type = $_.T } }); Rows = @($rowsOut) }
}

# ---------------- summary ----------------
$sumRows = New-Object System.Collections.Generic.List[object]
function SR($item, $value, $note = '') { $sumRows.Add(@($item, $value, $note)) }
$hunt = if ($Date -ge $RULE_FROM) { 'ali', 'gd', 'aw' } else { 'ali', 'gd', 'amz' }   # Amazon paused, AW Dropship active (user 2026-11-25)
SR 'Date' $Date 'UK date of the research run'
SR 'Workbook rebuilt (UK)' ((Get-Date).ToString('yyyy-MM-dd HH:mm')) 'full format rebuild from the hunt notes; earlier hand-built workbook/CSVs are kept unchanged (CLAUDE.md s19)'
SR 'Total products evaluated' $records.Count 'every product examined (see All Evaluated)'
foreach ($k in 'ali', 'gd', 'amz', 'aw', 'sy', 'none') { $n = @($records | Where-Object { $_.source -eq $srcLabel[$k] }).Count; if ($n -or $k -in $hunt) { SR "$($srcLabel[$k]) evaluated" $n $(if ($k -eq 'amz' -and $n -eq 0) { 'not run' } else { '' }) } }
SR 'Selected (passed every gate)' $recSel.Count 'see Daily 20'
foreach ($k in $hunt) { $n = @($recSel | Where-Object { $_.source -eq $srcLabel[$k] }).Count; SR "$($srcLabel[$k]) selected" $n "target 5; shortfall $([math]::Max(0, 5 - $n)); not padded with weak products" }
SR 'Total target' 15 'a target, not a quota'
SR 'Actual total selected' $recSel.Count "shortfall $([math]::Max(0, 15 - $recSel.Count))"
SR 'WATCH (near-miss, recheck later)' @($records | Where-Object { $_.cat -eq 'WATCH' }).Count 'see Rejected (decision says WATCH)'
SR 'Rejected' @($records | Where-Object { $_.cat -eq 'REJECTED' }).Count 'see Rejected and Rejection Details'
SR 'ESTIMATED financial results (selected)' @($recSel | Where-Object { $_.basis -eq 'ESTIMATED' }).Count 'fee categories assumed (hand calculation); highlighted yellow'
SR 'Compliance review needed' @($recSel | Where-Object { $_.compliance -ne 'PASS' }).Count 'retailer-sourced items stay COMPLIANCE_REVIEW until the user clears them'
$sf = Join-Path $daily "${Date}_summary_rows.psv"
if (Test-Path -LiteralPath $sf) { foreach ($x in (Import-Csv -LiteralPath $sf -Delimiter '|')) { SR $x.item $x.value $x.note } }
$script:SUMX = @(); $sx = Join-Path $daily "${Date}_summary_rows.ps1"
if (Test-Path -LiteralPath $sx) { . $sx; foreach ($x in $script:SUMX) { SR $x[0] $x[1] $x[2] } }
SR 'Important notes' 'Research only: nothing was purchased, listed or published. Row numbers are not a quality rank. UNKNOWN means not observed. Profit Engine figures are used where the product reached it; otherwise fees use an assumed eBay category (home 14.7%, health and beauty 13.5%, mobile 12.3% incl 0.35% regulatory and 20% VAT), fixed fees and ad rate per CLAUDE.md s10.' ''
$sumSheet = @{ Name = 'Summary'; Columns = @(@{ Header = 'Item'; Width = 38; Type = 'wrap' }, @{ Header = 'Value'; Width = 50; Type = 'auto' }, @{ Header = 'Notes'; Width = 70; Type = 'wrap' }); Rows = $sumRows.ToArray() }

$planRows = foreach ($c in $calendar) {
    , @($Date, $c.name, $c.type, $(if ($c.type -eq 'window') { $c.anchor_date } else { $c.event_date }), $(if ($c.type -eq 'window') { $c.window_start } else { 'N/A' }), $(if ($c.type -eq 'window') { $c.window_end } else { 'N/A' }),
        $c.days_until, $c.preferred_listing_start, $c.minimum_listing_start, $c.phase, $c.days_remaining_in_season, $c.priority, $c.role, "Lead-time dates are the user's business planning assumption, not an eBay requirement.")
}
$planSheet = @{ Name = 'Seasonal Plan'; Rows = @($planRows); Columns = @(
        @{ Header = "Today's UK date"; Width = 13; Type = 'date' }, @{ Header = 'Event / season'; Width = 20; Type = 'text' }, @{ Header = 'Type'; Width = 8; Type = 'text' }
        @{ Header = 'Event date (or season anchor)'; Width = 14; Type = 'date' }, @{ Header = 'Season window start'; Width = 13; Type = 'date' }, @{ Header = 'Season window end'; Width = 13; Type = 'date' }
        @{ Header = 'Days until'; Width = 9; Type = 'int' }, @{ Header = 'Preferred listing start (60-day planning assumption)'; Width = 16; Type = 'date' }
        @{ Header = 'Minimum listing start (30-day planning assumption)'; Width = 16; Type = 'date' }, @{ Header = 'Current phase'; Width = 19; Type = 'text' }
        @{ Header = 'Days left in season'; Width = 10; Type = 'int' }, @{ Header = 'Calendar priority'; Width = 12; Type = 'text' }, @{ Header = 'Seasonal bucket'; Width = 24; Type = 'text' }
        @{ Header = 'Notes'; Width = 60; Type = 'wrap' }) }

$out = Join-Path $daily "${Date}_ebay_product_hunt.xlsx"
$k = 1; while (Test-Path -LiteralPath $out) { $k++; $out = Join-Path $daily "${Date}_ebay_product_hunt_run$k.xlsx" }   # never overwrite (CLAUDE.md s19)
New-XlsxWorkbook -Path $out -Sheets @(
    (New-Sheet 'Daily 20' $C_MAIN $recSel),
    (New-Sheet 'Variants' $C_VAR @($recSel | ForEach-Object { $_.variants })),
    (New-Sheet 'Rejected' $C_REJ $recRej),
    (New-Sheet 'Rejection Details' $C_DET $recRej),
    (New-Sheet 'All Evaluated' $C_AUDIT $recAll),
    $sumSheet, $planSheet)
"Written: $out  (selected $($recSel.Count), rejected/watch $($recRej.Count), all $($recAll.Count))"

if ($ReviewJson) {
    $rjOut = Join-Path $daily "${Date}_review.json"
    if (Test-Path -LiteralPath $rjOut) { "Skipped: $rjOut already exists (never overwritten)" }
    else {
        foreach ($rec in $records) { $rec.roiMin = 'N/A'; $rec.roiBypass = 'N/A'; if (-not $rec.evidence) { $rec.evidence = 'UNKNOWN' } }
        $per = foreach ($k in $hunt) { $lab = $srcLabel[$k]; $ev = @($records | Where-Object { $_.source -eq $lab }).Count; $se = @($recSel | Where-Object { $_.source -eq $lab }).Count
            [ordered]@{ selected = $se; qualified = $se; source = $lab; has_file = ($ev -gt 0); evaluated = $ev; shortfall = [math]::Max(0, 5 - $se) } }
        $bk = foreach ($b in @(@('evergreen', 8), @('current_event', 4), @('next_event_preparation', 3))) { [ordered]@{ bucket = $b[0]; selected = @($recSel | Where-Object { $_.bucket -eq $b[0] }).Count; target = $b[1] } }
        $cal = foreach ($c in $calendar) { [ordered]@{ name = $c.name; type = $c.type; event_date = $c.event_date; window_start = $c.window_start; window_end = $c.window_end; anchor_date = $c.anchor_date
                days_until = [int]$c.days_until; preferred_listing_start = $c.preferred_listing_start; minimum_listing_start = $c.minimum_listing_start; phase = $c.phase; days_remaining_in_season = $c.days_remaining_in_season; priority = $c.priority; role = $c.role } }
        $obj = [ordered]@{ date = $Date; run = 1; generated_uk = (Get-Date).ToString('yyyy-MM-dd'); total_target = 15; per_source_target = 5; total_selected = $recSel.Count
            per_source = @($per); buckets = @($bk); allocation_changed = [bool]$AllocationReason; allocation_reason = $AllocationReason
            counts = [ordered]@{ qualified = $recSel.Count; surplus = 0; rejected = $recRej.Count; evaluated = $records.Count; duplicates = 0; unknown = 0 }
            blocked = $Blocked; run_notes = $RunNotes; calendar = @($cal); selected = @($recSel); rejected = @($recRej); all = @($recAll) }
        [IO.File]::WriteAllText($rjOut, ($obj | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
        "Written: $rjOut"
    }
}
