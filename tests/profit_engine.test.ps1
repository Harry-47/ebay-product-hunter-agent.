# Golden results: real rows whose figures the user has already been given. If a number moves, the calculation changed.
# Also INC-003 (fees from another day must not be VERIFIED). Uses a frozen copy of config and fees, so it tests the arithmetic only.
param($Root, $Tmp)
$ErrorActionPreference = 'Stop'
function Assert($c, $m) { if (-not $c) { throw $m } }
$h = ((Get-Content (Join-Path $Root 'templates\ebay_verification_template.csv') -TotalCount 1) -replace '"', '').Trim([char]0xFEFF) -split ','
function Row($id, $src, $cost, $price, $cat) { $o = [ordered]@{}; foreach ($x in $h) { $o[$x] = 'UNKNOWN' }; $o.candidate_id = $id; $o.source = $src; $o.source_price = $cost; $o.source_price_status = 'VERIFIED'; $o.source_delivery_charge = '0'; $o.source_delivery_charge_status = 'VERIFIED'; $o.reference_seller_price = $price; $o.ebay_category = $cat; $o.ebay_verification_status = 'PASS'; $o.proceed_to_profit = 'YES'; [pscustomobject]$o }
$in = Join-Path $Tmp 'in.csv'
@((Row 'GD' 'Go Dropship UK' '4.72' '10.92' 'Vehicle Parts & Accessories'), (Row 'AX' 'AliExpress UK' '3.31' '6.99' 'Home, Furniture & DIY'), (Row 'AXF' 'AliExpress UK' '4.71' '7.29' 'Pet Supplies'),
    (Row 'NOCAT' 'AliExpress UK' '1.00' '9.99' 'No Such Category'), (Row 'HIGH' 'AliExpress UK' '2.00' '35.01' 'Pet Supplies'), (Row 'LOW' 'AliExpress UK' '0.10' '1.99' 'Pet Supplies'), (Row 'AMZ' 'Amazon UK' '5.00' '9.99' 'Pet Supplies')) | Export-Csv $in -NoTypeInformation -Encoding UTF8
$calc = Join-Path $Root 'tools\profit_calc.ps1'; $cfg = Join-Path $Root 'tests\fixtures\config_2026-11-25.yaml'; $fees = Join-Path $Root 'tests\fixtures\fees_2026-11-11.csv'
function Run($date, $fee, $out) { & $calc -Date $date -InputFile $in -OutputFile $out -ConfigFile $cfg -FeeTableFile $fee -ExceptionsFile (Join-Path $Tmp 'none.csv') | Out-Null; $m = @{}; foreach ($x in (Import-Csv $out)) { $m[$x.candidate_id] = $x }; $m }
$a = Run '2026-11-11' $fees (Join-Path $Tmp 'a.csv')
function Eq($row, $col, $want) { Assert ($row.$col -eq $want) "$($row.candidate_id) $col = $($row.$col), expected $want" }
Eq $a.GD 'profit' '3.17'; Eq $a.GD 'roi_pct' '64.0'; Eq $a.GD 'minimum_listing_price' '7.90'; Eq $a.GD 'max_safe_cost' '6.45'; Eq $a.GD 'acceptance_status' 'PASS'; Eq $a.GD 'cost_buffer_gate' 'N/A'
Eq $a.AX 'profit' '1.79'; Eq $a.AX 'roi_pct' '52.1'; Eq $a.AX 'minimum_listing_price' '6.03'; Eq $a.AX 'max_safe_cost' '4.07'; Eq $a.AX 'profit_at_cost_buffer' '1.58'; Eq $a.AX 'acceptance_status' 'PASS'
Eq $a.AXF 'profit' '0.25'; Eq $a.AXF 'acceptance_status' 'FAIL'
Eq $a.NOCAT 'acceptance_status' 'UNKNOWN'; Eq $a.HIGH 'price_gate' 'FAIL'; Eq $a.LOW 'price_gate' 'FAIL'
Eq $a.AMZ 'ad_rate_pct' '3.0'; Eq $a.AMZ 'margin_min_pct' '15.0'; Eq $a.GD 'margin_min_pct' '30.0'; Eq $a.AX 'ad_rate_pct' '3.0'; Eq $a.GD 'ad_rate_pct' '5.0'
Eq $a.AX 'ebay_fee_rate_status' 'VERIFIED'
$b = Run '2026-11-13' $fees (Join-Path $Tmp 'b.csv')
Eq $b.AX 'ebay_fee_rate_status' 'ESTIMATED'; Eq $b.AX 'ebay_fixed_fee_status' 'ESTIMATED'; Eq $b.AX 'profit' '1.79'
$c = Run '2026-11-11' (Join-Path $Tmp 'missing.csv') (Join-Path $Tmp 'c.csv')
Eq $c.AX 'acceptance_status' 'UNKNOWN'
