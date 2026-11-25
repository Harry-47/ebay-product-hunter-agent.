# Go Dropship UK Hunter — source research module

**Stage:** source discovery and Go Dropship-side checks only.
**Workflow position:** Go Dropship UK → hot-selling / recent-sales evidence → **[hand-off]** → eBay verification → competition verification → profit calculation.
**Output:** a shortlist of Go Dropship products, each with evidence, passed to the later eBay verification stage (CLAUDE.md §9).
**Governing rules:** CLAUDE.md. This module applies §3, §4, §7, §13–§16, §19–§20, §22–§27. It does not change or relax them. If this file and CLAUDE.md disagree, CLAUDE.md wins.

This module does NOT:
- verify eBay demand or competition
- calculate eBay fees, profit, margin or ROI
- score candidates
- make a final accept decision
- buy, place supplier orders, list or publish anything

Go Dropship popularity is never proof that a product will sell on eBay. Every forwarded product still has to pass eBay verification, competition, profit and compliance.

**Platform features are not assumed.** Use features such as "hot sellers", best-seller lists, sales counts, stock levels or trade pricing only if they are actually visible. If a feature is not available, the related fields are `UNKNOWN`.

---

## 0. Before starting
1. Run the Seasonal Planning Engine (CLAUDE.md §13) for today's UK date, or load its output if it has already run today. Note:
   - each event/season, with its date or window, days until, preferred and minimum listing starts, phase and priority (`Not defined` unless set in `data/event_calendar.yaml`)
   - which events are **Current Event** and which are **Next Event Preparation**
   - the daily allocation (default 50/30/20)
2. Load previous Go Dropship stage files from `data/sources/godropship_uk/`, other source stage files in `data/sources/`, and previous daily files in `data/daily/`. Use them for deduplication (step 5). Never modify past files.
3. Record the research start time in UK time.

## 1. Discovery
**eBay first (user rule 2026-10-08):** start by searching Go Dropship for the products on today's eBay-demand list (`prompts/daily_hunt.md` Step 5a): products already selling well on eBay UK. A match must still meet the Go Dropship demand rule below. Browse the lists below only when that list is used up.

Look for **hot-selling / highest-sales items over the last 30 days** (CLAUDE.md §7), using whatever the platform shows:
- hot-seller or best-seller sections
- sorting by sales or popularity
- trending or new-in sections
- category browse and keyword search

Choose the search themes from:
- **evergreen** categories: generic, giftable, problem-solving, home, organisation and storage products
- the **Current Event** themes from the seasonal engine
- the **Next Event Preparation** themes from the seasonal engine (for Christmas, use the CLAUDE.md §13 priority order)

Skip categories that CLAUDE.md §4 excludes (food and drink, sized clothing/shoes (free-size clothing with no size options is allowed, 2026-10-13), electronics only if battery-free or sourced from a UK-based source (allowed on Amazon UK and Go Dropship UK, 2026-10-13), medicines/supplements, adult, tobacco, etc.).

## 2. Access rules
- Browse according to `prompts/stages/browser_research.md` (Go Dropship playbook): read-only, approved sites only, and log every value in the evidence log. A value with no evidence row is `UNKNOWN`.
- Go Dropship may show prices, stock or sales data only to logged-in supplier-account holders. Do not log in with the user's credentials, create an account, or use a paid plan unless the user has approved it (CLAUDE.md §23). Without access, the affected fields are `UNKNOWN`.
- Never bypass, solve or evade a CAPTCHA, anti-bot check, rate limit, login wall or paywall (§27). If blocked, stop on that site, record `SOURCE_BLOCKED` with the reason, and report the shortfall.
- **Never add to basket, place an order, or contact the supplier** (§23, §24).

## 3. Per-product checks
Each criterion gets a **status** (`PASS`, `FAIL` or `UNKNOWN`, or a recorded value where noted). Each also gets an **evidence** entry: the URL, plus what was seen (e.g. "Hot Sellers page, position 4, viewed 2026-10-02 10:15"). All observations are taken at `observed_at_uk`.

**Rules for UNKNOWN:**
- If a criterion cannot be verified, its status is `UNKNOWN`.
- `UNKNOWN` never counts as `PASS`.
- Never estimate a value from a different product or a generic page.

CLAUDE.md §7.2 (user rules 2026-10-04) sets the Go Dropship thresholds:
- UK warehouse;
- stock of 20+ units;
- delivery at most 5–7 days (user rule 2026-10-06; was next day to 2–3 working days).

Where no threshold exists, values are recorded and concerns go in `risks`.

| Check | Rule source | How to judge it |
|---|---|---|
| Hot-selling / recent sales | §7.1: best-selling (Weekly Top / hot-seller list / category "Bestselling" sort) **or** 1,000+ sold in the last 30 days (user rule 2026-10-03; a 500+ change on 2026-10-05 was reverted) | Record the exact evidence: hot-seller tag, list position, sales figure, and the **period shown**. PASS if the platform explicitly marks the product as hot-selling or top-selling (e.g. on Weekly Top or a Bestselling sort), or shows 1,000+ sales within 30 days or less. FAIL if only a sales figure is shown and it is under 1,000 in 30 days. UNKNOWN if there is no sales evidence, or the period is not stated. Never derive a sales number from a tag or position. |
| Warehouse | §7.2 (user rule 2026-10-04): UK warehouse | Record the warehouse or ship-from location shown in `warehouse_location`. `warehouse_location_status`: PASS if UK, FAIL if outside the UK, UNKNOWN if not shown. |
| Quality rules (user rules 2026-10-12) | CLAUDE.md §7a | UK stock 20+ (50+ seasonal; user rule 2026-10-24; decided on the day's reading); tracked delivery preferred, Large Letter only under about GBP 10 eBay price; read 'Price updated on' (stale over about 6 months); 5% cost buffer (`cost_buffer_gate`); count eBay sellers using the exact Go Dropship title; avoid sizing items over 3 variations, electrical/safety-regulated, health-claim and under-3 toys without safety mark; bestseller page 1 on 2 separate days; prefer under 1 kg; ROI 30% preferred, under 25% THIN. |
| Stock / availability | §7.2 (user rule 2026-10-04): 20+ units | Record the stock level or availability text exactly (e.g. "In stock", "23 available", "Out of stock"). `stock_status`:<br>• `IN_STOCK`: a number of 20 or more is shown.<br>• `FAIL`: a number under 20 is shown.<br>• `OUT_OF_STOCK`: the page says it is out of stock.<br>• `UNKNOWN`: "In stock" with no number.<br>`OUT_OF_STOCK` means the product cannot be sourced at the time it was observed (see step 4). |
| Delivery | §7.2 (user rule 2026-10-06): max 5–7 days (was next day to 2–3 working days) | Record the dispatch time, delivery service, delivery days and delivery charge exactly as shown. `delivery_status`: PASS if the quoted maximum is 7 days or fewer (a Large Letter 3–7 day service passes), FAIL if over 7 days, UNKNOWN if not shown. If an event product's delivery looks too tight for its target event, note it in `risks`. **Remote-area surcharge (user note 2026-10-13):** Go Dropship's shipping terms say delivery to Offshore & Remote Regions is domestic but surcharges may apply. Add this to `risks` / `rejection_risk` for every Go Dropship product (UK offshore or remote buyers, e.g. Highlands and Islands, may cost extra); it is a risk note, not a gate, and the eBay listing price does not change. Heavier items (2-4 kg, free delivery) carry more of this risk. |
| Profit margin (preference) | §7.2 (user rule 2026-10-04): prefer 30%+ | Not judged here. The Profit Engine records the margin and flags Go Dropship items under 30% as a **preference only**. It never fails a product on margin. |
| Baseline price | §10 baseline rule (user rule 2026-10-04) | `source_price` = the **baseline trade price** for the exact SKU, i.e. the undiscounted price. When the page shows a "Discount: x% OFF" price with a struck-through original (e.g. £3.99, was £4.34), use the **original** (£4.34) and record the discount in `risks`. Never use ladder or multi-buy prices ("2+ £3.15") for a single-item order. |
| Source price | §10 inputs | Record the trade/source price, whether it includes VAT (only if stated), and any per-order dropship or handling fee (this is `sourcing_buying_fee` in config.yaml). Also record the RRP if shown. Write `UNKNOWN` for anything not shown. |
| Price ceiling | §3: eBay listing price £5–£35 | Pre-screen only, not a profit calculation. If the source price plus the shown delivery charge and per-order fee is £35 or more, a profitable eBay price would be above £35, so FAIL. Otherwise PASS, but only as a pre-screen. UNKNOWN if the price is not visible. |
| Weight | §3: under 2 kg, or up to 4 kg when the Go Dropship delivery for the item is free (user rule 2026-10-13) | Use the stated item or package weight. PASS if under 2 kg; PASS if 2 kg to 4 kg and the delivery shown on the product page is free (record the delivery line); FAIL if over 4 kg, or 2 kg or more with delivery that is not free; UNKNOWN if weight or delivery cost is not stated. Never infer weight from photos. |
| Variations | §3: none preferred, maximum 2–3 | Count the variations that would actually be listed. PASS if 0. PASS with a note if 1–3. FAIL if more than 3. |
| Brand / IP risk | §4: no VeRO brands, counterfeit or character IP (user rule 2026-10-03: branded allowed if not VeRO) | FAIL if the brand is a VeRO participant, or it is a licensed or copyrighted character. A genuine branded product whose brand is not in VeRO can PASS. UNKNOWN if VeRO status could not be checked. Generic or unbranded products PASS. Write the specific concern in `brand_ip_notes`. |
| Avoid list (other) | §4 | FAIL if the product is in any excluded category or is fragile, bulky, prohibited, etc. Otherwise PASS, or UNKNOWN if unclear. |
| Other compliance risks | §4, §22 | Record any risk observed, such as product-safety or marking concerns (e.g. toys, child products, food-contact items, batteries), missing safety information, or supplier terms restricting eBay sales, image use or minimum advertised price. These are recorded for review in `other_compliance_risks`, not decided here. If a product falls under "legally prohibited items" (§4), use Avoid list = FAIL. |
| Compliance status | §7, §22: `COMPLIANCE_REVIEW` or `PASS`, depending on supplier-relationship evidence | Default `COMPLIANCE_REVIEW`. Set `PASS` only if documented evidence of a compliant wholesale-supplier dropship arrangement is on record, e.g. supplied by the user (an active supplier account plus terms permitting dropshipping to eBay buyers). Record where that evidence is in `supplier_relationship_evidence`. Never assume or invent a supplier relationship. Acting on any product still requires the user's approval (§23). |

Also record, where shown: the supplier SKU, EAN/GTIN, brand, product dimensions, and the supplier's image-usage terms.

## 4. Decision: proceed to eBay verification?
Apply these in order:
1. **Brand / IP FAIL**, **avoid list FAIL**, or **price ceiling FAIL** → `NO` (reject). Never an exception.
2. **`OUT_OF_STOCK`** → `NO`, with the reason "not available to source at the time observed". Record it so it can be rechecked on a later run.
3. **Any other FAIL** (weight, variations, warehouse, stock under 20, delivery) → `NO` (reject), unless it is a *minor* shortfall and the product looks commercially interesting. In that case set `YES_WITH_EXCEPTION`, write an `EXCEPTION` entry naming the rule not met, the observed value vs the threshold, and why it is still interesting. Exceptions are never silent and never applied to brand/IP, avoid-list or compliance rules. Final acceptance of an exception follows CLAUDE.md §3 (relaxation only when economics are clearly strong) and §23 (user approval before action).
4. **No FAIL, but one or more UNKNOWN** → `YES_WITH_UNKNOWNS`. List every unknown field in `unknown_fields`, and lower `confidence`.
5. **Every check PASS** → `YES`.

`YES` means only "passes the Go Dropship-side checks". It never means the product qualifies.

Rejected products (`NO`) are recorded with `failed_criteria` and `rejection_reason`, and also go into the daily rejections log (CLAUDE.md §20). The `failed_gate`, `observed_value` and `threshold` come from the failed check.

## 5. Deduplication
Do not record the same product twice in one day. Match by supplier SKU, EAN/GTIN, or close title plus matching image/specification.

If the product also appears in another source's stage file today (e.g. Amazon UK, AliExpress UK), note the match in `cross_source_match`. Cross-source deduplication is decided by a later stage (CLAUDE.md §18).

**Before evaluating a product, check the research history** (`prompts/stages/research_history.md` §6): `tools\history.ps1 -Action Check -SourceId GDS:<supplier SKU>` (or `-Gtin` / `-Title`).
- RESEARCH → evaluate normally.
- RECHECK → evaluate again with fresh evidence.
- SKIP → do not evaluate, unless a listed recheck trigger is directly observed (e.g. the price is lower than `last_source_price`, or it is back in stock).
- RETIRE or a user status → do not evaluate.

When re-evaluating, link the earlier record in `notes`. Never copy old values.

## 6. Provisional seasonal classification
Using the seasonal engine output, record a **provisional** classification. The eBay stage confirms it using sales-trend evidence.
- `product_type`: evergreen / seasonal / hybrid
- `seasonality`: CLAUDE.md §13 labels (e.g. `evergreen`, `christmas`, `winter`, `christmas_plus_evergreen`, `unclear`)
- `allocation_bucket`: `evergreen` / `current_event` / `next_event_preparation`
- `target_event`, `event_date`, `seasonal_phase`, `days_until_event`, `preferred_listing_start`, `minimum_listing_start`, copied from the engine. Use `NONE` for evergreen.
- `seasonal_confidence`: LOW / MEDIUM / HIGH, with a reason in `notes`

## 7. Output
Write one row per evaluated product, including rejected ones, to:

`data/sources/godropship_uk/YYYY-MM-DD_godropship_uk_stage.csv`

Use the column layout in `templates/godropship_uk_stage_template.csv`. Write `UNKNOWN` for unverified values and leave no field silently blank (use `N/A` where a field does not apply).

If the file for today already exists from an earlier run, append new rows; never overwrite or delete existing rows (CLAUDE.md §19).

At the end, report in the run log or summary:
- research start/end time (UK)
- whether supplier-account access was available
- number of products evaluated, and how many were YES / YES_WITH_UNKNOWNS / YES_WITH_EXCEPTION / NO
- forwarded products by allocation bucket
- the most common rejection reasons
- the most common UNKNOWN fields, and why
- any `SOURCE_BLOCKED` events
- every EXCEPTION raised
- how many products are `COMPLIANCE_REVIEW` vs `PASS`

## 8. Hand-off to the eBay stage
Pass forward only rows with `proceed_to_ebay` = `YES`, `YES_WITH_UNKNOWNS` or `YES_WITH_EXCEPTION`. Include `ebay_search_terms`: neutral, unbranded keywords describing the product, to use in the eBay sold-items search.

The eBay verification, competition, profit, scoring and compliance stages are separate modules. This module's output has no eBay metric, fee, profit, margin, ROI or score columns. Those are added only by later stages, from observed eBay data.

