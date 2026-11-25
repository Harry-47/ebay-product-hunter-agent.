# AliExpress UK Hunter — source research module

**Stage:** source discovery and AliExpress-side checks only.
**Output:** a shortlist of AliExpress products, each with evidence, passed to the later eBay verification stage (CLAUDE.md §9).
**Governing rules:** CLAUDE.md. This module applies §3, §4, §6, §13–§16, §19–§20, §22–§27. It does not change or relax them. If this file and CLAUDE.md disagree, CLAUDE.md wins.

This module does NOT:
- verify eBay demand or competition
- calculate eBay fees, profit, margin or ROI
- score candidates
- make a final accept decision
- buy, add to basket, list or publish anything

High AliExpress sales never mean a product qualifies. Every forwarded product still has to pass eBay verification, competition, profit and compliance.

---

## 0. Before starting
1. Run the Seasonal Planning Engine (CLAUDE.md §13) for today's UK date, or load its output if it has already run today. Note:
   - each event/season, with its date or window, days until, preferred and minimum listing starts, phase and priority (`Not defined` unless set in `data/event_calendar.yaml`)
   - which events are **Current Event** and which are **Next Event Preparation**
   - the daily allocation (default 50/30/20)
2. Load previous AliExpress stage files from `data/sources/aliexpress_uk/`, other source stage files in `data/sources/`, and previous daily files in `data/daily/`. Use them for deduplication (step 5). Never modify past files.
3. Record the research start time in UK time.

## 1. Discovery
Find candidate products on AliExpress with the ship-to destination set to the **United Kingdom** and prices shown in **GBP**, using only publicly visible pages.

**eBay first (user rule 2026-10-08):** start by searching for the products on today's eBay-demand list (`prompts/daily_hunt.md` Step 5a): products already selling well on eBay UK. Browse AliExpress's own best sellers only when that list is used up.

**Filters (user rule 2026-10-04), applied where AliExpress offers them:**
- Ship to: UK
- Do NOT apply the Ship from filter (user rule 2026-10-10): search items from any ship-from country; record the ship-from country shown
- Choice
- 4.3+ rating (user rule 2026-10-08; was 4.5+). If the site filter only offers 4.5+, use 4+ or no rating filter and check 4.3 on the item page
- shipping method / delivery time: AliExpress Selection Standard or Cainiao, 10 days or less

Discovery routes:
- category browse
- keyword searches
- best-selling / most-orders sorting

Choose the search themes from:
- **evergreen** categories: generic, giftable, problem-solving, home, organisation and storage products
- the **Current Event** themes from the seasonal engine
- the **Next Event Preparation** themes from the seasonal engine (for Christmas, use the CLAUDE.md §13 priority order)

Skip categories that CLAUDE.md §4 excludes (food and drink, battery-containing electronics (battery-free items like cables are allowed; from AliExpress battery electronics stay excluded, 2026-10-13), sized clothing/shoes (free-size clothing with no size options is allowed, 2026-10-13), medicines/supplements, adult, tobacco, etc.).

**Timing:** delivery time matters most for event products. A product must be able to reach a UK buyer before the event (§4, §13), even with AliExpress's delivery time added on top of the eBay order. Record this in `risks` whenever it is tight.

## 2. Access rules
- Browse according to `prompts/stages/browser_research.md` (AliExpress playbook): read-only, approved sites only, and log every value in the evidence log. A value with no evidence row is `UNKNOWN`.
- Do not log in to AliExpress or any other site with the user's credentials, and do not use a paid tool, unless the user has approved it (CLAUDE.md §23).
- Never bypass, solve or evade a CAPTCHA, slider check, anti-bot check, rate limit or login wall (§27). If blocked, stop on that site, record `SOURCE_BLOCKED` with the reason, and report the shortfall.
- **Never add items to the basket, click Buy Now or start checkout**, including to see a final price or delivery date (§24). The final price comes from the item page (see Fees shown).
- Setting the ship-to country to United Kingdom and the currency to GBP is allowed. Record the ship-to context. Use a UK postcode only if the user has supplied one; never invent one.
- If prices are not shown in GBP, record the price and currency exactly as shown. Never convert using an invented exchange rate. Mark the GBP price `UNKNOWN` unless a conversion source is recorded.

## 3. Per-product checks
Evaluate the **specific SKU** that would be sourced (e.g. a particular colour or pack size), not the listing's headline "from" price.

Each criterion gets a **status**: `PASS`, `FAIL` or `UNKNOWN`. Each also gets an **evidence** entry: the URL, plus what was seen (e.g. "page text: '1,000+ sold'"). All observations are taken at `observed_at_uk`.

**Rules for UNKNOWN:**
- If a criterion cannot be verified, its status is `UNKNOWN`.
- `UNKNOWN` never counts as `PASS`.
- Never estimate a value from a different listing, store or generic page.

| Check | Rule (from CLAUDE.md) | How to judge it |
|---|---|---|
| Demand (required) | §6.1 (user rule 2026-10-04, revised): **Choice** product **and** 500+ sold | Two checks, and both must PASS:<br>• **Choice:** record `choice_badge` (YES/NO) and set `choice_badge_status` to PASS or FAIL.<br>• **Sales:** record the sold count exactly as shown (AliExpress shows all-time totals; `sales_period_shown` = "NOT SHOWN (all-time)"). `sales_status` is **PASS** if 500 or more (e.g. "1,000+ sold"), **FAIL** if under 500 (e.g. "493 sold"), and **UNKNOWN** if no count is shown.<br>A best-seller badge alone does not meet the rule. |
| Rating | §6: 4.3+ (user rule 2026-10-08; was 4.5+) | Record the rating and the number of reviews. PASS if 4.3 or more, FAIL if below 4.3, UNKNOWN if not shown. A small number of reviews goes in `risks`. |
| Delivery to UK | §6.4 (user rule 2026-10-04): maximum 10 days; any ship-from country allowed (no Ship from filter, user rule 2026-10-10) | Record the delivery estimate exactly as shown (date range or days), the shipping method (prefer AliExpress Selection Standard or Cainiao), `ship_from` and the shipping cost. Days = the **latest** date in the range minus the observation date. PASS if 10 or fewer, FAIL if more than 10, UNKNOWN if no estimate is shown for UK delivery. Check the Ship from: UK option first. Use a China-shipped option only if no suitable UK-shipped item is found; the 10-day maximum still applies. |
| Supplier feedback | §6.3 (user rule 2026-10-04): 90%+ (was 95%) | Record `store_positive_feedback` from the store info. `store_positive_feedback_status`: PASS if 90% or more, FAIL if below, UNKNOWN if not shown. |
| Inventory | §6b (user rule 2026-10-13, same as Go Dropship): exact variant stock 20+ (50+ seasonal), user rule 2026-10-24 (was 50+/100+) | Read the variant's stock from the extension SKU-list / price panel on the item page (no purchase buttons are clicked). PASS if the figure is at or above the limit, FAIL if below, UNKNOWN if no figure is shown. Record the figure and the date (second day check where possible). |
| Fees shown | §6.6 (user rule 2026-10-04): final price from the item page | For the selected SKU with ship-to UK and GBP, record the item price, UK shipping and **every other fee or charge shown on the item page** (tax/VAT line, service or handling fee) in `other_fees`, with `other_fees_status` VERIFIED (fees shown, or the page explicitly shows none) or UNKNOWN. Never assume a fee is zero. **Never click "Buy Now", "Add to cart" or open the checkout/order page**, even to read the price (§24). |
| 3-day check + 10% buffer | CLAUDE.md §10 (user rule 2026-10-12) | The 3-day re-check was removed on 2026-10-12 (user). The profit test also runs at item cost +6% (user rule 2026-10-13) (`cost_buffer_gate`). Record the incognito price and date in `data/price_watch/aliexpress_price_log.csv` every time (user approved 2026-10-12). If the user's price-history extension shows a chart, use the highest price of the last 3 months held 5+ days (today's if higher); otherwise mark "history UNKNOWN". |`n| Actual price, incognito (never promo) | CLAUDE.md §6.6 (user rule 2026-10-12, replaces the baseline / struck-through reading): read the price in an **incognito window, logged out**. Use the **actual price** of the exact variant. Promotions never count (see below). If only a promotional price is shown, `UNKNOWN`. Older rule text follows and still bars the same promotions: | **Never use** Welcome Deals or first-order / new-shopper prices (e.g. £0.01 or £0.99, "New shoppers save £x"), coins or coupons, "Bundle for Less" or multi-buy prices ("£0.94 each, ≥ 2 pieces"), flash or sale prices, or the cheapest-variant "from" price. **Select the exact variant you will sell** and use that variant's baseline seller price; when a sale price is shown with an original price, the original is only the cost if the page shows it as the regular selling price (user rule 2026-10-12: actual price excluding promotions, read in incognito). **Choice free shipping** counts only if it applies to one item; if free shipping needs a minimum basket (e.g. £10), add the standalone one-item shipping fee shown, or `UNKNOWN`. Never open the basket or checkout to find out. If the baseline price is not visible, `aliexpress_price` = `UNKNOWN`. |
| Item cost | §6.6 / §10 (user rule 2026-10-04) | `aliexpress_price` (the cost passed on) = the **higher of** today's repeatable price and the highest price held for 5+ days.<br>• **Today's price:** what any buyer pays now. Never use a new-shopper-only or one-time coupon price; use the normal price for the selected SKU.<br>• **5+ day price:** only from a visible price history (chart or tool), recorded with its URL and dates.<br>• **No history visible:** use today's price and write "cost basis: current price only, history UNKNOWN" in `risks`.<br>• Record the strikethrough "was" price in `regular_price`; it is not treated as history. |
| Price ceiling | §3: eBay listing price £5–£35 | Pre-screen only, not a profit calculation. If the SKU price plus shown UK shipping is £35 or more, a profitable eBay price would be above £35, so FAIL. Otherwise PASS, but only as a pre-screen. UNKNOWN if price or shipping is not shown in GBP. Record whether the price is a temporary promotion (welcome deal, coins, coupon, flash sale) and also record the regular price where shown. A promotional price that can't be repeated goes in `risks`. **Item cost rule (user rule 2026-10-13, final): no cart; cost model = listed item cost + AliExpress shipping + 20% UK VAT at checkout + about 2% FX / payment buffer.** Listed item cost = SKU List "Price" (the highest price of the last month on the AliPrice chart if it changed; never struck-through, sale or new-shopper prices). Record `source_price` = listed item cost and `source_delivery_charge` = shipping (0 with Free shipping); `tools/profit_calc.ps1` adds the VAT and FX buffer from `data/fees/<date>_aliexpress_cost_factors.csv`. Write that daily file at the start of every AliExpress session (VAT_RATE, FX_PAYMENT_BUFFER, CNY_PER_GBP seen in the SKU List). `UNKNOWN` if the price, chart or SKU List cannot be read. Every search: Choice and Free shipping filters on, ship to United Kingdom, GBP. |
| Weight | §3: under 5 kg (AliExpress UK) | Use the package or item weight from the specifications. PASS if under 5 kg, FAIL if 5 kg or more, UNKNOWN if not stated. Never infer weight from photos. |
| Variations | §3: none preferred, maximum 2–3 | Count the variations that would actually be listed on eBay, and record the total offered on AliExpress. PASS if 0. PASS with a note if 1–3. FAIL if more than 3. |
| IP / counterfeit / brand risk | §4: no VeRO brands, counterfeit or character IP (user rule 2026-10-03: branded allowed if not VeRO) | FAIL if the brand is a VeRO participant, or there is replica or "inspired by" wording, a copyrighted or trademarked character, a famous design copy, or a big brand's name or logo on a product the seller cannot plausibly own (likely counterfeit). A seller's own brand that is not in VeRO can PASS. UNKNOWN if VeRO status or brand ownership is unclear. Write the specific concern in `ip_risk_notes`. |
| Avoid list (other) | §4 | FAIL if the product is in any excluded category or is fragile, bulky, prohibited, etc. Otherwise PASS, or UNKNOWN if unclear. |
| Other compliance risks | §4, §22 | Record any risk observed, such as UK product-safety or marking concerns (e.g. toys, child products, food-contact items, batteries, flammable items), missing safety information, or unclear materials. These are recorded for review in `other_compliance_risks`, not decided here. If a product falls under "legally prohibited items" (§4), use Avoid list = FAIL. |
| Compliance | §22 | Always `COMPLIANCE_REVIEW` for AliExpress products (marketplace sourcing), unless the user has supplied evidence of a compliant sourcing arrangement. |

**Store information** is reliability context, not a pass/fail gate. Record whatever is shown: store name, store URL, store ID, store age or opening date, positive feedback %, followers, and the store's ratings. Write `UNKNOWN` for anything not shown.

Also record, where shown: the AliExpress item ID, the SKU selected, and the full specification text relevant to weight, size and materials.

## 4. Decision: proceed to eBay verification?
Apply these in order:
1. **IP / counterfeit / brand risk FAIL**, **avoid list FAIL**, or **price ceiling FAIL** → `NO` (reject). Never an exception.
2. **Any other FAIL** → `NO` (reject), unless it is a *minor* shortfall and the product looks commercially interesting. In that case set `YES_WITH_EXCEPTION`, write an `EXCEPTION` entry naming the rule not met, the observed value vs the threshold, and why it is still interesting. Exceptions are never silent and never applied to IP, avoid-list or compliance rules. Final acceptance of an exception follows CLAUDE.md §3 (relaxation only when economics are clearly strong) and §23 (user approval before action).
3. **No FAIL, but one or more UNKNOWN** → `YES_WITH_UNKNOWNS`. List every unknown field in `unknown_fields`, and lower `confidence`.
4. **Every check PASS** → `YES`.

`YES` means only "passes the AliExpress-side checks". It never means the product qualifies.

Rejected products (`NO`) are recorded with `failed_criteria` and `rejection_reason`, and also go into the daily rejections log (CLAUDE.md §20). The `failed_gate`, `observed_value` and `threshold` come from the failed check.

## 5. Deduplication
Do not record the same product twice in one day. Match by AliExpress item ID, or by close title plus matching image/specification. The same product is often sold by many stores. Keep the strongest store option (best delivery, rating and evidence) and record the others in `notes`.

If the product also appears in another source's stage file today (e.g. Amazon UK), note the match in `cross_source_match`. Cross-source deduplication is decided by a later stage (CLAUDE.md §18).

**Before evaluating a product, check the research history** (`prompts/stages/research_history.md` §6): `tools\history.ps1 -Action Check -SourceId ALI:<item ID>` (or `-Gtin` / `-Title`).
- RESEARCH → evaluate normally.
- RECHECK → evaluate again with fresh evidence.
- SKIP → do not evaluate, unless a listed recheck trigger is directly observed (e.g. the price is lower than `last_source_price`, or delivery is faster).
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

`data/sources/aliexpress_uk/YYYY-MM-DD_aliexpress_uk_stage.csv`

Use the column layout in `templates/aliexpress_uk_stage_template.csv`. Write `UNKNOWN` for unverified values and leave no field silently blank (use `N/A` where a field does not apply).

If the file for today already exists from an earlier run, append new rows; never overwrite or delete existing rows (CLAUDE.md §19).

At the end, report in the run log or summary:
- research start/end time (UK)
- number of products evaluated, and how many were YES / YES_WITH_UNKNOWNS / YES_WITH_EXCEPTION / NO
- forwarded products by allocation bucket
- the most common rejection reasons
- the most common UNKNOWN fields, and why (e.g. "sold count shown without a time period")
- any `SOURCE_BLOCKED` events
- every EXCEPTION raised

## 8. Hand-off to the eBay stage
Pass forward only rows with `proceed_to_ebay` = `YES`, `YES_WITH_UNKNOWNS` or `YES_WITH_EXCEPTION`. Include `ebay_search_terms`: neutral, unbranded keywords describing the product, to use in the eBay sold-items search.

The eBay stage and the later profit, scoring and compliance stages are separate modules. This module's output has no eBay metric, fee, profit, margin, ROI or score columns. Those are added only by later stages, from observed eBay data.



