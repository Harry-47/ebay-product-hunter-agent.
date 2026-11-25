# Go Dropship UK: supplier rules (ACTIVE)

This is the full rule text moved unchanged from CLAUDE.md on 2026-11-25; section numbers are the same. It contains dated history: the current values are in CLAUDE.md section 0, and the newest user instruction in docs/rulebook_changelog.md applies where they differ.

## 7. Go Dropship workflow
1. Look for hot-selling or highest-sales items from the last 30 days. Demand rule (same for all sources, user rule 2026-10-03): valid if it is best-selling (e.g. on the Weekly Top / hot-seller list or a category's "Bestselling" sort) **or** it sold **1,000+ in the last 30 days** where a sales figure with that period is shown (500+ was tried on 2026-10-05 and reverted the same day at the user's instruction).
2. **Go Dropship criteria (user rules 2026-10-04):**
   - Warehouse location: **UK**. Record the warehouse shown; if none is shown, `UNKNOWN`.
   - Stock: **20+ units** (high stock). A stock figure under 20 fails. "In stock" with no number is `UNKNOWN`.
   - Delivery: **at most 5–7 days** (user rule 2026-10-06; was next day to 2–3 working days). The service's quoted maximum must be 7 days or less, so services such as Royal Mail Large Letter (3–7 business days) now pass. Anything quoted over 7 days fails; not shown is `UNKNOWN`.
   - Profit margin: the §3 margin rule applies to all sources (from 2026-10-08): 30%+ margin (or 20%+ ROI) when the listing price is £8 or more; £1 profit alone under £8. The earlier Go Dropship "30% preference only" is replaced by it.
3. Verify eBay demand and economics (§9).
4. Calculate eBay fees and profit (§10).
5. Compliance status is `COMPLIANCE_REVIEW` or `PASS`, depending on the evidence of the supplier relationship (§22).

## 7a. Go Dropship quality rules (user rules 2026-10-12)
Applied on top of §7. Rules 1, 3 (the 5% buffer) and 8 are tested by `tools/profit_calc.ps1`; the others are checked by hand and recorded in the stage notes.
1. **Stock (user rule 2026-10-24: 20 / 50):** UK stock of at least **20** (at least **50** for seasonal items); it was 50 / 100 from 2026-10-12 (§7.2 also says 20+). Decided on the day's reading (user rule 2026-10-17: no second-day stock check).
2. **Tracked delivery preferred:** "Tracked 2 Business Days" is preferred over Royal Mail Large Letter with no tracking. Large Letter stays allowed only when the eBay price is under about GBP 10, flagged as a not-received dispute risk; reject it for dearer items.
3. **Price freshness and buffer:** read the "Price updated on" date on the product page; flag prices older than about 6 months as stale. **The 5% cost buffer was removed on 2026-10-14 (user)**: Go Dropship is tested at the item cost without a buffer (`cost_buffer_gate` = N/A); `max_safe_cost` is still recorded.
4. **Crowded-title check:** count how many eBay sellers use the exact Go Dropship title; prefer products with few, and report the count.
5. **Low-return products:** avoid sizing items with more than 3 variations, electrical or safety-regulated items, health claims and under-3 toys without a stated safety mark; record them as compliance risks (not automatic rejections).
6. **Bestseller check:** the product appears on the category's Bestselling page 1 on the day of research (user rule 2026-10-17: the "2 separate days" repeat check is dropped).
7. **Weight and size:** prefer under 1 kg and small parcels; the weight limit is 2 kg, and there is no limit when Go Dropship delivery is free (user rule 2026-10-18, §3; was 4 kg from 2026-10-13); skip bulky items.
8. **Margin cushion:** prefer ROI of at least **30%**; ROI under 25% is flagged `THIN` (`thin_margin_flag`).

9. **Price stability (user rule 2026-10-17):** only Go Dropship products with a **stable price** are accepted, to avoid loss from supplier price rises. Go Dropship shows no price history, so stability is judged from (a) the "Price updated on" date: a price unchanged for 6+ months counts as stable; a price updated within the last 6 months is decided on the day's data and passes with the flag `PRICE_RECENTLY_CHANGED` (user rule 2026-10-17: no repeat read on a later day); and (b) the agent's own log `data/price_watch/godropship_price_log.csv`, to which every Go Dropship price read is added with its date (price, stock, "Price updated on"). If the log already holds an earlier read with a different price, the product fails. The §7a.3 "older than 6 months = stale" flag no longer counts against a product; an old date is evidence of stability (the agent still notes it, because the listed price may no longer be current if it was never refreshed).

