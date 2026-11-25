# User rule 2026-11-25: every selected product has the eBay listing link, source link, item code, variant code; items with variations have 1 to 3 complete variants.
param($Root, $Tmp)
$ErrorActionPreference = 'Stop'
function Assert($c, $m) { if (-not $c) { throw $m } }
foreach ($d in 'tools', 'data\daily', 'data\seasonal', 'data\profit') { New-Item -ItemType Directory -Path (Join-Path $Tmp $d) | Out-Null }
foreach ($f in 'build_manual_workbook.ps1', 'xlsx_writer.ps1', 'manual_daily_files.ps1') { Copy-Item (Join-Path $Root "tools\$f") (Join-Path $Tmp "tools\$f") }
$D = '2026-11-26'
[pscustomobject]@{ name = 'Christmas'; type = 'fixed'; event_date = '2026-12-25'; window_start = ''; window_end = ''; anchor_date = '2026-12-25'; days_until = 29; preferred_listing_start = '2026-10-26'; minimum_listing_start = '2026-11-25'; phase = 'LATE_EVENT_WINDOW'; days_remaining_in_season = ''; priority = 'Not defined'; role = 'CURRENT_EVENT' } | Export-Csv (Join-Path $Tmp "data\seasonal\${D}_calendar.csv") -NoTypeInformation
$p = foreach ($x in @(@('E1', '3.20', '1.82'), @('E1-V2', '3.00', '2.02'))) { [pscustomobject]@{ candidate_id = $x[0]; source_price = $x[1]; source_delivery_charge = '0.00'; sourcing_buying_fee = '0.13'; listed_price = '7.29'; ebay_fee_amount = '1.88'; ad_cost = '0.26'; ad_rate_incl_vat_pct = '3.6'; total_cost = '5.47'; profit = $x[2]; profit_pct = '24.9'; roi_pct = '54.6'; minimum_listing_price = '6.28'; profit_at_cost_buffer = '1.62'; calculation_status = 'VERIFIED'; acceptance_status = 'PASS'; max_safe_cost = '3.90' } }
$p | Export-Csv (Join-Path $Tmp "data\profit\${D}_profit.csv") -NoTypeInformation
$rec = Join-Path $Tmp "data\daily\${D}_records_data.ps1"; $b = Join-Path $Tmp 'tools\build_manual_workbook.ps1'
$base = "id='E1'; cat='SELECTED'; kind='ali'; name='Pet pad'; cost=3.20; ebayPrice=7.29; fvf='home'; seller='x'; hasVariations=`$true; srcUrl='https://www.aliexpress.com/item/1005.html'; ebayItemUrl='https://www.ebay.co.uk/itm/123456789012'; itemCode='1005'; variantCode='SKU-1'"
$v = "@{name='Grey S';variantCode='SKU-1';cost=3.20;stock=90;ebayPrice=7.29;sold30=40}, @{name='Grey M';variantCode='SKU-2';cost=3.00;stock=80;ebayPrice=7.29;sold30=22}, @{name='Blue S';variantCode='SKU-3';cost=3.10;stock=70;ebayPrice=7.49;sold30='UNKNOWN'}"
function Fails([string]$line, [string]$want) { Set-Content $rec $line -Encoding ASCII; $m = ''; try { & $b -Date $D | Out-Null } catch { $m = $_.Exception.Message }; Assert ($m -match $want) "expected '$want', got '$m'" }
Fails "Rec @{ $($base.Replace('https://www.ebay.co.uk/itm/123456789012','')); variants=@($v) }" 'eBay listing'
Fails "Rec @{ $($base.Replace('/item/1005.html','/')); variants=@($v) }" 'not its homepage'
Fails "Rec @{ $($base.Replace("; itemCode='1005'",'')); variants=@($v) }" 'itemCode is required'
Fails "Rec @{ $($base.Replace("; variantCode='SKU-1'",'')); variants=@($v) }" 'variantCode is required'
Fails "Rec @{ $($base.Replace("; hasVariations=`$true",'')); variants=@($v) }" 'hasVariations'
Fails "Rec @{ $base; variants=@($v, @{name='Blue M';variantCode='SKU-4';cost=3;stock=60;ebayPrice=7;sold30=2}) }" 'maximum is 3'
Fails "Rec @{ $base }" 'no variants given'
Fails "Rec @{ $base; variants=@($($v.Replace('stock=80;',''))) }" "variant 2: 'stock' is required"
Fails "Rec @{ $base; variants=@($($v.Replace('cost=3.20','cost=3.25'))) }" 'same cost'
Set-Content $rec "Rec @{ $base; variants=@($v) }" -Encoding ASCII
& $b -Date $D -ReviewJson | Out-Null
$s = ([IO.File]::ReadAllText((Join-Path $Tmp "data\daily\${D}_review.json")) | ConvertFrom-Json).selected[0]
Assert ($s.lItem.Url -eq 'https://www.ebay.co.uk/itm/123456789012' -and $s.ebayNo -eq '123456789012' -and $s.itemCode -eq '1005') 'link or code missing from the review file'
Assert (@($s.variants).Count -eq 3 -and $s.variants[0].vid -eq 'E1' -and $s.variants[1].vid -eq 'E1-V2') 'variants missing'
Assert ($s.variants[1].profit.Value -eq 2.02 -and $s.variants[1].result -match '^PASS') 'variant 2 did not use its own Profit Engine row'
Assert ($s.variants[2].result -match 'NOT PRICED') 'an unpriced variant was shown as passed'
Assert ($s.variants[2].lItem.Url -match '123456789012') 'variant link lost'
& (Join-Path $Tmp 'tools\manual_daily_files.ps1') -Date $D | Out-Null
$vc = @(Import-Csv (Join-Path $Tmp "data\daily\${D}_variants.csv")); Assert ($vc.Count -eq 3 -and $vc[1].variantCode -eq 'SKU-2' -and $vc[1].profit -eq '2.02' -and $vc[0].lSource -match 'aliexpress') 'variants.csv content is wrong'
$c = @(Import-Csv (Join-Path $Tmp "data\daily\${D}_candidates.csv")); Assert ($c[0].ebay_listing_url -match '/itm/' -and $c[0].source_item_code -eq '1005') 'candidates.csv lacks the links or codes'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [IO.Compression.ZipFile]::OpenRead((Join-Path $Tmp "data\daily\${D}_ebay_product_hunt.xlsx")); try { $n = @($z.Entries | Where-Object { $_.FullName -like 'xl/worksheets/sheet*.xml' }).Count } finally { $z.Dispose() }; Assert ($n -eq 7) "workbook has $n sheets, not 7"
Set-Content $rec "Rec @{ $($base.Replace('$true','$false').Replace("variantCode='SKU-1'","variantCode='none'")) }" -Encoding ASCII
& $b -Date $D | Out-Null   # a product without variations needs no variants