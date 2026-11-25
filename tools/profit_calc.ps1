<#
Profit Engine calculator (CLAUDE.md §3, §10). Deterministic arithmetic for prompts/stages/profit_engine.md.

Reads eBay verification rows (proceed_to_profit = YES), applies the CLAUDE.md §10 formulas,
and APPENDS results to the profit CSV. Never overwrites. Never invents a fee: missing values stay UNKNOWN.

Value statuses: VERIFIED (observed, with evidence), USER_SET (a rate the user chose, e.g. ad rate),
ESTIMATED (assumption, e.g. a config fee not observed for this listing), UNKNOWN.

Usage:
  .\tools\profit_calc.ps1                          # today's UK date
  .\tools\profit_calc.ps1 -Date 2026-10-02
  .\tools\profit_calc.ps1 -AdRate 0.07             # higher ad rate for this run (never below the price tier's ad rate; VAT added)
  .\tools\profit_calc.ps1 -NoInsertionFee          # leave the insertion fee out for this run (free listing allowance)
#>
param(
    [string]$Date,
    [string]$InputFile,
    [string]$OutputFile,
    [string]$ExceptionsFile,
    [string]$ConfigFile,
    [Nullable[double]]$AdRate,
    [switch]$NoInsertionFee,
    [string]$FeeTableFile      # default: data/fees/<Date>_ebay_business_fees.csv (today's observed eBay fee page)
)
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
$root = Split-Path $PSScriptRoot -Parent

$tz = [TimeZoneInfo]::FindSystemTimeZoneById('GMT Standard Time')
$nowUk = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz)
if (-not $Date) { $Date = $nowUk.ToString('yyyy-MM-dd') }
if (-not $InputFile) { $InputFile = Join-Path $root "data\ebay\${Date}_ebay_verification.csv" }
if (-not $OutputFile) { $OutputFile = Join-Path $root "data\profit\${Date}_profit.csv" }
if (-not $ExceptionsFile) { $ExceptionsFile = Join-Path $root "data\profit\${Date}_profit_exceptions.csv" }
if (-not $ConfigFile) { $ConfigFile = Join-Path $root 'config.yaml' }

# CLAUDE.md §3 thresholds. Changing these requires a CHANGE_PROPOSAL (§28).
$PRICE_MIN = 2.0; $PRICE_MAX = 35.0   # user rule 2026-10-06: minimum eBay listing price GBP 2 (was 5)
$MIN_PROFIT = 1.0                # profit must be at least £1, always (user rule 2026-10-02)
# Pricing tiers by eBay LISTING price (user rule 2026-10-08; replaces the 2026-10-03 item-cost ROI tiers):
#   tier 1: listing price <  £8.00 -> at least £1 profit, any margin; ad rate 3% (+ VAT)
#   tier 2: listing price >= £8.00 -> at least £1 profit AND (at least 30% margin OR at least 20% ROI); ad rate 5% (+ VAT)
#           (user, same day: 20%+ ROI overrides the 30% margin rule; the product passes with a "margin under 30%" note)
$TIER_BREAK = 8.0
$MARGIN_MIN_TIER2 = 0.30
$ROI_ALT_MIN = 0.20
$FORMULA_VERSION = 'claude_md_s10_v8'   # v7: ad rate 5% + VAT (2026-10-03); v8: listing-price tiers, 3%/5% ads, 30% margin, no ROI gate (2026-10-08)

function ConvertTo-Num([object]$v) {
    if ($null -eq $v) { return $null }
    $s = "$v".Trim()
    if ($s -eq '' -or $s -match '^(UNKNOWN|N/A|NA)$') { return $null }
    $pct = $s.EndsWith('%')
    $s = $s.TrimEnd('%').Replace([string][char]0x00A3, '').Replace(',', '').Trim()
    $d = 0.0
    if (-not [double]::TryParse($s, [Globalization.NumberStyles]::Float, $inv, [ref]$d)) { return $null }
    if ($pct) { $d = $d / 100 }
    return $d
}
function Get-Col($row, [string]$name) {
    if ($row.PSObject.Properties.Name -contains $name) { return $row.$name } else { return $null }
}
function Fmt([object]$d, [int]$dp = 2) {
    if ($null -eq $d) { return 'UNKNOWN' }
    return ([double]$d).ToString("F$dp", $inv)
}
function Pct([object]$d) {
    if ($null -eq $d) { return 'UNKNOWN' }
    return ([double]$d * 100).ToString('F1', $inv)
}
function P2([object]$d) { if ($null -eq $d) { return 'UNKNOWN' }; return ([double]$d * 100).ToString('0.##', $inv) }
function CeilPenny([double]$d) { return [math]::Ceiling($d * 100 - 1e-9) / 100 }

# Read simple "key: value" settings from config.yaml (flat keys inside the fees/profit blocks).
function Get-ConfigValue([string]$text, [string]$block, [string]$key) {
    $m = [regex]::Match($text, "(?ms)^$block\s*:\s*\r?\n(.*?)(?=^\S|\z)")
    if (-not $m.Success) { return $null }
    $k = [regex]::Match($m.Groups[1].Value, "(?m)^\s+$key\s*:\s*([^#\r\n]*)")
    if (-not $k.Success) { return $null }
    return $k.Groups[1].Value.Trim()
}
$cfg = Get-Content -Raw -LiteralPath $ConfigFile
$cfgAdRate = ConvertTo-Num (Get-ConfigValue $cfg 'fees' 'ad_rate')                     # listing price £8 or more (user: 5%)
$cfgAdMin = ConvertTo-Num (Get-ConfigValue $cfg 'fees' 'ad_rate_minimum')
$cfgAdLow = ConvertTo-Num (Get-ConfigValue $cfg 'fees' 'ad_rate_low_price')             # listing price under £8 (user 2026-10-08: 3%)
if ($null -eq $cfgAdLow) { $cfgAdLow = 0.03 }
$cfgBuyFee = ConvertTo-Num (Get-ConfigValue $cfg 'fees' 'sourcing_buying_fee')
$cfgBuyRate = ConvertTo-Num (Get-ConfigValue $cfg 'fees' 'sourcing_buying_fee_rate')   # share of item cost (user: 8%)
$cfgBuyRateGds = ConvertTo-Num (Get-ConfigValue $cfg 'fees' 'sourcing_buying_fee_rate_godropship')   # Go Dropship only (user 2026-10-13: 0%, was 3%)
$cfgBuyRateAmz = ConvertTo-Num (Get-ConfigValue $cfg 'fees' 'sourcing_buying_fee_rate_amazon')   # Amazon only (user 2026-10-13: 0%, was 8%)
# AliExpress cost factors (user rule 2026-10-13): read daily from data/fees/<Date>_aliexpress_cost_factors.csv
# (kind,rate_or_amount,...), else config.yaml aliexpress.*. Cost = listed item cost + AliExpress shipping
# + VAT charged at checkout (UK 20%, on item + shipping) + FX / payment-processing buffer (about 2%, on item + shipping + VAT).
$aliFactorsPath = Join-Path $root "data\fees\${Date}_aliexpress_cost_factors.csv"
$aliFactors = if (Test-Path -LiteralPath $aliFactorsPath) { @(Import-Csv -LiteralPath $aliFactorsPath) } else { $null }
function Get-AliFactor([string]$kind, [string]$cfgKey, [double]$default) {
    $x = @($aliFactors | Where-Object { $_.kind -eq $kind }) | Select-Object -First 1
    if ($x) { $v = ConvertTo-Num $x.rate_or_amount; if ($null -ne $v) { return @{ v = [double]$v; src = "data/fees/${Date}_aliexpress_cost_factors.csv" } } }
    $c = ConvertTo-Num (Get-ConfigValue $cfg 'aliexpress' $cfgKey); if ($null -ne $c) { return @{ v = [double]$c; src = "config.yaml aliexpress.$cfgKey (no daily file)" } }
    return @{ v = $default; src = "default $default (no daily file, no config)" }
}
$ALI_VAT = Get-AliFactor 'VAT_RATE' 'vat_rate' 0.20
$ALI_FX = Get-AliFactor 'FX_PAYMENT_BUFFER' 'fx_payment_buffer' 0.02
$cfgInsFee = ConvertTo-Num (Get-ConfigValue $cfg 'fees' 'insertion_fee')
$cfgInsOn = "$(Get-ConfigValue $cfg 'fees' 'include_insertion_fee')".Trim().ToLower() -ne 'false'
if ($NoInsertionFee) { $cfgInsOn = $false }
# eBay fees from CURRENT data (user rule 2026-10-03): today's observed eBay business-seller fee table
# (data/fees/<date>_ebay_business_fees.csv, written at each run from eBay's fee page), looked up by the
# product's eBay category. The user is not VAT registered, so eBay adds VAT to its fees.
$vatRegistered = "$(Get-ConfigValue $cfg 'fees' 'vat_registered')".Trim().ToLower() -eq 'true'
$feeVat = ConvertTo-Num (Get-ConfigValue $cfg 'fees' 'fee_vat_rate'); if ($null -eq $feeVat) { $feeVat = 0.20 }
$VATX = if ($vatRegistered) { 1.0 } else { 1 + $feeVat }
$adVatOn = "$(Get-ConfigValue $cfg 'fees' 'ad_fee_vat')".Trim().ToLower() -eq 'true'
$ADVATX = if ($adVatOn -and -not $vatRegistered) { 1 + $feeVat } else { 1.0 }
$feeTablePath = if ($FeeTableFile) { $FeeTableFile } else { Join-Path $root "data\fees\${Date}_ebay_business_fees.csv" }
$feeTable = if (Test-Path -LiteralPath $feeTablePath) { @(Import-Csv -LiteralPath $feeTablePath) } else { $null }
function Get-FeeAmt([string]$kind) { $x = @($feeTable | Where-Object { $_.kind -eq $kind }) | Select-Object -First 1; if ($x) { return (ConvertTo-Num $x.rate_or_amount) } return $null }
$REG = $null; $PO_LOW = $null; $PO_HIGH = $null; $PO_RED = $null
if ($feeTable) { $REG = Get-FeeAmt 'REGULATORY'; $PO_LOW = Get-FeeAmt 'PER_ORDER_LOW'; $PO_HIGH = Get-FeeAmt 'PER_ORDER_HIGH'; $PO_RED = Get-FeeAmt 'PER_ORDER_REDUCED' }
# Most specific match: the fee category whose name/alias equals the DEEPEST segment of the eBay category path.
function Find-FeeCategory([string]$path) {
    if (-not $feeTable -or "$path" -match '^\s*(UNKNOWN|N/A)?\s*$') { return $null }
    $segs = @($path -split '>' | ForEach-Object { $_.Trim().ToLower() })
    $best = $null; $bestIdx = -1
    foreach ($f in ($feeTable | Where-Object { $_.kind -eq 'FVF' })) {
        foreach ($al in (@($f.category) + @("$($f.path_aliases)" -split ';'))) {
            $a = "$al".Trim().ToLower(); if (-not $a) { continue }
            for ($i = $segs.Count - 1; $i -ge 0; $i--) { if ($segs[$i] -eq $a) { if ($i -gt $bestIdx) { $bestIdx = $i; $best = $f }; break } }
        }
    }
    return $best
}
$priceBasis = Get-ConfigValue $cfg 'profit' 'listed_price_basis'
if (-not $priceBasis) { $priceBasis = 'reference_seller_price' }   # CLAUDE.md §10: eBay competitor's listing price

if (-not (Test-Path -LiteralPath $InputFile)) { throw "eBay verification file not found: $InputFile" }
$rows = @(Import-Csv -LiteralPath $InputFile | Where-Object { $_.proceed_to_profit -eq 'YES' })

$exceptions = @{}
if (Test-Path -LiteralPath $ExceptionsFile) {
    foreach ($e in Import-Csv -LiteralPath $ExceptionsFile) {
        $exceptions["$($e.candidate_id)|$($e.gate)"] = $e.justification
    }
}

# Returns @{ v = value or $null; s = VERIFIED|USER_SET|ESTIMATED|UNKNOWN; src = text }
function Resolve-Input([object]$value, [string]$status, [string]$src) {
    $n = ConvertTo-Num $value
    if ($null -eq $n) { return @{ v = $null; s = 'UNKNOWN'; src = 'not available' } }
    $st = "$status".Trim().ToUpper()
    if ($st -notin @('VERIFIED', 'USER_SET', 'ESTIMATED')) { $st = 'UNKNOWN'; $n = $null }
    return @{ v = $n; s = $st; src = $src }
}

$rank = @{ 'FAIL' = 4; 'EXCEPTION' = 3; 'UNKNOWN' = 2; 'PASS' = 1 }
$out = foreach ($r in $rows) {
    $id = $r.candidate_id
    $notes = New-Object System.Collections.Generic.List[string]

    # --- Inputs ---------------------------------------------------------------
    $S = Resolve-Input (Get-Col $r 'source_price') (Get-Col $r 'source_price_status') 'source page'
    $D = Resolve-Input (Get-Col $r 'source_delivery_charge') (Get-Col $r 'source_delivery_charge_status') 'source page'
    $B = Resolve-Input (Get-Col $r 'sourcing_buying_fee') (Get-Col $r 'sourcing_buying_fee_status') 'source page'
    if ($B.s -eq 'UNKNOWN' -and $null -ne $cfgBuyFee) { $B = @{ v = $cfgBuyFee; s = 'ESTIMATED'; src = 'config.yaml fees.sourcing_buying_fee' } }
    elseif ($B.s -eq 'UNKNOWN' -and ("$(Get-Col $r 'source')" -match 'Ali') -and $null -ne $S.v) {
        # AliExpress: VAT charged at checkout on item + shipping, then the FX / payment-processing buffer (user rule 2026-10-13)
        $dv = if ($null -ne $D.v) { [double]$D.v } else { 0.0 }
        $vatAmt = $ALI_VAT.v * ([double]$S.v + $dv)
        $fxAmt = $ALI_FX.v * ([double]$S.v + $dv + $vatAmt)
        $B = @{ v = [math]::Round($vatAmt + $fxAmt, 2); s = 'ESTIMATED'; src = "AliExpress checkout VAT $(Pct $ALI_VAT.v)% on item + shipping + FX/payment buffer $(Pct $ALI_FX.v)% ($($ALI_VAT.src))" }
    }
    elseif ($B.s -eq 'UNKNOWN' -and $null -ne $cfgBuyRate -and $null -ne $S.v) {
        # user rule 2026-10-07: Go Dropship buying fee 3% (config fees.sourcing_buying_fee_rate_godropship); other sources keep the default rate
        $rate = $cfgBuyRate; $rkey = 'sourcing_buying_fee_rate'
        if ("$(Get-Col $r 'source')" -match 'Go ?Dropship' -and $null -ne $cfgBuyRateGds) { $rate = $cfgBuyRateGds; $rkey = 'sourcing_buying_fee_rate_godropship' }
        if ("$(Get-Col $r 'source')" -match 'Amazon' -and $null -ne $cfgBuyRateAmz) { $rate = $cfgBuyRateAmz; $rkey = 'sourcing_buying_fee_rate_amazon' }
        $B = @{ v = [math]::Round($rate * $S.v, 2); s = 'ESTIMATED'; src = "config.yaml fees.$rkey ($(Pct $rate)% of item cost)" }
    }

    # NB: PowerShell variable names are case-insensitive; keep fee variable names distinct.
    $catPath = "$(Get-Col $r 'ebay_category_path')"; if ($catPath -match '^\s*(UNKNOWN|N/A)?\s*$') { $catPath = "$(Get-Col $r 'ebay_category')" }
    $feeCat = Find-FeeCategory $catPath
    $vatTxt = if ($vatRegistered) { 'no VAT added (VAT registered)' } else { "+ VAT $(P2 $feeVat)% (not VAT registered)" }
    $poLow = $null; $poHigh = $null; $feeCatName = 'UNKNOWN'
    if (-not $feeTable) {
        $feeRate = @{ v = $null; s = 'UNKNOWN'; src = "eBay fee table not recorded for $Date (data/fees/${Date}_ebay_business_fees.csv)" }
        $fixedFee = @{ v = $null; s = 'UNKNOWN'; src = $feeRate.src }
        $notes.Add("eBay fee UNKNOWN: today's fee table was not recorded from eBay's fee page.")
    } elseif (-not $feeCat -or $null -eq $REG) {
        $feeRate = @{ v = $null; s = 'UNKNOWN'; src = "eBay category '$(if ($catPath) { $catPath } else { 'UNKNOWN' })' not matched in today's fee table" }
        $fixedFee = @{ v = $null; s = 'UNKNOWN'; src = $feeRate.src }
        $notes.Add("eBay fee UNKNOWN: eBay category not recorded or not in today's fee table.")
    } else {
        $fvfR = ConvertTo-Num $feeCat.rate_or_amount; $feeCatName = $feeCat.category
        # INC-003: a fee table read on another day is not "current data" -> ESTIMATED, never VERIFIED.
        $feeSt = if ("$($feeCat.observed_date)" -eq $Date) { 'VERIFIED' } else { 'ESTIMATED' }
        if ($feeSt -eq 'ESTIMATED') { $notes.Add("eBay fee ESTIMATED: fee table observed $($feeCat.observed_date), calculation date $Date.") }
        $feeRate = @{ v = ($fvfR + $REG) * $VATX; s = $feeSt; src = "eBay business fees $($feeCat.observed_date): $($feeCat.category) $(P2 $fvfR)% + regulatory $(P2 $REG)% $vatTxt" }
        $poLow = $(if ("$($feeCat.reduced_per_order_applies)" -eq 'YES' -and $null -ne $PO_RED) { $PO_RED } else { $PO_LOW }) * $VATX
        $poHigh = $PO_HIGH * $VATX
        $fixedFee = @{ v = $poHigh; s = $feeSt; src = "per-order fee GBP $(Fmt $PO_LOW)/$(Fmt $PO_HIGH) (orders up to/over GBP 10)$(if ("$($feeCat.reduced_per_order_applies)" -eq 'YES') { ", reduced GBP $(Fmt $PO_RED) up to GBP 10 in Home, Furniture & DIY" }) $vatTxt" }
    }
    # Insertion (listing) fee per sale, inc. VAT, when over the free listing allowance (user setting).
    if (-not $cfgInsOn) { $insFee = @{ v = 0.0; s = 'USER_SET'; src = 'insertion fee excluded (free listing allowance)' } }
    elseif ($null -ne $cfgInsFee) { $insFee = @{ v = $cfgInsFee; s = 'ESTIMATED'; src = 'config.yaml fees.insertion_fee (user setting)' } }
    else { $insFee = @{ v = $null; s = 'UNKNOWN'; src = 'config UNKNOWN' } }

    switch ($priceBasis) {
        'reference_seller_price' { $P = Resolve-Input (Get-Col $r 'reference_seller_price') 'VERIFIED' 'eBay competitor listing price (reference seller)' }
        default { $P = Resolve-Input (Get-Col $r 'sold_price_total_median') 'VERIFIED' 'median total sold price of matched eBay sample' }
    }

    # Ad rate by listing price (user rule 2026-10-08): under £8 -> 3%, £8 or more -> 5%. A higher rate may be
    # used (-AdRate), never a lower one than the tier's rate.
    $adHigh = if ($null -ne $cfgAdRate) { $cfgAdRate } else { $cfgAdMin }
    if ($null -ne $adHigh -and $null -ne $cfgAdMin -and $adHigh -lt $cfgAdMin) { $adHigh = $cfgAdMin }
    $adLow = $cfgAdLow
    if ($null -ne $AdRate) { $adHigh = [math]::Max([double]$AdRate, [double]$adHigh); $adLow = [math]::Max([double]$AdRate, [double]$adLow) }
    $adSrc = if ($null -ne $AdRate) { 'user-set for this run (-AdRate), not below the tier rate' } else { 'config.yaml fees.ad_rate_low_price (under GBP 8) / fees.ad_rate (GBP 8 or more)' }
    # Amazon-sourced rows (user rule 2026-10-13): promoted-listing ad rate 3% at every listing price (config fees.ad_rate_amazon).
    $cfgAdAmz = ConvertTo-Num (Get-ConfigValue $cfg 'fees' 'ad_rate_amazon')
    if (("$(Get-Col $r 'source')" -match 'Amazon') -and $null -ne $cfgAdAmz) {
        $adHigh = [double]$cfgAdAmz; $adLow = [double]$cfgAdAmz
        if ($null -ne $AdRate) { $adHigh = [math]::Max([double]$AdRate, $adHigh); $adLow = [math]::Max([double]$AdRate, $adLow) }
        $adSrc = 'config.yaml fees.ad_rate_amazon (Amazon-sourced products, user rule 2026-10-13)'
    }
    if ($null -eq $adHigh) { $a = @{ v = $null; s = 'UNKNOWN'; src = 'no ad rate set' } }
    elseif ($null -ne $P.v -and $P.v -lt $TIER_BREAK) { $a = @{ v = $adLow; s = 'USER_SET'; src = "$adSrc; listing price under GBP $(Fmt $TIER_BREAK)" } }
    else { $a = @{ v = $adHigh; s = 'USER_SET'; src = "$adSrc; listing price GBP $(Fmt $TIER_BREAK) or more" } }
    # The per-order fee depends on the order total (eBay: up to GBP 10 / over GBP 10).
    if ($null -ne $poLow -and $null -ne $P.v -and $P.v -le 10) { $fixedFee.v = $poLow }

    $inputs = [ordered]@{ source_price = $S; source_delivery_charge = $D; sourcing_buying_fee = $B; ebay_fee_rate = $feeRate; ebay_fixed_fee = $fixedFee; insertion_fee = $insFee; ad_rate = $a; listed_price = $P }
    $unknown = @($inputs.Keys | Where-Object { $inputs[$_].s -eq 'UNKNOWN' })
    $estimated = @($inputs.Keys | Where-Object { $inputs[$_].s -eq 'ESTIMATED' })
    $calcStatus = if ($unknown.Count) { 'UNKNOWN' } elseif ($estimated.Count) { 'ESTIMATED' } else { 'VERIFIED' }

    # --- Arithmetic (CLAUDE.md §10). Unknown costs/rates -> 0 gives an UPPER BOUND on profit. --
    $v = @{}; foreach ($inName in $inputs.Keys) { $v[$inName] = if ($null -ne $inputs[$inName].v) { [double]$inputs[$inName].v } else { 0.0 } }
    $profit = $null; $margin = $null; $roi = $null; $ebayFeeAmt = $null; $adCost = $null; $totalCost = $null
    $ub = $null; $ubMargin = $null; $ubRoi = $null
    $minList = $null; $minAll = $null
    # Amazon-sourced products (user rule 2026-10-14): minimum margin 15% from GBP 8 (20% ROI still passes too); other sources keep 30% margin or 20% ROI.
    $isAmzRow = ("$(Get-Col $r 'source')" -match 'Amazon')
    $mMinEff = if ($isAmzRow) { 0.15 } else { $MARGIN_MIN_TIER2 }
    $rAltEff = $ROI_ALT_MIN
    # Promoted-listing fees also carry VAT when the user is not VAT registered (user rule 2026-10-03): 5% -> 6%.
    $v.ad_rate = $v.ad_rate * $ADVATX
    $r_ = $v.ebay_fee_rate + $v.ad_rate
    $C = $v.source_price + $v.source_delivery_charge + $v.sourcing_buying_fee + $v.ebay_fixed_fee + $v.insertion_fee   # per-order costs
    $K = $v.source_price + $v.source_delivery_charge + $v.sourcing_buying_fee                                         # ROI cost base (recorded only)
    $Pv = $inputs.listed_price.v
    # Pricing tier by eBay listing price (user rule 2026-10-08); unknown price -> tier unknown.
    $tier = $null; $marginMin = $null
    if ($null -ne $Pv) { if ($Pv -lt $TIER_BREAK) { $tier = 1 } else { $tier = 2; $marginMin = $mMinEff } }

    if ($null -ne $Pv -and $Pv -gt 0) {
        $p0 = $Pv * (1 - $r_) - $C
        if ($calcStatus -eq 'UNKNOWN') {
            $ub = $p0; $ubMargin = $p0 / $Pv
            if ($inputs.source_price.v -and $K -gt 0) { $ubRoi = $p0 / $K }
        } else {
            $ebayFeeAmt = $v.ebay_fee_rate * $Pv + $v.ebay_fixed_fee + $v.insertion_fee
            $adCost = $v.ad_rate * $Pv
            $totalCost = $v.source_price + $v.source_delivery_charge + $v.sourcing_buying_fee + $ebayFeeAmt + $adCost
            $profit = $Pv - $totalCost
            $margin = $profit / $Pv
            if ($K -gt 0) { $roi = $profit / $K }
        }
    }
    if ($calcStatus -ne 'UNKNOWN' -and $null -ne $adHigh) {
        # minimum_listing_price = the lowest price that passes (user rule 2026-10-08):
        #   under £8 (3% ads): (C + £1) / (1 - f - a3)                      -> used if it is under £8
        #   otherwise (5% ads): max(£8, (C + £1) / (1 - f - a5), C / (1 - f - a5 - 30%))
        # C uses the per-order fee for orders up to GBP 10 first; if that price is over GBP 10, the higher fee is used.
        $f = $v.ebay_fee_rate; $aLo = $adLow * $ADVATX; $aHi = $adHigh * $ADVATX
        $Cb = $C - $v.ebay_fixed_fee
        $poL = if ($null -ne $poLow) { $poLow } else { $v.ebay_fixed_fee }
        $poH = if ($null -ne $poHigh) { $poHigh } else { $v.ebay_fixed_fee }
        # From £8: £1 profit AND (30% margin OR 20% ROI) -> the cheaper of the two conditions.
        $solve = { param($po) $d1 = 1 - $f - $aHi; if ($d1 -le 0) { return $null }
                   $byRoi = if ($rAltEff -ge 50) { [double]::MaxValue } else { ($Cb + $po + $rAltEff * $K) / $d1 }
                   $d2 = $d1 - $mMinEff; $alt = if ($d2 -gt 0) { [math]::Min(($Cb + $po) / $d2, $byRoi) } else { $byRoi }
                   [math]::Max([math]::Max($TIER_BREAK, ($Cb + $po + $MIN_PROFIT) / $d1), $alt) }
        $mLow = if ((1 - $f - $aLo) -gt 0) { CeilPenny (($Cb + $poL + $MIN_PROFIT) / (1 - $f - $aLo)) } else { $null }
        if ($null -ne $mLow -and $mLow -lt $TIER_BREAK) { $minList = $mLow }
        else {
            $m = & $solve $poL
            if ($null -ne $m -and $m -gt 10) { $m = & $solve $poH }
            if ($null -ne $m) { $minList = CeilPenny $m }
        }
        if ($null -ne $minList) { $minAll = [math]::Max($minList, $PRICE_MIN) }
    }

    # --- Gates ----------------------------------------------------------------
    $priceGate = if ($null -eq $Pv) { 'UNKNOWN' } elseif ($Pv -ge $PRICE_MIN -and $Pv -le $PRICE_MAX) { 'PASS' } else { 'FAIL' }
    if ($calcStatus -ne 'UNKNOWN' -and $null -ne $profit) {
        $profitGate = if ($profit -ge $MIN_PROFIT) { 'PASS' } else { 'FAIL' }
        if ($tier -eq 1) { $marginGate = 'N/A' }
        elseif ($margin -ge $marginMin) { $marginGate = 'PASS' }
        elseif ($null -ne $roi -and $roi -ge $rAltEff) {
            # User rule 2026-10-08: 20%+ ROI overrides the 30% margin rule; pass with a note.
            $marginGate = 'PASS'; $notes.Add("NOTE: margin $(Pct $margin)% is less than 30%; passed on ROI $(Pct $roi)% (20%+ ROI overrides the margin rule).")
        } else { $marginGate = 'FAIL' }
    } elseif ($null -ne $ub) {
        # Upper bound fails -> the real figure fails too. Upper bound passes -> still UNKNOWN.
        $profitGate = if ($ub -lt $MIN_PROFIT) { 'FAIL' } else { 'UNKNOWN' }
        if ($tier -eq 1) { $marginGate = 'N/A' }
        else { $marginGate = if ($null -ne $ubMargin -and $ubMargin -lt $marginMin -and $null -ne $ubRoi -and $ubRoi -lt $rAltEff) { 'FAIL' } else { 'UNKNOWN' } }
        if ($profitGate -eq 'FAIL' -or $marginGate -eq 'FAIL') { $notes.Add('FAIL proven by upper bound: unknown costs can only lower profit/margin.') }
    } else { $profitGate = 'UNKNOWN'; $marginGate = $(if ($tier -eq 1) { 'N/A' } else { 'UNKNOWN' }) }
    if ($null -ne $Pv -and $null -ne $minAll -and $Pv -lt $minAll) { $notes.Add("Competitor price GBP $(Fmt $Pv) is below the minimum listing price GBP $(Fmt $minAll).") }

    # Exceptions: only for a gate that FAILED on a completed (VERIFIED/ESTIMATED) calculation.
    $exc = New-Object System.Collections.Generic.List[string]
    $gates = [ordered]@{ price = $priceGate; profit = $profitGate; margin = $marginGate }
    foreach ($g in @($gates.Keys)) {
        $key = "$id|$g"
        if ($exceptions.ContainsKey($key)) {
            if ($gates[$g] -eq 'FAIL' -and $calcStatus -ne 'UNKNOWN') { $gates[$g] = 'EXCEPTION'; $exc.Add("${g}: $($exceptions[$key])") }
            else { $notes.Add("Exception requested for '$g' not applied (gate is $($gates[$g]); calculation $calcStatus).") }
        }
    }
    $upstreamExc = "$(Get-Col $r 'exceptions')"
    if ($upstreamExc -and $upstreamExc -notmatch '^(N/A|UNKNOWN)?$') { $exc.Insert(0, "upstream: $upstreamExc") }

    # --- Cost-buffer and max safe cost (user rule 2026-10-12) ------------------------------
    # max_safe_cost: the highest item cost (source_price) at which this listing price still gives
    #   GBP 1+ profit and (listing price under GBP 8: nothing more; from GBP 8: 30% margin or 20% ROI).
    # Cost buffer: AliExpress +6%, Amazon +4% (user rules 2026-10-13); the buffer gate must PASS as well.
    #   Go Dropship has no buffer (removed 2026-10-14).
    $maxSafe = $null; $bufGate = 'N/A'; $profitBuf = $null; $bufPct = 0.06; $thin = 'N/A'
    $isAli = ("$(Get-Col $r 'source')" -match 'Ali'); $isAmz = ("$(Get-Col $r 'source')" -match 'Amazon'); $isGds = ("$(Get-Col $r 'source')" -match 'Go ?Dropship'); if ($isGds) { $bufPct = 0.05 }; if ($isAmz) { $bufPct = 0.04 }   # Amazon buffer: removed 2026-10-13, re-added at 4% the same day (user)
    if ($calcStatus -ne 'UNKNOWN' -and $null -ne $Pv -and $Pv -gt 0 -and $null -ne $S.v) {
        $rateB = if ($S.v -gt 0 -and $null -ne $B.v) { $B.v / $S.v } else { 0.0 }
        $evalCost = {
            param([double]$sp)
            $fee = $sp * $rateB
            $eb = $v.ebay_fee_rate * $Pv + $v.ebay_fixed_fee + $v.insertion_fee
            $tc = $sp + $v.source_delivery_charge + $fee + $eb + $v.ad_rate * $Pv
            $pf = $Pv - $tc; $k = $sp + $v.source_delivery_charge + $fee
            $ok = ($pf -ge $MIN_PROFIT)
            if ($ok -and $Pv -ge $TIER_BREAK) { $mg = $pf / $Pv; $ro = if ($k -gt 0) { $pf / $k } else { 0 }; $ok = (($mg -ge $mMinEff) -or ($ro -ge $rAltEff)) }
            [pscustomobject]@{ ok = $ok; profit = $pf }
        }
        for ($c = [math]::Floor($Pv * 100); $c -ge 0; $c--) { if ((& $evalCost ($c / 100)).ok) { $maxSafe = $c / 100; break } }
        if ($isAli -or $isAmz) {   # Go Dropship cost buffer removed 2026-10-14 (user); max_safe_cost still recorded
            $bufRes = & $evalCost ([double]$S.v * (1 + $bufPct))
            $profitBuf = $bufRes.profit; $bufGate = $(if ($bufRes.ok) { 'PASS' } else { 'FAIL' })
            if ($bufGate -eq 'FAIL') { $notes.Add("$(if ($isAmz) { 'Amazon' } elseif ($isGds) { 'Go Dropship' } else { 'AliExpress' }) cost buffer: with item cost +$([int]($bufPct * 100))% (GBP $(Fmt ([double]$S.v * (1 + $bufPct)))) profit is GBP $(Fmt $profitBuf) and the margin/ROI rule fails.") }
        }
    }
    # Go Dropship remote-area surcharge (user rule 2026-10-13; Go Dropship shipping page, 2.1-15 kg: GBP 5-8 extra to Outer Hebrides/Shetland, NI,
    # Channel Islands, Highlands and Islands, Scilly/Isle of Wight/Isle of Man; free to the UK general area). Worst-case surcharge by parcel weight:
    # up to 2 kg GBP 2, 2.1-15 kg GBP 8, 15.01-30 kg GBP 24, over 30 kg GBP 50. For parcels OVER 2 kg the profit must still be GBP 0 or more with the
    # worst surcharge paid (flag REMOTE_RISK, not a pass/fail gate); under 2 kg the figure is recorded only (the page says free for the whole UK under 2 kg).
    $remoteSur = $null; $profitRemote = $null; $remoteGate = 'N/A'; $wKg = $null
    if ($isGds) {
        $wTxt = "$(Get-Col $r 'source_weight')"
        if ($wTxt -match '([\d\.,]+)\s*(kg|g)\b') { $wn = [double]($Matches[1] -replace ',', ''); $wKg = $(if ($Matches[2] -eq 'g') { $wn / 1000 } else { $wn }) }
        if ($null -ne $wKg) {
            $remoteSur = $(if ($wKg -le 2) { 2.0 } elseif ($wKg -le 15) { 8.0 } elseif ($wKg -le 30) { 24.0 } else { 50.0 })
            if ($null -ne $profit) { $profitRemote = $profit - $remoteSur }
            if ($wKg -gt 2 -and $null -ne $profitRemote) {
                $remoteGate = $(if ($profitRemote -ge 0) { 'OK' } else { 'REMOTE_RISK' })
                if ($remoteGate -eq 'REMOTE_RISK') { $notes.Add("Go Dropship remote-area surcharge: parcel $([math]::Round($wKg,2)) kg, worst-case extra postage GBP $(Fmt $remoteSur) turns profit GBP $(Fmt $profit) into GBP $(Fmt $profitRemote) (loss for a remote-area buyer; flagged, not a gate).") }
            }
        }
    }
    if ($bufGate -eq 'FAIL' -and $gates.profit -ne 'FAIL') { $gates['buffer'] = 'FAIL' }
    if ($null -ne $Pv -and $null -ne $minAll -and $minAll -gt 0) { $thin = $(if ($Pv -le ($minAll * 1.03)) { 'THIN' } else { 'OK' }); if ($isGds -and $null -ne $roi -and $roi -lt 0.25) { $thin = 'THIN' }; if ($thin -eq 'THIN') { $notes.Add('THIN margin: competitor price is within 3% of the minimum listing price, or (Go Dropship) ROI is under 25% (user rules 2026-10-12).') } }
    $ebayStatus = "$(Get-Col $r 'ebay_verification_status')".Trim().ToUpper()
    if (-not $rank.ContainsKey($ebayStatus)) { $ebayStatus = 'UNKNOWN' }
    $all = @($ebayStatus) + @($gates.Values | Where-Object { $_ -ne 'N/A' })
    $acceptance = ($all | Sort-Object { $rank[$_] } -Descending | Select-Object -First 1)

    [pscustomobject][ordered]@{
        profit_date              = $Date
        calculated_at_uk         = $nowUk.ToString('yyyy-MM-dd HH:mm')
        candidate_id             = $id
        source                   = Get-Col $r 'source'
        product_name             = Get-Col $r 'product_name'
        source_url               = Get-Col $r 'source_url'
        reference_seller_name    = Get-Col $r 'reference_seller_name'
        reference_seller_url     = Get-Col $r 'reference_seller_url'
        reference_seller_price   = Get-Col $r 'reference_seller_price'
        ebay_market_median_total = Get-Col $r 'sold_price_total_median'
        ebay_sold_sample_n       = Get-Col $r 'sold_sample_n'
        listed_price_basis       = $priceBasis
        listed_price             = Fmt $Pv
        listed_price_status      = $P.s
        source_price             = Fmt $S.v
        source_price_status      = $S.s
        source_delivery_charge   = Fmt $D.v
        source_delivery_status   = $D.s
        sourcing_buying_fee      = Fmt $B.v
        sourcing_buying_fee_status = $B.s
        sourcing_buying_fee_source = $B.src
        fee_category             = $feeCatName
        fee_vat_applied          = $(if ($vatRegistered) { 'NO' } else { Pct $feeVat })
        ebay_fee_rate_pct        = Pct $feeRate.v
        ebay_fee_rate_status     = $feeRate.s
        ebay_fee_rate_source     = $feeRate.src
        ebay_fixed_fee           = Fmt $fixedFee.v
        ebay_fixed_fee_status    = $fixedFee.s
        insertion_fee            = Fmt $insFee.v
        insertion_fee_status     = $insFee.s
        ebay_fee_amount          = Fmt $ebayFeeAmt
        ad_rate_pct              = Pct $a.v
        ad_rate_incl_vat_pct     = $(if ($null -ne $a.v) { Pct ($a.v * $ADVATX) } else { 'UNKNOWN' })
        ad_rate_status           = $a.s
        ad_rate_source           = $a.src
        ad_cost                  = Fmt $adCost
        total_cost               = Fmt $totalCost
        roi_cost_base            = $(if ($calcStatus -ne 'UNKNOWN') { Fmt $K } else { 'UNKNOWN' })
        profit                   = Fmt $profit
        profit_pct               = Pct $margin
        roi_pct                  = Pct $roi
        calculation_status       = $calcStatus
        unknown_inputs           = $(if ($unknown.Count) { $unknown -join ';' } else { 'none' })
        estimated_inputs         = $(if ($estimated.Count) { $estimated -join ';' } else { 'none' })
        profit_upper_bound       = Fmt $ub
        profit_pct_upper_bound   = Pct $ubMargin
        roi_pct_upper_bound      = Pct $ubRoi
        pricing_tier             = $(if ($null -ne $tier) { $tier } else { 'UNKNOWN' })
        max_safe_cost            = Fmt $maxSafe
        cost_buffer_pct          = $(if ($isAli) { '6' } elseif ($isAmz) { '4' } elseif ($isGds) { '0' } else { 'N/A' })
        thin_margin_flag         = $thin
        remote_surcharge_worst   = $(if ($null -ne $remoteSur) { Fmt $remoteSur } else { 'N/A' })
        profit_if_remote_surcharge = $(if ($null -ne $profitRemote) { Fmt $profitRemote } else { 'N/A' })
        remote_surcharge_gate    = $remoteGate
        profit_at_cost_buffer    = $(if ($null -ne $profitBuf) { Fmt $profitBuf } else { 'N/A' })
        cost_buffer_gate         = $bufGate
        price_watch              = $(if ($isAli) { 'ALIEXPRESS: cost basis = SKU List price of the exact variant; 3-month chart read (user rule 2026-11-13)' } else { 'N/A' })
        minimum_listing_price    = Fmt $minList
        roi_min_pct              = 'N/A'   # ROI has no gate of its own; 20%+ ROI can stand in for the 30% margin (margin_gate)
        min_price_for_roi_min    = 'N/A'
        min_price_all_gates      = Fmt $minAll
        price_gate               = $gates.price
        profit_gate              = $gates.profit
        roi_gate                 = 'N/A'
        margin_min_pct           = $(if ($tier -eq 2) { Pct $marginMin } elseif ($tier -eq 1) { 'N/A' } else { 'UNKNOWN' })
        margin_gate              = $gates.margin
        ebay_verification_status = $ebayStatus
        acceptance_status        = $acceptance
        acceptance_basis         = $calcStatus
        exceptions               = $(if ($exc.Count) { $exc -join ' | ' } else { 'none' })
        formula_version          = $FORMULA_VERSION
        notes                    = $(if ($notes.Count) { $notes -join ' ' } else { '' })
    }
}

$outDir = Split-Path $OutputFile -Parent
if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
if (@($out).Count -gt 0) {
    # Append only (CLAUDE.md §19). Re-runs add new rows with a new calculated_at_uk; latest row per candidate wins.
    $out | Export-Csv -LiteralPath $OutputFile -NoTypeInformation -Encoding UTF8 -Append
}
"Profit Engine: $(@($rows).Count) candidate(s) read from $InputFile; $(@($out).Count) row(s) appended to $OutputFile"
