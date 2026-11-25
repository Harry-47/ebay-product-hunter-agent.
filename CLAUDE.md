# eBay Product Hunter Agent — Business Rulebook

This file is loaded at the start of every session. It is the permanent business rulebook and every research run must follow it.
The agent must NOT silently change any rule in this file. See §28 (CHANGE_PROPOSAL process).

## 0. Start here

### Command: "start the daily hunt"
When the user types **"start the daily hunt"** (also "run the daily hunt", "start today's hunt", "start hunt"), from this terminal or from the Claude mobile/desktop app through Remote Control, **start at once. Do not ask for confirmation and do not only describe a plan.** Run the whole of `prompts/daily_hunt.md`, in order, in the connected Google Chrome:
1. **Prepare:** read `prompts/operating_loop.md`, `prompts/daily_hunt.md`, `config.yaml` and the supplier file of each active source (`prompts/suppliers/`). Run `tools\preflight.ps1`. Write today's calendar, eBay fee and AliExpress cost files if they are missing.
2. **Chrome:** load the Claude in Chrome tools and check that a browser is connected. If none is, try `tools\chrome_restart.ps1` once; if it still isn't, send one notification and stop. Use one tab.
3. **Sign-ins:** check ZIK, eBay UK, AliExpress, Go Dropship and AW Dropship. If one is signed out, send one notification and carry on with the others. The agent never signs in.
4. **Hunt:** eBay demand first (competitor stores, then ZIK), then match on the active sources. Per source: stop at 5 passes or 35 evaluated (§17).
5. **Check every product:** `tools\dedupe_check.ps1`, source rules, eBay verification, `tools\verif_batch.ps1` (Profit Engine), links, codes and up to 3 variants (§18).
6. **Report:** workbook, CSV files, history and the Daily 20 page at the URL in `config.yaml` (publishing that private page is part of the hunt).
7. **Close:** `tools\run_close.ps1`, then one notification with passes, shortfalls and what needs the user.

Other commands: **"continue"** = resume a paused hunt; **"pause"** = save the state in `data/notes/` and stop; **"finish without it"** = mark the waiting source `SOURCE_BLOCKED` and close the run.

The hunt is research only. "Start the daily hunt" is not permission to buy, use a basket or checkout, list, message anyone, log in, accept terms, solve a CAPTCHA or go round the browser guard (§23–§27). Permission prompts are answered by the user.

### Where things are
| Place | Holds |
|---|---|
| `CLAUDE.md` | rules (this file) |
| `prompts/daily_hunt.md` | the daily workflow, step by step |
| `prompts/operating_loop.md` | which tool to use, what to do when something fails |
| `prompts/suppliers/` | full rules per supplier (§5–§8) |
| `prompts/hunters/`, `prompts/stages/` | how each source and stage is worked |
| `tools/` | the scripts (the project's `scripts` folder; the browser guard hook points here, so it must not be renamed) |
| `tests/` | regression tests for the scripts |
| `config.yaml` | numeric settings; `.env` = optional API keys (never open, print or commit it; `tools\env_check.ps1` shows SET/EMPTY) |
| `data/` | all research, never deleted |
| `docs/rulebook_changelog.md` | every rule change with its date and the user's words |
| `docs/archive/` | old full copies of this file |

If another file conflicts with this rulebook, this rulebook wins. Report the conflict and raise a CHANGE_PROPOSAL if one needs updating.

### Current rules at a glance (restated 2026-11-25; no rule was changed)
Older sections and the supplier files keep their dated history. **Where an older text differs, the newest user instruction in `docs/rulebook_changelog.md` applies.** Report any difference found.

| Topic | Rule in force |
|---|---|
| Daily sources | AliExpress UK, Go Dropship UK, AW Dropship: 5 passes each, 15 in total, 35 evaluated at most per source. **Amazon paused.** Pound Wholesale = stock model, only when the user asks. New suppliers only when the user says so |
| Order | eBay demand first; ZIK first, eBay fills gaps; skip anything researched, passed or listed before |
| Price | eBay listing price £2–£35 |
| Profit | £1+ always. Under £8: £1 is enough. From £8: 30% margin **or** 20% ROI (noted "margin under 30%") |
| Ads | 3% under £8, 5% from £8, plus 20% VAT on the ad cost |
| eBay fees | read from eBay's fee page on the day, +0.35% regulatory, per-order and insertion fees, +20% VAT; Profit Engine only |
| Demand | **Route A:** of the top 20 sellers, 3+ with 30+ sales/30d AND 2+ with 500+ total sold, and sell-through 40%+. **Route B:** 3+ small sellers (under 20,000 feedback) with 5+ sales/30d each of the same product, and sell-through 20%+. Count only sellers of the same product |
| Sell-through | by hand: sold in 30 days (ZIK) ÷ eBay UK active listings (Buy It Now, New, UK) × 100 |
| Reference price | a top-20 seller of any size, same product, 5+ sales/30d, best price that meets every rule |
| Total listings | no limit; record only |
| AliExpress cost | SKU List price of the exact variant + 4% FX; must also pass with cost +6%. Read the AliPrice 3-month chart (flat = fake sale; a higher held price is a cost risk). Never new-shopper, coupon, coin, bundle or one-per-shopper prices |
| AliExpress source | Choice + 500+ sold, rating 4.3+, store 90%+, free shipping for one item, delivery 10 days or less, under 5 kg unless delivery is free |
| Go Dropship | price + 5% fee, no buffer; UK warehouse; delivery 7 days or less; bestseller on the day or 1,000+/30d; stable price (§7a.9); under 2 kg unless delivery is free; remote-area surcharge recorded |
| AW Dropship | net price × 1.20 + postage £2.79/£2.99/£5.99 (+£1 if under £3 net). Demand gate and margin/ROI test relaxed: sell-through 40%+ and £1 profit. Christmas gifts: eBay price test waived (§0 is a summary: see `prompts/suppliers/aw_dropship.md`) |
| Stock | 20+ normal, 50+ seasonal (AliExpress, Go Dropship, AW) |
| Variations | up to 3 (maximum), best seller first, each passes every gate and has full information |
| Packs | 2 or 3 of an item may be listed as a pack; cost = units × single-unit price |
| Avoid | §4. Small electric gadgets allowed (recorded as compliance risk); no large or mains-heavy electricals, sized clothing, food, breakables, VeRO brands |
| Winter/Christmas before the event | §16a pre-event tests instead of 30-day eBay sales |
| Every product | eBay listing link, source product link, item code, variant code (§18) |

## 1. Purpose of the agent
Find UK eBay product opportunities from the configured sourcing sites (Amazon UK, AliExpress UK and Go Dropship UK). Verify each one against real eBay UK demand, competition and economics. Produce an evidence-backed daily research report.

The agent is a **research assistant only**. It finds products, verifies them, scores them and reports on them. It never buys, lists, publishes or contacts suppliers on the user's behalf (see §23–§25).

Operating mode: **DYNAMIC_SEASONAL_PLUS_EVERGREEN**. The agent researches evergreen products continuously and prepares for upcoming UK commercial and consumer events on a rolling calendar (§12–§16). It is not limited to one season.

## 2. eBay UK target market
- Marketplace: **eBay UK (ebay.co.uk)** only.
- Buyers: UK consumers.
- Item location for research comparisons: **UK only**.
- Currency: GBP (£).
- Delivery must be realistic for UK buyers within the delivery limits of the relevant source (§5–§8).

## 3. General product criteria
These are the user's baseline rules (hard gates unless marked "prefer"):

| Rule | Requirement |
|---|---|
| Selling/listing price | £2 to £35 (user rule 2026-10-06; minimum was £5) |
| Profit | at least £1 profit (always required) |
| Margin / ROI | **Amazon-sourced: 15% margin (or 20% ROI) from GBP 8, and the small-seller (<20,000 feedback) rule is dropped for Amazon (user rule 2026-10-14).** Other sources: depends on the **eBay listing price** (user rule 2026-10-08): listing price under £8.00 → £1 profit is enough, whatever the margin; listing price £8.00 or more → at least **30% profit margin**, **or** at least **20% ROI** (a product that passes only on ROI is passed with the note "margin under 30%"). Replaces the item-cost ROI tiers. |
| eBay sell-through rate | **40%+** (user rule 2026-11-04; was 20%+), **calculated by hand**: items sold in the research window ÷ number of active listings × 100, with active listings counted from the eBay UK search (Buy It Now, New, UK only, "N results"). ZIK's own sell-through is not relied on (it never counts above its 100 listings) |
| Strong sellers | **hard gate (user rule 2026-10-17; was a preference)**: among the top 20 sellers for the product, at least 2 sellers with **500+ total sold** (user rule 2026-11-04; was 3 with 500+ since 2026-10-24, earlier 2 with 1,000+) **and** at least 3 sellers with **30+ sales in the last 30 days** (user rule 2026-11-04; was 50+). Both must pass; a count that cannot be read is `UNKNOWN` and the product does not pass. (History: 1,000+ count 3 → 2 on 2026-10-12; 50+/30d set 2026-10-11, was 3–5 sellers with 100+.) |
| Total sellers / total listings | **no limit** (user rule 2026-10-23: gate removed; was under 2,000, earlier under 1,000). The count is recorded for information only |
| Small sellers in top 20 | **dropped for all sources (user rule 2026-10-14)**: seller size (feedback count) is no longer a gate or a preference; record it for information only. (Earlier: prefer at least 2 sellers with under 20,000 feedback and 5+ sales in 30 days.) |
| eBay sales graph | **not a gate** (user rule 2026-10-14). Describe it in a separate `trend_description` column: whether sales follow a steady trend, an event, a season or a yearly pattern |
| Variations | none preferred; maximum 2–3 |
| Weight | **no weight limit when the source shows free delivery for a single-item order** (user rule 2026-10-18, all sources; bulky items that are expensive to ship stay avoided under §4, and the Go Dropship remote-area surcharge is still recorded, §10). Without free delivery: Amazon UK → under 2 kg; Go Dropship UK → under 2 kg; AliExpress UK → under 5 kg. If the delivery charge is not shown, the weight check is `UNKNOWN`. |

**Relaxation:** a minor relaxation is allowed only when the economics are clearly strong. Record exactly which rule was relaxed, the observed value, and why, in `criteria_relaxed`. A relaxed product must never be presented as fully compliant with the rules.

## 4. Products/categories to avoid
Reject:
- high-ticket items
- medicines
- supplements
- VeRO-protected brands: a branded product is **allowed** only if its brand is **not** in eBay's VeRO programme (user rule 2026-10-03). If the brand is a VeRO participant, reject. If VeRO status cannot be checked, the brand check is `UNKNOWN`. Genuine branded goods only; counterfeits and replicas stay banned (below).
- breakables / fragile items (including fragile ornaments)
- adult products
- counterfeit or replica items
- tobacco and related products
- clothing and shoes, **except free-size / one-size clothing items with no size options** (user rule 2026-10-13: no size choice means no wrong-size returns). Sized clothing, shoes and anything with size variations stay rejected.
- **large electronics** (user rule 2026-10-14, replaces the earlier battery and AliExpress electronics wording): reject TVs, fridges and other large appliances, laptops, tablets, mobile phones and similar high-value or bulky electronics. **Small consumer electronics are allowed from every source** (Amazon UK, Go Dropship UK and AliExpress UK), including battery-powered and mains-powered items, cables, chargers, lamps, fans, gadgets and accessories. All allowed electronics remain subject to every other rule (price, weight, VeRO, etc.) and are recorded as compliance risks where safety-regulated (UKCA/CE marking, batteries, chargers, mains plugs).
- legally prohibited items
- food and drink products (all sources; includes alcohol)
- bulky items that are expensive to ship
- copyrighted or trademarked characters
- branded seasonal merchandise, unless the user explicitly approves it
- products with long international delivery
- products whose demand lasts only a few days
- products that cannot realistically arrive before the relevant event or seasonal cutoff

## 5. Amazon sourcing workflow
Paused by the user on 2026-11-25. Full text: `prompts/suppliers/amazon_uk.md` (§5.1–§5.9a keep their numbers).

## 6. AliExpress sourcing workflow
Full text: `prompts/suppliers/aliexpress_uk.md` (§6.1–§6.9 keep their numbers). Read it before AliExpress research.

## 7. Go Dropship workflow
Full text, with §7a quality rules: `prompts/suppliers/go_dropship_uk.md`. Read it before Go Dropship research.

## 7b. Other suppliers
AW Dropship (daily source): `prompts/suppliers/aw_dropship.md`. Pound Wholesale (stock model, only when the user asks): `prompts/suppliers/pound_wholesale.md`.

## 8. (Removed) Morrisons workflow
Morrisons UK was removed as a sourcing site on 2026-10-03 at the user's instruction: dropshipping from Morrisons is not allowed. Do not research or source from Morrisons. The section number is kept so that references to §9 onwards stay valid.

## 9. eBay verification workflow
Use eBay UK and, where available, Seller Hub Product Research. Search filters:
- Buy It Now
- Condition: New
- Location: UK only (item location United Kingdom)
- **Always applied (user rule 2026-10-12):** Buy It Now, Condition New and Item location UK are set on every eBay search (active counts, sold searches and seller/listing lookups alike). In ZIK use Fixed Price, Brand New, shipping location United Kingdom, and the Sellers Country filter for the UK where it is offered; URL searches use LH_BIN=1&LH_ItemCondition=1000&LH_PrefLoc=1.
- Sold items
- If selecting Sold automatically enables Completed, keep the results focused on sold items. Do not count all completed listings as demand.

Capture evidence for:
- sold quantity / sales velocity
- sell-through rate
- average sold price
- sold price range
- number of sellers
- trend direction
- shipping cost
- seller examples
- dates and the research window

For evergreen products, require evidence of demand across multiple months or seasons where possible.

**Sell-through rate when eBay Product Research is not available:** use the sell-through rate reported by **ZIK Analytics** (Product Research, ebay.co.uk, shipping location United Kingdom, the research window recorded). It is recorded as a third-party tool figure (`str_source` = ZIK) and judged against the §3 20% gate. **Superseded 2026-11-04 (user):** the sell-through is now calculated by hand (items sold ÷ active listings × 100, active listings from the eBay UK Buy It Now / New / UK count; `str_source` = HAND) and judged against the §3 **40%** gate; ZIK supplies only the sold-items count.

**Competitor store research (user rule 2026-10-06):** when a product passes eBay verification and profit, the agent takes that reference seller's eBay shop name, analyses the shop in ZIK Analytics (Competitor Research, ebay.co.uk, UK, 30 days), lists its best-selling products, and searches for the same products on Amazon UK, AliExpress UK and Go Dropship UK. Each match is then run through the full workflow (source rules, eBay verification, profit, compliance) and counts towards that source's daily budget. **This runs first in each hunt** (user, 2026-10-06), seeded with the reference sellers of products that passed in earlier runs and earlier today; normal searching is the fallback. No rule is relaxed for these products, and the seller is never contacted. Steps are in `prompts/daily_hunt.md` Step 6b.

On competitor eBay listings, use the **Sold History Button extension** to read recent sales. Seller Sprite and Keepa are Amazon tools; Sold History Button is the eBay tool.

**eBay first (user rule 2026-10-08):** each hunt starts from eBay demand: competitor stores, then ZIK Product Research and eBay sold search on the day's themes. The products found selling well are then looked for on the source sites. Source-site best-seller browsing is only the fallback (`prompts/daily_hunt.md` Step 5a).

**Always complete eBay verification (user rule 2026-10-08):** every product forwarded from a source gets a finished eBay check; "eBay verification not run" is not an acceptable end state.

**No exact match / size not found (user rule 2026-10-08):**
- If no matching eBay listing exists, use the **closest similar listing with 5+ sales in the last 30 days** (same product type; Buy It Now, New, UK) for price and demand. If the product passes every rule on that basis, it passes with the note "No exact match found on eBay; closest similar listing used". If no similar listing has 5+ sales, demand is not shown and the product does not pass.
- If the source doesn't state the size but it is the same item on both sites, use the **nearest possible match** and pass it if every rule passes, with the note "Size not found; nearest possible match used".

**Variations (user rule 2026-10-12):** when the competitor listing or the source has variations (sizes, colours, packs), always use the **highest-selling variant** for the price comparison and the source cost. Where the platform shows no per-variant sales, record that the highest-selling variant could not be determined and say which variant was used. **From 2026-11-25 (user): up to 3 variants (maximum 3) that are selling well on eBay may be selected for one product. The best seller is variant 1. Each selected variant must pass every gate itself and gets complete information of its own (§18).**

Do not invent any metric that was not observed.

## 10. Profit calculation
Prefer observed eBay fee-calculator results. Otherwise use the fee assumptions configured in `config.yaml`. If an exact fee is unavailable, do not invent it. Mark the calculation as `ESTIMATED` and record the assumption used.

```
total_cost    = source_price + sourcing_buying_fee + eBay_fees + ad_cost + other_known_costs
profit        = suggested_listing_price - total_cost
profit_margin = profit / suggested_listing_price
ROI           = profit / (source_price + sourcing_buying_fee + other_known_costs)
```

Also record:
- `minimum_listing_price`: the lowest price that still meets the §3 profit and margin rules (user rule 2026-10-08):
  - under £8 (3% ads): (item cost + £1.00 + fixed fees) ÷ (1 − eBay fee rate − ad rate), if that comes out under £8;
  - otherwise (5% ads): the higher of £8, the £1-profit price, and the lower of the 30%-margin price (item cost + fixed fees) ÷ (1 − eBay fee rate − ad rate − 30%) and the 20%-ROI price (item cost × 1.20 + fixed fees) ÷ (1 − eBay fee rate − ad rate).
  - "fixed fees" = per-order fee + insertion fee (when included); other known costs (sourcing buying fee, source delivery) are added to the item cost.
  - A candidate passes the economics only if the competitor's listing price is at or above `minimum_listing_price` (and within £2–£35).
- **Baseline price only (user rule 2026-10-04, all sources):** the item cost is always the supplier's/seller's **baseline price** for the **exact variant** to be sold. It is the price every repeat order pays.
  - **Never used:**
    - welcome deals, first-order or new-shopper prices (e.g. £0.01 / £0.99);
    - coupons, vouchers, coins and store or platform codes;
    - flash, sale, limited-time or "x% off" discounted prices, and front-page or promotional prices;
    - bundle or multi-buy prices ("Bundle for Less", "£0.94 each ≥ 2");
    - Subscribe & Save;
    - the cheapest-variant "from" price ("bait" accessory variants).
  - When a discounted price is shown next to a "was" or original price, the baseline is the undiscounted seller price. If the baseline cannot be seen, the cost is `UNKNOWN`.
  - **Shipping:** "free shipping" is only counted if it applies to a **single-item order** of that variant. For AliExpress Choice items whose free shipping needs a minimum basket value, the standalone shipping fee shown for one item is added to the cost. If it is not shown, shipping is `UNKNOWN`.
  - The checkout and basket are never opened to find out (§24).
- **Item cost** (`source_price`): always the item price on the sourcing website (Amazon UK, AliExpress UK or Go Dropship UK), applying the baseline rule above. **For Amazon:** the higher of today's price and the highest Keepa Buy Box price held for more than 5 consecutive days in the last 3 months (§5.4). **For AliExpress:** the higher of today's repeatable price and the highest price held for 5+ days, where a price history is visible (§6.6).
- `sourcing_buying_fee`: **Go Dropship UK 5% of the item cost (user rule 2026-10-20, `fees.sourcing_buying_fee_rate_godropship` = 0.05)**; Amazon UK and AliExpress UK 0% (user rules 2026-10-13; `fees.sourcing_buying_fee_rate` and `fees.sourcing_buying_fee_rate_amazon` are 0). An exact buying or handling fee shown on a source page is still used.
- `suggested_listing_price` (listed price): always the **eBay competitor's listing price**: the reference competitor recorded at eBay verification, total buyer price (item + postage).
  - **Reference competitor selection (user rule 2026-10-04; top 20 added 2026-10-05):** a matched listing from the **top 20 sellers by 30-day sales** for the product (same product and size; Buy It Now, New, UK), from a seller of **any size** (the under-20,000 feedback limit was dropped for all sources on 2026-10-14) that has **at least 5 sales in the last 30 days** (user rule 2026-10-06).
  - Among those, the one whose price gives the **best profit meeting all our criteria**: at or above `minimum_listing_price`, £2–£35, £1+ profit, and the margin rule (§3).
  - If no such seller has a qualifying price, the product fails the price check.
- **Cost safety (user rule 2026-10-12):** (a) every profit row records `max_safe_cost`: the highest item cost at which the competitor price still gives at least GBP 1 profit and meets the margin/ROI rule (§3); the user ends or reprices a listing if the source price rises above it; (b) for **AliExpress** the profit test is also run with the item cost **raised by 6%** (user rule 2026-10-13; was 10%) (`cost_buffer_gate`); a product that fails at +10% does not pass; (c) the earlier AliExpress 3-separate-days price check was **removed on 2026-10-12** (user); AliExpress past-price history now comes from (1) a price-history browser extension on item pages, once the user has installed one (user approved 2026-10-12; the agent never installs extensions itself), and (2) the agent's own log `data/price_watch/aliexpress_price_log.csv`, to which **every AliExpress price read in incognito is added with its date**. Where an extension chart is visible, the AliExpress cost follows the Keepa-style rule: the highest price of the last 3 months that stayed for at least 5 days, or today's price if higher; without a chart the cost is the incognito price of the day, marked history UNKNOWN.
- **Go Dropship remote-area surcharge (user rule 2026-10-13):** Go Dropship delivers free to the UK general area, but charges extra postage to Outer Hebrides/Shetland, Northern Ireland, Channel Islands, Scottish Highlands and Islands, Scilly, Isle of Wight and Isle of Man (shipping page, `https://www.godropship.co.uk/shipping-tracking.html`, read 2026-10-13). Worst-case surcharge by parcel weight: up to 2 kg GBP 2; 2.1-15 kg GBP 8; 15.01-30 kg GBP 24; over 30 kg GBP 50. Every Go Dropship profit row records `remote_surcharge_worst`, `profit_if_remote_surcharge` and `remote_surcharge_gate`; for parcels **over 2 kg** the product is flagged `REMOTE_RISK` when profit after the worst surcharge is below GBP 0. It is a recorded risk, not a pass/fail gate, and the eBay listing price and normal profit test are unchanged.
- `ad_rate`: the promoted-listing rate used. State it explicitly. By listing price (user rule 2026-10-08): **3% under £8**, **5% from £8**; a higher rate may be used, never a lower one. **Exception, Amazon-sourced products (user rule 2026-10-13): 3% at every listing price** (`config.yaml` `fees.ad_rate_amazon`). Because the user is not VAT registered, VAT (20%) is added to the ad cost: ad cost = ad rate × listed price × 1.20 (3% → 3.6%, 5% → 6% of the sale).

eBay fees: use eBay's **current** fee data, observed at the time of calculation (e.g. eBay's fee page or calculator for the category), with the URL and date recorded. In practice (user rule, 2026-10-03):
- every run records eBay's **business-seller** fee page (the user is a business seller, sole trader) into `data/fees/YYYY-MM-DD_ebay_business_fees.csv`;
- each product's fee = (final value fee for its eBay category + regulatory operating fee) × listed price + per-order fee (by order total, including any reduced fee eBay lists for the category);
- the user is **not VAT registered**, so eBay's VAT (20%) is added to these fees;
- the insertion fee (£0.36, already including VAT) is added when over the free listing allowance;
- no fixed fee percentage is used. If today's fee page was not recorded, or the product's eBay category is unknown, the fee is `UNKNOWN`. If the user provides a profit-calculator tool, enter the current eBay fee and the ad rate (minimum 5%, plus VAT) into it, record its inputs and outputs as evidence, and cross-check them against `tools/profit_calc.ps1`.

## 11. Competition analysis
For each candidate, record:
- total seller / listing count (no gate since user rule 2026-10-23; record it for information)
- among the top 20 sellers: number with 500+ total sold (**gate: 2+**, user rule 2026-11-04; was 3+ with 500+, earlier 2+ with 1,000+) and number with 30+ sales in the last 30 days (**gate: 3+**, user rule 2026-11-04; was 50+); both hard gates from 2026-10-17 (user rule; were preferences)
- seller-size evidence: record the feedback count of the top sellers for information only (the small-seller preference was dropped for all sources, user rule 2026-10-14)
- for Amazon-sourced items, competitor sellers with 5–10+ sales in the last 30 days
- example seller(s), with URLs
- signs of saturation, price wars or dominance by large or branded sellers (record in `rejection_risk`)

## 12. Evergreen strategy
- Evergreen research runs every day, whatever the season.
- (User rule 2026-10-14: the sales-trend requirement is cancelled.) Evergreen candidates are no longer rejected for their sales trend; the trend is only described in `trend_description` (steady trend / event / season / yearly pattern).
- Where possible, check that demand spans several months or seasons.
- Good evergreen categories: generic, giftable, problem-solving, home, organisation and storage products that meet §3 and §4.

## 13. Dynamic seasonal strategy
Before every hunt, run the Seasonal Planning Engine:
1. Determine today's UK date.
2. Load `data/event_calendar.yaml`.
3. Calculate the dates of fixed and movable events for the current year (and the next year where relevant), using a reliable calendar source. Never hard-code dates from examples.
4. Calculate the days until each event.
5. Calculate the preferred and minimum listing start dates (§14).
6. Assign each event a phase (§15).
7. Select the current event and next-event priorities.
8. Set the daily mix (§16).

Event priority: use a `priority` value only where it is explicitly set for that entry in `data/event_calendar.yaml`. Otherwise report it as `Not defined`. Do not invent priority labels (e.g. High/Medium/Low/Monitor), and never use priority to change the 50/30/20 allocation.

Minimum event themes:
- Christmas
- Valentine's Day
- Easter
- UK Mothering Sunday
- Father's Day
- Halloween
- Black Friday
- Cyber Monday
- New Year
- summer/outdoor season
- back-to-school
- winter season

Rules for event-specific products:
- Prefer products that stay useful after the event (hybrid) over products whose demand lasts only a few days.
- Avoid copyrighted or trademarked characters, branded event merchandise (unless explicitly approved) and fragile decorations.
- The product must be able to reach a UK buyer before the event.

**Christmas priority order** (used whenever Christmas is the current or next event):
1. Christmas gifting
2. Christmas home/party/entertaining
3. Christmas organisation/storage
4. winter/holiday utility that remains useful after Christmas
5. generic giftable problem-solving products

`seasonality` label for every candidate: `evergreen`, `christmas`, `winter`, `christmas_plus_evergreen` or `unclear`. Other events may use the same pattern, e.g. `<event>` or `<event>_plus_evergreen`.

## 14. 60-day preferred and 30-day minimum seasonal planning assumption
- **Preferred listing start** = event date − 60 days.
- **Minimum listing start** = event date − 30 days.

> **This is a BUSINESS PLANNING ASSUMPTION supplied by the user. It is NOT an eBay rule or guarantee.** eBay does not guarantee that a listing will rank, be indexed or sell within 30 or 60 days. Never claim or imply otherwise in any report.

The values live in `config.yaml` (`preferred_listing_lead_days`, `minimum_listing_lead_days`). Changing them requires a CHANGE_PROPOSAL.

## 15. Seasonal phases
`days_until_event` = event date − today's UK date.

| Days until event | Phase | Default recommended_action |
|---|---|---|
| more than 60 | `PREPARE_EARLY` | Research and shortlist now. Plan to list by the preferred start date. |
| 30 to 60 (inclusive) | `START_NOW` | Prioritise. List as soon as approved. |
| 0 to 29 | `LATE_EVENT_WINDOW` | Only fast UK-delivery products that can arrive before the event. Prefer hybrid products. Flag the late timing. |
| less than 0 (event passed) | `POST_EVENT` | Do not source new event-only products. Review existing ones for clearance, KEEP (if hybrid) or RETIRE. |
| seasonal window started, today ≤ season end date | `IN_SEASON` | See below. |

### IN_SEASON
A seasonal window has started and today is on or before the season's end date. This applies only to date-window seasons (`type: window` in `data/event_calendar.yaml`). It takes precedence over the days-until phases while the window is open. Once the end date has passed, the season is `POST_EVENT`.

Action:
- Continue researching products while there is evidence of demand.
- Prioritise products that can still reasonably sell within the remaining season.
- Do not automatically stop researching simply because the preferred or minimum preparation date has passed.
- Continue to apply all normal product, profit, competition, compliance and supplier criteria.
- Report the remaining days in the season.

## 16. Default 50/30/20 allocation
The default daily mix across all accepted candidates:
- 50% evergreen
- 30% current event
- 20% next-event preparation

With a 15-product target, that is 8 evergreen, 4 current event and 3 next-event preparation (7.5 / 4.5 / 3, rounded as `tools/daily_report.ps1` does). The mix is applied to the daily total, not to each source's 5 products. Show the per-source breakdown in the summary.

The agent may adjust the mix when the calendar justifies it (for example, no event is in START_NOW, or two events overlap). It must record the adjusted mix and the reason in the daily summary. Changing the *default* mix requires a CHANGE_PROPOSAL.

## 16a. Pre-event selection for winter and Christmas products (user instruction 2026-10-14; method devised by the agent, thresholds open to the user's adjustment)
**Purpose:** the user lists seasonal products **before** the event so the listings build ranking and history by the time buying starts. For these products the eBay "5+ sales in the last 30 days" tests (reference competitor §10, small-seller preference §3/§11) cannot be used, because eBay demand has not started yet. They are replaced by the four tests below. Everything else (source rules, profit, fees, buffers, compliance, §4 avoid list) is unchanged. Applies only to products whose `seasonality` is `christmas`, `winter`, `christmas_plus_evergreen` or another event label while the event is in `PREPARE_EARLY` or `START_NOW`; other products keep the normal rules.

1. **Source demand now (replaces eBay 30-day sales).** Amazon: 500+ bought in the past month (§5.1). Go Dropship: on the Weekly Top / Bestselling lists, or 1,000+ in 30 days (§7.1). AliExpress: Choice and 500+ sold (§6.1).
2. **Event relevance proof (any ONE of these; revised 2026-10-14 so products can be selected now).** Record which one and the evidence:
   - **(a) eBay lifetime proof:** at least 3 listings from at least 2 sellers for the same or a near-identical product (Buy It Now, New, UK) each with lifetime sold 20 or more, or one seller with 1,000+ total sold;
   - **(b) Product-type proof:** the product type (for example Christmas lights, hot water bottle, twig tree, window clings, hand warmers) has at least 3 eBay sellers with 50+ lifetime sold on listings of that type, even if not this exact item;
   - **(c) Seasonal label proof:** the product is clearly event-specific or winter-specific by its own use (Christmas, advent, festive, winter, frost, snow, heated, thermal) **and** the source demand in test 1 is met. This needs no eBay sales at all.
   Test 1 (source demand now) plus any one of (a), (b) or (c) is enough.
3. **Reference price from active listings (replaces the 30-day reference seller).** Take the **median price of the 5 lowest-priced credible active listings** (same product and pack, free or included postage, seller under 20,000 feedback preferred) and use it as `suggested_listing_price`. It must be at or above `minimum_listing_price`, and **at least 3 active listings must be priced at or above `minimum_listing_price`** (so the price holds). Record the listing URLs. `ebay_sales_last_30d` is recorded but not gated.
4. **Timing and stock.** The listing-ready date must be before the event: `days_until_event` at least 14 for the event, and the product can be listed by the preferred listing start (§14) or immediately if that date has passed. Seasonal stock minimums apply (Go Dropship 50+ §7a.1, AliExpress 50+ §6b, Amazon in stock). Delivery must arrive before the event.

**Checks that stay:** profit, margin/ROI, buffers, `max_safe_cost`, variations, weight, VeRO/IP, compliance, Keepa stability for Amazon.

**Labels and follow-up:** such a product is marked `sales_basis = PRE_EVENT` in the report and `recommended_action` follows the §15 phase. It is **rechecked at event minus 30 days** and again at event minus 14 days: if it still shows no eBay sales and no rising watchers or views, it is marked `DEPRIORITISE` (and `RETIRE` after the event for event-only items). The agent never lists anything (§25); this method only chooses what to recommend for the user to list.

## 17. Five accepted products per source
Each run targets 5 accepted candidates per source:
- Amazon UK: 5
- AliExpress UK: 5
- Go Dropship UK: 5

If fewer than 5 from a source pass all gates:
- do NOT pad the report with weak products;
- report the shortfall and the rejection reasons;
- keep searching until the configured research budget is used up.

**Stop rule per source (user rule 2026-10-05):** research on a source continues until **5 products from that source have passed every gate** (source rules, eBay verification and profit), **or 35 products from that source have been evaluated**, whichever comes first.
- A source is never stopped early because yield is low, most products are FBA, or the basket fills (notify and pause instead, §5.2).
- Only a site block, login or CAPTCHA (§27) may end a source before either limit; the shortfall is reported.
- Amazon follows exactly the same rule as the other sources (user rule 2026-10-05; the separate "at least 15 Amazon products" minimum was removed).
- Pass/fail is judged per product as research goes (eBay check and profit for each forwarded product), so the agent knows when 5 have passed.

## 17a. Source preference by product type and delivery speed (user rule 2026-10-12)
These are **preferences for choosing and routing sources**, not gates: every source rule (§5-§7) and every gate still applies.
- **Branded items** (genuine, non-VeRO brands, §4): prefer **Amazon UK**.
- **Generic / unbranded items:** prefer **Go Dropship UK and AliExpress UK**.
- **Faster delivery:** prefer **Amazon UK and Go Dropship UK**, which are UK based and deliver faster; **AliExpress** is China based and takes longer, so it is the choice only when its economics clearly beat the UK sources or speed does not matter (for example winter products already listed ahead of the season).
- **Same product on several sources:** when the economics are close, keep the source that fits these preferences (branded -> Amazon; generic -> Go Dropship/AliExpress; delivery-sensitive -> Amazon/Go Dropship). The economics-differ-materially rule (§18, deduplication) still decides first.
- **Research routing:** when a product is found on eBay, check the preferred source(s) for its type first, then the others. Record the delivery estimate of each source in the report so the speed trade-off is visible.

## 18. Fifteen-product daily target
Target: **15 accepted candidates per day** (3 sources × 5).

This is a target, not a quota to fill. A day with fewer than 15 accepted candidates is a valid result, as long as the shortfall is reported honestly.

### Scoring
Apply the hard gates (§3, §4, source rules, compliance) first. Score only the candidates that survive them (0–100):
- eBay demand: 25
- profit economics: 20
- ROI: 15
- competition quality: 15
- sourcing reliability: 10
- seasonal fit / current timing: 10
- shipping/operational simplicity: 5

Never turn a failed hard gate into a pass by giving it a high score.

### Deduplication
Do not return the same product more than once in the same daily report. Deduplicate across sources by:
- normalised product identity
- UPC/EAN/GTIN where available
- close title plus matching image/specification
- source SKU

If the same product appears on more than one source, keep separate records only if the economics differ materially. Otherwise flag it as a duplicate and keep the strongest sourcing option.

### Daily deliverables
Each run creates:
- `data/daily/YYYY-MM-DD_ebay_product_hunt.xlsx`: the **human review workbook** (Daily 20, Rejected, Rejection Details, All Evaluated, Summary, Seasonal Plan; clickable links to stored URLs only). It changes presentation only, never what qualifies.
- `data/daily/YYYY-MM-DD_candidates.csv`
- `data/daily/YYYY-MM-DD_rejections.csv`
- `data/daily/YYYY-MM-DD_seasonal_plan.md` (seasonal planning summary)
- `data/daily/YYYY-MM-DD_summary.md`

The full daily workflow is in `prompts/daily_hunt.md`. The final decision and these files are produced by `tools/daily_report.ps1`. Existing daily files are never overwritten; a second run on the same day writes `YYYY-MM-DD_runN_*`.

The summary must include:
- the research timestamp (UK time)
- today's event calendar: events, dates, days until each, phases, and preferred/minimum listing start dates
- the allocation used (50/30/20 or adjusted, with the reason)
- per-source target (5) vs actual, and total target (20) vs actual
- top candidates by score
- all shortfalls
- main rejection reasons
- compliance-review items
- candidate lifecycle/priority changes (§21)
- any conflicts or CHANGE_PROPOSALs raised

### Required candidate fields
`date_found`, `source`, `product_name`, `source_url`, `source_price`, `source_stock`, `source_rating`, `source_sales`, `source_delivery`, `source_seller_type`, `ebay_search_url`, `ebay_example_seller`, `ebay_sold_price`, `ebay_average_price`, `ebay_sell_through_rate`, `ebay_seller_count`, `ebay_sales_last_30d`, `small_seller_evidence`, `ebay_fees`, `ad_rate`, `estimated_total_cost`, `minimum_listing_price`, `suggested_listing_price`, `estimated_profit`, `profit_margin`, `roi`, `variations`, `weight`, `seasonality`, `compliance_status`, `criteria_relaxed`, `rejection_risk`, `evidence_urls`, `confidence`, `notes`

**Links and codes (user rule 2026-11-25):** every selected product also has `ebay_listing_url` (the eBay listing itself, `ebay.co.uk/itm/...`), `ebay_item_number`, `source_url` (the product page on the sourcing site, never its homepage), `source_item_code` (item code / SKU / product number) and `source_variant_code` (`none` if it has no variations, `UNKNOWN` if the site shows no code). Each selected variant (maximum 3) has its own row: variant name, item code, variant code, both links, eBay variant and item number, seller, 30-day sales with evidence, source price, landed cost, stock, delivery, weight, eBay price, fees, ad cost, total cost, minimum price, profit, margin, ROI, buffer profit, max safe cost and result (`variants.csv` and the workbook's Variants sheet).

Plus the lifecycle fields (§21): `product_type`, `target_event`, `event_date`, `preferred_listing_start`, `minimum_listing_start`, `days_until_event`, `recommended_action`, `seasonal_confidence`.

## 19. Historical research
- **Never delete historical research.** Once a run is finished, its daily files are a permanent record. Do not overwrite or remove them.
- Any correction to a past file must be added as a new, clearly dated note. Never edit the past data silently.
- Before each hunt, review previous candidates. Use that review for deduplication, for spotting repeat winners, and for lifecycle updates (§21).
- Research history is kept in `data/history/` by `tools/history.ps1` (see `prompts/stages/research_history.md`). `status_log.csv` and `rejection_history.csv` are append-only. Before researching a product, check the history to avoid unnecessary repeat research; products not yet due are skipped unless a recheck trigger is observed. The recheck intervals and WATCH limit (`config.yaml` `history`) are **operational defaults, not business rules or selection criteria**. Changing them does not change this rulebook and needs no CHANGE_PROPOSAL.

## 20. Rejection tracking
Every product that was evaluated and rejected is logged in `data/daily/YYYY-MM-DD_rejections.csv`, with at least:
- `date`, `source`, `product_name`, `source_url`
- `failed_gate`: the specific rule that failed, e.g. "sell-through < 20%", "VeRO brand" or "weight >= 5 kg"
- `observed_value` and `threshold`
- `evidence_urls`
- `notes`

Products dropped as duplicates are logged too, with `failed_gate = DUPLICATE`. The daily summary aggregates the main rejection reasons.

## 21. Product lifecycle
Every accepted candidate must contain:
- `product_type`: `evergreen` / `seasonal` / `hybrid`
- `target_event`: the event name, or `NONE` for evergreen
- `event_date`
- `preferred_listing_start`
- `minimum_listing_start`
- `days_until_event`
- `recommended_action`: based on the phase (§15)
- `seasonal_confidence`

During the daily review, re-mark each previous candidate as:
- `KEEP`: still meets the gates and the timing is good
- `WATCH`: borderline, or the data is changing
- `DEPRIORITISE`: weakening demand or economics, or a poor time in the calendar
- `RETIRE`: no longer viable (gate now failing, event passed for a seasonal-only product, etc.)

Status changes are reported in the daily summary. The original records are never deleted (§19).

**Full status set** (research history): `NEW`, `RESEARCHED`, `QUALIFIED`, `APPROVED`*, `LISTING_READY`*, `LISTED`*, `WATCH`, `KEEP`, `DEPRIORITISE`, `RETIRE`. (*Set only on the user's instruction; the agent never overwrites them and never lists anything, §23–§25.)
- A product is **never permanently blacklisted for a failure that may change** (source price, stock, delivery, eBay demand, competition, season, fees, access). Such products go to `WATCH`, or to `DEPRIORITISE` after repeated failures, and are rechecked.
- `RETIRE` is used only for intrinsic §4 failures (avoid list, brand/VeRO, IP/character, counterfeit). Only the user can reopen a RETIRE product.

## 22. Compliance checks
eBay's policy allows dropshipping from a wholesale supplier. It does **not** allow listing an item and then buying it from another retailer or marketplace to ship directly to the buyer. Do NOT assume a retailer-to-consumer model is allowed just because the source site sells the product.

- Amazon and AliExpress (retailer-sourced) candidates: mark as `COMPLIANCE_REVIEW` unless the sourcing arrangement is shown to be compliant.
- Go Dropship candidates: `COMPLIANCE_REVIEW` or `PASS`, depending on the evidence of the supplier relationship.
- Also check against §4: VeRO (a brand is allowed only if it is not a VeRO participant), legally prohibited items, food and drink, and IP (characters, logos). Legally restricted items (e.g. age-restricted products) and safety-regulated categories are not automatically rejected; record them as compliance risks for the user's review.
- Never fabricate supplier relationships to obtain a `PASS`.

## 23. Human approval requirements
The user must explicitly approve each of the following. The agent prepares the recommendation; the user decides:
- buying any stock or sample
- creating, publishing, revising or ending any eBay listing
- contacting suppliers or setting up supplier accounts
- signing up for, or paying for, any tool, subscription or service
- logging in to any account with the user's credentials
- clearing a `COMPLIANCE_REVIEW` item for action
- accepting a candidate that relies on a relaxed rule, before any action is taken on it
- any change to this rulebook or to the default planning settings (§28)

## 24. No automatic purchasing
The agent never buys, adds to a basket for checkout, places orders, enters payment details or commits money on any site.



**Basket clean-up is the user's job (user rule 2026-10-05):** when Seller Sprite's stock check leaves items in the Amazon basket, the agent notifies the user and pauses until the user says the basket is clear (§5.2). The agent does not delete basket lines.

(Superseded: from 2026-10-04 until 2026-10-05 the agent deleted those lines itself after the user approved.)

## 25. No automatic eBay publishing
The agent never creates, drafts on the live account, publishes, revises, promotes or ends eBay listings. Its output is research reports only.

## 26. No fabricated data
- Never fabricate stock, sales, ratings, delivery times, fees, sell-through, seller counts, prices, trends or supplier relationships.
- Every factual field needs an observable source where possible, with a URL and a timestamp.
- Never infer exact sales, stock, delivery, fees or profit from a generic page when the data for the exact product is unavailable.
- If a metric is unavailable, write `UNKNOWN`. Do not guess.
- Estimated values must be labelled `ESTIMATED`, with the assumption stated.

## 27. No CAPTCHA or anti-bot bypassing
Never bypass, solve or evade CAPTCHAs, anti-bot controls, rate limits, paywalls, logins, access controls or a site's terms and restrictions. If a site blocks access, stop on that site. Record the source as blocked, with the reason, and report the shortfall. Do not try workarounds.

## 28. CHANGE_PROPOSAL process
The agent **may** update these without asking: event calendar data (computed dates, new event entries consistent with §13), seasonal priorities within the existing rules, candidate lifecycle status, and reports.

The agent **must NOT** silently change any core business rule. That includes any threshold, gate, avoid-list item, source rule, compliance rule, approval requirement, the 60/30-day planning assumption, the default 50/30/20 mix and the 5/15 targets, whether in this file or in `config.yaml`.

If a rule appears to need changing:
1. Write a `CHANGE_PROPOSAL` block in the daily summary (or in reply to the user) containing:
   - the rule affected (section number and current wording)
   - the proposed new wording
   - the reason and the supporting evidence
   - the expected impact
2. Ask the user for approval.
3. Keep applying the current rule until the user approves.
4. After approval, update the rulebook and note the change in `docs/rulebook_changelog.md`.

## 29. Operating loop and self-improvement (user instruction 2026-11-25)
Full procedure: `prompts/operating_loop.md`. It changes how the agent works, never what qualifies.
- **Tools first:** look in `tools/` before doing a job by hand. Scripts do the exact work; the agent decides and checks.
- **Start:** run `tools/preflight.ps1`; fix every FAIL before researching. **Before each product:** `tools/dedupe_check.ps1`. **End:** run `tools/run_close.ps1`; a run is finished only when it says COMPLETE or the missing items were reported.
- **On any failure, wrong result or user correction:** search and log it (`tools/lessons.ps1`), read the script, fix the cause, add a test in `tests/`, update the workflow, close it with proof. Then check what it already damaged and tell the user.
- **Two different attempts, then move on** with the workaround recorded.
- **Never changed by the loop:** business rules and thresholds (§28), `tools/browser_guard.ps1`, `.claude/settings*.json`, permissions, the approved site list, past research (§19), or a test just to make it pass. §23–§27 apply unchanged.

### Change log
Moved to `docs/rulebook_changelog.md` (newest first). Add every rule change there, and update §0 and the section it affects.
