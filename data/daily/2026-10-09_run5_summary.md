# Daily product hunt - 2026-10-09

Report generated 2026-10-09 21:08 UK. Research files: data/sources, data/ebay, data/profit, data/seasonal (2026-10-09).
Research only: nothing was purchased, listed or published. Retailer-sourced items stay COMPLIANCE_REVIEW until the user clears them (CLAUDE.md s22-s25).

## Run notes (blocked sources, conflicts, CHANGE_PROPOSALs)
- Run 5: Go Dropship finished at 4 selected (BBQ cover added; can opener is a USER_APPROVED exception). Amazon re-run from Amazon best sellers / eBay market comparison on top of the 41 evaluated in run 4: 0 passed (Amazon price equals eBay price, every item needs about 1.7x its cost). AliExpress not searched.

## Seasonal plan
See 2026-10-09_run5_seasonal_plan.md. Mix: 5 evergreen / 5 current event / 5 next-event preparation. ADJUSTED: October 2026 mix set by the user: 70% Christmas/New Year/winter, 30% evergreen

## Target vs actual (target 5 per source, 15 total; a target, not a quota to fill)
| Source | Evaluated | Forwarded to eBay | Qualified | Selected | Target | Shortfall |
|---|---|---|---|---|---|---|
| Amazon UK | 41 | 0 | 0 | 0 | 5 | 5 |
| AliExpress UK | 1 | 0 | 0 | 0 | 5 | 5 |
| Go Dropship UK | 12 | 12 | 4 | 4 | 5 | 1 |
| **Total** | | | 4 | **4** | 15 | **11** |

| Allocation bucket | Target | Selected |
|---|---|---|
| evergreen | 5 | 4 |
| current_event | 5 | 0 |
| next_event_preparation | 5 | 0 |

## Shortfalls
- **Amazon UK**: 0 of 5 (5 short). main rejections: source_check x31, demand x10. Not padded.
- **AliExpress UK**: 0 of 5 (5 short). main rejections: choice_badge x1. Not padded.
- **Go Dropship UK**: 4 of 5 (1 short). main rejections: profit x7, margin x4, ebay_verification x1. Not padded.
- Bucket **evergreen**: 4 of 5.
- Bucket **current_event**: 0 of 5.
- Bucket **next_event_preparation**: 0 of 5.

## Accepted products (selected)
Not scored: CLAUDE.md s18 defines score weights but no sub-score method, so no score is invented. Listed by source.

| Source | Product | Item cost | eBay price | Profit | Margin | ROI | Margin rule | Calc | Status | Bucket | Compliance |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Go Dropship UK | Cat Puppy Calming Plush Cushion Round Pet Bed without Zippers and Non-removable - Grey Diameter 60cm | 8.65 | 17.85 | 4.19 | 23.5% | 47.0% | under 30%, passed on 20%+ ROI | ESTIMATED | PASS (ESTIMATED) | evergreen | COMPLIANCE_REVIEW |
| Go Dropship UK | Cat Puppy Calming Plush Cushion Round Pet Bed without Zippers and Non-removable - Grey Diameter 70cm | 10.27 | 20.95 | 4.94 | 23.6% | 46.7% | under 30%, passed on 20%+ ROI | ESTIMATED | PASS (ESTIMATED) | evergreen | COMPLIANCE_REVIEW |
| Go Dropship UK | Stainless Steel Tin Can Opener | 4.56 | 10.99 | 3.18 | 28.9% | 67.6% | under 30%, passed on 20%+ ROI | ESTIMATED | PASS (ESTIMATED) | evergreen | COMPLIANCE_REVIEW |
| Go Dropship UK | BBQ Cover Barbecue Cover Grill Cover Protector Waterproof 190x71x117cm | 8.74 | 14.59 | 1.90 | 13.1% | 21.2% | under 30%, passed on 20%+ ROI | ESTIMATED | PASS (ESTIMATED) | evergreen | COMPLIANCE_REVIEW |

## Main rejection reasons
- SOURCE/source_check: 31
- SOURCE/demand: 10
- PROFIT/profit: 7
- PROFIT/margin: 4
- EBAY/ebay_verification: 1
- SOURCE/choice_badge: 1
- Duplicates flagged: 0; incomplete (UNKNOWN data, not accepted): 0

## Compliance-review items
- Go Dropship UK: Cat Puppy Calming Plush Cushion Round Pet Bed without Zippers and Non-removable - Grey Diameter 60cm - COMPLIANCE_REVIEW (user must clear before any action, s22-s23)
- Go Dropship UK: Cat Puppy Calming Plush Cushion Round Pet Bed without Zippers and Non-removable - Grey Diameter 70cm - COMPLIANCE_REVIEW (user must clear before any action, s22-s23)
- Go Dropship UK: Stainless Steel Tin Can Opener - COMPLIANCE_REVIEW (user must clear before any action, s22-s23)
- Go Dropship UK: BBQ Cover Barbecue Cover Grill Cover Protector Waterproof 190x71x117cm - COMPLIANCE_REVIEW (user must clear before any action, s22-s23)

## ESTIMATED results and EXCEPTIONS
- ESTIMATED (assumed inputs, not observed): Cat Puppy Calming Plush Cushion Round Pet Bed without Zippers and Non-removable - Grey Diameter 60cm; Cat Puppy Calming Plush Cushion Round Pet Bed without Zippers and Non-removable - Grey Diameter 70cm; Stainless Steel Tin Can Opener; BBQ Cover Barbecue Cover Grill Cover Protector Waterproof 190x71x117cm
- EXCEPTION (user approval needed before any action): none

## Lifecycle / status changes (research history)
- Cat Puppy Calming Plush Cushion Round Pet Bed without Zippers and Non-removable - Grey Diameter 60cm: RESEARCHED -> QUALIFIED (Outcome: QUALIFIED at SEASONAL.)
- Draft Draught Excluder for Door Window, Brush Seal Strip Tape, Gap Blocker: QUALIFIED -> WATCH (source_check failed. Price: item cost GBP 3.69 needs an eBay price of about GBP 6.7; 5m brush strips sell GBP 3.4-5.5 on eBay)
- Draught Excluder for Doors and Windows, Grey, 9mm x 9mm x 6M: QUALIFIED -> WATCH (source_check failed. Price: item cost GBP 3.99 needs an eBay price of about GBP 7.09; 6M brush strips sell GBP 4.5-6 on eBay)
- BBQ Cover Barbecue Cover Grill Cover Protector Waterproof 190x71x117cm: RESEARCHED -> QUALIFIED (Outcome: QUALIFIED at SEASONAL.)

## Files
- Accepted: 2026-10-09_run5_candidates.csv
- Rejected: 2026-10-09_run5_rejections.csv
- Seasonal plan: 2026-10-09_run5_seasonal_plan.md
