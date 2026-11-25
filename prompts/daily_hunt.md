# Daily Product Hunt — full workflow

Run the steps below in order. **CLAUDE.md is the governing rulebook**: if anything here conflicts with it, CLAUDE.md wins. Report the conflict and raise a `CHANGE_PROPOSAL`; never silently rewrite a rule (§28).

**Research only:**
- Never buy, add to a basket, place an order, list, draft on the live account, publish, revise or promote anything (§24, §25).
- Never log in or use paid tools without the user's approval (§23).
- Never bypass CAPTCHA or anti-bot controls (§27).
- Never invent data: unknown stays `UNKNOWN`, assumptions are `ESTIMATED`, relaxed rules are `EXCEPTION` (§26).

`D` below means today's UK date (YYYY-MM-DD).

---

## Step 0 - Operating loop (CLAUDE.md s29)
1. Read `prompts/operating_loop.md`.
2. `powershell -File tools\preflight.ps1`. Fix every FAIL (the fee, cost-factor and calendar files are written in steps 2, 5a2 and 5b; run preflight again after them). Do not research before it says READY.
3. Before each product: `tools\dedupe_check.ps1 -Words "..." -ItemId ...`.
4. When anything fails, or the user corrects something: operating_loop.md section 2.

## Step 1 — Load the permanent business rules
Read `CLAUDE.md` (section 0 first), `config.yaml` and the files in `prompts/suppliers/` for the active sources. Note the current values:
- product criteria (§3–§4)
- source rules (§5–§8)
- profit rules (§10): item cost from the source site; listed price from the eBay competitor; current eBay fee; sourcing buying fee 0% (Go Dropship 5%, user rule 2026-10-20); pricing tiers by **eBay listing price** (user rule 2026-10-08): under £8 → £1 profit, any margin, 3% ads; £8 or more → £1 profit and 30% margin (or 20% ROI, passed with a "margin under 30%" note), 5% ads
- allocation and targets (§16–§18)

`config.yaml` `history` values are operational defaults, not business rules.

## Step 2–3 — Seasonal Planning Engine
```
powershell -File tools\seasonal_dates.ps1 -OutputFile data\seasonal\D_calendar.csv
```
This gives today's UK date, and for every event/season: date or window, days until, preferred listing start (−60), minimum listing start (−30), phase (PREPARE_EARLY / START_NOW / LATE_EVENT_WINDOW / IN_SEASON / POST_EVENT), priority (`Not defined` unless set in the calendar), and allocation role (CURRENT_EVENT / NEXT_EVENT_PREPARATION / NOT_ALLOCATED).

The 60/30-day lead times are the user's business planning assumption, not an eBay rule.

## Step 4 — Daily allocation
Default: **50% evergreen / 30% current event / 20% next-event preparation** of 15 = **8 / 4 / 3** (7.5 / 4.5 / 3, rounded by `daily_report.ps1`).
- Search themes: evergreen categories, plus the current events' themes, plus the next event's themes (Christmas priority order, §13).
- Change the mix only when the calendar evidence justifies it (e.g. no event in a current phase). Record the reason, and pass it to the report (step 13).
- No priority scores are invented; priority never changes the mix.

## Browser research (applies to steps 5–7)
All website and tool research follows `prompts/stages/browser_research.md`:
- **Before browsing:** confirm with the user that a browser tool is connected and which sites are approved (`config.yaml` `browser`); pause for logins, CAPTCHAs and security checks.
- **How runs start (user, 2026-10-03):** no schedule. The user signs in to all sites on the server's Chrome, then writes "start the daily hunt" (from the terminal or the Claude app via Remote Control) and the run starts at once.
- **Before researching a site, check that it is signed in.** **Never research on a logged-out site** (user rule). Signs of being logged out: a "Sign in" / "Log in" header where the account name normally shows, a sign-in page, or prices/stock hidden behind a login.
- **A site is logged out (or shows a CAPTCHA / security check):** stop on that site immediately and send **one** push notification (PushNotification, under 200 characters), e.g. "Hunt paused on Go Dropship: logged out. Please sign in on the server's Chrome, then reply 'continue'." Carry on with the other signed-in sources meanwhile. When the user replies "continue", check the site is signed in, then resume it where it stopped. Never sign in yourself.
- If the user has not signed in by the time everything else is finished, wait and do not write the daily files until they reply. If they say to finish without it, mark the source `SOURCE_BLOCKED (logged out)` and report the shortfall.
- **No browser connected at all:** send one notification ("Chrome not connected on the server: run /chrome in Claude Code") and stop without writing daily files.
- Send one notification when the run finishes, with selected vs 15 and the review page link.
- **Research only:** read-only actions only.
- **Evidence:** log every value in `data/evidence/D_evidence_log.csv`.
- **No browser connected or site not approved:** the affected values are `UNKNOWN` and the site's status is reported as `NOT_CONNECTED` / `NOT_APPROVED`. Never claim browsing that did not happen.

## Step 5a — Start from eBay demand (user rule 2026-10-08)
Every hunt starts on eBay, not on the source sites' best-seller lists. Build today's **eBay-demand list** before opening any source site:
1. **Competitor stores first** (Step 6b): best sellers of the reference sellers of products that passed before.
2. **ZIK Analytics Product Research** (ebay.co.uk, United Kingdom, last 30 days) on the day's themes (evergreen + event themes from Step 4): keep products with a hand-calculated sell-through of 40%+ (items sold ÷ eBay UK active listings, Buy It Now / New / UK, × 100; user rule 2026-11-04), sold price £2–£35, steady or rising sales, not on the §4 avoid list.
3. **eBay sold search** (Sold, Buy It Now, New, UK) for the same themes, reading Sold History Button on promising listings.
Write the list to `data/sources/D_ebay_demand_list.csv` (product, eBay URL, sold price, 30-day sales, STR, seller, how found). The hunters then look for these products on Amazon UK, AliExpress UK and Go Dropship UK first. Each match still goes through the full source rules, eBay verification and profit. Only when the list is used up does a hunter fall back to browsing its own site.

**Throughput (user rule 2026-10-08): get through more products per run.**
- Before starting, check all sites are signed in (Amazon, AliExpress, Go Dropship, eBay, ZIK), so the run does not pause mid-way.
- Screen quickly: read the search cards first and drop products that clearly fail (avoid list, price, rating, no 500+ label on Amazon) without opening them.
- Use short targeted `find` reads, not full-page text.
- Aim to reach the stop rule on every source (5 passed or 35 evaluated).

## Step 5 — Rechecks due, then the sourcing hunters
**Daily hunt sources (user, 2026-11-25): AliExpress UK, Go Dropship UK, AW Dropship (5 passes each, 15 in total). Amazon UK is paused: skip every Amazon step in this file, including the sign-in check and basket steps, until the user says otherwise.** Pound Wholesale is **not** part of the daily hunt: it is for the stock model and is used only when the user asks (then read `prompts/suppliers/pound_wholesale.md` first).
1. List the products due for a recheck. Include them in today's research where they fit the day's themes:
   ```
   powershell -File tools\history.ps1 -Action Due -Date D
   ```
2. Run each hunter. Each one **checks the research history before evaluating a product** (`tools\history.ps1 -Action Check`): RESEARCH / RECHECK / SKIP (step 10 of the user's list, applied here to avoid wasted work).
   - Amazon UK: `prompts/hunters/amazon_uk_hunter.md` → `data/sources/amazon_uk/D_amazon_uk_stage.csv`
   - AliExpress UK: `prompts/hunters/aliexpress_uk_hunter.md` → `data/sources/aliexpress_uk/D_aliexpress_uk_stage.csv`
   - Go Dropship UK: `prompts/hunters/godropship_uk_hunter.md` → `data/sources/godropship_uk/D_godropship_uk_stage.csv`
   - (Morrisons UK was removed on 2026-10-03: dropshipping from Morrisons is not allowed.)

**Source preference (user rule 2026-10-12, CLAUDE.md §17a):** for a product found on eBay, check the preferred source first: branded -> Amazon; generic -> Go Dropship and AliExpress; delivery-sensitive -> Amazon and Go Dropship (UK based; AliExpress is China based and slower). Preference only; all gates apply.

Hunters record every evaluated product, rejected ones included. Forward more than 5 per source where possible, because later stages reject some. **Stop rule per source (user, 2026-10-05; CLAUDE.md §17):** keep researching a source until 5 of its products have **passed every gate** (source, eBay verification, profit) or 35 of its products have been evaluated, whichever comes first. Run the eBay check and profit for each forwarded product as you go, so you know the pass count. Never stop a source early for low yield, FBA prevalence or basket risk; only a site block, login or CAPTCHA (§27) ends it sooner, reported as a shortfall. **Research budget: 35 products evaluated per source per day** (user, 2026-10-04) (`config.yaml` `browser.research_budget_products_per_source`). Products screened out on the avoid list count towards the 35. Amazon follows the same stop rule as the other sources (user, 2026-10-05): 5 passed or 35 evaluated. If the Amazon basket fills, notify the user and pause (§5.2), then resume. Record any `SOURCE_BLOCKED` source for the report.

## Step 5a2 — Record today's AliExpress cost factors (user rule 2026-10-13, CLAUDE.md §6.6 and §10)
At the start of every AliExpress session write `data/fees/D_aliexpress_cost_factors.csv` (columns `kind,rate_or_amount,description,source,observed_at_uk`): `VAT_RATE` (UK VAT charged at checkout, currently 0.00: the listed UK price already includes VAT), `FX_PAYMENT_BUFFER` (0.04, UK card), `CNY_PER_GBP` (the rate the SKU List extension shows, information only) and `SHIPPING_RULE`. Read the VAT note on an item page ("Price includes VAT" / regulatory note) and the exchange rate from the SKU List; note anything that changed. `tools/profit_calc.ps1` uses this file for every AliExpress row (cost = listed item cost + shipping + checkout VAT (0) + 4% FX / payment buffer, then the 6% cost buffer). **FX check every day (user, 2026-10-13):** also read the live mid-market GBP/CNY rate (xe.com currency converter) and the rate the SKU List shows, and record `MID_MARKET_CNY_PER_GBP`, `ALI_CNY_PER_GBP` and the computed `ALI_RATE_SPREAD` = (mid-market - AliExpress) / mid-market; record `CARD_NON_STERLING_FEE` once the user's card fee is known (typical UK range 1-3%). `FX_PAYMENT_BUFFER` is the user's card premium (4% from 2026-10-13 for the UK card; the first PKR-card order measured 6.3%); ask the user for a fresh statement figure when it may have changed, and say in the summary if the observed AliExpress spread alone exceeds it. Use the config values only if the file cannot be written.

## Step 5b — Record today's eBay fees (current data, CLAUDE.md §10)
Open eBay's business-seller fee page (`https://www.ebay.co.uk/help/selling/fees-credits-invoices/business-selling-fees?id=4809`) and write today's table to `data/fees/D_ebay_business_fees.csv` (layout: `templates/ebay_fee_table_template.csv`):
- one `FVF` row per category: name, category ID, path aliases, first-tier rate, and whether the reduced per-order fee applies;
- `REGULATORY`, `PER_ORDER_LOW` (orders up to £10), `PER_ORDER_HIGH` (over £10) and `PER_ORDER_REDUCED` rows;
- the page's "last updated" date.

If the page shows different rules or rates than the previous table, say so in the run notes. Without today's table the Profit Engine marks every fee `UNKNOWN`.

## Step 6 — eBay verification
`prompts/stages/ebay_verification.md` is applied to every forwarded product (`proceed_to_ebay` = YES / YES_WITH_UNKNOWNS / YES_WITH_EXCEPTION).
- **Always complete eBay verification (user rule 2026-10-08).** Every forwarded product gets a finished eBay check before the report is written: no "eBay verification not run" rows. If a run must pause, finish the open eBay checks when it resumes.
- No exact eBay match: use the closest similar listing with 5+ sales in 30 days (`NEAREST_SIMILAR`) and note "no exact match found on eBay". Source size not stated: use the nearest possible match (`CLOSE_SIZE_UNKNOWN`) and note "size not found". Both can pass if every other rule passes.
- Output: `data/ebay/D_ebay_verification.csv`, including the competitor listing price (`reference_seller_price`) and the current eBay fee if observed.

## Step 6b — Competitor store research (user rule 2026-10-06, CLAUDE.md §9)
**Run this FIRST, before broad searching on any source** (user, 2026-10-06: it finds the 5 daily products faster and uses less search budget and tokens). Seed sellers, in order:
1. reference sellers of products that passed (or were accepted) in earlier runs (`data/daily/*_candidates.csv`, `data/ebay/*_ebay_verification.csv`);
2. reference sellers of good products found earlier in today's run.
Then the rest of the eBay-demand list (Step 5a: ZIK Product Research and eBay sold search). Only when that list gives no more matches does the agent fall back to the normal category/best-seller searching on the source sites (Step 5).
For each seed seller:
1. Take the seller's eBay shop name from the eBay listing (or ZIK's sellers table).
2. In ZIK Analytics, open Competitor Research for that seller (ebay.co.uk, United Kingdom, last 30 days) and list their best-selling products.
3. For each best seller that fits §3/§4 (price £2–£35, not on the avoid list), look for the same product on the approved sources: Amazon UK, AliExpress UK, Go Dropship UK.
4. Every match found becomes a normal candidate for that source: full source rules, eBay verification, profit, compliance and evidence. It counts towards that source's 35-product budget (`discovery = competitor_store:<seller>`; note it in `notes`).
5. No gate is relaxed for products found this way. Never contact the seller (§23).
Keep it token-light: read ZIK's table with short targeted `find` queries, not full-page text.

## Step 7 — Profit Engine
```
powershell -File tools\profit_calc.ps1 -Date D            (add -AdRate 0.xx only for a higher ad rate)
```
`prompts/stages/profit_engine.md` covers rows with `proceed_to_profit` = YES.
- Output: `data/profit/D_profit.csv`.
- Results using an unobserved fee are **ESTIMATED**. Missing inputs give **UNKNOWN**; best-case bounds can only prove a FAIL.
- If the user's calculator tool is available, cross-check (profit_engine.md §9).

## Step 8 — Product criteria and compliance
These are already applied inside the stages:
- **Product criteria:** §3/§4 at the hunter, eBay and profit stages.
- **Compliance (§22):** retailer-sourced items stay `COMPLIANCE_REVIEW`; Go Dropship is `PASS` only with documented supplier evidence; VeRO brands, character IP, counterfeits and avoid-list failures are rejected (branded products whose brand is not in VeRO are allowed); restricted items are recorded as risks.

Nothing is cleared for action without the user (§23).

## Step 9 — Seasonal classification
`prompts/stages/seasonal_classification.md` classifies every verified candidate (evergreen / seasonal / hybrid), sets the target event, timing checks and allocation bucket, and carries the overall status.
- Output: `data/seasonal/D_seasonal_classification.csv`.
- Seasonal fit never turns a FAIL or UNKNOWN into a PASS.

## Step 9b — Evidence check
```
powershell -File tools\evidence_check.ps1 -Date D
```
Every research value in the stage files must be backed by the evidence log. Fix every `UNEVIDENCED` value (evidence it, or set it to `UNKNOWN`) and every `MISMATCH` before continuing. If any stage value was changed to UNKNOWN, re-run the Profit Engine and seasonal classification for that product. Add each site's access status to the report's `-RunNotes`.

## Step 10 — Research history
```
powershell -File tools\history.ps1 -Action Ingest -Date D
```
This appends every status change and every rejection (with reason, evidence, may-change flag and recheck date) to `data/history/`. Nothing is deleted.

## Steps 11–13 — Final decision, accepted/rejected files, daily report
```
powershell -File tools\daily_report.ps1 -Date D [-RunNotes "SOURCE_BLOCKED: ...; CHANGE_PROPOSAL: ..."]
                                                 [-Evergreen 0.x -CurrentEvent 0.x -NextEvent 0.x -AllocationReason "..."]
```

**Final decision:**
- **Accepted:** a product's overall status after seasonal classification is `PASS` or `EXCEPTION`.
- **Not accepted:** `UNKNOWN` (incomplete data) and `FAIL`.
- **Duplicates across sources** (same product key) → keep the strongest option, i.e. the higher calculated profit, with VERIFIED before ESTIMATED on a tie. The other is logged as `DUPLICATE`, with both sets of economics (§18).

**Daily selection (quotas):**
- **Limits:** at most **5 per source**; the total target is **15** (3 sources × 5). These are **targets, not quotas to fill**.
- **Selection order:**
  1. Products are taken in research order, VERIFIED before ESTIMATED.
  2. First pass: fill each allocation bucket up to its target (8 / 4 / 3).
  3. Second pass: if a source still has room and other buckets have no qualified products, more qualified products from a bucket already at target may be selected. This is reported as a difference from the target mix.
- **No quality score is invented.** CLAUDE.md §18 gives score weights but no sub-score method; propose one via CHANGE_PROPOSAL if scoring is wanted.
- **Qualified products not selected** are kept and flagged, never discarded:
  - `SURPLUS_OVER_SOURCE_TARGET`: the source already has 5.
  - `SURPLUS_NOT_ALLOCATED`: the target event is not current or next.
- **Weak products are never added** to reach 5 or 15.

**Files written** (existing daily files are never overwritten; a re-run writes `D_run2_*` / `D_ebay_product_hunt_run2.xlsx`, §19):

| File | Content |
|---|---|
| **`data/daily/D_ebay_product_hunt.xlsx`** | **Human review workbook**, generated automatically. Sheets: **Daily 20** (selected products), **Rejected** (one row per product, plain-English reasons), **Rejection Details** (one row per failed rule: what was seen vs the limit, reason, could it change, next status and recheck date, source / eBay / profit details and every stored link), **All Evaluated** (audit trail of every product examined), **Summary**, **Seasonal Plan**. Clickable links (Open Source / Open eBay / Open Seller / Open Keepa / Open ZIK / Open eBay search / Open Evidence) only for URLs actually stored; otherwise UNKNOWN. ESTIMATED financial cells are highlighted (light yellow, italic) and the Financial basis column says VERIFIED / ESTIMATED / UNKNOWN. Presentation only: it does not change any decision. |
| `data/daily/D_candidates.csv` | accepted products (`daily_selection` = SELECTED…), plus kept surplus. All CLAUDE.md §18 required fields and lifecycle fields, competitor seller/link/price, fees, ad rate, profit, margin, ROI and the margin rule (30% margin / 20% ROI from GBP 8), `calculation_status`, `acceptance_status` (PASS / PASS (ESTIMATED) / EXCEPTION), compliance, history status |
| `data/daily/D_rejections.csv` | one row per failed criterion (`REJECTED`), plus `DUPLICATE` and `NOT_ACCEPTED_UNKNOWN` rows: failed gate, observed vs threshold, evidence, may-change flag, change triggers, resulting status, recheck date, seasonal fields |
| `data/daily/D_seasonal_plan.md` | the seasonal planning summary: calendar table, phases, priority, roles, allocation used and reason |
| `data/daily/D_summary.md` | the daily report (below) |

**Daily report contents:**
- research timestamp
- run notes (blocked sources, conflicts, CHANGE_PROPOSALs)
- seasonal plan and mix (default or adjusted, with the reason)
- **target vs actual** per source (evaluated / forwarded / qualified / selected / shortfall) and per allocation bucket
- **shortfalls**, with each source's main rejection reasons, incomplete counts and blocked sources ("Not padded")
- accepted products, unscored, with item cost, eBay price, profit, margin, ROI, margin rule, calculation basis and status
- qualified surplus
- main rejection reasons, duplicates and incomplete items
- compliance-review items
- ESTIMATED results and EXCEPTIONS
- lifecycle/status changes, and user-status products needing attention

## Step 14 — Update the pinned review page
```
powershell -File tools\build_review_page.ps1
```
Then publish `data/review_page/ebay_daily_20.html` with the Artifact tool **to the existing URL in `config.yaml` → `review_page.url`** (pass it as `url`; read the artifact first if this session has not published it). This keeps the same pinned page in the user's claude.ai sidebar. Never create a new page for a new day; the page's date list shows earlier hunts. Every product row (Rejected, All evaluated and Daily) has a **Full details and links** section: each failed rule with what was seen vs the limit, the reason, whether it can change, next status and recheck date; the source, eBay and profit details; lifecycle notes; and every stored link. The builder joins these read-only from that day's files. The page is a view only: it shows the decisions already made and changes none.

## Starting a run (user decision 2026-10-03)
- **No automatic schedule.** The daily schedule was removed at the user's request. A hunt starts only when the user writes "run the daily hunt" (or similar), after signing in to all sites on the server's Chrome.
- Do not create a schedule (CronCreate) unless the user asks for one again.

## Links, codes and variants for every product (user rule 2026-11-25, CLAUDE.md §9 and §18)
Record these **while the pages are open**, for every product forwarded to eBay verification (not only at the end):
- the eBay listing link of the reference competitor (`https://www.ebay.co.uk/itm/<number>`) and the sourcing product page link (never a homepage or search page);
- the supplier's **item code** (AliExpress item number in the URL; Go Dropship SKU such as HOM-55114; AW product code such as XBB-02) and the **variant code** (AliExpress SKU id / the SKU List's option; Go Dropship child SKU). `none` = no variations, `UNKNOWN` = not shown. Never invent a code.
- **Variations:** choose up to 3 variants that sell well on eBay (**maximum 3**), best seller first. Evidence per variant: Sold History Button or the eBay listing. No per-variant sales shown = `UNKNOWN`, and say how the variant was chosen. Read price and stock of each chosen variant on the source and its own price on eBay. Run **each** through the Profit Engine: variant 1 uses the product id, the others `<id>-V2`, `<id>-V3` (one `verif_batch.ps1` row each). A variant that fails any gate is not selected.
- In `records_data.ps1` a SELECTED product needs: `srcUrl`, `ebayItemUrl`, `itemCode`, `variantCode`, `hasVariations=$true/$false`, and for variations `variants=@(@{ name; variantCode; cost; stock; ebayPrice; sold30; soldEvidence; ebayVariant; ... })`. The workbook script refuses the product without them. An AW Dropship Christmas gift with no eBay reference uses `ebayItemUrl='UNKNOWN'` plus its `exception` text.

## Step 15 - Close the run (CLAUDE.md s29)
Hand-researched day: `build_manual_workbook.ps1 -Date D -ReviewJson`, `manual_daily_files.ps1 -Date D`, `history.ps1 -Action IngestReview -Date D`, `build_review_page.ps1`. Then, for every day:
```
powershell -File tools\run_close.ps1 -Date D
```
Fix every FAIL or report it. Then do operating_loop.md section 5.

## After the run
Give the user a short summary: selected count vs 15, shortfalls by source, compliance-review items, and anything needing their decision (exceptions, CHANGE_PROPOSALs, user-status products with a different recommendation). Never act on any product without the user's approval.

## Saved sellers (user instruction 2026-10-14)
When a product passes every gate, append its eBay reference seller to `data/competitors/passing_sellers.csv` (date_found, source, passing_product, reference_seller, seller_link, seller_price, estimated_profit, competitor_analysis_done = NO). Step 6b competitor-store research seeds from this file; set competitor_analysis_done to YES once a seller has been analysed in ZIK Competitor Research.

