---
name: daily-review-page
description: "Pinned claude.ai artifact \"eBay Daily 20\" where the user checks each day's 20 products; update the same URL after every hunt"
metadata:
  node_type: memory
  type: reference
  originSessionId: 534716d4-3bc7-4d6d-ac78-caa4c40c217e
  modified: 2026-10-03T10:24:22.057Z
---

The user reviews daily hunt results on a pinned private artifact: https://claude.ai/artifact/VgttmGdPunwq2X1iqbKnLa (also stored in config.yaml `review_page.url`).

After each daily hunt: run `tools/build_review_page.ps1`, then publish `data/review_page/ebay_daily_20.html` to that same URL (pass `url`; never create a new artifact per day). The page's date list holds earlier days. The user chose this instead of linking the folder to their claude.ai Project "ebay product hunter" (not possible from Claude Code).
