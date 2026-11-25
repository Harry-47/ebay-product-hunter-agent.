# INC-005: the workbook recalculated profit with its own fee table, and an unknown fee key counted as a 0% fee.
param($Root, $Tmp)
$ErrorActionPreference = 'Stop'
function Assert($c, $m) { if (-not $c) { throw $m } }
foreach ($d in 'tools', 'data\daily', 'data\seasonal', 'data\profit') { New-Item -ItemType Directory -Path (Join-Path $Tmp $d) | Out-Null }
foreach ($f in 'build_manual_workbook.ps1', 'xlsx_writer.ps1', 'manual_daily_files.ps1') { Copy-Item (Join-Path $Root "tools\$f") (Join-Path $Tmp "tools\$f") }
[pscustomobject]@{ name = 'Christmas'; type = 'fixed'; event_date = '2026-12-25'; window_start = ''; window_end = ''; anchor_date = '2026-12-25'; days_until = 30; preferred_listing_start = '2026-10-26'; minimum_listing_start = '2026-11-25'; phase = 'START_NOW'; days_remaining_in_season = ''; priority = 'Not defined'; role = 'CURRENT_EVENT' } | Export-Csv (Join-Path $Tmp 'data\seasonal\2026-01-01_calendar.csv') -NoTypeInformation
[pscustomobject]@{ candidate_id = 'E1'; source_price = '3.20'; source_delivery_charge = '0.00'; sourcing_buying_fee = '0.13'; listed_price = '7.29'; ebay_fee_amount = '1.88'; ad_cost = '0.26'; ad_rate_incl_vat_pct = '3.6'; total_cost = '5.47'; profit = '1.82'; profit_pct = '24.9'; roi_pct = '54.6'; minimum_listing_price = '6.28'; profit_at_cost_buffer = '1.62'; calculation_status = 'ESTIMATED' } | Export-Csv (Join-Path $Tmp 'data\profit\2026-01-01_profit.csv') -NoTypeInformation
$rec = Join-Path $Tmp 'data\daily\2026-01-01_records_data.ps1'; $b = Join-Path $Tmp 'tools\build_manual_workbook.ps1'
Set-Content $rec "Rec @{ id='E1'; cat='SELECTED'; kind='ali'; name='Pet pad'; cost=3.20; ebayPrice=7.29; fvf='home'; seller='x' }`r`nRec @{ id='R1'; cat='REJECTED'; kind='ali'; name='Other'; cost=5; ebayPrice=6; failedRule='price'; seen='s'; limit='l' }" -Encoding ASCII
& $b -Date 2026-01-01 -ReviewJson | Out-Null
$j = [IO.File]::ReadAllText((Join-Path $Tmp 'data\daily\2026-01-01_review.json')) | ConvertFrom-Json
Assert ($j.selected[0].profit.Value -eq 1.82) "workbook profit $($j.selected[0].profit.Value) is not the Profit Engine's 1.82"
Assert ($j.selected[0].evidence -match 'Profit Engine') 'evidence does not name the Profit Engine'
& (Join-Path $Tmp 'tools\manual_daily_files.ps1') -Date 2026-01-01 | Out-Null
foreach ($f in 'candidates.csv', 'rejections.csv', 'seasonal_plan.md', 'summary.md') { Assert (Test-Path (Join-Path $Tmp "data\daily\2026-01-01_$f")) "$f was not written" }
$c = @(Import-Csv (Join-Path $Tmp 'data\daily\2026-01-01_candidates.csv')); Assert ($c.Count -eq 1 -and $c[0].estimated_profit -eq '1.82' -and $c[0].weight -eq 'UNKNOWN') 'candidates.csv content is wrong'
Set-Content $rec "Rec @{ id='E2'; cat='SELECTED'; kind='ali'; name='Scale'; cost=3.55; ebayPrice=7.99; fvf='jewel' }" -Encoding ASCII
$msg = ''; try { & $b -Date 2026-01-01 | Out-Null } catch { $msg = $_.Exception.Message }
Assert ($msg -match "unknown fee key") 'an unknown fee key was accepted'
# INC-014: $eng overwrote $ENG (names are not case-sensitive), so only the first product used the Profit Engine
$e = Import-Csv (Join-Path $Tmp 'data\profit\2026-01-01_profit.csv'); $e2 = $e.PSObject.Copy(); $e2.candidate_id = 'E9'; $e2.profit = '1.77'; @($e, $e2) | Export-Csv (Join-Path $Tmp 'data\profit\2026-01-01_profit.csv') -NoTypeInformation
Remove-Item (Join-Path $Tmp 'data\daily\2026-01-01_review.json')
Set-Content $rec "Rec @{ id='E0'; cat='REJECTED'; kind='ali'; name='No engine row'; cost=2; ebayPrice=5; fvf='home' }`r`nRec @{ id='E1'; cat='SELECTED'; kind='ali'; name='Pet pad'; cost=3.20; ebayPrice=7.29; fvf='home' }`r`nRec @{ id='E9'; cat='SELECTED'; kind='ali'; name='Second'; cost=3.20; ebayPrice=7.29; fvf='home' }" -Encoding ASCII
& $b -Date 2026-01-01 -ReviewJson | Out-Null
$j = [IO.File]::ReadAllText((Join-Path $Tmp 'data\daily\2026-01-01_review.json')) | ConvertFrom-Json
Assert ($j.selected[0].profit.Value -eq 1.82 -and $j.selected[1].profit.Value -eq 1.77) 'a later product did not use its own Profit Engine row'