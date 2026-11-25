# eBay Verification Engine — common verification stage

**Stage:** eBay UK verification for candidates from any sourcing hunter.
**Workflow position:** source hunters (Amazon UK, AliExpress UK, Go Dropship UK) → **eBay verification** → [hand-off] → Profit Engine → scoring / compliance / daily report.
**Purpose:** decide whether a source product has enough eBay UK evidence to move on to profit calculation, and pass forward the observed eBay data the Profit Engine needs.
**Governing rules:** CLAUDE.md §2, §3, §4, §9, §10 (inputs only), §11, §12–§16, §19–§20, §22–§27. This module does not change or relax them. If this file and CLAUDE.md disagree, CLAUDE.md wins.

This module does NOT:
- calculate profit, margin, ROI, minimum or suggested listing price (that is the Profit Engine)
- score candidates or make the final accept decision
- run or orchestrate the daily hunt
- buy, list, draft, publish or promote anything on eBay

---

## 0. Inputs
1. Today's stage files from the hunters:
   - `data/sources/amazon_uk/YYYY-MM-DD_amazon_uk_stage.csv`
   - `data/sources/aliexpress_uk/YYYY-MM-DD_aliexpress_uk_stage.csv`
   - `data/sources/godropship_uk/YYYY-MM-DD_godropship_uk_stage.csv`
2. Take only rows with `proceed_to_ebay` = `YES`, `YES_WITH_UNKNOWNS` or `YES_WITH_EXCEPTION`. Carry forward each row's `unknown_fields`, `exceptions`, `risks`, `compliance_status` and provisional seasonal fields unchanged. This module adds to them; it never deletes them.
3. The Seasonal Planning Engine output for today (CLAUDE.md §13).
4. `config.yaml` `fees` settings (user-editable; the Profit Engine applies them).
5. Previous eBay verification files in `data/ebay/` (for re-check context only; old values are never copied).
6. Record the research start time in UK time.

### Source cost fields carried for the Profit Engine
These are copied exactly from the hunter row. `UNKNOWN` stays `UNKNOWN`.

| Source | `source_price` from | `source_delivery_charge` from | `sourcing_buying_fee` from |
|---|---|---|---|
| Amazon UK | `amazon_price` | `UNKNOWN` unless shown in notes | `UNKNOWN` here; the Profit Engine applies config (0%; AliExpress FX buffer 4%) |
| AliExpress UK | `aliexpress_price` (SKU) | `uk_shipping_cost` | `UNKNOWN` here; the Profit Engine applies config (0%; AliExpress FX buffer 4%) |
| Go Dropship UK | `source_price` | `delivery_charge` | `per_order_fee` (if shown), else `UNKNOWN` here and config in the Profit Engine |

Each of the three fields gets a status column (`source_price_status`, `source_delivery_charge_status`, `sourcing_buying_fee_status`):
- `VERIFIED` if the value was observed on the source page with evidence;
- `ESTIMATED` if it came from a config assumption;
- `UNKNOWN` otherwise.

A value of 0 counts as VERIFIED only if the page explicitly shows it (e.g. "Free delivery"). Never assume it.

## 1. Access rules
Browse according to `prompts/stages/browser_research.md`: read-only, approved sites only, pause for logins and CAPTCHAs, and log every value in the evidence log.
- **eBay UK (ebay.co.uk) only.**
- Public eBay search (including sold items) needs no login.
- **Seller Hub Product Research** requires the user's eBay login. Use it only if the user has approved it (CLAUDE.md §23). Record `product_research_used` = YES/NO for every row.
- Never bypass, solve or evade a CAPTCHA, anti-bot check, rate limit or login wall (§27). If blocked: stop, record `SOURCE_BLOCKED: ebay`, and set every affected check to `UNKNOWN` (not FAIL).
- Never create, draft, list, revise or promote anything (§25). Never buy anything (§24).

## 2. Search setup (CLAUDE.md §9)
For each candidate, build a neutral, unbranded search from `ebay_search_terms`, refined to match the product. Apply and record these filters:
- Buy It Now
- Condition: New
- Item location: UK only
- Sold items (if Completed switches on with Sold, count only sold items as demand; never count unsold completed listings)

Record the exact search URL (`ebay_sold_search_url`), the matching active-listings search URL (`ebay_active_search_url`), the filters actually applied, and the research window dates. If a filter could not be applied, note it in `filter_notes` and treat the affected metrics as less reliable.

## 3. Product match (do this first)
Compare the source product with the eBay results: function, size or dimensions, quantity or pack size, material, specification, and images.

| `match_level` | Meaning | Effect |
|---|---|---|
| `EXACT` | Same product: same spec, quantity and design (EAN/GTIN match if available) | Use the evidence normally |
| `CLOSE` | Same product type; minor differences (e.g. colour, packaging) | Use the evidence; record the differences in `match_notes` |
| `CLOSE_SIZE_UNKNOWN` | Same item on both sites, but the source page doesn't state the size (user rule 2026-10-08) | Use the **nearest possible match** (the eBay size/variant closest to what the source photos, description and price show) and treat it as CLOSE. Add to `notes`: "Size not found on the source page; nearest possible eBay match used (<size chosen and why>)". |
| `NEAREST_SIMILAR` | No EXACT or CLOSE listing on eBay UK (user rule 2026-10-08) | Use the **closest similar listing** that has **5+ sales in the last 30 days** (same product type and use; Buy It Now, New, UK) as the reference listing. Its search gives the price, sell-through, trend and seller count. Add to `notes`: "No exact match found on eBay; closest similar listing used: <URL>, <how it differs>". If no similar listing has 5+ sales in 30 days, demand is not shown: the product fails (`no eBay demand for similar items`). |
| `LOOSE` | Similar category but materially different spec, size or quantity, and fewer than 5 sales in 30 days | Demand metrics are `UNKNOWN`; record a hint in `notes` only |
| `NO_MATCH` | Nothing similar found on eBay UK | See step 9 (missing evidence) |

EXACT, CLOSE, CLOSE_SIZE_UNKNOWN and NEAREST_SIMILAR listings count towards sales, sellers, price and sell-through. Always try for EXACT/CLOSE first, and use NEAREST_SIMILAR only when none exists. Record `match_level` and `matched_listings_sample`: the URLs of the listings used. A product that passes on a CLOSE_SIZE_UNKNOWN or NEAREST_SIMILAR match is reported as PASS, with that note carried into the candidate's `notes` and `rejection_risk`.

## 4. Status values
Every check gets exactly one of these:

| Status | Meaning |
|---|---|
| `PASS` | The observed evidence meets the rule. |
| `FAIL` | The observed evidence does not meet the rule. |
| `UNKNOWN` | The evidence could not be observed or verified. **Never treated as PASS.** |
| `EXCEPTION` | The check FAILED, but a minor shortfall is recorded explicitly for the user's decision (step 7). The observed value and threshold are kept. |

Each check also has a **rule type**:
- `HARD_GATE`: a CLAUDE.md §3/§4 rule. A FAIL rejects the product, unless an EXCEPTION is allowed and recorded.
- `PREFERENCE`: marked "prefer" in CLAUDE.md. Recorded with a status; a FAIL or UNKNOWN does not reject on its own. It feeds the later competition-quality score.
- `INFO`: evidence for the Profit Engine or later stages. No pass/fail.

**Lower-bound evidence rule.** Public sold results can undercount: e.g. a multi-quantity listing may show only some of its sales, and old sales drop out of results. A counted figure is therefore a **minimum**:
- If the counted minimum already meets a threshold, the check is `PASS`.
- If the counted minimum is below a threshold, the check is `UNKNOWN`, not FAIL, unless a complete figure (e.g. from Product Research) confirms the shortfall.

The same applies to upper bounds. (The total-sellers gate was removed on 2026-10-23, user rule; the listing count is recorded for information only.)

## 5. Checks

### 5.1 Demand and market (eBay evidence)
| Check | Type | Rule (CLAUDE.md) | How to judge it |
|---|---|---|---|
| Sold-item evidence | HARD_GATE (via sell-through and trend) | §9 | Record the number of matched sold items in the window, with dates, and whether the source was Product Research or public sold search. Zero matched sold items with the correct filters (and no blocking) = observed no demand: sell-through and trend are FAIL. |
| Recent sales (Sold History Button) | INFO, feeds the competitor 30-day sales checks and trend | §9, §11 | On each competitor's eBay listing page, read the **Sold History Button extension**, which shows that listing's recent sales. Record `sold_history_recent_sales` (quantity and period exactly as shown, e.g. "14 sold in last 30 days"), the dates where shown, and `sold_history_evidence`, with `source_type = THIRD_PARTY_TOOL`. Use it for the strong-seller, small-seller and Amazon-competitor counts, and as trend evidence. If the extension shows nothing on a listing: `UNKNOWN`, never estimated. |
| Sell-through rate | HARD_GATE | §3: **40%+ hand calculated (user rule 2026-11-04)**; §9 | **CURRENT METHOD (2026-11-04, overrides items 1-3 below):** sell-through = items sold in the window ÷ active listings × 100. Sold items come from ZIK (or eBay sold search) for the matched product; active listings = the eBay UK search count with Buy It Now, New and UK only ("N results"). Do not use ZIK's own sell-through percentage (it divides by at most 100 listings). PASS if 40% or more; FAIL if under 40%; `str_source` = HAND. Record both numbers. **Older method, kept for history:** **1. From eBay Product Research (observed):** PASS if 20% or more; FAIL if under 20%. **2. Product Research not available → ZIK Analytics sell-through** (Product Research, ebay.co.uk, shipping location United Kingdom, window recorded; `str_source` = ZIK, `source_type = THIRD_PARTY_TOOL`): PASS if 20% or more; FAIL if under 20%. Use the ZIK search whose results match the product (EXACT/CLOSE); if ZIK's results are mostly LOOSE matches, the status is `UNKNOWN`. **3. Neither available:** record an indicative ratio (matched sold count ÷ (sold + active count)), labelled `ESTIMATED`, with the method stated; status `UNKNOWN`. Always record `str_source`. |
| Sales trend | HARD_GATE | §3: up-trending or continuous; evergreen must not depend on a narrow seasonal spike | Use the longest window available (Product Research trend chart or sold dates). Record `trend_window` and `trend_direction` (UP / CONTINUOUS / DOWN / SPIKE_ONLY / INSUFFICIENT_DATA). PASS = UP or CONTINUOUS. FAIL = DOWN, or SPIKE_ONLY for an evergreen candidate. For seasonal/hybrid candidates, a seasonal pattern matching the target event is acceptable if demand spans more than a few days. Demand lasting only a few days breaks a §4 avoid rule: FAIL, no exception. UNKNOWN if the data is insufficient. |
| Evergreen multi-month demand | part of trend | §9, §12: demand across several months or seasons, where possible | For evergreen candidates, record which months show sales. If the data covers too short a period: UNKNOWN. |
| eBay market price | HARD_GATE (pre-check) | §3: listing price £2–£35 (min £2 since 2026-10-06) | From the matched sold sample, record `n`, min, max, median and mean of the **total buyer price (item + postage)**, plus the same for item price only. Label these as computed from the observed sample. PASS if the median total sold price is £2–£35. FAIL if outside. UNKNOWN if there are no matched sold prices. The final listing price is set by the Profit Engine. |
| Variations | HARD_GATE | §3: none preferred, max 2–3 | Use the planned variations from the source row and the typical variation count in competing listings. PASS if 3 or fewer (0 preferred). FAIL if more than 3. |
| Weight | HARD_GATE | §3: under 2 kg (Amazon UK); Go Dropship UK under 2 kg, or up to 4 kg with free delivery (2026-10-13); under 5 kg (AliExpress UK) | Carry over the source weight and apply the limit for its source. Corroborate it from eBay item specifics if stated. If the two sources conflict, use the higher weight and note it. UNKNOWN if neither states a weight. |
| Seasonality confirmation | INFO | §13, §21 | Confirm or revise the hunter's provisional `product_type` / `seasonality` / `allocation_bucket` using the sales-timing evidence. Record `seasonality_confirmed` (CONFIRMED / REVISED / UNKNOWN) with the reason. For event products, last year's same-period sales need a long Product Research window; otherwise UNKNOWN. |

### 5.2 Competition (CLAUDE.md §11)
| Check | Type | Rule (CLAUDE.md) | How to judge it |
|---|---|---|---|
| Total sellers | INFO | §3, §11: no limit (user rule 2026-10-23: the under-2,000 gate was removed) | Record the count for information and competition risk only. It never fails a product and is never UNKNOWN-blocking. **Method (user rule 2026-10-04): take it from eBay itself, never from ZIK.**<br>• Run an eBay UK search with the product keyword and the filters Buy It Now, Condition New, UK only: `https://www.ebay.co.uk/sch/i.html?_nkw=<keyword>&LH_BIN=1&LH_ItemCondition=1000&LH_PrefLoc=1`.<br>• Read the "N results for …" count (N is the total number of listings and an upper bound on sellers).<br>• Record N in `seller_count`, set `seller_count_source` = "eBay active search results count (upper bound)", and put the URL in `ebay_active_search_url` and `total_sellers_evidence`.<br>• Where the count cannot be read, write UNKNOWN and continue.<br>• ZIK's "Listings" figure stops at 100 and is not used for this count. |
| Multiple sellers making sales | PREFERENCE | §11 | Number of distinct sellers with at least 1 matched sale in the window. PASS if 2 or more. Record the count. |
| Strong sellers | HARD GATE | §3 (user rule 2026-10-17; 1,000+ count changed to 3 sellers with 500+ total sold on 2026-10-24): among the top 20 sellers, at least 3 with 500+ total sold and at least 3 with 50+ sales in the last 30 days | From the top 20 sellers by 30-day sales (ZIK table: 30 Day Sales and Total Sold columns), count sellers with 50+ sales in the last 30 days (`strong_seller_count`) and sellers with 500+ total sold (write both counts in `strong_sellers_evidence`, e.g. "50+/30d: 3; 500+ total: 4"). PASS if 500+ total sold is 3 or more AND 50+/30d is 3 or more. FAIL if either is short, based on complete data. UNKNOWN otherwise (does not pass). |
| Small sellers in top 20 | PREFERENCE | §3 (top 20 since 2026-10-05): prefer at least 2 small sellers with under 20,000 feedback and at least 5 sales in the last 30 days (5+ since 2026-10-06; was 10+) | Rank the top 20 sellers by matched sales. For each, record feedback score and 30-day sales. PASS if at least 2 have feedback of 2,000 or less **and** 5 or more sales. Also record `small_sellers_2k_to_4k`: sellers with 2,001–4,000 feedback and 5+ sales. If PASS depends on that band, the status is FAIL with the band count noted. UNKNOWN if feedback or sales can't be observed. |
| Amazon competitor sales | PREFERENCE (Amazon-sourced only) | §5.7, §11: prefer competitor sellers with 5–10+ sales in the last 30 days | Count competing sellers with 10+ sales and with 5–9 sales in the last 30 days. PASS if at least 2 have 10 or more. Otherwise FAIL (complete data) or UNKNOWN. `N/A` for other sources. |
| Saturation / dominance | INFO | §11 | Record signs of price wars, a few large or branded sellers dominating, or very many near-identical listings, in `rejection_risk`. |
| Example sellers | INFO | §9, §11 | Up to 5 example sellers, each with seller name, store URL, feedback score, 30-day matched sales (or `UNKNOWN`), and price. |
| Reference seller (competitor) | INFO | Profit Engine input: the listed price (CLAUDE.md §10) | **Selection rule (user rule 2026-10-04; top 20 added 2026-10-05):** choose the reference from the **top 20 sellers by 30-day sales** in the product search, using only EXACT/CLOSE matched listings (same product, same pack size or size; Buy It Now, New, UK; or CLOSE_SIZE_UNKNOWN / NEAREST_SIMILAR when step 3 allows it, with the note) whose seller has **under 20,000 feedback (user rule 2026-10-09; was under 5,000)** and which has **at least 5 sales in the last 30 days** (user rule 2026-10-06; was 10+, set 2026-10-04).<br>• Among those, pick the listing whose price gives the **best profit that meets all our criteria**: at or above `minimum_listing_price`, within £2–£35, at least £1 profit, and, when the listing price is £8 or more, a 30%+ margin or 20%+ ROI (user rule 2026-10-08).<br>• Record why it was chosen in `notes`, e.g. "under 5k fb, 14 sales, best qualifying price".<br>• If no seller under 20,000 feedback (user rule 2026-10-09; was under 5,000) has a qualifying price, record the best under-20k listing anyway (so the Profit Engine shows the shortfall) and note "no under-20k competitor at a qualifying price".<br>• If no under-20k matched seller has 5+ sales in 30 days, `reference_seller_price` = `UNKNOWN` (no qualifying competitor; the product cannot pass the price check).<br>• Never pick a listing only because its price is high: it must be the same product and have 5+ sales in the last 30 days.<br>Record for the chosen listing:  `reference_seller_name`, `reference_seller_url` (their listing), `reference_seller_store_url` (the seller's eBay store or profile page, exactly as opened; `UNKNOWN` if not opened), and `reference_seller_price` = the price on that competitor's listing (total buyer price, item + postage), observed at verification time. If that listing is no longer active, use its last sold price and say so in `notes`. `UNKNOWN` if it cannot be determined. |

### 5.3 Shipping, fees and IP
| Check | Type | Rule (CLAUDE.md) | How to judge it |
|---|---|---|---|
| Shipping information | INFO | §9 | From matched listings, record: share offering free postage, typical postage charged (range), typical dispatch time, and item location (UK). Our own postage cost is not invented. It stays a source-side cost (`source_delivery_charge`) or `UNKNOWN`. |
| eBay category | INFO, **required** | §10 inputs | The category used by the reference competitor's listing, with its full breadcrumb path (e.g. `Home & Garden > Garden & Patio > Weed & Pest Control > Other Weed & Pest Control`) in `ebay_category_path`. The Profit Engine looks up the fee by this path in today's fee table (deepest matching level wins). If the path is not recorded, the fee is UNKNOWN. |
| eBay fees | INFO | §10 | **Priority:** (1) observed in eBay's fee calculator or fee table for this category/seller type (`fee_source` = OBSERVED); (2) a user-set value in `config.yaml` (`fee_source` = CONFIG_ASSUMPTION, labelled ESTIMATED); (3) otherwise `UNKNOWN`. Record the final-value fee rate, the fixed per-order fee, the basis (whether postage is included, if stated), the seller account type the fee applies to (user stated 2026-10-03: **business seller, sole trader**; `config.yaml` `fees.ebay_seller_account_type`), and the evidence URL with its date. Never invent a fee. |
| Ad rate | INFO | §10 | Use the rate the user set for this run or in `config.yaml`. Otherwise `UNKNOWN`. If competitor listings show "Sponsored", record that as market context only, never as our rate. |
| IP / VeRO risk | HARD_GATE | §4: no VeRO brands, counterfeit or character IP (user rule 2026-10-03: branded allowed if not VeRO) | Generic/unbranded (e.g. competitors list "Unbranded"): PASS. **Branded:** check the brand against eBay's VeRO programme (eBay UK's public VeRO participant profiles, plus eBay's VeRO policy pages), with the URL and date recorded. PASS if the brand is not a VeRO participant; FAIL if it is (no exception). UNKNOWN if the VeRO list could not be checked. Note that a missing VeRO profile is not a guarantee: say so in `ip_vero_notes`. Character IP and counterfeit/replica: FAIL. |

## 6. Duplicate source products
If two or more source rows today are the same product (e.g. the same item found on Amazon and AliExpress), verify it on eBay once. Give each source row the same eBay evidence, and record `shared_ebay_evidence_with` (the other candidate_ids). The final choice between sources is a later stage (CLAUDE.md §18).

## 7. Exceptions
An `EXCEPTION` may be recorded only when:
- a HARD_GATE check is FAIL by a **minor** margin (e.g. sell-through 18% against 20%, or 4 variations against a maximum of 3), and
- the product looks commercially interesting on the observed evidence.

Record in `exceptions`: the rule, the observed value, the threshold, the margin, and why it is still interesting. Never allowed for: IP/VeRO, the §4 avoid list (including "demand lasting only a few days"), or compliance. Exceptions carried over from the hunter stay in the list. Final acceptance follows CLAUDE.md §3 (relaxation only when economics are clearly strong) and §23 (user approval).

## 8. Overall result
`ebay_verification_status` is the worst status across all HARD_GATE checks, in this order: `FAIL` > `EXCEPTION` > `UNKNOWN` > `PASS`.
- `PASS`: every hard gate observed and passing.
- `UNKNOWN`: no FAIL or EXCEPTION, but at least one hard gate could not be verified.
- `EXCEPTION`: no plain FAIL, at least one recorded EXCEPTION.
- `FAIL`: at least one hard gate FAIL with no exception allowed or recorded.

PREFERENCE results never change this status. They are reported in `preference_summary`.

**`proceed_to_profit`:**
- `YES` when the status is PASS, UNKNOWN or EXCEPTION **and** there is a matched sold-price sample, which the Profit Engine needs.
- `NO` otherwise, with `rejection_reason` (status FAIL, or no matched sold-price evidence).

UNKNOWN hard gates stay UNKNOWN downstream. A product with any UNKNOWN or EXCEPTION can never be reported as fully passing.

FAIL rows also go into the daily rejections log (CLAUDE.md §20), with `failed_gate`, `observed_value`, `threshold` and evidence.

## 9. Missing eBay evidence
| Situation | Handling |
|---|---|
| Search blocked / CAPTCHA / rate-limited | `SOURCE_BLOCKED: ebay`. Affected checks `UNKNOWN`. `proceed_to_profit` = NO (reason "eBay evidence not obtainable"). Re-queue for the next run. Not a product rejection. |
| Correct filters, zero matched sold items | Observed absence of demand. Sell-through and trend FAIL. Status FAIL. |
| No EXACT/CLOSE match | Don't stop here: look for a NEAREST_SIMILAR listing (step 3, user rule 2026-10-08) and continue with it. |
| Only LOOSE matches or NO_MATCH (no similar listing with 5+ sales in 30 days) | Demand, price and competition checks `UNKNOWN`. `proceed_to_profit` = NO (reason "no comparable eBay evidence: no similar listing with 5+ sales in 30 days"). Logged for review. |
| Product Research not available | Use ZIK Analytics sell-through for the gate (see Sell-through rate), plus public sold/active search. If ZIK is also unavailable: sell-through `UNKNOWN` (indicative ratio recorded as ESTIMATED). Lower-bound rule for counts. |
| A metric not displayed anywhere | `UNKNOWN`, listed in `unknown_fields`. Never filled from another product, category averages or memory. |
| Fees not observed and config `UNKNOWN` | Fee fields `UNKNOWN`. The Profit Engine must mark any profit as ESTIMATED/UNKNOWN accordingly. |

## 10. Output
Write one row per verified candidate to:

`data/ebay/YYYY-MM-DD_ebay_verification.csv`

Use the column layout in `templates/ebay_verification_template.csv`. Every check has `<check>_status`, its value fields, and `<check>_evidence` (URL plus what was seen). All values are observed at `observed_at_uk`. Write `UNKNOWN` for unverified values and `N/A` where a field does not apply. Never leave a field silently blank.

If today's file already exists, append; never overwrite or delete rows (CLAUDE.md §19).

At the end of the stage, report:
- research start/end time (UK)
- whether Product Research was used
- the number verified and the number in each `ebay_verification_status`
- the `proceed_to_profit` YES/NO counts
- the most common FAIL gates and the most common UNKNOWN fields, with reasons
- every EXCEPTION
- any SOURCE_BLOCKED events

## 11. Hand-off to the Profit Engine
The Profit Engine reads rows with `proceed_to_profit` = YES. It uses:
- source costs: `source_price`, `source_delivery_charge`, `sourcing_buying_fee`, each with its status column
- reference seller: `reference_seller_name`, `reference_seller_url`, `reference_seller_price`
- the eBay price sample: `sold_price_total_median`, `sold_price_total_min`, `sold_price_total_max`, `sold_price_total_mean`, `sold_sample_n`, and the item-only equivalents
- fees: `fee_final_value_rate`, `fee_fixed_per_order`, `fee_basis`, `fee_source`, `fee_status`, and `ad_rate` / `ad_rate_source`
- carried fields: statuses, unknowns, exceptions, seasonal and compliance fields

This module does not calculate profit, margin, ROI, minimum price or suggested price.

## Interpretations to confirm with the user
Where CLAUDE.md gives a range, this module applies the stricter end and records raw values, so nothing is silently relaxed:
- Strong sellers (2026-10-11; HARD GATE from 2026-10-17): PASS needs 3+ sellers with 30+ sales in 30 days (was 50+, changed 2026-11-04) AND 2+ sellers with 500+ total sold, both among the top 20 (total-sold rule: 2+ with 1,000+ until 2026-10-24, 3+ with 500+ until 2026-11-04, now 2+ with 500+). FAIL or UNKNOWN rejects the product (not a scoring preference any more).
- Small sellers "under 20,000" feedback: PASS needs under 20,000 feedback.
- Amazon competitors "5–10+ sales": PASS needs at least 2 sellers with 10 or more.
- The £2–£35 price check uses the median **total** buyer price (item + postage).

These are PREFERENCE checks, except the price check and the strong-seller check (hard gate from 2026-10-17), so the others affect scoring, not rejection.
