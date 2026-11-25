# Daily product hunt - 2026-10-12

Report generated 2026-10-12 18:53 UK. Research files: data/sources, data/ebay, data/profit, data/seasonal (2026-10-12).
Research only: nothing was purchased, listed or published. Retailer-sourced items stay COMPLIANCE_REVIEW until the user clears them (CLAUDE.md s22-s25).

## Run notes (blocked sources, conflicts, CHANGE_PROPOSALs)
- PARTIAL RUN: Amazon 6 evaluated 0 passed; Go Dropship 5 evaluated 2 passed; AliExpress 4 evaluated 1 passed (200pc copper crush washers, incognito actual price GBP 3.90, price check 1 of 3 - see data/price_watch/aliexpress_price_log.csv). 35-per-source budget NOT used up (shortfalls reported). New this session: AliExpress incognito actual-price rule, 10% cost buffer, max_safe_cost in every row, 3-day price check, strong-seller preference 2+/3+, highest-selling variant, eBay BIN/New/UK filters. ALI-20261010-02 (brass tap adaptor) re-priced in incognito at GBP 1.54: profit 2.50, buffer PASS (not in today's selection).

## Seasonal plan
See 2026-10-12_run3_seasonal_plan.md. Mix: 5 evergreen / 5 current event / 5 next-event preparation. ADJUSTED: October 2026 adjusted mix: 70% Christmas/New Year/winter, 30% evergreen (user)

## Target vs actual (target 5 per source, 15 total; a target, not a quota to fill)
| Source | Evaluated | Forwarded to eBay | Qualified | Selected | Target | Shortfall |
|---|---|---|---|---|---|---|
| Amazon UK | 6 | 0 | 0 | 0 | 5 | 5 |
| AliExpress UK | 4 | 1 | 1 | 1 | 5 | 4 |
| Go Dropship UK | 5 | 2 | 2 | 2 | 5 | 3 |
| **Total** | | | 3 | **3** | 15 | **12** |

| Allocation bucket | Target | Selected |
|---|---|---|
| evergreen | 5 | 2 |
| current_event | 5 | 1 |
| next_event_preparation | 5 | 0 |

## Shortfalls
- **Amazon UK**: 0 of 5 (5 short). main rejections: source_check x6. Not padded.
- **AliExpress UK**: 1 of 5 (4 short). main rejections: source_check x3. Not padded.
- **Go Dropship UK**: 2 of 5 (3 short). main rejections: source_check x3. Not padded.
- Bucket **evergreen**: 2 of 5.
- Bucket **current_event**: 1 of 5.
- Bucket **next_event_preparation**: 0 of 5.

## Accepted products (selected)
Not scored: CLAUDE.md s18 defines score weights but no sub-score method, so no score is invented. Listed by source.

| Source | Product | Item cost | eBay price | Profit | Margin | ROI | Margin rule | Calc | Status | Bucket | Compliance |
|---|---|---|---|---|---|---|---|---|---|---|---|
| AliExpress UK | 100/200PCS Copper Washer Gasket Nut And Bolt Set Flat Ring Seal Assortment Kit With Box M4-M14 (200PCS variant) | 3.90 | 11.95 | 4.34 | 36.3% | 103.1% | PASS (min 30.0%) | ESTIMATED | PASS (ESTIMATED) | evergreen | COMPLIANCE_REVIEW |
| Go Dropship UK | 2x10m Wide Garden Cold Frost Wind Fleece for Winter Plant Protection | 5.86 | 9.99 | 1.28 | 12.8% | 21.2% | under 30%, passed on 20%+ ROI | ESTIMATED | PASS (ESTIMATED) | current_event | COMPLIANCE_REVIEW |
| Go Dropship UK | Adjustable Posture Corrector Slouch Shoulder Corset Back Lumbar Brace Orthosis Support Shoulder Straight Hold - S | 5.93 | 11.99 | 2.70 | 22.5% | 44.2% | under 30%, passed on 20%+ ROI | ESTIMATED | PASS (ESTIMATED) | evergreen | COMPLIANCE_REVIEW |

## Main rejection reasons
- SOURCE/source_check: 12
- Duplicates flagged: 0; incomplete (UNKNOWN data, not accepted): 0

## Compliance-review items
- AliExpress UK: 100/200PCS Copper Washer Gasket Nut And Bolt Set Flat Ring Seal Assortment Kit With Box M4-M14 (200PCS variant) - COMPLIANCE_REVIEW (user must clear before any action, s22-s23)
- Go Dropship UK: 2x10m Wide Garden Cold Frost Wind Fleece for Winter Plant Protection - COMPLIANCE_REVIEW (user must clear before any action, s22-s23)
- Go Dropship UK: Adjustable Posture Corrector Slouch Shoulder Corset Back Lumbar Brace Orthosis Support Shoulder Straight Hold - S - COMPLIANCE_REVIEW (user must clear before any action, s22-s23)

## ESTIMATED results and EXCEPTIONS
- ESTIMATED (assumed inputs, not observed): 100/200PCS Copper Washer Gasket Nut And Bolt Set Flat Ring Seal Assortment Kit With Box M4-M14 (200PCS variant); 2x10m Wide Garden Cold Frost Wind Fleece for Winter Plant Protection; Adjustable Posture Corrector Slouch Shoulder Corset Back Lumbar Brace Orthosis Support Shoulder Straight Hold - S
- EXCEPTION (user approval needed before any action): none

## Lifecycle / status changes (research history)
- 2x10m Wide Garden Cold Frost Wind Fleece for Winter Plant Protection: WATCH -> QUALIFIED (Outcome: QUALIFIED at SEASONAL.)
- Large Pet Carrier Bag Soft Fabric Fold Portable Travel Puppy Cat Bag - Grey: RESEARCHED -> WATCH (source_check failed. Recheck due 2026-10-12: baseline GBP 10.15 (GBP 9.65 shown with 5% off); minimum listing price GBP 17.14; best qualifying top-20 sellers under 20k feedback with 5+ sales: neverance3 (5,517 fb, 6 sales) GBP 16.88, joy-ocean-ltd (535 fb, 5 sales) GBP 16.90 (below minimum; ZIK 'large pet carrier bag soft fabric foldable portable travel puppy cat', avg GBP 11.02))
- Outdoor Cushion Dustproof Cover Storage Bag Garden Furniture Covers 173x76x51cm - Black: RESEARCHED -> WATCH (source_check failed. Recheck due 2026-10-12: cost GBP 9.14; minimum listing price about GBP 14.85; best under-20k seller rugs-house (15,592 fb, 137 sales) GBP 10.99 (ZIK 'garden cushion storage bag waterproof' avg GBP 11.41))
- Adjustable Extendable Rack Closet Cupboard Divider Rack Storage Organizer Shelf Easy to install: RESEARCHED -> WATCH (source_check failed. Recheck due 2026-10-12: cost GBP 7.96; minimum listing price about GBP 13; ZIK 'adjustable extendable closet cupboard divider rack storage shelf' avg GBP 7.81, sell-through 185%)

## Files
- Accepted: 2026-10-12_run3_candidates.csv
- Rejected: 2026-10-12_run3_rejections.csv
- Seasonal plan: 2026-10-12_run3_seasonal_plan.md
