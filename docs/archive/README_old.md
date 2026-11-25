# UK eBay Product Hunter — Claude Code

This project turns the supplied eBay product-hunting rules into a Claude Code research agent.

## What it does

Daily workflow (full steps in `prompts/daily_hunt.md`):

Rules (CLAUDE.md) + Seasonal Planning Engine (`tools/seasonal_dates.ps1`)
→ daily allocation (default 50/30/20)
→ rechecks due + history check (`tools/history.ps1`)
→ three sourcing hunters (`prompts/hunters/`)
→ eBay verification (`prompts/stages/ebay_verification.md`)
→ Profit Engine (`tools/profit_calc.ps1`)
→ seasonal classification (`prompts/stages/seasonal_classification.md`)
→ research history ingest (`tools/history.ps1 -Action Ingest`)
→ final decision, de-duplication, daily selection, report (`tools/daily_report.ps1`)

Candidates are not scored: CLAUDE.md defines score weights but no sub-score method.

Daily target:
- Amazon UK: 5
- AliExpress UK: 5
- Go Dropship UK: 5

Total target: 15 accepted candidates/day. (Morrisons UK was removed on 2026-10-03: dropshipping from Morrisons is not allowed.)

## Important

The project is a research agent, not an auto-lister or auto-purchaser.

eBay's current dropshipping policy distinguishes wholesale-supplier dropshipping from buying from another retailer/marketplace and having it ship directly to the buyer. Treat retailer-sourced products as compliance-review items unless your sourcing arrangement is demonstrably permitted.

## Setup

1. Install Claude Code.
2. Install Node.js 20+.
3. Open this folder in PowerShell.
4. Run `claude`.
5. Run `/init` only if you want Claude to inspect/refine the project; the supplied CLAUDE.md already contains the operating rules.
6. Add browser access through Playwright MCP:
   `claude mcp add playwright npx @playwright/mcp@latest`
7. Start a fresh Claude Code session.
8. Test with:
   `@prompts/daily_hunt.md`
   and ask Claude to execute the daily hunt.

## Browser research (Stage 11)

The research protocol is in `prompts/stages/browser_research.md`. **No browser tool is connected yet**, so nothing is browsed and every browser-sourced value stays UNKNOWN. Setting it up requires decisions by the user: see that file's §8 "Setup proposals" and the `browser` block in `config.yaml`. Evidence for every researched value goes into `data/evidence/YYYY-MM-DD_evidence_log.csv`, and `tools/evidence_check.ps1` flags any value without evidence.

## Authentication

Log into the relevant websites in the browser when prompted. Do not put passwords, cookies, API keys or session files in this repository.

## Outputs

Daily results go into `data/daily/`:
- **`YYYY-MM-DD_ebay_product_hunt.xlsx`: the workbook to review.** Sheets: Daily 20, Rejected, Rejection Details (every failed rule with full details and links), All Evaluated, Summary, Seasonal Plan. Click "Open Source" / "Open eBay" / "Open Seller" etc. to go straight to the pages. Yellow italic money/percent cells are ESTIMATED. A second run on the same day creates `..._run2.xlsx`.
- `YYYY-MM-DD_candidates.csv`: accepted products (+ qualified surplus, flagged)
- `YYYY-MM-DD_rejections.csv`: rejections, duplicates, incomplete items
- `YYYY-MM-DD_seasonal_plan.md`: seasonal planning summary
- `YYYY-MM-DD_summary.md`: daily report

The CSV/Markdown files and the stage/history files are the system's internal records; the workbook is the human review output.
Stage files: `data/sources/`, `data/ebay/`, `data/profit/`, `data/seasonal/`. Research history: `data/history/`. Nothing is deleted or overwritten.

The initial template deliberately avoids fabricating eBay fee percentages because those depend on the account/category/transaction setup. Use the eBay fee calculator or observed Product Research data when available.
