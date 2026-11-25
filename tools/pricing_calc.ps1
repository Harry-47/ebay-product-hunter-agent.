# Pricing calculator: cost-plus minimum selling price for eBay UK (business seller, sole trader, not VAT registered).
# Standalone check for one cost. Uses the same formula and the same CURRENT eBay fee table as tools/profit_calc.ps1.
#
# Usage:
#   powershell -File tools\pricing_calc.ps1 -SupplierCost 8.50                                  (Home, Furniture & DIY)
#   powershell -File tools\pricing_calc.ps1 -SupplierCost 6.31 -Category "Garden & Patio"
#   powershell -File tools\pricing_calc.ps1 -SupplierCost 8.50 -NoInsertionFee
#   powershell -File tools\pricing_calc.ps1 -Test            (comparison table)
#   . .\tools\pricing_calc.ps1; Get-SellingPrice -SupplierCost 15   (dot-source to use the function)
#
# Pricing rules (CLAUDE.md s3, s10):
#   cost base = supplier cost + sourcing buying fee (8% of supplier cost)
#   ad fee            = ad rate (5%) x (1 + VAT) = 6% of the sale
#   Tier 1 (cost <  GBP 10): price = (cost base + 1.00 + fixed fees) / (1 - eBay variable fee - ad fee)
#   Tier 2 (cost >= GBP 10): price = (cost base x 1.20 + fixed fees) / (1 - eBay variable fee - ad fee)
#   eBay variable fee = (final value fee for the category + regulatory fee) x (1 + VAT)
#   fixed fees        = per-order fee x (1 + VAT) + insertion fee (GBP 0.36, already inc. VAT)
#   per-order fee     = GBP 0.30 up to GBP 10 (0.10 in Home, Furniture & DIY), GBP 0.40 over GBP 10 (from the fee table)
# Fees come from the latest data/fees/<date>_ebay_business_fees.csv (eBay's fee page, recorded at each run).
# The price is rounded UP to the next penny, so profit never falls below the target after rounding.

param(
    [double]$SupplierCost,
    [string]$Category = 'Home, Furniture & DIY',
    [switch]$NoInsertionFee,
    [switch]$Test
)
$script:Root = Split-Path $PSScriptRoot -Parent

function Get-SellingPrice {
    param(
        [Parameter(Mandatory)][double]$SupplierCost,
        [string]$Category = 'Home, Furniture & DIY',
        [bool]$IncludesInsertionFee = $true,
        [double]$AdRate = 0.05,            # promoted listings (project minimum 5%); VAT is added below
        [double]$InsertionFee = 0.36,      # inc. VAT, when over the free listing allowance
        [double]$BuyingFeeRate = 0.08,     # sourcing buying fee, share of supplier cost
        [double]$VatRate = 0.20,           # not VAT registered: eBay adds VAT to its fees
        [double]$Tier1Profit = 1.00,
        [double]$Tier2Roi = 0.20,
        [double]$TierBreak = 10.00,
        [string]$FeeTableFile
    )
    if ($SupplierCost -le 0) { throw "SupplierCost must be greater than 0" }
    if (-not $FeeTableFile) {
        $FeeTableFile = Get-ChildItem (Join-Path $script:Root 'data\fees') -Filter '*_ebay_business_fees.csv' -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $FeeTableFile) { throw 'No eBay fee table found in data\fees (record eBay''s fee page first).' }
    $tbl = @(Import-Csv -LiteralPath $FeeTableFile)
    $cat = $tbl | Where-Object { $_.kind -eq 'FVF' -and ($_.category -eq $Category -or (("$($_.path_aliases)" -split ';') -contains $Category)) } | Select-Object -First 1
    if (-not $cat) { throw "Category '$Category' is not in the fee table $FeeTableFile" }
    $amt = { param($k) [double](@($tbl | Where-Object { $_.kind -eq $k })[0].rate_or_amount) }
    $vx = 1 + $VatRate
    $variable = ([double]$cat.rate_or_amount + (& $amt 'REGULATORY')) * $vx
    $poLow  = $(if ($cat.reduced_per_order_applies -eq 'YES') { & $amt 'PER_ORDER_REDUCED' } else { & $amt 'PER_ORDER_LOW' }) * $vx
    $poHigh = (& $amt 'PER_ORDER_HIGH') * $vx
    $insertion = if ($IncludesInsertionFee) { $InsertionFee } else { 0 }
    $buyingFee = [math]::Round($SupplierCost * $BuyingFeeRate, 2)
    $costBase  = $SupplierCost + $buyingFee
    $adEff = $AdRate * $vx            # ad fee + VAT (not VAT registered): 5% -> 6%
    $mult = 1 - ($variable + $adEff)

    if ($SupplierCost -lt $TierBreak) { $tier = 1; $target = "GBP {0:N2} net profit" -f $Tier1Profit; $need = $costBase + $Tier1Profit }
    else { $tier = 2; $target = "{0:P0} net ROI" -f $Tier2Roi; $need = $costBase * (1 + $Tier2Roi) }
    # Per-order fee depends on the order total: try the up-to-GBP-10 fee first; if the price is over GBP 10, use the higher fee.
    $raw = ($need + $poLow + $insertion) / $mult
    $po = $poLow
    if ($raw -gt 10) { $raw = ($need + $poHigh + $insertion) / $mult; $po = $poHigh }
    $price = [math]::Ceiling([math]::Round($raw * 100, 6)) / 100

    $fvf = $price * $variable; $ad = $price * $adEff
    $total = $fvf + $po + $insertion + $ad
    $profit = $price - $costBase - $total
    [pscustomobject][ordered]@{
        supplier_cost      = [math]::Round($SupplierCost, 2)
        category           = $cat.category
        fees_observed      = $cat.observed_date
        tier               = $tier
        target             = $target
        insertion_fee_used = $IncludesInsertionFee
        buying_fee         = $buyingFee
        selling_price      = $price
        fee_ebay_variable  = [math]::Round($fvf, 2)    # (final value fee + regulatory) inc. VAT
        fee_per_order      = [math]::Round($po, 2)     # inc. VAT
        fee_insertion      = [math]::Round($insertion, 2)
        fee_ad             = [math]::Round($ad, 2)
        total_fees         = [math]::Round($total, 2)
        net_profit         = [math]::Round($profit, 2)
        net_margin_pct     = [math]::Round($profit / $price * 100, 2)
        net_roi_pct        = [math]::Round($profit / $costBase * 100, 2)   # on supplier cost + buying fee
    }
}

if ($Test) {
    $rows = foreach ($c in 4.00, 8.50, 15.00, 50.00) {
        foreach ($ins in $true, $false) { Get-SellingPrice -SupplierCost $c -Category $Category -IncludesInsertionFee $ins }
    }
    $rows | Format-Table supplier_cost, buying_fee, tier, insertion_fee_used, selling_price, fee_ebay_variable, fee_per_order, fee_insertion, fee_ad,
        total_fees, net_profit, net_margin_pct, net_roi_pct -AutoSize
} elseif ($PSBoundParameters.ContainsKey('SupplierCost')) {
    Get-SellingPrice -SupplierCost $SupplierCost -Category $Category -IncludesInsertionFee (-not $NoInsertionFee) | Format-List
}
