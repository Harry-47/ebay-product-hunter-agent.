---
name: amazon-margin-and-seller-rules
description: "Amazon-only rules from 14 Oct 2026 - 15% margin (or 20% ROI), no small-seller limit, FBA and Amazon-sold allowed"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-10-14T18:15:34.209Z
---

User 2026-10-14, Amazon only: minimum profit margin 15% from GBP 8 (20% ROI route and GBP 1 profit unchanged); the under-20,000-feedback small-seller rule is dropped (reference seller of any size, still needs 5+ sales in 30 days, or the pre-event method for winter/Christmas); FBA and Amazon-sold offers are allowed alongside FBM; Amazon cost buffer stays 4%, ad rate 3%.

**Why:** Amazon prices sit close to eBay resellers' prices, so the 30% margin and small-seller tests rejected nearly everything.

**How to apply:** `tools/profit_calc.ps1` already applies the 15% margin to rows whose source contains "Amazon". Go Dropship and AliExpress keep the old rules. Related: [[amazon-price-gap-finding]], [[pre-event-selection]], [[save-passing-sellers]].
