# env_check reports SET/EMPTY, never a value, and refuses an unprotected .env or a key in the shareable copy.
param($Root, $Tmp)
$ErrorActionPreference = 'Stop'
function Assert($c, $m) { if (-not $c) { throw $m } }
$E = Join-Path $Root 'tools\env_check.ps1'
Set-Content (Join-Path $Tmp '.gitignore') '.env' -Encoding ASCII
Set-Content (Join-Path $Tmp '.env.example') @('# c', 'KEEPA_API_KEY=', 'EBAY_CLIENT_ID=') -Encoding ASCII
Set-Content (Join-Path $Tmp '.env') @('KEEPA_API_KEY=zz-dummy-zz', 'EBAY_CLIENT_ID=', 'EBAY_PASSWORD=qq-dummy-qq') -Encoding ASCII
$o = (& $E -Root $Tmp) -join "`n"
Assert ($o -match 'KEEPA_API_KEY\s+SET') 'set key not reported'
Assert ($o -match 'EBAY_CLIENT_ID\s+EMPTY') 'empty key not reported'
Assert ($o -notmatch 'dummy') 'a value was printed'
Assert ($o -match 'WARN EBAY_PASSWORD') 'password not flagged'
Set-Content (Join-Path $Tmp '.env.example') 'KEEPA_API_KEY=oops' -Encoding ASCII
$err = $false; try { & $E -Root $Tmp | Out-Null } catch { $err = $true; Assert ("$_" -notmatch 'oops') 'value in error' }; Assert $err 'key in .env.example accepted'
Set-Content (Join-Path $Tmp '.gitignore') 'cookies/' -Encoding ASCII
$err = $false; try { & $E -Root $Tmp | Out-Null } catch { $err = $true }; Assert $err 'unprotected .env accepted'