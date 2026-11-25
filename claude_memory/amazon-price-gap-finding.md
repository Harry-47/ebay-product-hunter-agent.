---
name: amazon-price-gap-finding
description: Amazon UK items rarely pass because Amazon price is at or above eBay sold price; tried demand 1K/500/200 and a reverse eBay-first test on 9 Oct 2026
metadata:
  type: project
---

On 2026-10-09 Amazon yielded 0 passes in runs 2-4 even after the demand rule fell from 1,000+ to 500+ to 200+ (41 products evaluated at search-card level, plus a reverse eBay-first test on hot water bottles).

**Why:** Amazon cost plus the 8% buying fee needs an eBay price of about 1.7x the Amazon price (e.g. 4.49 needs 7.75). eBay sold prices for the same product types (draught strips, lint/pet rollers, donut beds, hot water bottles) are at or below Amazon's price, and the cheaper Amazon copies carry no 200+ bought label.

2026-10-11: 35 more Amazon cards (1K+ rule), 0 passes; every 1K+ item cost more than the eBay price level. User then set demand to 500+ (rulebook updated), and declined a change to the eBay strong-seller rule.

**How to apply:** do not expect Amazon passes from generic categories; report the gap honestly, don't pad. Go Dropship pet supplies (large eBay markup) is the only source that passed. See [[source-stop-rule]] for the 5-or-35 rule.
