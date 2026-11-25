---
name: browsing-popups-cookies
description: "While browsing research sites, close pop-ups and reject cookies whenever they appear"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 534716d4-3bc7-4d6d-ac78-caa4c40c217e
  modified: 2026-10-03T07:05:23.674Z
---

When browsing (Claude in Chrome) for the eBay Product Hunter, close any pop-up (X / Close / "No thanks") and reject cookies ("Reject all" / "Necessary only", or Manage → all non-essential off → Save) as soon as they appear. Never press a pop-up's call-to-action (Shop now, Subscribe, Claim coupon, Install app).

**Why:** the user asked for this explicitly on 2026-10-03 so pages are usable and no consent is given on their behalf.

**How to apply:** if a banner offers only "Accept all", leave it and pause for the user. Login, CAPTCHA, security, payment and terms dialogs are never "closed past"; pause for the user. Describe the click as "Closes the … pop-up" / "Clicks Reject All on the cookie banner" so the project browser guard (tools/browser_guard.ps1) recognises it as safe. Full rule: prompts/stages/browser_research.md §2.
