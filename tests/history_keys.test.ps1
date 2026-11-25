# INC-001: a product with only a title key was stored as product_key 'T'. INC-002: hand-researched days were never ingested.
param($Root, $Tmp)
$ErrorActionPreference = 'Stop'
function Assert($c, $m) { if (-not $c) { throw $m } }
foreach ($d in 'data\history', 'data\sources\aliexpress_uk', 'data\daily') { New-Item -ItemType Directory -Path (Join-Path $Tmp $d) | Out-Null }
Copy-Item (Join-Path $Root 'tests\fixtures\config_2026-11-25.yaml') (Join-Path $Tmp 'config.yaml')
$h = Join-Path $Root 'tools\history.ps1'
# 1. stage ingest of a title-only product
[pscustomobject]@{ candidate_id = 'AX-1'; product_name = 'Blue Widget Lamp'; aliexpress_item_id = 'UNKNOWN'; aliexpress_url = 'UNKNOWN'; aliexpress_price = '1.00'; ean_gtin = 'UNKNOWN'; proceed_to_ebay = 'NO'; failed_criteria = 'x'; rejection_reason = 'stock'; stock_status = 'FAIL' } |
    Export-Csv (Join-Path $Tmp 'data\sources\aliexpress_uk\2026-01-01_aliexpress_uk_stage.csv') -NoTypeInformation
& $h -Action Ingest -Date 2026-01-01 -Root $Tmp | Out-Null
$log = @(Import-Csv (Join-Path $Tmp 'data\history\status_log.csv'))
Assert ($log[0].product_key -eq 'TITLE:blue widget lamp') "title-only key is '$($log[0].product_key)'"
# 2. old 'T' rows are told apart when read
foreach ($n in 'old one', 'old two') { $r = $log[0].PSObject.Copy(); $r.product_key = 'T'; $r.alt_keys = "TITLE:$n"; $r.product_name = $n; $r | Export-Csv (Join-Path $Tmp 'data\history\status_log.csv') -NoTypeInformation -Append }
& $h -Action Register -Root $Tmp | Out-Null
$reg = @(Import-Csv (Join-Path $Tmp 'data\history\product_register.csv'))
Assert ($reg.Count -eq 3) "register has $($reg.Count) products, expected 3"
Assert (-not ($reg | Where-Object { $_.product_key -eq 'T' })) 'a T key is still in the register'
# 3. hand-researched day: selected, rejected and duplicate
$item = { param($id, $cat, $rule, $name, $url) [ordered]@{ id = $id; cat = $cat; rule = $rule; name = $name; source = 'AliExpress UK'; lSource = @{ Url = $url }; lSearch = @{ Url = 'https://www.ebay.co.uk/x' }; sourcePrice = @{ Value = 2.5 }; ebayPrice = 7.99; decision = 'd'; seen = 's'; limit = 'l'; reason = 'r' } }
$all = @((& $item 'AX-2' 'SELECTED' '' 'Pocket Scale (item)' 'https://www.aliexpress.com/item/1005010285414833.html'), (& $item 'AX-3' 'REJECTED' 'stock' 'Nose Trimmer' ''), (& $item 'AX-4' 'REJECTED' 'duplicate' 'Old Thing' ''))
@{ all = $all; selected = @($all[0]); rejected = @($all[1], $all[2]) } | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $Tmp 'data\daily\2026-01-02_review.json') -Encoding UTF8
& $h -Action IngestReview -Date 2026-01-02 -Root $Tmp | Out-Null
$day = @(Import-Csv (Join-Path $Tmp 'data\history\status_log.csv') | Where-Object { $_.research_date -eq '2026-01-02' })
Assert ($day.Count -eq 2) "expected 2 events, got $($day.Count)"
Assert (($day | Where-Object { $_.candidate_id -eq 'AX-2' }).product_key -eq 'ALI:1005010285414833') 'AliExpress item id not used as key'
Assert (($day | Where-Object { $_.candidate_id -eq 'AX-2' }).status -eq 'QUALIFIED') 'selected product is not QUALIFIED'
Assert (($day | Where-Object { $_.candidate_id -eq 'AX-3' }).status -eq 'WATCH') 'rejected product is not WATCH'
& $h -Action IngestReview -Date 2026-01-02 -Root $Tmp | Out-Null
Assert (@(Import-Csv (Join-Path $Tmp 'data\history\status_log.csv') | Where-Object { $_.research_date -eq '2026-01-02' }).Count -eq 2) 'a second ingest added rows'
$c = (& $h -Action Check -SourceId 'ALI:1005010285414833' -Date 2026-01-03 -Root $Tmp) -join ' '
Assert ($c -match 'SKIP') 'Check does not find the ingested product'
