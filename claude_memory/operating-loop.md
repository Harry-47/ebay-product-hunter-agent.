---
name: operating-loop
description: "User wants tools-first work and a self-improvement loop - preflight, log failures, fix script, test, update workflow, close run"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-11-25T13:53:07.063Z
---

On 2026-11-25 the user asked for a system where the agent looks into its tools, learns when things fail, reads and fixes the script, updates the workflow and does not repeat the error.

**Why:** the same mistakes came back (repeat products, stale rules, old fees, hand calculations).

**How to apply:** follow prompts/operating_loop.md (CLAUDE.md section 29). Start with tools/preflight.ps1, dedupe_check before each product, lessons.ps1 for every failure or user correction, selftest after any script change, run_close at the end. Rules, the browser guard, settings and past data are never changed by the loop. See [[dedupe-grep-whole-data]].
