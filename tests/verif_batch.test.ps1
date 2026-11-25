# INC-003 wrong-day fees, INC-004 partial writes and silently lost columns.
param($Root, $Tmp)
$ErrorActionPreference = 'Stop'
function Assert($c, $m) { if (-not $c) { throw $m } }
foreach ($d in 'data\ebay', 'data\profit', 'data\fees') { New-Item -ItemType Directory -Path (Join-Path $Tmp $d) | Out-Null }
$vb = Join-Path $Root 'tools\verif_batch.ps1'; $cfg = Join-Path $Root 'tests\fixtures\config_2026-11-25.yaml'
$rows = Join-Path $Tmp 'rows.ps1'
function Put($extra) { Set-Content $rows "@(@{ candidate_id='T1'; source='AliExpress UK'; product_name='x'; source_price='3.31'; reference_seller_price='6.99'; ebay_category='Home, Furniture & DIY'; observed_at_uk='2026-11-11' $extra })" -Encoding ASCII }
function Fails($text, [scriptblock]$s) { $msg = ''; try { & $s | Out-Null } catch { $msg = $_.Exception.Message }; Assert ($msg -match $text) "expected an error about '$text', got '$msg'"; Assert (@(Get-ChildItem (Join-Path $Tmp 'data') -Recurse -File | Where-Object { $_.Name -match 'verification|profit' }).Count -eq $script:files) "a failed batch wrote a file ($text)" }
$script:files = 0
Put ''
Fails 'no eBay fee table' { & $vb -RowsFile $rows -Batch b1 -Date 2026-11-11 -Root $Tmp -ConfigFile $cfg }
Copy-Item (Join-Path $Root 'tests\fixtures\fees_2026-11-11.csv') (Join-Path $Tmp 'data\fees\2026-11-11_ebay_business_fees.csv')
Put "; refrence_seller='typo'"
Fails "unknown column" { & $vb -RowsFile $rows -Batch b1 -Date 2026-11-11 -Root $Tmp -ConfigFile $cfg }
Set-Content $rows "@(@{ candidate_id='T1'; source='AliExpress UK'; source_price='3.31'; reference_seller_price='6.99'; ebay_category='Home, Furniture & DIY'; observed_at_uk='2026-11-13' })" -Encoding ASCII
Fails 'is after -Date' { & $vb -RowsFile $rows -Batch b1 -Date 2026-11-11 -Root $Tmp -ConfigFile $cfg }
Set-Content $rows "@(@{ candidate_id='T1'; source='AliExpress UK'; source_price='3.31' })" -Encoding ASCII
Fails 'is required' { & $vb -RowsFile $rows -Batch b1 -Date 2026-11-11 -Root $Tmp -ConfigFile $cfg }
Put ''
& $vb -RowsFile $rows -Batch b1 -Date 2026-11-11 -Root $Tmp -ConfigFile $cfg | Out-Null
$p = @(Import-Csv (Join-Path $Tmp 'data\profit\2026-11-11_profit.csv'))
Assert ($p.Count -eq 1 -and $p[0].profit -eq '1.79') 'a good batch did not give profit 1.79'
Assert (Test-Path (Join-Path $Tmp 'data\ebay\2026-11-11_ebay_verification.csv')) 'main file not appended'
$script:files = 3
Fails 'already exists' { & $vb -RowsFile $rows -Batch b1 -Date 2026-11-11 -Root $Tmp -ConfigFile $cfg }
