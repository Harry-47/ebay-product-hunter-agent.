<#
Incident log for the self-improvement loop (CLAUDE.md s29, prompts/operating_loop.md).
data/learning/incidents.csv is append-only: every change of state is a new row; the last row per incident is its state.

  -Action Search  -Text "chrome frozen"                      known failures first, before trying anything
  -Action Log     -Signature "short stable name" -Area tool -Symptom "..." [-Cause "..."]
                  a known signature is logged as RECURRED; if it was FIXED it is reported as a REGRESSION
  -Action Fix     -Id INC-007 -Cause "..." -Fix "..." -Files "tools\x.ps1" -Proof "tests\x.test.ps1"
                  refused unless the proof exists and tools\selftest.ps1 passes
  -Action Workaround -Id INC-007 -Cause "..." -Fix "..." -Files "prompts\operating_loop.md"
  -Action NeedsUser  -Id INC-007 -Fix "what the user must do or decide"
  -Action Open | Stats
#>
param(
    [Parameter(Mandatory)][ValidateSet('Search', 'Log', 'Fix', 'Workaround', 'NeedsUser', 'Open', 'Stats')][string]$Action,
    [string]$Id, [string]$Signature, [ValidateSet('tool', 'browser', 'site', 'data', 'workflow', 'rule', 'environment', 'guard')][string]$Area = 'tool',
    [string]$Symptom, [string]$Cause, [string]$Fix, [string]$Files, [string]$Proof, [string]$Text, [string]$Note, [string]$Root
)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$file = Join-Path $Root 'data\learning\incidents.csv'
$tz = [TimeZoneInfo]::FindSystemTimeZoneById('GMT Standard Time')
$now = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz).ToString('yyyy-MM-dd HH:mm')
$all = @(); if (Test-Path -LiteralPath $file) { $all = @(Import-Csv -LiteralPath $file) }
$state = [ordered]@{}; $count = @{}
foreach ($r in $all) { $state[$r.incident_id] = $r; if ($r.event -in 'OPENED', 'RECURRED', 'REGRESSION') { $count[$r.incident_id] = 1 + [int]$count[$r.incident_id] } }
function Add-Event($iid, $ev, $base) {
    $pick = { param($new, $old) if ("$new".Trim()) { $new } else { $old } }
    $row = [pscustomobject][ordered]@{ event_at_uk = $now; incident_id = $iid; event = $ev; area = $(if ($base) { $base.area } else { $Area }); signature = $(if ($base) { $base.signature } else { $Signature })
        symptom = & $pick $Symptom $base.symptom; root_cause = & $pick $Cause $base.root_cause; fix = & $pick $Fix $base.fix; files_changed = & $pick $Files $base.files_changed; proof = & $pick $Proof $base.proof; note = $Note }
    $dir = Split-Path $file -Parent; if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $row | Export-Csv -LiteralPath $file -NoTypeInformation -Encoding UTF8 -Append
    return $row
}
function Need($v, $n) { if (-not "$v".Trim()) { throw "-$n is required for $Action" } }
function Get-Inc { Need $Id 'Id'; if (-not $state.Contains($Id)) { throw "Unknown incident $Id" }; return $state[$Id] }

switch ($Action) {
    'Search' {
        Need $Text 'Text'
        $words = @($Text.ToLower() -split '[^a-z0-9]+' | Where-Object { $_.Length -gt 2 })
        $hits = foreach ($r in $state.Values) { $hay = "$($r.signature) $($r.symptom) $($r.root_cause) $($r.fix)".ToLower(); $n = @($words | Where-Object { $hay.Contains($_) }).Count; if ($n) { [pscustomobject]@{ n = $n; r = $r } } }
        $hits = @($hits | Sort-Object n -Descending | Select-Object -First 5)
        if (-not $hits.Count) { 'No known incident matches. Diagnose it, then log it.' }
        foreach ($h in $hits) { $r = $h.r; "{0} [{1}] {2}`n   cause: {3}`n   do:    {4}" -f $r.incident_id, $r.event, $r.signature, $r.root_cause, $r.fix }
    }
    'Log' {
        Need $Signature 'Signature'; Need $Symptom 'Symptom'
        $old = $state.Values | Where-Object { $_.signature -eq $Signature } | Select-Object -First 1
        if ($old) {
            $ev = if ($old.event -eq 'FIXED') { 'REGRESSION' } else { 'RECURRED' }
            [void](Add-Event $old.incident_id $ev $old)
            if ($ev -eq 'REGRESSION') { "REGRESSION of $($old.incident_id): the earlier fix did not hold. Find out why its test passed, strengthen the test, then fix again. Earlier fix: $($old.fix)" }
            else { "$($old.incident_id) RECURRED ($(1 + [int]$count[$old.incident_id]) times, state was $($old.event)). Known answer: $($old.fix)" }
        } else {
            $max = 0; foreach ($k in $state.Keys) { if ($k -match 'INC-(\d+)' -and [int]$Matches[1] -gt $max) { $max = [int]$Matches[1] } }
            $iid = 'INC-{0:D3}' -f ($max + 1); [void](Add-Event $iid 'OPENED' $null); "$iid OPENED: $Signature"
        }
    }
    'Fix' {
        $b = Get-Inc; Need $Cause 'Cause'; Need $Fix 'Fix'; Need $Files 'Files'; Need $Proof 'Proof'
        if ($Proof -notmatch '^tests\\.+\.test\.ps1$') { throw 'A FIXED incident needs a regression test (tests\*.test.ps1). Without one, use -Action Workaround.' }
        if (-not (Test-Path -LiteralPath (Join-Path $Root $Proof))) { throw "Proof not found: $Proof" }
        foreach ($f in ($Files -split ';')) { if ($f -match '(?i)browser_guard|\.claude\\|settings') { throw "The loop may not change $f (safety guard and settings are the user's)." } }
        $res = & (Join-Path $PSScriptRoot 'selftest.ps1') -Quiet -Root $Root
        if ($res -ne 'PASS') { throw "selftest does not pass; $Id stays open. Run tools\selftest.ps1 to see why." }
        [void](Add-Event $Id 'FIXED' $b); "$Id FIXED (proof: $Proof, selftest PASS)"
    }
    'Workaround' { $b = Get-Inc; Need $Cause 'Cause'; Need $Fix 'Fix'; [void](Add-Event $Id 'WORKAROUND' $b); "$Id WORKAROUND recorded" }
    'NeedsUser' { $b = Get-Inc; Need $Fix 'Fix'; [void](Add-Event $Id 'NEEDS_USER' $b); "$Id NEEDS_USER: $Fix" }
    'Open' {
        $o = @($state.Values | Where-Object { $_.event -notin 'FIXED' })
        "Not fully fixed: $($o.Count)"
        $o | ForEach-Object { "{0} [{1}] x{2} {3} -> {4}" -f $_.incident_id, $_.event, [int]$count[$_.incident_id], $_.signature, $_.fix }
    }
    'Stats' { $state.Values | Group-Object event | Sort-Object Name | ForEach-Object { "{0}: {1}" -f $_.Name, $_.Count } }
}
