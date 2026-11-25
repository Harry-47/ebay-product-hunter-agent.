# Nothing secret may reach GitHub, and CLAUDE.md must keep the hunt command and valid file paths. Values are never printed.
param($Root, $Tmp)
$ErrorActionPreference = 'Stop'
function Assert($c, $m) { if (-not $c) { throw $m } }
$gi = @(Get-Content -LiteralPath (Join-Path $Root '.gitignore') | ForEach-Object { $_.Trim() })
foreach ($x in '.env', '.env.*', '*.key', '*.pem', 'cookies/', 'storage/', 'session/', 'User Data/', '*.log', '.claude/settings.local.json', 'Thumbs.db', '.DS_Store') { Assert ($gi -contains $x) ".gitignore lacks $x" }
$secret = '(?i)(api[_-]?key|app[_-]?secret|client[_-]?secret|password|passwd|access[_-]?token|api[_-]?token|bearer)\b\s*["'']?\s*[:=]\s*["'']?[A-Za-z0-9_\-\.]{16,}|sk-ant-[A-Za-z0-9\-]{10,}|AIza[0-9A-Za-z_\-]{30,}|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{20,}|xox[bap]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY'
Assert ('EBAY_CLIENT_SECRET=abcdefghijklmnop1234' -match $secret -and 'AW_DROPSHIP_API_TOKEN=abcdefghijklmnop1234' -match $secret) 'the secret pattern finds nothing'
$files = Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.Name -ne '.env' -and $_.Name -ne 'browser_guard_log.csv' -and $_.Extension -match '^\.(md|ps1|yaml|yml|json|csv|txt|example|html)$' -and $_.Length -lt 3MB }
foreach ($f in $files) { $h = Select-String -LiteralPath $f.FullName -Pattern $secret -List; if ($h -and $f.Name -notin 'repo_safety.test.ps1', 'env_check.test.ps1') { throw "secret-like text in $($f.FullName.Substring($Root.Length + 1)):$($h.LineNumber)" } }
$md = [IO.File]::ReadAllText((Join-Path $Root 'CLAUDE.md'))
Assert ($md.Contains('"start the daily hunt"') -and $md -match 'start at once') 'CLAUDE.md lost the hunt command'
Assert ($md.Length -lt 60000) "CLAUDE.md is $($md.Length) characters: move detail to prompts/ or docs/"
foreach ($m in [regex]::Matches($md, '`((?:prompts|tools|docs|tests|scripts)[/\\][A-Za-z0-9_./\\-]+?\.(?:md|ps1|yaml|csv))`')) { Assert (Test-Path -LiteralPath (Join-Path $Root $m.Groups[1].Value)) "CLAUDE.md points to a missing file: $($m.Groups[1].Value)" }
foreach ($n in 1..29) { Assert ($md -match "(?m)^## $n\. ") "CLAUDE.md section $n is missing" }
