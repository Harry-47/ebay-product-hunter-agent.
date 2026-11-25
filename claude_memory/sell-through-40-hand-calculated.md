---
name: sell-through-40-hand-calculated
description: "4 Nov 2026 rule - sell-through gate is 40%+ for all sources, calculated by hand (sold / eBay UK active listings x 100), not ZIK's percentage"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-11-04T14:46:28.143Z
---

User, 2026-11-04: "make the 40% sell through rate minimum in rules" and "dont rely on zik sell through because it never goes above 100 listing, calculate it yourself". CLAUDE.md section 3 / 9 and the change log, `prompts/stages/ebay_verification.md`, `prompts/daily_hunt.md` and the report labels now say 40%.

Method: sell-through = items sold in the window (ZIK or eBay sold search, 30 days) / active listings x 100, where active listings = eBay UK search "N results" with Buy It Now + New + UK only. Record both numbers, `str_source` = HAND.

**Why:** ZIK divides sold items by at most its 100 analysed listings, so its percentage is inflated (salt lamps showed 256%).
**How to apply:** pull the active count from ebay.co.uk (LH_BIN=1&LH_ItemCondition=1000&LH_PrefLoc=1) for every product. This supersedes the AW-only "above 200%" figure in [[aw-dropship-relaxed-demand]]: the AW relaxation now means 40% hand sell-through plus GBP 1 profit (agent's reading, user to confirm).
