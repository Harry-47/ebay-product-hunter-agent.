---
name: dedupe-grep-whole-data
description: "Before researching any product, grep the WHOLE data/ folder (passing_sellers, candidates, history, notes) for its keywords; glob filters missed the tap cover on 13 Nov"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-11-13T05:25:26.848Z
---

On 13 Nov 2026 I spent time on the Go Dropship 2pcs outside tap cover, which had passed on 14 Oct; the user said "dont waste time on previously passed products". My dedupe grep used a brace glob that silently matched nothing.

**Why:** the user does not want repeat work on old passes. **How to apply:** run Grep on path data/ with no glob (or output files_with_matches) for 2-3 product keywords before opening any source page; if it appears in candidates/passing_sellers/status_log as passed, skip it. Related: [[no-repeat-passed-products]], [[skip-already-researched-products]]
