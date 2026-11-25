---
name: total-sellers-limit-2000
description: "23 Oct 2026 user rule - the total-sellers / total-listings gate is REMOVED (was under 1,000, then under 2,000); count is recorded for information only"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-10-23T16:14:00.845Z
---

User, 2026-10-23: first "make the limit of total seller to 2k", later the same day "remove the max listing limit ... total number of listing". CLAUDE.md section 3, 11 and 16a now say no limit; change log entry added; verification stage prompt (ebay_verification.md row now INFO) and the daily_report / history labels updated.

**Why:** the limit rejected products with real demand (extendable feather duster had 1,800+ listings; the car phone holder shows 4,500+ results on a broad query).

**How to apply:** still read the eBay UK active results count (Buy It Now, New, UK only, exact product title) and record it as information / competition risk, but never fail, relax or mark UNKNOWN on it. Do not confuse with the GBP 2-35 listing price range (user said "not price"); that limit is unchanged. Products rejected earlier only for a listing count are open for recheck. See [[skip-already-researched-products]].
