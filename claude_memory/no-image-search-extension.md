---
name: no-image-search-extension
description: "How to find an eBay item on AliExpress: user's 17 Oct method is right-click the eBay listing image > Find on AliExpress; the 9 Oct toolbar button looped, stop if it loops again"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-10-17T16:44:53.482Z
---

User 2026-10-09: don't use the eBay toolbar "Image search on AliExpress" button if it causes issues. After pressing it on 2026-10-08, every AliExpress /w/ search page redirected to an isNewImageSearch results page (old car-tool results), even in new tabs.

User 2026-10-17 (new method): to find an item on AliExpress, open the eBay listing, right-click the listing image and choose "Find on AliExpress"; it opens AliExpress sellers and similar sellers; then choose by the rules (Choice, 500+ sold, rating 4.3+, store feedback 90+, delivery 10 days or less, exact SKU price and stock from the AliPrice SKU List, never the cut-off price).

**Why:** image-matching finds the exact product faster than text search. The 9 Oct loop came from the toolbar button; this is a different entry point but may use the same extension.

**How to apply:** try the right-click method once per session; if AliExpress search pages start redirecting in a loop again, stop and tell the user (the agent cannot change extension settings); fall back to text search. The user denied one navigation on 17 Oct when I tried to start this on the cat scratching ball listing; ask or wait for a go-ahead before navigating again. See [[aliexpress-workflow-13oct]].
