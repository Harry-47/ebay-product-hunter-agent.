---
name: save-passing-sellers
description: Save the eBay seller of every product that passes into data/competitors/passing_sellers.csv for later competitor analysis
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-10-14T17:35:54.299Z
---

User 2026-10-14: from now on, save the sellers whose product passes (the eBay reference seller) so they can be used later for competitor analysis to find more products.

**Why:** competitor-store research (ZIK Competitor Research) is the fastest discovery route, and the best seeds are sellers already proven to sell qualifying products.

**How to apply:** when a product passes, append a row to `data/competitors/passing_sellers.csv` (date, source, product, reference_seller, link, price, profit, competitor_analysis_done = NO). Seeded on 14 Oct with 23 rows back-filled from earlier accepted candidates. Related: [[zik-first-then-ebay]].
