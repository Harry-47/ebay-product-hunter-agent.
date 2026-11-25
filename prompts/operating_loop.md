# Operating loop: use the tools, learn from failures, fix them for good

Governed by CLAUDE.md s29. CLAUDE.md wins over this file.

Three layers:
- **Instructions** (CLAUDE.md, `prompts/`): what to do and the rules.
- **Agent**: reads the instructions, chooses the tool, checks the result, asks the user when a decision is theirs.
- **Scripts** (`tools/`): do the exact work (arithmetic, files, checks). The agent does not do by hand what a script does.

## 1. Before doing anything: look for a tool
| Need | Tool |
|---|---|
| Start a run | `preflight.ps1` |
| Has this product been researched? | `dedupe_check.ps1 -Words "..." -ItemId ...`, then `history.ps1 -Action Check` |
| Price a product | `verif_batch.ps1` (runs `profit_calc.ps1`). Never by hand when the product could be selected |
| Event dates | `seasonal_dates.ps1` |
| Write the day's files | `daily_report.ps1` (stage files), or for hand research `build_manual_workbook.ps1 -ReviewJson`, then `manual_daily_files.ps1` |
| Product history | `history.ps1 -Action Ingest` (stage files) / `IngestReview` (hand research) |
| Review page | `build_review_page.ps1`, then publish to the stored URL |
| End a run | `run_close.ps1` |
| Chrome frozen | `chrome_restart.ps1` |
| Known failures | `lessons.ps1 -Action Search` |
| Which API keys are set (never open or print `.env`) | `env_check.ps1` |
| Check the scripts | `selftest.ps1`; `mutation_check.ps1` after changing a test |

If no tool fits and the job will come back, write one (small, one job, refuses bad input, test in `tests/`), and add it to this table.

## 2. When something fails
1. **Stop and read the whole error.** Do not repeat the same action unchanged.
2. **Search:** `lessons.ps1 -Action Search -Text "..."`. If it is known, use that answer.
3. **Log it:** `lessons.ps1 -Action Log -Signature "short stable name" -Area ... -Symptom "..."`. A wrong result counts as a failure, even without an error message. So does a correction from the user.
4. **Read the script** (or the instruction) that failed and find the cause. Reproduce it in a test that fails.
5. **Fix the cause**, not the symptom. Change the smallest thing. Make the script refuse bad input instead of guessing.
6. **Prove it:** `selftest.ps1` passes, including the new test. For a script bug add a line to `tests/mutations.csv`.
7. **Update the workflow:** the instruction that led to it, the table above or section 4, and memory if it is about the user.
8. **Close it:** `lessons.ps1 -Action Fix` (needs a test) or `Workaround` (no test possible, e.g. a website). What only the user can solve: `NeedsUser`.
9. **Check what the fault already damaged** (past results, files already given to the user) and tell the user plainly. Past files are corrected by a new dated note, never edited (s19).

Limits: two different attempts on the same failure, then use the workaround, or record it and carry on with other work. Never loop on one failure. A `REGRESSION` means the test was too weak: strengthen the test first.

## 3. What the loop may and may not change
**May change:** `tools/` (except the guard), `tests/`, `templates/`, `prompts/`, `docs/`, operational settings that are not rules, memory.

**Must not change:**
- business rules, thresholds, gates or targets (CHANGE_PROPOSAL, s28), in CLAUDE.md, config or inside a script;
- `tools/browser_guard.ps1`, `.claude/settings*.json`, permissions, the approved site list. If the guard blocks something, take another allowed route or ask. Never reword an action so the guard misreads it;
- past research, logs or daily files (append only);
- a test so that it passes. A golden result changes only when the user changed a rule; say so in the change log.

Paid actions, logins, orders and CAPTCHAs stay with the user whatever the failure.

## 4. Known failures and what to do
| Failure | Do this |
|---|---|
| Chrome frozen, screenshot times out | One light text read; then `chrome_restart.ps1` once. Keep one tab. Prefer `find` / page text over screenshots |
| "Tab is not in the group" | `tabs_context_mcp`, use the new id. Do not batch a tab close with other actions |
| ZIK back to ebay.com / United States | Open by the dashboard, set ebay.co.uk, United Kingdom, Fixed Price, 30 days, clear the price range, and check them on a screenshot **before** reading numbers |
| ZIK shows the previous search | Check "Searched on" matches the keyword before reading the table |
| ZIK price on a variation listing | It may be another variation: read the variant on the eBay listing |
| eBay variation list unreadable | `find` the listbox options; if the prices stay hidden, record UNKNOWN |
| Guard refuses an action | Do not reword it to slip past. Skip it, use another allowed way to get the same public fact, or ask |
| Site signed out | Stop on that site, ask the user to sign in, continue elsewhere |
| AliExpress "Max 1 pcs/shopper", one-time, first-try price | Not a cost. Use the SKU price without it, else UNKNOWN |
| Strong-seller count from a keyword | Count only sellers of the **same product**; sets, kits and brand-fit versions do not count |
| `[0]` on a script result gives one letter | PowerShell unrolled a one-item list: wrap with `@( )` or return `, $list` |
| A script variable changes by itself | PowerShell names are not case-sensitive: eng and ENG are one variable. Use clearly different names |
| Command declined by the user | Do not run it again in another form. Say what was not done |

## 5. After every run
1. `run_close.ps1 -Date D`. Report `COMPLETE`, or list exactly what is missing.
2. Log every failure and user correction of the run that is not logged yet.
3. Ask: what took the most time? what was done by hand twice? which instruction was unclear? Fix the biggest one.
4. Every fifth run, or when the user asks: `lessons.ps1 -Action Stats` and `-Action Open`, remove outdated memory and instructions, run `mutation_check.ps1`.
5. Tell the user in two or three lines what was learned and changed. Rule ideas go in as a CHANGE_PROPOSAL.
