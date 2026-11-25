---
name: links-codes-variants
description: "25 Nov 2026 - every hunted product needs eBay listing link, source product link, item code, variant code; up to 3 (MAX 3) good-selling variants with complete info each"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-11-25T14:33:19.607Z
---

On 2026-11-25 the user asked that every hunted product includes the eBay listing link, the sourcing site product link, and its item code or variant code. For items with variations: choose variants that sell well on eBay, **maximum 3** (user corrected "at least 3" to "max 3"), with complete info for each.

**Why:** the user lists from these records; earlier workbooks had no eBay listing link and some source links were only the supplier homepage.

**How to apply:** record links and codes while the pages are open; each variant gets its own Profit Engine row (id, id-V2, id-V3). Details in prompts/daily_hunt.md "Links, codes and variants"; build_manual_workbook.ps1 refuses a selected product without them. See [[operating-loop]].
