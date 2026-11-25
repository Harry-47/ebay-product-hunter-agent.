---
name: godropship-remote-surcharge
description: Go Dropship shipping terms - Offshore & Remote Regions are domestic but surcharges may apply; record as a risk on every Go Dropship product
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d2dbd52-007b-43cd-97db-29e7140c5acf
  modified: 2026-10-13T10:33:02.661Z
---

User note 2026-10-13: Go Dropship shipping says "Offshore & Remote Regions: Domestic, but Surcharges May Apply".

**Why:** a UK buyer in a remote or offshore area (e.g. Highlands and Islands) can trigger an extra supplier charge that eats the thin margin.

**How to apply:** add it to `risks` / `rejection_risk` for every Go Dropship candidate. It is a risk note, not a gate. Related: [[amazon-price-gap-finding]] for why Go Dropship is the main source that passes.
