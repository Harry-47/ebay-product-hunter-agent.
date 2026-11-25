# INC-013: run_close must accept a seller label, and must fail when the seller, files, history or fees are missing.
param($Root, $Tmp)
$ErrorActionPreference = 'Stop'
function Assert($c, $m) { if (-not $c) { throw $m } }
foreach ($d in 'data\daily', 'data\profit', 'data\competitors', 'data\history', 'tests') { New-Item -ItemType Directory -Force -Path (Join-Path $Tmp $d) | Out-Null }
Set-Content (Join-Path $Tmp 'tests\ok.test.ps1') 'param($Root,$Tmp)' -Encoding ASCII
$s = @{ id = 'GD-20260102-01'; cat = 'SELECTED'; seller = 'am_1 (Shop CO)'; rule = '' }
@{ selected = @($s); all = @($s) } | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $Tmp 'data\daily\2026-01-02_review.json') -Encoding UTF8
[pscustomobject]@{ candidate_id = 'GD-20260102-01'; acceptance_status = 'PASS'; fee_category = 'Pet'; profit_date = '2026-01-01'; ebay_fee_rate_source = 'eBay business fees 2026-01-01: Pet' } | Export-Csv (Join-Path $Tmp 'data\profit\2026-01-01_profit.csv') -NoTypeInformation
Set-Content (Join-Path $Tmp 'data\competitors\passing_sellers.csv') '2026-01-02,x,y,am_1,z' -Encoding ASCII
$o = (& (Join-Path $Root 'tools\run_close.ps1') -Date 2026-01-02 -Root $Tmp) -join "`n"
Assert ($o -match 'OK\s+GD-20260102-01: reference seller saved') 'a seller with a label was not recognised'
Assert ($o -match 'FAIL\s+GD-20260102-01: not priced with fees older') 'older fees were not noticed'
Assert ($o -match 'FAIL\s+every evaluated product is in the product history') 'missing history was not noticed'
Assert ($o -match 'FAIL\s+data\\daily\\2026-01-02_summary.md') 'missing file was not noticed'
Assert ($o -match 'NOT COMPLETE') 'an incomplete day was called complete'
