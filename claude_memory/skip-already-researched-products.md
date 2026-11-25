---
name: skip-already-researched-products
description: Before researching any product, check data/history/product_register.csv (and past candidates files); user is annoyed when I redo products already selected or watched
metadata:
  type: feedback
---

User said on 2026-10-21: "Dont waste time on already selected products" and "You selected it some days before" (after I researched Go Dropship Weekly Top items such as the memory foam coccyx cushion, 100-pack puppy pads, cat scat mat, coat hooks that are already in history or already listed by the user).

**Why:** Go Dropship Weekly Top is mostly products I already evaluated on 3-14 Oct; redoing them burns ZIK/browser time and the browser/guard is fragile (frequent disconnects, low PC memory).

**How to apply:** For every lead, grep data/history/product_register.csv and data/daily/*candidates*.csv for the product title or the GDS/ALI/AMZ id first. Skip it unless a recheck trigger exists (rule change that was the only failure reason, e.g. the 18 Oct free-delivery weight rule, the 14 Oct small-seller drop). Also skip products the user says are already listed. See [[no-repeat-passed-products]].
