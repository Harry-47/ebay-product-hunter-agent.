# AW Dropship UK (aw-dropship.com): supplier rules

Active daily source from 2026-11-25 (user). Extra giftware supplier since 2026-10-23. Collected from the rule change log (`docs/rulebook_changelog.md`); CLAUDE.md wins.

| Topic | Rule |
|---|---|
| Catalogue | giftware: aromatherapy, candles, bath and body, home and garden, jewellery, gemstones, bags, tea (tea/food stays banned, §4) |
| Access | prices and stock show only to the user's signed-in trade account in Chrome. The agent never logs in, registers or orders |
| Cost | net price × 1.20 (VAT, the user is not VAT registered) + UK postage for one order: £2.79 (0–99 g), £2.99 (100 g–2 kg), £5.99 (over 2 kg); + £1 small-order fee if the order is under £3 net. No buying fee, no buffer |
| Delivery | dispatch 1–2 working days (3–4 in Oct–Dec) + Royal Mail Tracked 48 (2–5 days). Limit 7 days. Scottish Highlands, Channel Islands and Scilly over 2 kg cost £14.50 |
| Stock | shown as "In stock (N available)". 20+ normal, 50+ seasonal |
| Demand (AW only, user 2026-11-04) | the strong-seller gate and the 30% margin / 20% ROI test are relaxed: hand sell-through 40%+ and profit of £1 or more. Record in `criteria_relaxed`. (The agent's reading of the user's instruction; confirmation still open) |
| Christmas gifts (user 2026-11-13) | eBay reference price test waived. Suggested price set from the landed cost so profit is at least £1, within £2–£35, rounded. eBay demand recorded as information. `criteria_relaxed` = "eBay reference price waived (user, Christmas gifts)" (confirmation still open) |
| Item code | AW product code (e.g. XBB-02); variant code where a product has options |
| API | optional read-only token in `.env` (`AW_DROPSHIP_API_TOKEN`); no script uses it yet |
| Compliance | `COMPLIANCE_REVIEW` or `PASS` by evidence of the supplier relationship (§22) |
