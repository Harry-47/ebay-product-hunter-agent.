# Amazon UK Hunter — source research module

**Stage:** source discovery and Amazon-side checks only.
**Output:** a shortlist of Amazon UK products, each with evidence, passed to the later eBay verification stage (CLAUDE.md §9).
**Governing rules:** CLAUDE.md. This module applies §3, §4, §5, §13–§16, §19–§20, §22–§27. It does not change or relax them. If this file and CLAUDE.md disagree, CLAUDE.md wins.

This module does NOT:
- verify eBay demand or competition
- calculate eBay fees, profit, margin or ROI
- score candidates
- make a final accept decision
- buy, add to basket, list or publish anything

---

## 0. Before starting
1. Run the Seasonal Planning Engine (CLAUDE.md §13) for today's UK date, or load its output if it has already run today. Note:
   - each event/season, with its date or window, days until, preferred and minimum listing starts, phase and priority (`Not defined` unless set in `data/event_calendar.yaml`)
   - which events are **Current Event** and which are **Next Event Preparation**
   - the daily allocation (default 50/30/20)
2. Load previous Amazon stage files from `data/sources/amazon_uk/` and the previous daily candidate files from `data/daily/`. Use them for deduplication (step 5) and lifecycle context. Never modify past files.
3. Record the research start time in UK time.

## 1. Discovery
Find candidate products on Amazon UK (amazon.co.uk) using only publicly visible pages:
- **First (user rule 2026-10-08):** search for the products found on eBay in the eBay-demand step (`prompts/daily_hunt.md` Step 5a): products already selling well on eBay UK.
- Then category browse and keyword searches, looking only for the "500+ bought in past month" label or higher (user rule 2026-10-11). A Best Seller or Amazon's Choice badge alone does not count (user rule 2026-10-08).
- Best Sellers lists are mostly Amazon-fulfilled (FBA) items, so they are not a starting point.

Choose the search themes from:
- **evergreen** categories: generic, giftable, problem-solving, home, organisation and storage products
- the **Current Event** themes from the seasonal engine
- the **Next Event Preparation** themes from the seasonal engine (for Christmas, use the CLAUDE.md §13 priority order)

Skip categories that CLAUDE.md §4 excludes (food and drink, sized clothing/shoes (free-size clothing with no size options is allowed, 2026-10-13), electronics only if battery-free or sourced from a UK-based source (allowed on Amazon UK and Go Dropship UK, 2026-10-13), medicines/supplements, adult, tobacco, etc.), and on Amazon also **jewellery** (user rule 2026-10-04).

**Search filters (user rule 2026-10-04), applied where Amazon offers them:**
- Customer Reviews: 4 stars & up
- Price: £2–£40 (user rule 2026-10-06; was £5–£40)
- Condition: New
- Small business
- Seller type: FBM

Record which filters were actually available and applied. A criterion with no filter is checked on the product page instead (§3 below).

## 2. Access rules
- Browse according to `prompts/stages/browser_research.md` (Amazon and Keepa playbooks): read-only, approved sites only, and log every value in the evidence log. A value with no evidence row is `UNKNOWN`.
- Do not log in to Amazon, Keepa or any other site with the user's credentials, and do not use a paid tool or subscription, unless the user has approved it (CLAUDE.md §23).
- Never bypass, solve or evade a CAPTCHA, anti-bot check, rate limit, login wall or paywall (§27). If blocked, stop on that site, record `SOURCE_BLOCKED` with the reason, and report the shortfall.
- **Never add items to the basket**, including to probe stock quantity (§24).
- Delivery estimates depend on the delivery location. Use a UK postcode only if the user has supplied one, and record which postcode/location context the estimate was shown for. Never invent a postcode.

## 3. Per-product checks
Each criterion gets a **status**: `PASS`, `FAIL` or `UNKNOWN`. Each also gets an **evidence** entry: the URL, plus what was seen (e.g. "page text: 'Only 12 left in stock'"). All observations are taken at `observed_at_uk`.

**Rules for UNKNOWN:**
- If a criterion cannot be verified, its status is `UNKNOWN`.
- `UNKNOWN` never counts as `PASS`.
- Never estimate a value from a different product, a similar listing or a generic page.

| Check | Rule (from CLAUDE.md) | How to judge it |
|---|---|---|
| Demand | §5.1: **500+ sold in the last 30 days** (user rule 2026-10-11; was 1,000+; Best Seller and Amazon's Choice badges do not count) | PASS only if Amazon's label shows 500+ in the past month ("500+ bought in past month" or higher). FAIL if the label shows under 500 (e.g. "400+ bought in past month"), or if no monthly label is shown (a badge alone is not enough). Record the exact wording, and any badge or rank for information only. The label is a lower bound ("500+" means at least 500); never turn it into an exact sales figure. |
| Price-gap pre-screen | CLAUDE.md §5.9a-1 (user rule 2026-10-12) | Open a product only if the Amazon price is at most about 55% of the eBay reference price. Work eBay first (ZIK tables, competitor stores). |
| Deal price / Keepa stability | §5.9a-3, 6 | Reject or re-cost at the regular price when a deal, coupon, subscription voucher or "Save x%" sets the price. The Keepa 3-month average must be within 10% of today's price. Read the Keepa Buy Box graph for the last 3 months: the cost is the highest price that stayed for at least 5 days (spikes under 5 days ignored); today's price if higher (user rule 2026-10-12; replaces the 3-separate-days check). |
| Cost buffer / max safe cost | §5.9a-2, §10 | Profit also tested at item cost +4% (`cost_buffer_gate`, user rule 2026-10-13); `max_safe_cost` recorded in every profit row. |
| Preference / quality / thin flag | §5.9a-4, 5, 7, 8 | Prefer multipacks and sets from small-business sellers; start from eBay competitors with unbranded light items at about GBP 8-20; flag ratings 4.0-4.2 as a returns risk; `thin_margin_flag` = THIN when the eBay reference price is within 3% of the minimum listing price. |
| Stock (Seller Sprite) | §5.2: the selected offer (FBM or FBA) in stock; a visible unit figure must be **30+** | Seller Sprite is used **only** to see seller type and in-stock status, without clicking (user rule 2026-10-05). **Never click "View details"** (it can fill the basket and slows research; the guard denies it). Read the Seller Sprite "Stock Status" summary box and Amazon's own stock text. PASS if a visible FBM figure is 30+, or if only "In stock" shows with no number; FAIL if out of stock or a visible figure is under 30 (e.g. "Only 12 left"); UNKNOWN if nothing is visible. Record the figure or "In stock (no number)" in `stock_observed`. After each product page read the basket counter: if it is not 0, notify the user to clear the basket and pause Amazon until they say it is clear (the agent never deletes basket lines). Never add to the basket and never open checkout. |
| Seller type | §5.3 (user rule 2026-10-09): FBM or FBA, with free Amazon Prime delivery | Use the "Dispatches from" and "Sold by" fields on the page. Dispatched by a third party = `FBM`. Dispatched by Amazon for a third-party seller = `FBA`. Sold and dispatched by Amazon = `AMAZON_RETAIL`. Record the seller name. PASS = FBM or FBA, **and** the offer shows the Prime badge with FREE delivery (record `prime_free_delivery` = YES/NO). FAIL = AMAZON_RETAIL, or an offer without Prime free delivery. UNKNOWN if the fields are not shown or unclear. **Offer selection:** when the same product has several offers or listings, take the one with the **lowest product cost and the higher profit margin** (note the other offers in `notes`). |
| Keepa (Buy Box graph only) | §5.4: Buy Box price and availability stable and continuous for at least 3 months; avoid breaks over 5–7 days | Use **only the Keepa extension's Buy Box price graph** on the Amazon product page, with the 3-month range. Sales Rank and other lines are not used. Only if Keepa data is actually accessible. Record the window observed (days), whether the Buy Box price was stable, and the longest availability/Buy Box gap in days. PASS needs at least 90 days observed, stable, and a longest gap of 5 days or less. FAIL if the history is under 90 days, unstable, or the longest gap is over 7 days. A longest gap of more than 5 and up to 7 days is `FAIL`, but may be raised as an `EXCEPTION` (step 4) with the exact gap recorded. UNKNOWN if Keepa is not available. |
| Delivery | §5.5: fastest delivery 3–5 days or better | Days = the earliest delivery date shown minus the observation date. PASS if 5 days or fewer. FAIL if more than 5. UNKNOWN if no date is shown. Record the postcode context. |
| Baseline price | §10 baseline rule (user rule 2026-10-04) | `amazon_current_price` = the seller's price for the exact variant, **excluding** vouchers or coupons ("Save 5% on any 4", "Extra 25% off" vouchers), Subscribe & Save, "Voucher price", Prime-only or limited-time deal prices, and multi-buy offers. When a "Limited time deal" or "Was" price is shown, record both and use the non-deal price. Then apply the Keepa rule below (the higher of this and the highest Keepa Buy Box price in the last 3 months). |
| Sourcing cost (Keepa) | §5 / §10: Amazon item cost (user rule 2026-10-08) | From the same Keepa Buy Box graph (last 3 months), take the **highest Buy Box price shown in those 3 months**, however long it lasted (the "held 5+ days" condition was removed on 2026-10-08). Record it as `keepa_max_held_price` (column name kept), with its date in `keepa_max_held_dates`; `keepa_max_held_days` = `N/A`. Record today's page price as `amazon_current_price`. **`amazon_price` (the sourcing cost passed to the Profit Engine) = the higher of the Keepa 3-month high and `amazon_current_price`.** Record the basis in `sourcing_cost_basis` (`KEEPA_3M_HIGH` / `CURRENT_PRICE_HIGHER`). If the Keepa graph is unavailable, use `amazon_current_price` and set `sourcing_cost_basis` = `CURRENT_PRICE_ONLY_KEEPA_UNKNOWN`, noted as a risk. Never estimate a level that is not visible on the graph. |
| Price ceiling | §3: eBay listing price £2–£35 | Pre-screen only, not a profit calculation. If the sourcing cost (`amazon_price`) is £35 or more, a profitable eBay price would be above £35, so FAIL. Otherwise PASS, but only as a pre-screen. The final price check happens in the eBay and profit stages. UNKNOWN if no price is shown. |
| Free delivery | §5.1 (user rule 2026-10-04): free delivery | Record the delivery charge shown for the postcode context in `delivery_fee`. PASS if the page shows FREE delivery for the offer being evaluated, FAIL if a delivery charge is shown, UNKNOWN if not shown. A "free over £X" note alone is not free delivery for a cheaper item: record it and judge by the item price. |
| Sellers on the listing | §5.1 (user rule 2026-10-04): 3 to 20 sellers | Count the sellers offering the product, from Amazon's "Other sellers on Amazon" / "New (N) from £x" / all-offers panel, or the Seller Sprite sellers table (record which). `offer_sellers` = the count. PASS if 3–20, FAIL if under 3 or over 20, UNKNOWN if no count is visible. |
| Rating | §5.1 (user rule 2026-10-04): 4+ stars | Record `amazon_rating` and the review count. PASS if 4.0 or more, FAIL if below 4.0, UNKNOWN if not shown. |
| Amazon price range | §5.1 (user rule 2026-10-04): £5–£40 | Judge `amazon_price` (the sourcing cost). PASS if £2–£40 (user rule 2026-10-06; was £5–£40), FAIL if outside. (The eBay listing price must be £2–£35, §3.) |
| Condition / small business | §5.1 search filters | Record `condition_shown` (must be New; a used/renewed offer is not evaluated) and `small_business_shown` (YES if Amazon's small-business badge or filter applies, NO, or UNKNOWN). Small business is a search filter, not a gate. |
| Weight | §3: under 2 kg (Amazon UK, user rule 2026-10-04) | Use the item or shipping weight from the product details. PASS if under 2 kg, FAIL if 2 kg or more, UNKNOWN if not stated. Never infer weight from photos. |
| Variations | §3: none preferred, maximum 2–3 | Count the selectable variations (size, colour, pack, etc.). PASS if 0. PASS with a note if 1–3. FAIL if more than 3. |
| Avoid list | §4 | FAIL if the product is in any excluded category, its **brand is a VeRO participant**, or it is character IP, counterfeit, fragile, bulky, etc. A branded product is allowed if the brand is **not** in eBay's VeRO programme (user rule 2026-10-03): check the brand as in `ebay_verification.md` (IP / VeRO) and record it in `risks`. UNKNOWN if VeRO status could not be checked. Write the specific concern in `risks`. |
| Compliance | §22 | Always `COMPLIANCE_REVIEW` for Amazon-sourced products (retailer sourcing), unless the user has supplied evidence of a compliant sourcing arrangement. |

Also record, where shown: price, ASIN, EAN/GTIN, brand and rating. Do not record anything that was not seen.

**Tools on the Amazon product page:** Seller Sprite extension (inventory: availability, quantities, top holder, FBM figures) and Keepa extension (Buy Box price graph only). Neither needs signing in for these uses. Never use another extension's toolbar (e.g. "Upload on eBay").

## 4. Decision: proceed to eBay verification?
Apply these in order:
1. **Avoid list FAIL**, or **price ceiling FAIL** → `NO` (reject). Never an exception.
2. **Any other FAIL** → `NO` (reject), unless it is a *minor* shortfall and the product looks commercially interesting. In that case set `YES_WITH_EXCEPTION`, write an `EXCEPTION` entry naming the rule not met, the observed value vs the threshold, and why it is still interesting. Exceptions are never silent and never applied automatically to avoid-list or compliance rules. Final acceptance of an exception follows CLAUDE.md §3 (relaxation only when economics are clearly strong) and §23 (user approval before action).
3. **No FAIL, but one or more UNKNOWN** → `YES_WITH_UNKNOWNS`. List every unknown field in `unknown_fields`, and lower `confidence`.
4. **Every check PASS** → `YES`.

`YES` means only "passes the Amazon-side checks". It never means the product qualifies. Every forwarded product still has to pass eBay verification, competition, profit and compliance (§8 of this file and CLAUDE.md).

Rejected products (`NO`) are recorded with `failed_criteria` and `rejection_reason`, and also go into the daily rejections log (CLAUDE.md §20). The `failed_gate`, `observed_value` and `threshold` come from the failed check.

## 5. Deduplication
Do not record the same product twice in one day. Match by ASIN, EAN/GTIN, or close title plus matching image/specification. **Before evaluating a product, check the research history** (`prompts/stages/research_history.md` §6): `tools\history.ps1 -Action Check -SourceId AMZ:<ASIN>` (or `-Gtin` / `-Title`).
- RESEARCH → evaluate normally.
- RECHECK → evaluate again with fresh evidence.
- SKIP → do not evaluate, unless a listed recheck trigger is directly observed (e.g. the price is lower than `last_source_price`, or it is back in stock).
- RETIRE or a user status → do not evaluate.

When re-evaluating, link the earlier record in `notes` (e.g. "seen 2026-10-01, WATCH: stock FAIL; trigger: restock"). Never copy old values.

## 6. Provisional seasonal classification
Using the seasonal engine output, record a **provisional** classification. The eBay stage confirms it using sales-trend evidence.
- `product_type`: evergreen / seasonal / hybrid
- `seasonality`: CLAUDE.md §13 labels (e.g. `evergreen`, `christmas`, `winter`, `christmas_plus_evergreen`, `unclear`)
- `allocation_bucket`: `evergreen` / `current_event` / `next_event_preparation`
- `target_event`, `event_date`, `seasonal_phase`, `days_until_event`, `preferred_listing_start`, `minimum_listing_start`, copied from the engine. Use `NONE` for evergreen.
- `seasonal_confidence`: LOW / MEDIUM / HIGH, with a reason in `notes`

## 7. Output
Write one row per evaluated product, including rejected ones, to:

`data/sources/amazon_uk/YYYY-MM-DD_amazon_uk_stage.csv`

Use the column layout in `templates/amazon_uk_stage_template.csv`. Write `UNKNOWN` for unverified values and leave no field silently blank (use `N/A` where a field does not apply).

If the file for today already exists from an earlier run, append new rows; never overwrite or delete existing rows (CLAUDE.md §19).

At the end, report in the run log or summary:
- research start/end time (UK)
- number of products evaluated, and how many were YES / YES_WITH_UNKNOWNS / YES_WITH_EXCEPTION / NO
- forwarded products by allocation bucket
- the most common rejection reasons
- the most common UNKNOWN fields, and why (e.g. "Keepa not accessible")
- any `SOURCE_BLOCKED` events
- every EXCEPTION raised

## 8. Hand-off to the eBay stage
Pass forward only rows with `proceed_to_ebay` = `YES`, `YES_WITH_UNKNOWNS` or `YES_WITH_EXCEPTION`. Include `ebay_search_terms`: neutral, unbranded keywords describing the product, to use in the eBay sold-items search.

The eBay stage and the later profit, scoring and compliance stages are separate modules. This module's output has no eBay metric, fee, profit, margin, ROI or score columns. Those are added only by later stages, from observed eBay data.

**Amazon updates (user rules 2026-10-13):** no 55% pre-screen (profit test decides); stable Limited-time-deal prices may be used as cost when Keepa shows them stable; cost buffer 4% (user rule 2026-10-13); ad rate 3% at every price for Amazon-sourced products; discovery per CLAUDE.md 5.9a-9 to 12 (exact-match Product Explorer at GBP 15-35, niche/fitment categories, Christmas timing, route generic items to Go Dropship/AliExpress first).
