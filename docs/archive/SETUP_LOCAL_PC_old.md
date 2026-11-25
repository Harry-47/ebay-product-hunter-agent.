# Moving the eBay Product Hunter to your own PC

You do not need to write any code. Do the steps in order. Where a step says "tell Claude", type that sentence into Claude Code.

## A. Install these on your PC (one time)

1. **Google Chrome**, then sign in to the sites you use for research: ZIK (zik2.amzsuccesstools.com), eBay UK, AliExpress, Go Dropship (and AW Dropship / Saleyee if you use them).
2. **Chrome extensions** you already use on the VPS: Claude in Chrome (claude.ai/chrome), ZIK, Sold History Button / purchase-history tool, AliPrice (price history + SKU List), Keepa and Seller Sprite (only if you use Amazon).
3. **Git for Windows**: https://git-scm.com/download/win , run the installer and click Next on every screen.
4. **Visual Studio Code**: https://code.visualstudio.com , then install the **Claude Code** extension inside it and sign in with the same claude.ai account.

## B. Download the project from GitHub

1. Open VS Code. Press `Ctrl+Shift+P`, type **Git: Clone**, press Enter.
2. Paste your repository address (it looks like `https://github.com/YOUR-NAME/ebay-product-hunter.git`).
3. Choose a folder, for example `Documents`. Sign in to GitHub in the window that appears.
4. Click **Open** when VS Code asks to open the cloned folder.

## C. First run in Claude Code

Open the Claude Code panel in VS Code and tell Claude, one at a time:

1. `Run tools\setup_local.ps1` (fixes the browser safety guard path for this PC).
2. `Import the files in claude_memory into your memory` (brings back all the rules and notes Claude learned on the VPS).
3. `Check the Chrome extension is connected`.
4. Then, as before: `Start the daily hunt`.

## D. Keeping GitHub up to date (optional)

At the end of a day, tell Claude: `Commit and push today's files to GitHub`.
