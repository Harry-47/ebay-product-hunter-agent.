---
name: aw-dropship-relaxed-demand
description: 4 Nov 2026 AW Dropship-only rule - skip the strong-seller gate; pass if ZIK sell-through is above 200% and profit is at least GBP 1
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-11-04T14:41:22.039Z
---

For AW Dropship products only (user, 2026-11-04): the strong-seller demand gate (3+ sellers with 30+/30d, 2+ with 500+ total) and the 30% margin / 20% ROI test are replaced by: ZIK sell-through above 200% AND profit of at least GBP 1. Record the relaxation in `criteria_relaxed`. Other sources keep the normal rules.

Sell-through hand formula (user, 2026-11-04): items sold / number of active listings x 100, with active listings counted as eBay UK Buy It Now + New + UK-only ("N results"). Sold items come from ZIK (30 days). Salt lamp check: 256 sold / 110 active ("himalayan salt lamp 2kg") = 233%.

**Why:** AW giftware niches never have 3 sellers at 30+/30d, so nothing could pass; the user chose sell-through plus GBP 1 profit as the test. The user first said "good" sell-through, then set it above 200%.
**How to apply:** AW landed cost = ex-VAT price x 1.2 + postage 2.79/2.99 (+1 if net under 3). Break-even eBay price is roughly 2.7x the ex-VAT cost, so only items priced well above AW's RRP can pass. On 4 Nov only Himalayan salt lamps reached 256% sell-through, and they lose money (AW about GBP 12.8 landed vs eBay GBP 11-15). Re-run ZIK from a fresh tab: repeated searches in one tab silently switch to ebay.com. See [[aw-dropship-source]].
