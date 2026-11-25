---
name: aliexpress-price-without-sale
description: "11 Nov 2026 user rule - AliExpress cost = variant price WITHOUT the sale discount (struck-through price), not the SKU List sale price"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-11-11T05:00:31.739Z
---

User instruction 2026-11-11: "on aliexpress, use the price without sale". Cost = the struck-through (pre-sale) price of the exact variant, read on the item page with that variant selected. Supersedes [[aliexpress-sku-price-ignore-superdeals]] (SKU List price) during sales like 11.11.

**Why:** user does not want costs based on temporary sale prices. **How to apply:** select the exact variant, read the struck price next to the sale price, use it as source_price (plus 4% FX, 6% buffer test). Note: struck prices are often 2-3x the sale price, so few AliExpress items will pass; say so if yield is 0.
