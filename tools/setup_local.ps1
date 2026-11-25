# One-time setup after copying this project to a new computer.
# Points the browser safety guard hook in .claude\settings.json at THIS computer's copy of tools\browser_guard.ps1.
# Run from anywhere:  powershell -ExecutionPolicy Bypass -File tools\setup_local.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$settingsPath = Join-Path $root '.claude\settings.json'
$guard = Join-Path $root 'tools\browser_guard.ps1'
if (-not (Test-Path $guard)) { throw "browser_guard.ps1 not found at $guard" }
$s = Get-Content $settingsPath -Raw | ConvertFrom-Json
$hook = $s.hooks.PreToolUse[0].hooks[0]
$args2 = @($hook.args)
$i = [Array]::IndexOf($args2, '-File')
if ($i -lt 0) { throw 'Could not find -File in the hook arguments' }
$old = $args2[$i + 1]
$args2[$i + 1] = $guard
$hook.args = $args2
$s | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Output "Browser guard path updated:"
Write-Output "  old: $old"
Write-Output "  new: $guard"
