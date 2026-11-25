# Daily product hunt - 2026-10-03

Report generated 2026-10-03 19:34 UK. Research files: data/sources, data/ebay, data/profit, data/seasonal (2026-10-03).
Research only: nothing was purchased, listed or published. Retailer-sourced items stay COMPLIANCE_REVIEW until the user clears them (CLAUDE.md s22-s25).

## Run notes (blocked sources, conflicts, CHANGE_PROPOSALs)
- Run 2 (UK 18:40-19:45). Go Dropship was logged out at the start; the user signed in, then it was researched. Rule changes mid-run (user, logged in CLAUDE.md): demand = best seller OR Choice OR 1,000+ sold in 30 days (all sources); branded products allowed if the brand is not in eBay VeRO. Amazon AMZ-07..15 were rejected only for being branded; reopened as recheck, not evaluated further today. Chrome renderer froze once (RDP); resumed after the user reopened Chrome. eBay showed a Checking your browser security screen at 19:30; not interacted with, eBay browsing stopped (CLAUDE.md s27); total sellers for GDS-09 stays UNKNOWN. eBay Product Research unavailable: ZIK sell-through used (s9). Budget used: Go Dropship 20/20, Amazon 15/20, AliExpress 8/20 (time). No CHANGE_PROPOSAL raised.

## Seasonal plan
See 2026-10-03_run2_seasonal_plan.md. Mix: 8 evergreen / 4 current event / 3 next-event preparation. Default 50/30/20.

## Target vs actual (target 5 per source, 15 total; a target, not a quota to fill)
| Source | Evaluated | Forwarded to eBay | Qualified | Selected | Target | Shortfall |
|---|---|---|---|---|---|---|
| Amazon UK | 15 | 9 | 0 | 0 | 5 | 5 |
| AliExpress UK | 8 | 3 | 0 | 0 | 5 | 5 |
| Go Dropship UK | 20 | 18 | 1 | 1 | 5 | 4 |
| **Total** | | | 1 | **1** | 15 | **14** |

| Allocation bucket | Target | Selected |
|---|---|---|
| evergreen | 8 | 1 |
| current_event | 4 | 0 |
| next_event_preparation | 3 | 0 |

## Shortfalls
- **Amazon UK**: 0 of 5 (5 short). main rejections: seller_type x6, variations x4, avoid_list x1; 9 incomplete (UNKNOWN data). Not padded.
- **AliExpress UK**: 0 of 5 (5 short). main rejections: delivery x3, rating x3, profit x2. Not padded.
- **Go Dropship UK**: 1 of 5 (4 short). main rejections: ebay_verification x5, profit x5, avoid_list x2; 6 incomplete (UNKNOWN data). Not padded.
- Bucket **evergreen**: 1 of 8.
- Bucket **current_event**: 0 of 4.
- Bucket **next_event_preparation**: 0 of 3.

## Accepted products (selected)
Not scored: CLAUDE.md s18 defines score weights but no sub-score method, so no score is invented. Listed by source.

| Source | Product | Item cost | eBay price | Profit | Margin | ROI (min) | Calc | Status | Bucket | Compliance |
|---|---|---|---|---|---|---|---|---|---|---|
| Go Dropship UK | 12pcs Cat Scat Mat Animal Deterrent Mat with Spikes Prickle Strip Dig Stopper | 6.31 | 11.99 | 2.00 | 16.7% | 29.4% (min N/A) | ESTIMATED | PASS (ESTIMATED) | evergreen | COMPLIANCE_REVIEW |

## Main rejection reasons
- PROFIT/profit: 7
- SOURCE/seller_type: 6
- SOURCE/variations: 5
- EBAY/ebay_verification: 5
- SOURCE/rating: 3
- SOURCE/avoid_list: 3
- SOURCE/delivery: 3
- PROFIT/price: 2
- EBAY/str: 2
- EBAY/trend: 1
- SOURCE/stock: 1
- EBAY/ebay_evidence_unavailable: 1
- Duplicates flagged: 0; incomplete (UNKNOWN data, not accepted): 15

## Compliance-review items
- Go Dropship UK: 12pcs Cat Scat Mat Animal Deterrent Mat with Spikes Prickle Strip Dig Stopper - COMPLIANCE_REVIEW (user must clear before any action, s22-s23)

## ESTIMATED results and EXCEPTIONS
- ESTIMATED (assumed inputs, not observed): 12pcs Cat Scat Mat Animal Deterrent Mat with Spikes Prickle Strip Dig Stopper
- EXCEPTION (user approval needed before any action): none

## Lifecycle / status changes (research history)
- 4X Garden Gazebo Foot Leg Feet Weights Sand Sand Bags for Marquee Party Tent: WATCH -> RESEARCHED (Outcome: RESEARCHED at SEASONAL.)
- 2 PCS 165 Degree Kitchen Cabinet Hinges Soft Close Cupboard Hinges with Fixing Screws: WATCH -> RESEARCHED (Outcome: RESEARCHED at SEASONAL.)

## Files
- Accepted: 2026-10-03_run2_candidates.csv
- Rejected: 2026-10-03_run2_rejections.csv
- Seasonal plan: 2026-10-03_run2_seasonal_plan.md

---
**Correction note (added 2026-10-03 19:34 UK):** `criteria_relaxed` for GDS-20261003-01 shows 'EXCEPTION: upstream: none'. That is a placeholder, not a relaxed rule: no criterion was relaxed for this candidate. `tools/daily_report.ps1` now ignores the placeholder in future runs. No data changed.
