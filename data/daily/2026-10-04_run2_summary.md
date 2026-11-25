# Daily product hunt - 2026-10-04

Report generated 2026-10-05 18:58 UK. Research files: data/sources, data/ebay, data/profit, data/seasonal (2026-10-04).
Research only: nothing was purchased, listed or published. Retailer-sourced items stay COMPLIANCE_REVIEW until the user clears them (CLAUDE.md s22-s25).

## Run notes (blocked sources, conflicts, CHANGE_PROPOSALs)
- Run 2 for 2026-10-04 (prepared 2026-10-05 00:30 UK; uses only data gathered on 2026-10-04). Changes vs run 1: (1) baseline price rule (user 2026-10-04): GDS-20261004-10 windscreen cover re-costed at GBP 4.34 (was the 8%-off GBP 3.99) -> profit about GBP 0.58, FAIL; (2) reference competitor rule (user 2026-10-04: under 5,000 feedback + 10+ sales in 30 days, best qualifying price): BBQ cover -> azeglobal GBP 16.69 (multi-size listing; size price not confirmed), bidet unchanged (homiely), cat mat and bike saddle have no qualifying competitor in the 2026-10-04 ZIK data -> UNKNOWN; (3) AliExpress store feedback threshold now 90% (applied to new research; 2026-10-04 AliExpress rows were judged at 95%: ALI-04 94.6% and ALI-07 94.9% would pass feedback at 90% but fail on rating/price). Amazon run 2: 4 more products (Yukiyi, Vellure, Hojoy, Marwood), all FBA -> FAIL. SAFETY: Seller Sprite added/removed Amazon basket items on page load; basket items deleted only with user approval / user instruction (BBQ cover x1000; Hojoy); basket left at 0. Budget used: Go Dropship 19/35, Amazon 13/35, AliExpress 11/35. No CHANGE_PROPOSAL pending.

## Seasonal plan
See 2026-10-04_run2_seasonal_plan.md. Mix: 8 evergreen / 4 current event / 3 next-event preparation. Default 50/30/20.

## Target vs actual (target 5 per source, 15 total; a target, not a quota to fill)
| Source | Evaluated | Forwarded to eBay | Qualified | Selected | Target | Shortfall |
|---|---|---|---|---|---|---|
| Amazon UK | 13 | 0 | 0 | 0 | 5 | 5 |
| AliExpress UK | 11 | 4 | 0 | 0 | 5 | 5 |
| Go Dropship UK | 19 | 12 | 2 | 2 | 5 | 3 |
| **Total** | | | 2 | **2** | 15 | **13** |

| Allocation bucket | Target | Selected |
|---|---|---|
| evergreen | 8 | 2 |
| current_event | 4 | 0 |
| next_event_preparation | 3 | 0 |

## Shortfalls
- **Amazon UK**: 0 of 5 (5 short). main rejections: seller_type x11, offer_sellers x2, demand x1. Not padded.
- **AliExpress UK**: 0 of 5 (5 short). main rejections: store_positive_feedback x6, profit x4, rating x3. Not padded.
- **Go Dropship UK**: 2 of 5 (3 short). main rejections: delivery x7, str x2, trend x2; 3 incomplete (UNKNOWN data). Not padded.
- Bucket **evergreen**: 2 of 8.
- Bucket **current_event**: 0 of 4.
- Bucket **next_event_preparation**: 0 of 3.

## Accepted products (selected)
Not scored: CLAUDE.md s18 defines score weights but no sub-score method, so no score is invented. Listed by source.

| Source | Product | Item cost | eBay price | Profit | Margin | ROI (min) | Calc | Status | Bucket | Compliance |
|---|---|---|---|---|---|---|---|---|---|---|
| Go Dropship UK | BBQ Cover Barbecue Cover Grill Cover Protector Waterproof 190x71x117cm | 8.74 | 16.69 | 3.16 | 18.9% | 33.4% (min N/A) | ESTIMATED | PASS (ESTIMATED) | evergreen | COMPLIANCE_REVIEW |
| Go Dropship UK | Chrome Muslim Shower Head and Hose Bidet Spray Tap for Toilet Hygienic | 5.06 | 8.99 | 1.30 | 14.4% | 23.8% (min N/A) | ESTIMATED | PASS (ESTIMATED) | evergreen | COMPLIANCE_REVIEW |

## Main rejection reasons
- SOURCE/seller_type: 11
- SOURCE/delivery: 7
- PROFIT/profit: 6
- SOURCE/store_positive_feedback: 6
- SOURCE/rating: 3
- EBAY/str: 2
- EBAY/trend: 2
- SOURCE/offer_sellers: 2
- PROFIT/roi: 2
- EBAY/ebay_verification: 2
- PROFIT/price: 2
- SOURCE/demand: 1
- EBAY/ebay_evidence_unavailable: 1
- Duplicates flagged: 0; incomplete (UNKNOWN data, not accepted): 3

## Compliance-review items
- Go Dropship UK: BBQ Cover Barbecue Cover Grill Cover Protector Waterproof 190x71x117cm - COMPLIANCE_REVIEW (user must clear before any action, s22-s23)
- Go Dropship UK: Chrome Muslim Shower Head and Hose Bidet Spray Tap for Toilet Hygienic - COMPLIANCE_REVIEW (user must clear before any action, s22-s23)

## ESTIMATED results and EXCEPTIONS
- ESTIMATED (assumed inputs, not observed): BBQ Cover Barbecue Cover Grill Cover Protector Waterproof 190x71x117cm; Chrome Muslim Shower Head and Hose Bidet Spray Tap for Toilet Hygienic
- EXCEPTION (user approval needed before any action): none

## Lifecycle / status changes (research history)
- 12pcs Cat Scat Mat Animal Deterrent Mat with Spikes Prickle Strip Dig Stopper: QUALIFIED -> KEEP (Outcome: QUALIFIED at SEASONAL.)
- Chrome Muslim Shower Head and Hose Bidet Spray Tap for Toilet Hygienic: RESEARCHED -> QUALIFIED (Outcome: QUALIFIED at SEASONAL.)
- Car Windscreen Windshield Frost Cover Ice Snow Shield Front Window Protector Sunshade: QUALIFIED -> WATCH (profit failed. N/A)

## Files
- Accepted: 2026-10-04_run2_candidates.csv
- Rejected: 2026-10-04_run2_rejections.csv
- Seasonal plan: 2026-10-04_run2_seasonal_plan.md
