# The loop's own safety: incidents cannot be closed without proof, regressions are noticed, duplicates are found,
# protected files are unchanged, every script parses, and stale instructions do not come back.
param($Root, $Tmp)
$ErrorActionPreference = 'Stop'
function Assert($c, $m) { if (-not $c) { throw $m } }
$L = Join-Path $Root 'tools\lessons.ps1'
$o = & $L -Action Log -Signature 'sig a' -Area tool -Symptom 'boom' -Root $Tmp; Assert ($o -match 'INC-001 OPENED') 'incident not opened'
Set-Content (Join-Path $Tmp 'notes.txt') 'a file that exists but is not a test' -Encoding ASCII
$o = & $L -Action Log -Signature 'sig a' -Symptom 'boom again' -Root $Tmp; Assert ($o -match 'RECURRED') 'repeat not recognised'
foreach ($try in @(@{ Files = 'tools\x.ps1'; Proof = 'notes.txt' },@{ Files = 'tools\browser_guard.ps1'; Proof = 'tests\p.test.ps1' }, @{ Files = 'tools\x.ps1'; Proof = 'tests\nothere.test.ps1' })) {
    New-Item -ItemType Directory -Force -Path (Join-Path $Tmp 'tests') | Out-Null; Set-Content (Join-Path $Tmp 'tests\p.test.ps1') 'param($Root,$Tmp)' -Encoding ASCII
    $err = $false; try { & $L -Action Fix -Id INC-001 -Cause c -Fix f -Root $Tmp @try | Out-Null } catch { $err = $true }; Assert $err "Fix accepted: $($try.Files) / $($try.Proof)" }
& $L -Action Fix -Id INC-001 -Cause c -Fix f -Files 'tools\x.ps1' -Proof 'tests\p.test.ps1' -Root $Tmp | Out-Null
$o = & $L -Action Log -Signature 'sig a' -Symptom 'back' -Root $Tmp; Assert ($o -match 'REGRESSION') 'regression not noticed'
$o = (& $L -Action Search -Text 'boom sig' -Root $Tmp) -join ' '; Assert ($o -match 'INC-001') 'search does not find the incident'
Set-Content (Join-Path $Tmp 'tests\p.test.ps1') 'param($Root,$Tmp) throw "x"' -Encoding ASCII
$err = $false; try { & $L -Action Fix -Id INC-001 -Cause c -Fix f -Files 'tools\x.ps1' -Proof 'tests\p.test.ps1' -Root $Tmp | Out-Null } catch { $err = $true }; Assert $err 'Fix accepted while a test fails'
# duplicates (INC-006)
New-Item -ItemType Directory -Force -Path (Join-Path $Tmp 'data\competitors'), (Join-Path $Tmp 'data\notes') | Out-Null
Set-Content (Join-Path $Tmp 'data\competitors\passing_sellers.csv') '2026-10-14,Go Dropship UK,2 pcs outside tap covers,x' -Encoding ASCII
Set-Content (Join-Path $Tmp 'data\notes\n.txt') 'REJECT garden hose reel price' -Encoding ASCII
$D = Join-Path $Root 'tools\dedupe_check.ps1'
Assert ("$(& $D -Words 'tap cover' -Root $Tmp)" -match 'PASSED BEFORE') 'earlier pass not found'
Assert ("$(& $D -Words 'hose reel' -Root $Tmp)" -match 'SEEN BEFORE') 'earlier rejection not found'
Assert ("$(& $D -Words 'purple kite' -Root $Tmp)" -eq 'NEW') 'a new product was not NEW'
# protected files: only the user changes these. If the user did change one, they ask for the baseline to be updated.
foreach ($p in (Import-Csv (Join-Path $Root 'tests\protected_files.csv'))) { Assert ((Get-FileHash -LiteralPath (Join-Path $Root $p.path) -Algorithm SHA256).Hash -eq $p.sha256) "$($p.path) changed since the baseline: ask the user" }
# every script parses, and non-ASCII scripts carry a BOM (PowerShell 5.1 misreads them otherwise)
foreach ($f in (Get-ChildItem (Join-Path $Root 'tools'), (Join-Path $Root 'tests') -Filter *.ps1)) {
    $e = $null; [void][Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$null, [ref]$e); Assert (-not $e.Count) "$($f.Name) does not parse"
    $b = [IO.File]::ReadAllBytes($f.FullName); $na = $false; foreach ($x in $b) { if ($x -gt 127) { $na = $true; break } }; Assert (-not $na -or ($b[0] -eq 239)) "$($f.Name) has non-ASCII text but no BOM" }
# stale instructions (INC-007): phrases that contradict CLAUDE.md must not return to the prompts
foreach ($s in (Import-Csv (Join-Path $Root 'tests\stale_phrases.csv'))) { $hit = Get-ChildItem (Join-Path $Root 'prompts') -Recurse -Filter *.md | Select-String -SimpleMatch $s.phrase | Select-Object -First 1; Assert (-not $hit) "$($hit.Filename):$($hit.LineNumber) says '$($s.phrase)' ($($s.why))" }
