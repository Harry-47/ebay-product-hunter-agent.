# Running the agent on the VPS without VS Code

## 1. Install once (user does this, in PowerShell)
Claude Code for the terminal:
```powershell
irm https://claude.ai/install.ps1 | iex
```
Git (only needed for GitHub): download the 64-bit Setup from https://git-scm.com/download/win and click Next on every screen. This server has no winget and had only 1.0 GB of free disk on 2026-11-25: free some space first.

Close and reopen PowerShell, then check `claude --version` and `git --version`.

First start only: run `claude` in the project folder, sign in with the same claude.ai account (`/login`), and accept the workspace trust question. The browser safety guard works only after the folder is trusted.

## 2. Every day
```powershell
Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe"
cd "C:\Users\Administrator\Documents\eby product hunter dropship\ebay_product_hunter_agent"; claude --chrome
/rc eBay Product Hunter
```
The third line is typed inside Claude. `scripts\start_agent.ps1` does all three.
Then, in the Claude app (Code section), open the session "eBay Product Hunter" and type: **start the daily hunt**

## 3. Keep it alive
- Close Remote Desktop with the X (disconnect). Do **not** sign out or restart: that ends Claude and Chrome.
- Keep the PowerShell window open. If it closed: `cd` to the folder, `claude --chrome --continue`, then `/rc`.
- Close VS Code. It uses about 0.7 GB of the server's 2 GB.
- Sign in to ZIK, eBay, AliExpress, Go Dropship and AW Dropship in Chrome yourself. The agent never signs in.
- Permission prompts appear in the Claude app. Do not turn them off with bypass mode.
- Keep the project in this folder: Claude's memory and the guard path belong to it.

## 4. Another computer
Clone the repository, run `powershell -ExecutionPolicy Bypass -File tools\setup_local.ps1` (guard path), copy `.env.example` to `.env`, and tell Claude: "Import the files in claude_memory into your memory".
