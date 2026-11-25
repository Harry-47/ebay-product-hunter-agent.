<#
Starts Chrome and Claude Code (Chrome + Remote Control) for this project. Then type "start the daily hunt" here or in the Claude app.
Usage: powershell -ExecutionPolicy Bypass -File scripts\start_agent.ps1
Permission prompts stay on: they appear here and in the Claude app. It never signs in to any site.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
if (-not (Test-Path -LiteralPath $chrome)) { throw "Chrome not found: $chrome" }
$claude = (Get-Command claude -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $claude -and (Test-Path "$env:USERPROFILE\.local\bin\claude.exe")) { $claude = "$env:USERPROFILE\.local\bin\claude.exe" }
if (-not $claude) { throw 'Claude Code is not installed for the terminal. See docs\setup_vps.md step 1.' }
if (-not (Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 })) { Start-Process $chrome; Start-Sleep -Seconds 8 }
Set-Location -LiteralPath $root
& $claude --chrome --remote-control 'eBay Product Hunter'