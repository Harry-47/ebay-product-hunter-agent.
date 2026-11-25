---
name: strong-sellers-500-total
description: "24 Oct 2026 user rule - eBay strong-seller total-sold gate is 3+ sellers with 500+ total sold (was 2+ with 1,000+); 3+ with 50+/30d unchanged"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-10-24T09:05:33.466Z
---

User, 2026-10-24: "change the rule of 3 sellers above 1000 total sold to 3 sellers with 500+ total sold". CLAUDE.md section 3, 11, change log and prompts/stages/ebay_verification.md updated. Hard gate, among the top 20 sellers: 3+ with 500+ total sold AND 3+ with 50+ sales in 30 days; unread = UNKNOWN = not passed.

**Why:** the 2+ with 1,000+ total-sold gate was rejecting niches with real demand where sellers are mid-sized.
**How to apply:** count sellers with Total Sold 500+ in the ZIK top-20 table. Products rejected earlier only on the 1,000+ count are open for recheck (e.g. dual USB car charger). Related: [[total-sellers-limit-2000]] (listing count has no gate).
