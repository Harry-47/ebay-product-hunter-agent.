<#
Runs every tests\*.test.ps1 (regression tests for the project's own scripts). Tests use a temporary folder and never
touch data\. A test fails by throwing. Run before a hunt, after any script change, and before an incident is closed.
Usage: .\tools\selftest.ps1 [-Quiet]     -Quiet returns only PASS or FAIL
#>
param([switch]$Quiet, [string]$Root)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$failed = 0; $n = 0
foreach ($t in (Get-ChildItem -LiteralPath (Join-Path $Root 'tests') -Filter '*.test.ps1' | Sort-Object Name)) {
    $n++
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("hunt_test_" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try { & $t.FullName -Root $Root -Tmp $tmp | Out-Null; if (-not $Quiet) { "PASS  $($t.Name)" } }
    catch { $failed++; if (-not $Quiet) { "FAIL  $($t.Name): $($_.Exception.Message)" } }
    finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
if ($Quiet) { if ($failed -or -not $n) { 'FAIL' } else { 'PASS' } } else { "selftest: $($n - $failed) of $n passed" }
