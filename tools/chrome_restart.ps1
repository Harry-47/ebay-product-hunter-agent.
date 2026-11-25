<#
Restart a frozen Chrome (user permission 2026-11-13: "if chrome freeze, close it and load again").
Asks Chrome to close first so sessions and cookies are saved; only what is still running after that is ended.
After it: tab ids are new (call tabs_context_mcp), and sites may be signed out (the user signs in, never the agent).
#>
$ErrorActionPreference = 'Stop'
$exe = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
if (-not (Test-Path -LiteralPath $exe)) { throw "Chrome not found: $exe" }
Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | ForEach-Object { [void]$_.CloseMainWindow() }
$end = (Get-Date).AddSeconds(10)
while ((Get-Process chrome -ErrorAction SilentlyContinue) -and (Get-Date) -lt $end) { Start-Sleep -Milliseconds 500 }
$left = @(Get-Process chrome -ErrorAction SilentlyContinue); if ($left.Count) { $left | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2 }
Start-Process $exe
Start-Sleep -Seconds 10
"Chrome restarted ($(if ($left.Count) { 'had to be ended' } else { 'closed normally' })); {0:N2} GB RAM free. Get new tab ids before continuing." -f ((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB)
