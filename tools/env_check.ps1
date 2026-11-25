<#
Says which optional API keys in .env are SET or EMPTY. Never prints a value.
Usage: .\tools\env_check.ps1
#>
param([string]$Root)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$envFile = Join-Path $Root '.env'; $example = Join-Path $Root '.env.example'
if (-not (Test-Path -LiteralPath $envFile)) { 'MISSING .env: copy .env.example to .env'; return }
$gi = Join-Path $Root '.gitignore'
if (-not ((Test-Path -LiteralPath $gi) -and ((Get-Content -LiteralPath $gi) -contains '.env'))) { throw '.env is not in .gitignore: add it before anything is uploaded' }
$have = @{}
foreach ($l in (Get-Content -LiteralPath $envFile)) { if ($l -match '^\s*([A-Za-z_]\w*)\s*=\s*(.*?)\s*$') { $have[$Matches[1]] = [bool]$Matches[2] } }
foreach ($l in (Get-Content -LiteralPath $example)) {
    if ($l -match '^\s*([A-Za-z_]\w*)\s*=\s*(.*?)\s*$') {
        $state = 'EMPTY'; if ($have[$Matches[1]]) { $state = 'SET' }
        "{0,-24} {1}" -f $Matches[1], $state
        if ($Matches[2] -and $Matches[1] -match 'SECRET|KEY|CLIENT_ID|TOKEN') { throw '.env.example contains a real key: remove it, it is the shareable copy' }
    }
}
foreach ($k in $have.Keys) { if ($k -match 'PASS') { "WARN $k looks like a password: remove it, the agent does not use passwords" } }