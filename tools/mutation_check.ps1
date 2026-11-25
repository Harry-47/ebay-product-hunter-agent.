<#
Do the regression tests really catch the bugs they claim to? Puts each old bug back in a scratch copy and runs the tests.
Every line must say CAUGHT. Mutations are listed in tests\mutations.csv (name,file,good,bad); add one for each fixed script bug.
Usage: .\tools\mutation_check.ps1     (slow: run after changing a test, not on every hunt)
#>
param([string]$Root)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$s = Join-Path ([IO.Path]::GetTempPath()) ('hunt_mut_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $s | Out-Null
$missed = 0
try {
    foreach ($d in 'tools', 'tests', 'templates', 'prompts', '.claude') { Copy-Item (Join-Path $Root $d) $s -Recurse }
    $utf = New-Object Text.UTF8Encoding($true)
    if ((& (Join-Path $s 'tools\selftest.ps1') -Quiet -Root $s) -ne 'PASS') { throw 'the tests already fail before any bug is put back' }
    foreach ($m in @(Import-Csv -LiteralPath (Join-Path $Root 'tests\mutations.csv'))) {
        $p = Join-Path $s $m.file; $o = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)
        if (-not $o.Contains($m.good)) { $missed++; "STALE   $($m.name): the code it changes is gone, update tests\mutations.csv"; continue }
        [IO.File]::WriteAllText($p, $o.Replace($m.good, $m.bad), $utf)
        $r = & (Join-Path $s 'tools\selftest.ps1') -Quiet -Root $s
        if ($r -eq 'FAIL') { "CAUGHT  $($m.name)" } else { $missed++; "MISSED  $($m.name): the tests did not notice" }
        [IO.File]::WriteAllText($p, $o, $utf)
    }
} finally { Remove-Item -LiteralPath $s -Recurse -Force -ErrorAction SilentlyContinue }
if ($missed) { "RESULT: $missed problem(s)" } else { 'RESULT: every old bug is caught' }
