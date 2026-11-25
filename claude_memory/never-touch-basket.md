---
name: never-touch-basket
description: "Never add to or delete from any basket; when Seller Sprite's Amazon stock check fills the basket, notify the user to clear it and pause until they say it is clear"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 534716d4-3bc7-4d6d-ac78-caa4c40c217e
  modified: 2026-10-05T19:13:20.499Z
---

Never add anything to a basket/cart on any site, never open checkout, and (since 2026-10-05) never delete basket lines either.

Seller Sprite's Amazon stock check adds units to the user's real basket (e.g. 2026-10-03 vacuum bags ×1000; 2026-10-04 fitted sheet ×1000, phone holders, Yukiyi, Hojoy; 2026-10-05 Tydi ×1000, which even reappeared after a delete). The user tried "agent clears it with approval", then on 2026-10-05 chose: **notify me to clear the basket and pause until I say it is clear**.

**Why:** the extension adds/re-adds items unpredictably; the user wants to control their own basket and keep the guard strict.

Since 2026-10-05 (later): never click Seller Sprite "View details" at all; read FBM + in-stock from the visible summary only (visible figure must be 30+; "In stock" with no number passes). Guard denies View details.

**How to apply:** after each Amazon stock check, read the header basket counter (zoom/text only). If not 0: one PushNotification asking the user to clear it, pause Amazon research (other sources can continue), resume only after "basket is clear" and the counter shows 0. Don't open the basket page or write the approval file. Related: [[browsing-popups-cookies]].
