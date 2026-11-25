---
name: october-2026-mix
description: "User's adjusted daily mix for October 2026 - 70% Christmas/New Year/winter, 30% evergreen"
metadata:
  node_type: memory
  type: project
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-10-08T21:18:19.209Z
---

User instruction 2026-10-08 (during the 8 Oct hunt): "For this month, try to focus 70% of the products on Christmas, New Year and winter and remaining 30% on evergreen products."

Applies to hunts for the rest of October 2026 only. It is an adjusted mix under CLAUDE.md §16 (record mix + reason in the summary), not a change to the default 50/30/20.

**Why:** user wants to prepare seasonal stock ahead of Christmas/New Year/winter.

**How to apply:** pass `-Evergreen 0.30 -CurrentEvent 0.35 -NextEvent 0.35 -AllocationReason "User 2026-10-08: October focus 70% Christmas/New Year/winter, 30% evergreen"` to `tools/daily_report.ps1`; search themes = winter utility, Christmas gifting/home/organisation, New Year; Halloween/Black Friday get no priority. From November, go back to the default unless the user says otherwise. Related: [[remote-daily-schedule]]
