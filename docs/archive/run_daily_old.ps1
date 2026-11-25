$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
claude -p (Get-Content ".\prompts\daily_hunt.md" -Raw)
