---
name: chrome-freeze-wait-and-retry
description: User rules 11 Nov 2026 - on Chrome freeze wait then reload the page (allowed); one tab per site (close old tab when opening new); keep hunting
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-11-11T10:26:10.158Z
---

When Chrome freezes ("still navigating or redirecting", renderer unresponsive, tab vanished): wait a little, then **reload the page** (user allows pressing reload / F5 / re-navigating the same URL), then continue once it works. Do not stop the hunt to report routine freezes.

**One tab per site:** when opening a new tab for a site, close the previous tab of that site first, to save RAM (VPS has only 2 GB).

**Why:** VPS low RAM; freezes are temporary and the user wants the hunt to keep going. **How to apply:** wait ~10-20 s, reload, retry; keep at most one ZIK, one eBay, one source-site tab open; only ask the user when a site shows a login page or the extension is fully disconnected. Related: [[hunt-2026-11-11-paused]], [[godropship-low-yield]]
