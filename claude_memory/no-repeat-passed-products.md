---
name: no-repeat-passed-products
description: Never re-select or re-count a product that already passed on an earlier day; skip it during discovery
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-10-16T10:40:11.573Z
---

Do not select previously passed products again. Before evaluating a candidate, check the earlier daily candidates, `data/history/` and `data/competitors/passing_sellers.csv`; if it already passed on any earlier day, skip it and do not count it as a new pass.

**Why:** user said on 16 Oct 2026 "Dont select the previously passed products again and again" after the Go Dropship bidet spray (HOM-59579, passed 4 and 8 Oct) was presented as a pass again.

**How to apply:** at discovery, deduplicate against all earlier passes (not just today's file). Report such matches as "already passed" only, outside the new-pass count. Related: [[save-passing-sellers]].
