---
name: amazon-basket-pause-2026-10-09
description: Amazon research paused 2026-10-09 because the basket showed GBP 999 (100 x car mats); resume only after the user says it is clear
metadata:
  node_type: memory
  type: project
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-10-09T13:08:44.107Z
---

On 2026-10-09 an Amazon search page showed the basket flyout Subtotal GBP 999.00 (one line GBP 9.99 car floor mats, Qty 100). The agent had only opened search pages, no clicks; Seller Sprite auto stock check is the suspected cause (same pattern as 2026-10-04 and 2026-10-06).

**Why:** CLAUDE.md s5.2 / s24: if the basket has items, notify the user once, pause all Amazon research, never delete lines or open the basket page.

**How to apply:** do not evaluate Amazon products until the user replies "basket is clear" (or similar); then check the header counter is 0 first. Amazon rule changed 2026-10-09: FBA allowed with free Prime delivery, pick lowest cost / better margin (CLAUDE.md s5.3). See [[never-touch-basket]].
