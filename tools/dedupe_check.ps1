<#
Has this product been researched before? Run BEFORE opening a source page. Searches all of data\ (csv, txt, md, ps1), not a glob.
Usage: .\tools\dedupe_check.ps1 -Words "tap cover" [-ItemId 1005007097015654] [-Root path]
All the words must be on the same line. Prints PASSED BEFORE / SEEN BEFORE / NEW with the lines found.
#>
param([string]$Words, [string]$ItemId, [string]$Root, [int]$Max = 8)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
if (-not $Words -and -not $ItemId) { throw 'Give -Words and/or -ItemId' }
$w = @("$Words".ToLower() -split '\s+' | Where-Object { $_ } | ForEach-Object { if ($_.Length -gt 4) { $_ -replace 's$', '' } else { $_ } })
$hits = New-Object System.Collections.Generic.List[object]
foreach ($f in (Get-ChildItem -LiteralPath (Join-Path $Root 'data') -Recurse -File -Include *.csv, *.txt, *.md, *.ps1 -ErrorAction SilentlyContinue)) {
    if ($f.Name -match 'evidence_log|guard_log|incidents') { continue }
    $n = 0
    foreach ($line in [IO.File]::ReadLines($f.FullName)) {
        $n++; $l = $line.ToLower()
        $ok = ($ItemId -and $l.Contains($ItemId.ToLower()))
        if (-not $ok -and $w.Count) { $ok = $true; foreach ($x in $w) { if (-not $l.Contains($x)) { $ok = $false; break } } }
        if ($ok) { $hits.Add([pscustomobject]@{ passed = ($f.Name -eq 'passing_sellers.csv' -and $l -notmatch 'correction|duplicate|not counted') -or ($l -match "cat = 'selected'|\*\*\* pass|^pass "); where = "$($f.Name):$n"; text = $line.Substring(0, [math]::Min(150, $line.Length)) }) }
    }
}
$p = @($hits | Where-Object { $_.passed })
if ($p.Count) { 'PASSED BEFORE: do not research or count it again'; $p | Select-Object -First $Max | ForEach-Object { "  $($_.where)  $($_.text)" } }
elseif ($hits.Count) { "SEEN BEFORE ($($hits.Count) lines): read the reason, recheck only if it may have changed"; $hits | Select-Object -First $Max | ForEach-Object { "  $($_.where)  $($_.text)" } }
else { 'NEW' }
