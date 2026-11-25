---
name: pre-event-selection
description: Winter/Christmas products use the 16a pre-event method (lifetime eBay proof + active-price reference) instead of 5+ sales in 30 days
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-10-14T17:52:31.826Z
---

User 2026-10-14: for winter and Christmas best sellers, do not require 5+ eBay sales in 30 days; the user lists before the event so listings rank by the time buying starts. Method written as CLAUDE.md section 16a: source demand now, lifetime eBay proof (3 listings from 2 sellers with 20+ sold, or one seller 1,000+), reference price = median of the 5 lowest credible active listings (3 at or above minimum price), timing/stock checks, recheck at event-30 and event-14 days, label `sales_basis = PRE_EVENT`.

**Why:** eBay seasonal demand starts mid-November; waiting for 30-day sales means listing too late to rank.

**How to apply:** use only for event products in PREPARE_EARLY/START_NOW; everything else keeps the normal rules. Thresholds are the agent's proposal and can be tuned. Related: [[zik-first-then-ebay]], [[october-2026-mix]].

Update 2026-10-14 (later): user wants to select now. 16a test 2 loosened to any one of: (a) exact-item lifetime proof, (b) product-type proof (3 sellers 50+ lifetime), (c) event/winter-specific product with source demand met (no eBay sales needed). Source demand + holding active-price median is enough.
