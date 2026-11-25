<#
Research history and rejection tracking (CLAUDE.md s19-s21). See prompts/stages/research_history.md.

Append-only logs (never edited or deleted):
  data/history/status_log.csv         every status event per product
  data/history/rejection_history.csv  every failed criterion, with reason and evidence
Derived view (rebuilt from the status log; contains no original research):
  data/history/product_register.csv   current status per product

Actions:
  -Action Ingest    -Date YYYY-MM-DD   read that day's stage files, append statuses and rejections, rebuild register
  -Action IngestReview -Date YYYY-MM-DD hand-researched day: append statuses and rejections from data/daily/<Date>_review.json (INC-002)
  -Action Check     -Gtin/-SourceId/-Title  before researching: RESEARCH / RECHECK / SKIP (+ last known prices)
  -Action SetStatus -Key <product_key> -Status <S> -Reason "..." [-SetBy USER] [-RecheckDue YYYY-MM-DD]
  -Action Due       [-Date YYYY-MM-DD]  products whose recheck date has arrived
  -Action Register  rebuild data/history/product_register.csv
Never purchases, lists or publishes anything.
#>
param(
    [Parameter(Mandatory)][ValidateSet('Ingest', 'IngestReview', 'Check', 'SetStatus', 'Due', 'Register')][string]$Action,
    [string]$Date,
    [string]$Key,
    [string]$Gtin,
    [string]$SourceId,
    [string]$Title,
    [string]$Status,
    [string]$Reason,
    [ValidateSet('AGENT', 'USER')][string]$SetBy = 'AGENT',
    [string]$RecheckDue,
    [string]$Root
)
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$tz = [TimeZoneInfo]::FindSystemTimeZoneById('GMT Standard Time')
$nowUk = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz)
if (-not $Date) { $Date = $nowUk.ToString('yyyy-MM-dd') }
$day = [DateTime]::ParseExact($Date, 'yyyy-MM-dd', $inv)

$histDir = Join-Path $Root 'data\history'
$logFile = Join-Path $histDir 'status_log.csv'
$rejFile = Join-Path $histDir 'rejection_history.csv'
$regFile = Join-Path $histDir 'product_register.csv'

$STATUSES = @('NEW', 'RESEARCHED', 'QUALIFIED', 'APPROVED', 'LISTING_READY', 'LISTED', 'WATCH', 'KEEP', 'DEPRIORITISE', 'RETIRE')
$USER_ONLY = @('APPROVED', 'LISTING_READY', 'LISTED')   # only on the user's instruction (CLAUDE.md s23)

# --- Settings (config.yaml history block; editable operational settings, not business rules) --
$cfg = Get-Content -Raw -LiteralPath (Join-Path $Root 'config.yaml')
function Get-HistSetting([string]$k) {
    $m = [regex]::Match($cfg, "(?ms)^history\s*:\s*\r?\n(.*?)(?=^\S|\z)")
    if (-not $m.Success) { throw "config.yaml history block missing" }
    $v = [regex]::Match($m.Groups[1].Value, "(?m)^\s+$k\s*:\s*(\d+)")
    if (-not $v.Success) { throw "config.yaml history.$k missing" }
    return [int]$v.Groups[1].Value
}
$WATCH_DAYS = Get-HistSetting 'watch_recheck_days'
$DEPRI_DAYS = Get-HistSetting 'deprioritise_recheck_days'
$RESEARCHED_DAYS = Get-HistSetting 'researched_recheck_days'
$QUALIFIED_DAYS = Get-HistSetting 'qualified_review_days'
$MAX_WATCH = Get-HistSetting 'max_consecutive_watch'

# --- Failure classification -------------------------------------------------
# NO  -> intrinsic to the product (CLAUDE.md s4): RETIRE (only the user can reopen)
# LOW -> could change only with a different variant/pack: DEPRIORITISE
# YES -> may change later (price, demand, competition, season, delivery, stock...): WATCH
$CHANGE_NO = @('avoid_list', 'ip_risk', 'brand_ip', 'ip_vero')
$CHANGE_LOW = @('weight', 'variations')
$TRIGGERS = @{
    price_ceiling = 'source price drop'; price = 'competitor price change; source price drop'; price_range = 'eBay price change'
    profit = 'source price drop; competitor price rise; fee change'; roi = 'source price drop; competitor price rise; fee change'; margin = 'source price drop; competitor price rise; fee change'
    stock = 'restock'; delivery = 'faster delivery option'; keepa = 'longer stable Buy Box history'; seller_type = 'Prime FBM/FBA offer appears'
    rating = 'rating improves'; sales = 'source sales rise'; demand = 'demand rises'; str = 'eBay demand change'; trend = 'eBay demand change'
    total_sellers = 'competition change'; amazon_price_range = 'source price change'; delivery_fee = 'free delivery offered'; offer_sellers = 'seller count change'; choice_badge = 'Choice badge added'; store_positive_feedback = 'store feedback improves'; warehouse_location = 'UK stock appears'; seasonal_timing = 'next event/season occurrence'
    ebay_evidence_unavailable = 'eBay access restored or comparable listing appears'; weight = 'lighter pack/variant'; variations = 'fewer variations listed'
}
$THRESHOLDS = @{
    price_ceiling = 'source cost < GBP 35 (pre-screen)'; price = 'GBP 2-GBP 35 listed price'; price_range = 'GBP 2-GBP 35 median sold'
    profit = '>= GBP 1 profit'; roi = '(no longer a gate from 2026-10-08) >= 20% (cost >= GBP 10)'; margin = 'listing price GBP 8 or more: >= 30% margin, or >= 20% ROI'
    stock = 'Amazon FBM seller >= 30 units or In stock; Go Dropship >= 20 units'; delivery = 'Amazon <= 5 days; AliExpress <= 10 days; Go Dropship <= 7 days'; keepa = '>= 90 days stable, gaps <= 5 days'
    seller_type = 'FBM or FBA with free Prime delivery (from 2026-10-09); not Amazon retail'; rating = '>= 4 (Amazon) / >= 4.3 (AliExpress)'; sales = 'Amazon: 500+ bought in past month; AliExpress: Choice + 500+ sold; Go Dropship: best-selling or 1,000+ in 30 days'; str = '>= 20%'; trend = 'informational only (rule cancelled 2026-10-14)'
    total_sellers = 'no limit (gate removed 2026-10-23)'; weight = 'no limit with free delivery; otherwise < 2 kg (Amazon) / < 2 kg (Go Dropship) / < 5 kg (AliExpress)'; variations = '<= 3'; avoid_list = 'CLAUDE.md s4'; ip_risk = 'CLAUDE.md s4'
    brand_ip = 'CLAUDE.md s4'; ip_vero = 'CLAUDE.md s4'; amazon_price_range = 'Amazon price GBP 2-40'; delivery_fee = 'free delivery (Amazon)'; offer_sellers = '3-20 sellers on the Amazon listing'; choice_badge = 'AliExpress Choice'; store_positive_feedback = '>= 90% (AliExpress)'; warehouse_location = 'UK warehouse (Go Dropship)'; other_fees = 'all fees shown'; seasonal_timing = 'arrives before event; not a passed event'
}
$SKIP_STATUS_COLS = @('compliance_status', 'source_compliance_status', 'ebay_verification_status', 'fee_status', 'calculation_status',
    'acceptance_status', 'multiple_sellers_status', 'strong_sellers_status', 'small_sellers_status', 'amazon_competitor_status',
    'source_price_status', 'source_delivery_charge_status', 'sourcing_buying_fee_status', 'food_drink_status', 'listed_price_status',
    'source_delivery_status', 'ebay_fee_rate_status', 'ebay_fixed_fee_status', 'ad_rate_status')

function Test-Val($v) { $s = "$v".Trim(); return ($s -ne '' -and $s -notmatch '^(UNKNOWN|N/A|NA|none)$') }
function Get-Col($row, [string]$n) { if ($null -ne $row -and $row.PSObject.Properties.Name -contains $n) { return $row.$n } return $null }
function Norm-Title([string]$t) { return ((($t.ToLower() -replace '[^a-z0-9]+', ' ').Trim()) -replace '\s+', ' ') }
function Get-Jaccard([string]$a, [string]$b) {
    $x = @($a -split ' ' | Where-Object { $_ }); $y = @($b -split ' ' | Where-Object { $_ })
    if (-not $x.Count -or -not $y.Count) { return 0 }
    $inter = @($x | Where-Object { $y -contains $_ } | Select-Object -Unique).Count
    $union = @(($x + $y) | Select-Object -Unique).Count
    return $inter / $union
}
function Read-Csv([string]$p) { if (Test-Path -LiteralPath $p) { return @(Import-Csv -LiteralPath $p) } return @() }
function Append-Rows($rows, [string]$p) {
    if ($null -eq $rows -or $rows.Count -eq 0) { return }
    if (-not (Test-Path -LiteralPath $histDir)) { New-Item -ItemType Directory -Path $histDir | Out-Null }
    $rows | Export-Csv -LiteralPath $p -NoTypeInformation -Encoding UTF8 -Append
}

# --- Identity keys ------------------------------------------------------------
$SRC = @{
    amazon_uk = @{ prefix = 'AMZ'; id = 'asin'; url = 'amazon_url'; price = 'amazon_price' }
    aliexpress_uk = @{ prefix = 'ALI'; id = 'aliexpress_item_id'; url = 'aliexpress_url'; price = 'aliexpress_price' }
    godropship_uk = @{ prefix = 'GDS'; id = 'supplier_sku'; url = 'godropship_url'; price = 'source_price' }
    # Morrisons UK removed 2026-10-03 (dropshipping from Morrisons not allowed).
}
function Get-Keys([string]$gtin, [string]$prefix, [string]$sid, [string]$title) {
    $keys = New-Object System.Collections.Generic.List[string]
    if (Test-Val $gtin) { $keys.Add("GTIN:$("$gtin".Trim())") }
    if ((Test-Val $sid) -and $prefix) { $keys.Add("${prefix}:$("$sid".Trim())") }
    if (Test-Val $title) { $keys.Add("TITLE:$(Norm-Title $title)") }
    return , $keys   # INC-001: the comma stops PowerShell unrolling a one-item list to a string (then $alts[0] was 'T')
}
# INC-001: events written before the fix carry product_key 'T' (any key without a "PREFIX:" is invalid).
# The log is append-only, so the key is repaired when it is read, from the event's own alt_keys.
function Repair-Key($e) {
    if ("$($e.product_key)" -match '^[A-Z]+:.+') { return $e.product_key }
    $first = ("$($e.alt_keys)" -split ';' | Where-Object { $_ -match '^[A-Z]+:.+' } | Select-Object -First 1)
    if ($first) { return $first } else { return $e.product_key }
}

# --- Log index ---------------------------------------------------------------
function Get-Index {
    $log = Read-Csv $logFile
    $idx = @{}; $latest = [ordered]@{}; $events = @{}
    foreach ($e in $log) {
        $e.product_key = Repair-Key $e
        $hit = $null; foreach ($k in ("$($e.alt_keys)" -split ';')) { if ($k -and $idx.ContainsKey($k)) { $hit = $idx[$k]; break } }
        if ($hit) { $e.product_key = $hit }   # same product seen before under another key
        $latest[$e.product_key] = $e
        if (-not $events.ContainsKey($e.product_key)) { $events[$e.product_key] = New-Object System.Collections.Generic.List[object] }
        $events[$e.product_key].Add($e)
        foreach ($k in ("$($e.alt_keys)" -split ';')) { if ($k) { $idx[$k] = $e.product_key } }
        $idx[$e.product_key] = $e.product_key
    }
    return @{ log = $log; idx = $idx; latest = $latest; events = $events }
}
function Get-ConsecutiveWatch($evs) {
    if (-not $evs) { return 0 }
    $n = 0; $seen = @{}
    for ($i = $evs.Count - 1; $i -ge 0; $i--) {
        $d = "$($evs[$i].research_date)"   # count research days, not clock time
        if ($evs[$i].status -ne 'WATCH') { break }
        if (-not $seen.ContainsKey($d)) { $seen[$d] = 1; $n++ }
    }
    return $n
}

function Write-Register {
    $ix = Get-Index
    $reg = foreach ($pk in $ix.latest.Keys) {
        $e = $ix.latest[$pk]; $evs = $ix.events[$pk]
        [pscustomobject][ordered]@{
            product_key = $pk; alt_keys = $e.alt_keys; product_name = $e.product_name; source = $e.source
            current_status = $e.status; recommended_status = $e.recommended_status; set_by = $e.set_by; last_event_at_uk = $e.event_at_uk
            recheck_due = $e.recheck_due; recheck_trigger = $e.recheck_trigger; last_reason = $e.reason
            times_researched = @($evs | Where-Object { $_.stage -ne 'MANUAL' } | ForEach-Object { "$($_.research_date)" } | Select-Object -Unique).Count
            consecutive_watch = Get-ConsecutiveWatch $evs
            last_candidate_id = $e.candidate_id; last_source_price = $e.source_price; last_ebay_price = $e.ebay_price
            source_url = $e.source_url; ebay_url = $e.ebay_url
        }
    }
    if (-not (Test-Path -LiteralPath $histDir)) { New-Item -ItemType Directory -Path $histDir | Out-Null }
    @($reg) | Export-Csv -LiteralPath $regFile -NoTypeInformation -Encoding UTF8   # derived view: safe to rebuild
    return @($reg)
}

function New-Event($pk, $alts, $name, $source, $cid, $stage, $status, $prev, $recommended, $reason, $by, $due, $trigger, $sp, $ep, $surl, $eurl, $ref) {
    [pscustomobject][ordered]@{
        event_at_uk = $nowUk.ToString('yyyy-MM-dd HH:mm'); research_date = $Date; product_key = $pk; alt_keys = ($alts -join ';')
        product_name = $name; source = $source; candidate_id = $cid; stage = $stage; status = $status; previous_status = $prev
        recommended_status = $recommended; reason = $reason; set_by = $by; recheck_due = $due; recheck_trigger = $trigger
        source_price = $sp; ebay_price = $ep; source_url = $surl; ebay_url = $eurl; evidence_ref = $ref
    }
}

function Get-NextSeasonStart([string]$eventName, [string]$eventDate, [string]$windowEnd) {
    $d = if (Test-Val $eventDate) { $eventDate } elseif (Test-Val $windowEnd) { $windowEnd } else { $null }
    if (-not $d -or -not (Test-Val $eventName)) { return $day.AddDays($WATCH_DAYS).ToString('yyyy-MM-dd') }
    $after = [DateTime]::ParseExact($d, 'yyyy-MM-dd', $inv).AddDays(1).ToString('yyyy-MM-dd')
    $rows = & (Join-Path $PSScriptRoot 'seasonal_dates.ps1') -Today $after -PassThru
    $r = $rows | Where-Object { $_.name -eq $eventName } | Select-Object -First 1
    if ($r) { return $r.preferred_listing_start }
    return $day.AddDays($WATCH_DAYS).ToString('yyyy-MM-dd')
}

# ============================================================================
switch ($Action) {

'Register' { $r = Write-Register; "Register rebuilt: $(@($r).Count) product(s) -> $regFile" }

'Due' {
    $reg = Write-Register
    $due = $reg | Where-Object { $_.current_status -in @('WATCH', 'DEPRIORITISE', 'RESEARCHED', 'QUALIFIED', 'KEEP') -and (Test-Val $_.recheck_due) -and $_.recheck_due -le $Date }
    "Rechecks due on or before ${Date}: $(@($due).Count)"
    $due | Format-Table product_key, product_name, current_status, recheck_due, recheck_trigger, last_reason -AutoSize | Out-String -Width 250
}

'Check' {
    $ix = Get-Index
    $keys = @()
    if (Test-Val $Gtin) { $keys += "GTIN:$($Gtin.Trim())" }
    if (Test-Val $SourceId) { $keys += $SourceId.Trim() }          # e.g. AMZ:B0XXXX, ALI:1005..., GDS:SKU, MOR:123
    if (Test-Val $Title) { $keys += "TITLE:$(Norm-Title $Title)" }
    $pk = $null; foreach ($k in $keys) { if ($ix.idx.ContainsKey($k)) { $pk = $ix.idx[$k]; break } }
    $possible = @()
    if (-not $pk -and (Test-Val $Title)) {
        $nt = Norm-Title $Title
        $possible = foreach ($p in $ix.latest.Keys) {
            $t = ("$($ix.latest[$p].alt_keys)" -split ';' | Where-Object { $_ -like 'TITLE:*' } | Select-Object -First 1)
            if ($t) { $s = Get-Jaccard $nt $t.Substring(6); if ($s -ge 0.6) { "$p ($($ix.latest[$p].status), similarity $([math]::Round($s,2)))" } }
        }
    }
    if (-not $pk) {
        $decision = if (@($possible).Count) { 'RESEARCH_CHECK_POSSIBLE_MATCH' } else { 'RESEARCH' }
        [pscustomobject]@{ decision = $decision; product_key = 'not found'; possible_matches = (@($possible) -join ' | ') } | Format-List | Out-String
        break
    }
    $e = $ix.latest[$pk]; $st = $e.status
    $due = "$($e.recheck_due)"; $isDue = (Test-Val $due) -and $due -le $Date
    $decision = switch ($st) {
        'RETIRE' { 'SKIP (RETIRE: intrinsic failure; only the user can reopen)' }
        { $_ -in $USER_ONLY } { "SKIP (user status $($st): in the user's pipeline)" }
        'NEW' { if ("$($e.research_date)" -lt $Date) { 'RECHECK (NEW from an earlier day, not completed)' } else { 'SKIP (already in today''s pipeline)' } }
        default { if ($isDue) { "RECHECK (recheck due $due)" } else { "SKIP unless a recheck trigger is observed (status $st, recheck due $due; triggers: $($e.recheck_trigger))" } }
    }
    [pscustomobject][ordered]@{
        decision = $decision; product_key = $pk; current_status = $st; last_reason = $e.reason; recheck_due = $due
        recheck_trigger = $e.recheck_trigger; last_source_price = $e.source_price; last_ebay_price = $e.ebay_price; last_researched = $e.research_date
    } | Format-List | Out-String
}

'SetStatus' {
    if ($Status -notin $STATUSES) { throw "Status must be one of: $($STATUSES -join ', ')" }
    if (-not (Test-Val $Reason)) { throw 'A reason is required.' }
    $ix = Get-Index
    if (-not $ix.latest.Contains($Key)) { throw "Unknown product_key: $Key" }
    $e = $ix.latest[$Key]
    if ($Status -in $USER_ONLY -and $SetBy -ne 'USER') { throw "$Status can only be set on the user's instruction (-SetBy USER)." }
    if ($e.status -eq 'RETIRE' -and $SetBy -ne 'USER') { throw 'Reopening a RETIRE product requires the user (-SetBy USER).' }
    if ($e.status -in $USER_ONLY -and $SetBy -ne 'USER') { throw "Product is in user status $($e.status); only the user can change it." }
    $due = if ($RecheckDue) { $RecheckDue } else { switch ($Status) {
            'WATCH' { $day.AddDays($WATCH_DAYS).ToString('yyyy-MM-dd') } 'DEPRIORITISE' { $day.AddDays($DEPRI_DAYS).ToString('yyyy-MM-dd') }
            'RESEARCHED' { $day.AddDays($RESEARCHED_DAYS).ToString('yyyy-MM-dd') } { $_ -in 'QUALIFIED', 'KEEP' } { $day.AddDays($QUALIFIED_DAYS).ToString('yyyy-MM-dd') }
            default { '' } } }
    $ev = New-Event $Key ("$($e.alt_keys)" -split ';') $e.product_name $e.source $e.candidate_id 'MANUAL' $Status $e.status $Status $Reason $SetBy $due $e.recheck_trigger $e.source_price $e.ebay_price $e.source_url $e.ebay_url 'manual'
    Append-Rows @($ev) $logFile
    Write-Register | Out-Null
    "Status set: $Key $($e.status) -> $Status (by $SetBy). Recheck due: $(if ($due) { $due } else { 'none' })"
}

'IngestReview' {
    # Days researched by hand have no stage files, so 'Ingest' found nothing from 15 Oct on (INC-002).
    $rj = Join-Path $Root "data\daily\${Date}_review.json"
    if (-not (Test-Path -LiteralPath $rj)) { throw "Review file not found: $rj" }
    $j = [IO.File]::ReadAllText($rj, [Text.Encoding]::UTF8) | ConvertFrom-Json
    $ix = Get-Index
    $logged = @{}; foreach ($l in $ix.log) { $logged["$($l.research_date)|$($l.candidate_id)"] = 1 }
    $lab = @{ 'AliExpress UK' = @('aliexpress_uk', 'ALI'); 'Go Dropship UK' = @('godropship_uk', 'GDS'); 'Amazon UK' = @('amazon_uk', 'AMZ'); 'AW Dropship' = @('aw_dropship', 'AWD'); 'Saleyee' = @('saleyee', 'SAL') }
    $newEvents = New-Object System.Collections.Generic.List[object]; $newRejs = New-Object System.Collections.Generic.List[object]; $skipped = 0
    foreach ($rec in @($j.all)) {
        $cat = "$(Get-Col $rec 'cat')"; $cid = "$(Get-Col $rec 'id')"
        if (-not $cat -or -not $cid -or $logged.ContainsKey("$Date|$cid") -or "$(Get-Col $rec 'rule')" -match '(?i)^duplicate') { $skipped++; continue }
        $src = if ($lab.ContainsKey("$($rec.source)")) { $lab["$($rec.source)"] } else { @('screen', '') }
        $name = "$($rec.name)"; $url = "$($rec.lSource.Url)"; $sid = ''
        if ($src[1] -eq 'ALI' -and "$url $name" -match '\b(100\d{10,})\b') { $sid = $Matches[1] }
        elseif ($src[1] -eq 'GDS' -and $name -match '\b([A-Z]{2,4}-\d{3,6})\b') { $sid = $Matches[1] }
        elseif ($src[1] -eq 'AMZ' -and "$url $name" -match '\b(B0[A-Z0-9]{8})\b') { $sid = $Matches[1] }
        $alts = Get-Keys '' $src[1] $sid (($name -replace '\([^)]*\)', ' ').Trim())
        if (-not $alts.Count) { $skipped++; continue }
        $pk = $null; foreach ($k in $alts) { if ($ix.idx.ContainsKey($k)) { $pk = $ix.idx[$k]; break } }
        if (-not $pk) { $pk = $alts[0] }
        foreach ($k in $alts) { if (-not $ix.idx.ContainsKey($k)) { $ix.idx[$k] = $pk } }
        $prev = if ($ix.latest.Contains($pk)) { $ix.latest[$pk].status } else { '' }
        $rule = "$($rec.rule)"; $due = $day.AddDays($WATCH_DAYS).ToString('yyyy-MM-dd'); $chg = 'YES'
        if ($cat -eq 'SELECTED') { $new = if ($prev -in (@('QUALIFIED', 'KEEP') + $USER_ONLY)) { 'KEEP' } else { 'QUALIFIED' }; $due = $day.AddDays($QUALIFIED_DAYS).ToString('yyyy-MM-dd') }
        elseif ($rule -match '(?i)avoid|vero|ip_risk|brand_ip') { $new = 'RETIRE'; $due = ''; $chg = 'NO' }
        else { $new = 'WATCH'; $cw = if ($ix.events.ContainsKey($pk)) { Get-ConsecutiveWatch $ix.events[$pk] } else { 0 }
            if ($prev -eq 'DEPRIORITISE' -or ($prev -eq 'WATCH' -and $cw -ge $MAX_WATCH)) { $new = 'DEPRIORITISE'; $due = $day.AddDays($DEPRI_DAYS).ToString('yyyy-MM-dd') } }
        $out = if ($prev -in $USER_ONLY -or $prev -eq 'RETIRE') { $prev } else { $new }
        $sp = "$($rec.sourcePrice.Value)"; if (-not $sp) { $sp = 'UNKNOWN' }
        $why = if ($cat -eq 'SELECTED') { "$($rec.decision)" } else { "$rule failed. $($rec.seen)" }
        $ev = New-Event $pk $alts $name $src[0] $cid 'REVIEW' $out $prev $new $why 'AGENT' $due $TRIGGERS[$rule] $sp "$($rec.ebayPrice)" $(if ($url) { $url } else { 'UNKNOWN' }) "$($rec.lSearch.Url)" "$Date review.json#$cid"
        $newEvents.Add($ev); $ix.latest[$pk] = $ev
        if ($cat -ne 'SELECTED') {
            $newRejs.Add([pscustomobject][ordered]@{ rejected_on = $Date; product_key = $pk; alt_keys = ($alts -join ';'); candidate_id = $cid; product_name = $name; source = $src[0]; source_url = $(if ($url) { $url } else { 'UNKNOWN' }); ebay_url = "$($rec.lSearch.Url)"
                stage = 'REVIEW'; failed_criterion = $rule; rejection_reason = "$($rec.reason)"; observed_value = "$($rec.seen)"; threshold = "$($rec.limit)"; evidence = "data/daily/${Date}_review.json#$cid"; failure_may_change = $chg
                change_triggers = $(if ($chg -eq 'NO') { 'none (intrinsic); user may reopen' } else { $TRIGGERS[$rule] }); resulting_status = $out; recheck_due = $due; product_type = 'UNKNOWN'; seasonality = "$($rec.seasonal)"; target_event = "$($rec.target)"; seasonal_phase = "$($rec.phase)"; notes = "$($rec.notes)" })
        }
    }
    Append-Rows $newEvents $logFile; Append-Rows $newRejs $rejFile
    $reg = Write-Register
    "IngestReview ${Date}: $($newEvents.Count) status event(s), $($newRejs.Count) rejection row(s) appended, $skipped skipped (already logged, duplicate or no data); register has $(@($reg).Count) product(s)."
}

'Ingest' {
    $ix = Get-Index
    $loggedKeys = @{}; foreach ($l in $ix.log) { $loggedKeys["$($l.research_date)|$($l.candidate_id)|$($l.stage)"] = 1 }
    $rejLogged = @{}; foreach ($r in (Read-Csv $rejFile)) { $rejLogged["$($r.rejected_on)|$($r.candidate_id)|$($r.stage)|$($r.failed_criterion)"] = 1 }

    $cands = [ordered]@{}
    foreach ($s in $SRC.Keys) {
        $f = Join-Path $Root "data\sources\$s\${Date}_${s}_stage.csv"
        foreach ($row in (Read-Csv $f)) { $cands[$row.candidate_id] = @{ row = $row; src = $s; file = $f } }
    }
    $latestBy = { param($rows, $tsCol) $m = @{}; foreach ($x in $rows) { $m[$x.candidate_id] = $x }; $m }   # file order: last row wins
    $ebayF = Join-Path $Root "data\ebay\${Date}_ebay_verification.csv"; $ebay = & $latestBy (Read-Csv $ebayF) ''
    $profF = Join-Path $Root "data\profit\${Date}_profit.csv"; $prof = & $latestBy (Read-Csv $profF) ''
    $seasF = Join-Path $Root "data\seasonal\${Date}_seasonal_classification.csv"; $seas = & $latestBy (Read-Csv $seasF) ''

    $newEvents = New-Object System.Collections.Generic.List[object]
    $newRejs = New-Object System.Collections.Generic.List[object]
    foreach ($cid in $cands.Keys) {
        $c = $cands[$cid]; $h = $c.row; $meta = $SRC[$c.src]
        $alts = Get-Keys (Get-Col $h 'ean_gtin') $meta.prefix (Get-Col $h $meta.id) (Get-Col $h 'product_name')
        $pk = $null; foreach ($k in $alts) { if ($ix.idx.ContainsKey($k)) { $pk = $ix.idx[$k]; break } }
        if (-not $pk) { $pk = $alts[0] }
        foreach ($k in $alts) { if (-not $ix.idx.ContainsKey($k)) { $ix.idx[$k] = $pk } }   # same-batch products link to each other
        $prevE = if ($ix.latest.Contains($pk)) { $ix.latest[$pk] } else { $null }
        $prev = if ($prevE) { $prevE.status } else { '' }
        $er = $ebay[$cid]; $pr = $prof[$cid]; $sr = $seas[$cid]

        $fails = New-Object System.Collections.Generic.List[object]
        $stage = 'SOURCE'; $outcome = 'NEW'; $reasonText = ''
        function Add-StatusFails($row, [string]$stg, [string]$file) {
            foreach ($p in $row.PSObject.Properties) {
                if ($p.Name -notlike '*_status' -or $p.Name -in $SKIP_STATUS_COLS) { continue }
                $v = "$($p.Value)".Trim().ToUpper()
                if ($v -eq 'FAIL' -or $v -eq 'OUT_OF_STOCK') {
                    $crit = $p.Name -replace '_status$', ''
                    if ($crit -eq 'stock' -or $v -eq 'OUT_OF_STOCK') { $crit = 'stock' }
                    $ev = Get-Col $row "${crit}_evidence"
                    $fails.Add(@{ stage = $stg; crit = $crit; observed = (Get-Col $row $crit); evidence = $(if (Test-Val $ev) { "$ev | $file#$cid" } else { "$file#$cid" }) })
                }
            }
        }
        if ("$(Get-Col $h 'proceed_to_ebay')" -eq 'NO') {
            Add-StatusFails $h 'SOURCE' $c.file
            if (-not $fails.Count) { $fails.Add(@{ stage = 'SOURCE'; crit = 'source_check'; observed = (Get-Col $h 'failed_criteria'); evidence = "$($c.file)#$cid" }) }
            $reasonText = Get-Col $h 'rejection_reason'; $outcome = 'FAIL'
        } elseif ($er) {
            $stage = 'EBAY'; $reasonText = Get-Col $er 'rejection_reason'
            if ("$(Get-Col $er 'ebay_verification_status')" -eq 'FAIL') { Add-StatusFails $er 'EBAY' $ebayF; $outcome = 'FAIL'
                if (-not $fails.Count) { $fails.Add(@{ stage = 'EBAY'; crit = 'ebay_verification'; observed = 'FAIL'; evidence = "$ebayF#$cid" }) } }
            elseif ("$(Get-Col $er 'proceed_to_profit')" -eq 'NO') {
                $fails.Add(@{ stage = 'EBAY'; crit = 'ebay_evidence_unavailable'; observed = $reasonText; evidence = "$ebayF#$cid" }); $outcome = 'FAIL' }
            else { $outcome = 'RESEARCHED' }
            if ($pr -and $outcome -ne 'FAIL') {
                $stage = 'PROFIT'
                foreach ($g in 'price', 'profit', 'roi', 'margin') {
                    if ("$(Get-Col $pr "${g}_gate")" -eq 'FAIL') {
                        $obs = switch ($g) { 'price' { Get-Col $pr 'listed_price' } 'profit' { Get-Col $pr 'profit' } 'roi' { "$(Get-Col $pr 'roi_pct')% (min $(Get-Col $pr 'roi_min_pct')%)" } 'margin' { "$(Get-Col $pr 'profit_pct')% (min $(Get-Col $pr 'margin_min_pct')%)" } }
                        $fails.Add(@{ stage = 'PROFIT'; crit = $g; observed = $obs; evidence = "$profF#$cid" })
                    }
                }
                $acc = "$(Get-Col $pr 'acceptance_status')"
                $outcome = if ($fails.Count) { 'FAIL' } elseif ($acc -in 'PASS', 'EXCEPTION') { 'QUALIFIED' } else { 'RESEARCHED' }
                if ($sr -and $outcome -ne 'FAIL') {
                    $stage = 'SEASONAL'
                    if ("$(Get-Col $sr 'timing_status')" -eq 'FAIL') { $fails.Add(@{ stage = 'SEASONAL'; crit = 'seasonal_timing'; observed = (Get-Col $sr 'timing_flags'); evidence = "$seasF#$cid" }); $outcome = 'FAIL' }
                    elseif ("$(Get-Col $sr 'overall_status')" -eq 'UNKNOWN') { $outcome = 'RESEARCHED' }
                }
            }
        }

        # --- Status decision ---------------------------------------------------
        $classes = @($fails | ForEach-Object { if ($_.crit -in $CHANGE_NO) { 'NO' } elseif ($_.crit -in $CHANGE_LOW) { 'LOW' } else { 'YES' } })
        $trig = (@($fails | ForEach-Object { $TRIGGERS[$_.crit] } | Where-Object { $_ } | Select-Object -Unique) -join '; ')
        $due = ''
        if ($outcome -eq 'FAIL') {
            if ($classes -contains 'NO') { $new = 'RETIRE'; $trig = 'none (intrinsic, CLAUDE.md s4); only the user can reopen' }
            elseif ($classes -contains 'LOW') { $new = 'DEPRIORITISE'; $due = $day.AddDays($DEPRI_DAYS).ToString('yyyy-MM-dd') }
            else {
                $new = 'WATCH'
                $due = if (@($fails | Where-Object { $_.crit -eq 'seasonal_timing' }).Count) {
                    Get-NextSeasonStart (Get-Col $sr 'target_event') (Get-Col $sr 'event_date') (Get-Col $sr 'window_end') } else { $day.AddDays($WATCH_DAYS).ToString('yyyy-MM-dd') }
                $cw = if ($ix.events.ContainsKey($pk)) { Get-ConsecutiveWatch $ix.events[$pk] } else { 0 }
                # Access problems (blocked/no eBay evidence) and seasonal timing say nothing about the product itself:
                # never escalate to DEPRIORITISE on them alone.
                $productFail = @($fails | Where-Object { $_.crit -notin 'ebay_evidence_unavailable', 'seasonal_timing' }).Count -gt 0
                if ($productFail -and $prev -eq 'DEPRIORITISE') { $new = 'DEPRIORITISE'; $due = $day.AddDays($DEPRI_DAYS).ToString('yyyy-MM-dd') }
                elseif ($productFail -and $prev -eq 'WATCH' -and $cw -ge $MAX_WATCH) { $new = 'DEPRIORITISE'; $due = $day.AddDays($DEPRI_DAYS).ToString('yyyy-MM-dd'); $trig = "$trig; failed $($cw + 1) consecutive rechecks" }
            }
        } elseif ($outcome -eq 'QUALIFIED') {
            $new = if ($prev -in (@('QUALIFIED', 'KEEP') + $USER_ONLY)) { 'KEEP' } else { 'QUALIFIED' }; $due = $day.AddDays($QUALIFIED_DAYS).ToString('yyyy-MM-dd'); $trig = 'lifecycle review (s21)'
        } elseif ($outcome -eq 'RESEARCHED') {
            $new = 'RESEARCHED'; $due = $day.AddDays($RESEARCHED_DAYS).ToString('yyyy-MM-dd'); $trig = 'missing data becomes available'
        } else { $new = 'NEW' }

        $recommended = $new; $outStatus = $new; $by = 'AGENT'
        $why = if ($fails.Count) { "$(($fails | ForEach-Object { $_.crit }) -join ', ') failed. $reasonText".Trim() } else { "Outcome: $outcome at $stage." }
        if ($prev -in $USER_ONLY) { $outStatus = $prev; $why = "User status kept; agent recommends $recommended. $why" }

        $k = "$Date|$cid|$stage"   # one event per candidate per stage per research day (re-runs add nothing)
        if (-not $loggedKeys.ContainsKey($k)) {
            $loggedKeys[$k] = 1
            $sp = Get-Col $h $meta.price
            $ep = if ($pr) { Get-Col $pr 'listed_price' } elseif ($er) { Get-Col $er 'reference_seller_price' } else { 'UNKNOWN' }
            $eurl = if ($er) { $(if (Test-Val (Get-Col $er 'reference_seller_url')) { Get-Col $er 'reference_seller_url' } else { Get-Col $er 'ebay_sold_search_url' }) } else { 'N/A' }
            $newEvents.Add((New-Event $pk $alts (Get-Col $h 'product_name') $c.src $cid $stage $outStatus $prev $recommended $why 'AGENT' $due $trig $sp $ep (Get-Col $h $meta.url) $eurl "$Date stage files#$cid"))

            foreach ($fl in $fails) {
                $rk = "$Date|$cid|$($fl.stage)|$($fl.crit)"
                if ($rejLogged.ContainsKey($rk)) { continue }; $rejLogged[$rk] = 1
                $chg = if ($fl.crit -in $CHANGE_NO) { 'NO' } elseif ($fl.crit -in $CHANGE_LOW) { 'LOW' } else { 'YES' }
                $newRejs.Add([pscustomobject][ordered]@{
                    rejected_on = $Date; product_key = $pk; alt_keys = ($alts -join ';'); candidate_id = $cid; product_name = Get-Col $h 'product_name'
                    source = $c.src; source_url = Get-Col $h $meta.url; ebay_url = $eurl; stage = $fl.stage; failed_criterion = $fl.crit
                    rejection_reason = $reasonText; observed_value = $(if (Test-Val $fl.observed) { $fl.observed } else { 'see evidence' })
                    threshold = $(if ($THRESHOLDS.ContainsKey($fl.crit)) { $THRESHOLDS[$fl.crit] } else { 'see stage rules' })
                    evidence = $fl.evidence; failure_may_change = $chg; change_triggers = $(if ($chg -eq 'NO') { 'none (intrinsic); user may reopen' } else { $TRIGGERS[$fl.crit] })
                    resulting_status = $outStatus; recheck_due = $due
                    product_type = $(if ($sr) { Get-Col $sr 'product_type' } else { Get-Col $h 'product_type' })
                    seasonality = $(if ($sr) { Get-Col $sr 'seasonality' } else { Get-Col $h 'seasonality' })
                    target_event = $(if ($sr) { Get-Col $sr 'target_event' } else { Get-Col $h 'target_event' })
                    seasonal_phase = $(if ($sr) { Get-Col $sr 'seasonal_phase' } else { Get-Col $h 'seasonal_phase' })
                    notes = Get-Col $h 'notes'
                })
            }
        }
    }
    Append-Rows $newEvents $logFile
    Append-Rows $newRejs $rejFile
    $reg = Write-Register
    "Ingest ${Date}: $($cands.Count) candidate(s); $($newEvents.Count) status event(s) and $($newRejs.Count) rejection row(s) appended; register has $(@($reg).Count) product(s)."
}
}


