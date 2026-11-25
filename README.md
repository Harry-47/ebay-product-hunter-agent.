# UK eBay Product Hunter Agent

A Claude Code research agent that finds products for an eBay UK dropshipping shop, checks them against real eBay demand and profit, and reports the ones that pass. It is research only: it never buys, lists, messages or signs in.

- **Start:** see `docs/setup_vps.md`. Then type `start the daily hunt`.
- **Rules:** `CLAUDE.md` (section 0 first). Supplier rules: `prompts/suppliers/`. Rule history: `docs/rulebook_changelog.md`.
- **Workflow:** `prompts/daily_hunt.md`. Fixing and learning: `prompts/operating_loop.md`.
- **Scripts:** `tools/` (tests in `tests/`, run `tools\selftest.ps1`). Launcher: `scripts/start_agent.ps1`.
- **Results:** `data/daily/` (workbook, CSV files, summary). Research is never deleted.
- **Keys:** optional, in `.env` only (copy `.env.example`). Never commit `.env`. Check with `tools\env_check.ps1`.

Daily sources: AliExpress UK, Go Dropship UK, AW Dropship (5 each, 15 in total). Amazon is paused. Pound Wholesale is for the stock model, only on request.

Retailer-sourced products stay `COMPLIANCE_REVIEW`: eBay allows dropshipping from a wholesale supplier, not from another retailer or marketplace.