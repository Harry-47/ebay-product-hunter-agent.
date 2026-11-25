---
name: zik-first-then-ebay
description: "Check every product in ZIK first; fill missing data directly from eBay; Amazon = branded non-VeRO only; don't stop between sources"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-10-16T12:49:44.365Z
---

User 2026-10-14: always check each product in ZIK Analytics first (Product Research / Competitor Research); where ZIK shows no or partial data, find the missing data directly on eBay (sold search, item page Sold History).

Also from 14 Oct: on Amazon search only non-VeRO branded products already selling on eBay (no generic items; generic goes to Go Dropship/AliExpress). Do not stop between sources; keep going until 5 pass or 35 evaluated per source. Skip the memory foam seat cushion (HOM-75116): the user already listed it.

User 2026-10-16 (reinforced): ALWAYS start discovery from ZIK (find demand on eBay first: Product Explorer/Research/Competitor Research), then look for the product on the source sites. Unbranded products go to Go Dropship and AliExpress; branded (non-VeRO) products go to Amazon. Do not start from a source site's bestseller list. Also never re-select previously passed products ([[no-repeat-passed-products]]).

User 2026-10-16: items in demand on eBay (per ZIK) that Go Dropship does not stock must be looked for on AliExpress (same unbranded route), not dropped.

**Why:** ZIK gives STR, seller counts and top-20 sales in one view; eBay fills gaps. Stopping repeatedly annoyed the user.

**How to apply:** open ZIK Product Research (ebay.co.uk, United Kingdom, 30 days, Fixed price, Brand New) per candidate before eBay checks. Related: [[amazon-price-gap-finding]], [[aliexpress-workflow-13oct]].

USER 17 Oct: Go Dropship only products with stable price (CLAUDE.md 7a.9): price-updated date 6+ months old = stable; newer = need repeat read; log every read to data/price_watch/godropship_price_log.csv.

USER 17 Oct: every daily file/page must record ALL eBay data (STR, sellers count, top-20 strong sellers, sold, avg price, eBay fee, ad cost, listing URLs) for every pass; never leave fields UNKNOWN that could be read; record eBay fee every time.

USER 17 Oct: strong-seller rules are HARD GATES (CLAUDE.md 3/11): top 20 must have 2+ sellers with 1,000+ total sold AND 3+ sellers with 50+ sales/30d; unread = UNKNOWN = no pass. User also floated sell-through 200%+ (not confirmed yet; gate still 20%).

USER 18 Oct: never wait or observe products over several days; decide pass/fail on the day's data using the rules (no 2-day stock, no 2-day bestseller, no GD repeat price read; recent GD price = flag PRICE_RECENTLY_CHANGED). Don't list 'second-day check due' as an open item.

USER 18 Oct: weight is not a gate when the source shows free delivery (any source); old limits only apply when delivery is charged; still avoid bulky expensive-to-ship items and record GD remote surcharge.
