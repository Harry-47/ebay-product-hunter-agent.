<#
Run a batch of hand-entered eBay verification rows through the Profit Engine.
RowsFile: a .ps1 that returns an array of hashtables.
Everything is validated BEFORE anything is written (INC-003, INC-004):
  - every key must be a real verification column (a typo used to become an extra column and was lost)
  - candidate_id, source, source_price, reference_seller_price and ebay_category are required
  - no row may be observed after -Date (that is how 13 Nov rows were priced with 11 Nov fees)
  - today's fee table must exist; -FeeDate uses an older table on purpose and the result is then ESTIMATED
The day's main file is appended only after the Profit Engine succeeded; a failed batch leaves nothing behind.
Usage: .\tools\verif_batch.ps1 -RowsFile rows.ps1 -Batch b1 [-Date YYYY-MM-DD] [-FeeDate YYYY-MM-DD] [-ValidateOnly]
#>
param([Parameter(Mandatory)][string]$RowsFile, [Parameter(Mandatory)][string]$Batch, [string]$Date, [string]$FeeDate, [switch]$ValidateOnly, [string]$Root, [string]$ConfigFile)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$tz = [TimeZoneInfo]::FindSystemTimeZoneById('GMT Standard Time')
if (-not $Date) { $Date = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz).ToString('yyyy-MM-dd') }
if (-not $FeeDate) { $FeeDate = $Date }
if (-not $ConfigFile) { $ConfigFile = Join-Path $Root 'config.yaml' }
$main = Join-Path $Root "data\ebay\${Date}_ebay_verification.csv"
$batchFile = Join-Path $Root "data\ebay\${Date}_ebay_verification_$Batch.csv"
$profitFile = Join-Path $Root "data\profit\${Date}_profit.csv"
$feeFile = Join-Path $Root "data\fees\${FeeDate}_ebay_business_fees.csv"
$template = Join-Path (Split-Path $PSScriptRoot -Parent) 'templates\ebay_verification_template.csv'
$header = ((Get-Content -LiteralPath $template -TotalCount 1) -replace '"', '').Trim([char]0xFEFF) -split ','

$bad = New-Object System.Collections.Generic.List[string]
if (Test-Path -LiteralPath $batchFile) { $bad.Add("batch '$Batch' already exists for $Date (use the next batch name)") }
if (-not (Test-Path -LiteralPath $feeFile)) { $bad.Add("no eBay fee table for $FeeDate ($feeFile). Record today's fee page first (prompts/daily_hunt.md Step 5b), or pass -FeeDate to use an older table as ESTIMATED") }
if (Test-Path -LiteralPath $main) {
    $mh = ((Get-Content -LiteralPath $main -TotalCount 1) -replace '"', '').Trim([char]0xFEFF) -split ','
    if (($mh -join ',') -ne ($header -join ',')) { $bad.Add("columns of $main differ from templates/ebay_verification_template.csv") }
}
$vals = @(& $RowsFile)
if (-not $vals.Count) { $bad.Add("$RowsFile returned no rows") }
$seen = @{}
foreach ($v in $vals) {
    $id = "$($v.candidate_id)"
    foreach ($k in $v.Keys) { if ($header -notcontains $k) { $bad.Add("${id}: unknown column '$k'") } }
    foreach ($k in 'candidate_id', 'source', 'source_price', 'reference_seller_price', 'ebay_category') { if (-not "$($v[$k])".Trim()) { $bad.Add("${id}: '$k' is required (write UNKNOWN if it was not observed)") } }
    if ($seen.ContainsKey($id)) { $bad.Add("${id}: candidate_id used twice in this batch") }; $seen[$id] = 1
    if ("$($v.observed_at_uk)" -match '^(\d{4}-\d{2}-\d{2})' -and $Matches[1] -gt $Date) { $bad.Add("${id}: observed $($Matches[1]) is after -Date $Date; use the observation date so the right fee table is used") }
}
if ($bad.Count) { throw "verif_batch stopped, nothing written:`n - $($bad -join "`n - ")" }
if ($ValidateOnly) { "Validation OK: $($vals.Count) row(s)"; return }

$defaults = @{ verification_date = $Date; observed_at_uk = $Date; source_price_status = 'VERIFIED'; source_delivery_charge = '0'; source_delivery_charge_status = 'VERIFIED'; ebay_verification_status = 'PASS'; proceed_to_profit = 'YES' }
$rows = foreach ($v in $vals) {
    $o = [ordered]@{}
    foreach ($h in $header) { $o[$h] = 'UNKNOWN' }
    foreach ($k in $defaults.Keys) { $o[$k] = $defaults[$k] }
    foreach ($k in $v.Keys) { $o[$k] = $v[$k] }
    [pscustomobject]$o
}
$rows | Export-Csv -LiteralPath $batchFile -NoTypeInformation -Encoding UTF8
try { & (Join-Path $PSScriptRoot 'profit_calc.ps1') -Date $Date -InputFile $batchFile -OutputFile $profitFile -FeeTableFile $feeFile -ConfigFile $ConfigFile }
catch { Remove-Item -LiteralPath $batchFile -Force; throw "Profit Engine failed, batch file removed, nothing appended: $($_.Exception.Message)" }
$rows | Export-Csv -LiteralPath $main -NoTypeInformation -Encoding UTF8 -Append
$ids = $rows | ForEach-Object { $_.candidate_id }
Import-Csv -LiteralPath $profitFile | Where-Object { $ids -contains $_.candidate_id } |
    Format-List candidate_id, listed_price, source_price, total_cost, profit, profit_pct, roi_pct, minimum_listing_price, max_safe_cost, profit_at_cost_buffer, cost_buffer_gate, acceptance_status, ebay_fee_rate_status, unknown_inputs, notes
