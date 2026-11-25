# Amazon UK: supplier rules (PAUSED by the user 2026-11-25)

This is the full rule text moved unchanged from CLAUDE.md on 2026-11-25; section numbers are the same. It contains dated history: the current values are in CLAUDE.md section 0, and the newest user instruction in docs/rulebook_changelog.md applies where they differ.

## 5. Amazon sourcing workflow
1. Look for high-selling products on Amazon UK, starting from products already selling on eBay (eBay first, §9). Demand rule (user rule 2026-10-08): the product must have sold **500+ in the last 30 days** (user rule 2026-10-11; was 1,000+), as shown by Amazon's own label (e.g. "500+ bought in past month" or higher). A Best Seller or Amazon's Choice badge alone does not count. "400+ bought in past month" or lower, or no monthly label, fails this check. All other Amazon rules below are unchanged.
   - **Amazon criteria (user rules 2026-10-04):**
     - free delivery;
     - 3 to 20 sellers offering the product on the Amazon listing;
     - rating 4+ stars;
     - item weight under 2 kg, or any weight when the offer has free delivery (user rule 2026-10-18, §3);
     - Amazon item price £2–£40 (user rule 2026-10-06; minimum was £5) (the eBay listing price must still be £2–£35, §3);
     - condition New.
   - **Search filters to apply where Amazon offers them:**
     - Customer Reviews: 4 stars & up;
     - price £2–£40 (was £5–£40; 2026-10-06; if Amazon's filter has no £2 step, use the nearest lower option and check the price on the page);
     - Condition: New;
     - Small business;
     - FBM seller.
   - **Skip these categories on Amazon:** sized clothes and shoes (free-size / one-size clothing with no size options is allowed, user rule 2026-10-13) and jewellery. Small consumer electronics are allowed on Amazon (user rule 2026-10-14); large electronics (TV, fridge, laptop, mobile and similar) are not. Recorded as compliance risks where safety-regulated.
   - A filter Amazon doesn't offer is not invented: the criterion is checked on the product page instead.
   - "Small business" is a search filter, not a pass/fail gate: if Amazon shows no small-business filter or badge, record `UNKNOWN`.
2. **Stock and seller type, current rule (user rule 2026-10-05, supersedes everything below where it differs):** Seller Sprite is used **only** to see whether the seller is **FBM** and whether the product is **in stock**, from what the extension and the page show without clicking.
   - **Never click Seller Sprite's "View details"** (it can add the product to the basket and slows research). The browser guard blocks it.
   - **Stock gate:** if a unit figure for the FBM seller is visible, it must be **30+** (under 30 fails). If only "In stock" shows with no number, the stock check **passes**. Out of stock, or a visible "Only N left" with N under 30, fails. Nothing visible at all is `UNKNOWN`.
   - Seller type is cross-checked with Amazon's "Dispatches from / Sold by".
   - The basket counter is still read after each product page; the basket rule below still applies if it ever fills.
   **Basket handling (user rule 2026-10-05, supersedes the clean-up steps below):** after checking stock on an Amazon product, the agent reads the basket counter in the page header.
   - **If the basket has any items:**
     1. send the user **one notification** asking them to clear the basket;
     2. **pause all Amazon research**;
     3. resume only after the user replies **"basket is clear"** (or similar), checking the counter shows 0 first.
   - **The agent never deletes basket lines itself** (the guard's basket exception is not used).
   - It never opens the basket page, and never adds to a basket or opens checkout.
   Stock (user decision 2026-10-04, option 2, **supersedes the read-only bullets below where they differ**):
   - **Stock check:** the stock check uses **Seller Sprite's "View details"** panel on the Amazon product page. This click adds units to the basket.
   - **Basket record:** the agent reads the basket counter before the Amazon session. During it, it keeps a list of every product checked this way.
   - **Clean-up:** after the Amazon session, the agent lists exactly what the checks added (product and quantity) and asks the user. Only after the user says yes does it:
     1. write a 15-minute approval (`.claude/basket_clear_approval.json`);
     2. open only `amazon.co.uk/gp/cart/view.html`;
     3. click "Delete" on exactly those lines and nothing else;
     4. confirm the counter is back to its starting value.
   - **Guard:** the browser guard enforces this narrow exception. Checkout, buy, quantity, "save for later" and every other basket action stay blocked, and no basket action is possible outside the approved basket page.
   - **Never:** the agent never adds anything to a basket itself and never opens checkout.
   Earlier same-day wording (read-only stock):
   - **Seller Sprite use (user rule 2026-10-04, later the same day):** Seller Sprite is used **only** to see:
     - the seller type (FBM or FBA, e.g. its "Fulfilment" label);
     - whether stock is **available or not**.
   - **Stock gate (unchanged, user confirmed 2026-10-04):** the FBM seller must have **30+ units**.
     - PASS if a visible figure for the FBM seller is 30 or more.
     - FAIL if it is under 30, or out of stock (e.g. Amazon "Only 12 left in stock").
     - UNKNOWN if no quantity is visible without clicking. "In stock" alone is not enough.
   - Seller type is cross-checked with Amazon's "Dispatches from / Sold by".
   - **Never click Seller Sprite's "View details" stock button.** It was found to add 1,000 of the item to the user's Amazon basket (§24).
   - Use only figures visible without clicking:
     - Seller Sprite's summary "Stock Status / Current Stock" box (the seller row and the stock figure shown in it);
     - Amazon's own stock text (e.g. "Only 12 left in stock").
   - If no figure is visible without clicking, record `UNKNOWN`.
   - **Seller Sprite stock check off first (2026-10-04):** the Seller Sprite "Stock Status" feature also seems to add units to the basket automatically when a product page loads.
     - Amazon product pages are opened only after the user has confirmed that Seller Sprite's Stock Status feature (or the extension) is switched off.
     - The agent never changes extension settings itself.
     - If the basket indicator changes during research, stop Amazon immediately and tell the user.
     - The agent reads the basket counter (header text only, never the basket page) before and after each Amazon product page.
3. Seller type (user rule 2026-10-09): **FBM or FBA are both allowed** (FBA = a third-party seller whose item is dispatched by Amazon). The offer must have **free Amazon Prime delivery** (Prime badge and FREE delivery shown for the offer evaluated). **Sold and dispatched by Amazon itself (Amazon retail) is also allowed (user rule 2026-10-14)**, so FBM, FBA and Amazon-sold offers all qualify; the Prime free-delivery requirement still applies. When the same product has several offers or listings, **select the one with the lowest product cost and the higher profit margin**. The other Amazon rules (§5.1 sellers 3–20, rating, weight, price, New, demand 1K+) are unchanged.
4. Keepa (extension, **Buy Box price graph only**): the Buy Box price and availability must have been stable and continuous for at least 3 months. Avoid any break longer than 5–7 days.
   - **Sourcing cost (user rule 2026-10-12, supersedes the 2026-10-08 wording):** the **highest Buy Box price on the Keepa graph in the last 3 months that stayed in place for at least 5 days** is the baseline item cost; a spike shorter than 5 days is ignored. If today's price is higher, today's price is used. (This restores the "held 5+ days" condition that 2026-10-08 had removed.)
5. Fastest delivery: **5 days maximum** (user rule 2026-10-06; same limit as the earlier "3–5 days or better"). Over 5 days fails.
6. Verify the product on eBay UK using Product Research and sold data (§9).
7. Prefer eBay competitor sellers with 5–10+ sales in the last 30 days.
8. Calculate eBay fees and profit (§10) before accepting.
9. Compliance status defaults to `COMPLIANCE_REVIEW` (§22).
9a. **Amazon cost safety and screening rules (user rules 2026-10-12):**
   1. **eBay first (user rule 2026-10-13: the 55% price-gap pre-screen is removed):** start from eBay (ZIK seller tables, competitor stores, Product Explorer) and look for the product on Amazon; do not browse Amazon labels first. Any Amazon product may be opened; the profit test (§10) decides, not a fixed price ratio.
   2. **Cost buffer: 4% for Amazon (user rule 2026-10-13, after the 5% buffer was removed and re-added at 4% the same day).** The profit test also runs with the Amazon item cost raised **4%** (`cost_buffer_gate`, must pass) to cover price fluctuations; `max_safe_cost` is recorded in every profit row.
   3. **Deal-priced costs (user rule 2026-10-13):** a Limited time deal price may be used as the cost **when the Keepa Buy Box graph shows that price has been stable** (held for most of the 3-month window, §5.4); otherwise re-cost at the highest regular price held 5+ days. Coupons, subscription vouchers and "Save x%" offers are still not used. The Keepa 3-month average must be within **10%** of today's price.
   4. **Preference:** multipacks and sets from small-business sellers with an eBay price gap; avoid single low-value items and heavy brands.
   5. **Discovery:** eBay competitors with unbranded, light items at about GBP 8-20 are the preferred starting point for Amazon checks.
   6. **Price stability (user rule 2026-10-12, replaces the earlier 3-separate-days check):** read the Keepa Buy Box graph for the **last 3 months**. The cost is the **highest price that stayed in place for at least 5 days**; a brief spike shorter than 5 days is ignored. If today's price is higher than that, today's price is used.
   7. **Thin margin flag (all sources):** if the eBay reference price is within **3%** of `minimum_listing_price` the product is flagged `THIN` in the report (`thin_margin_flag`); it can still pass.
   8. **Quality guard:** rating 4.0-4.2 stays allowed (rule is 4+) but is flagged as a returns risk.
9. **Exact-match discovery (user rule 2026-10-13):** start from ZIK Product Explorer with ebay.co.uk, United Kingdom, Buy It Now, Brand New, an eBay price of about GBP 15-35, sales 30+ and the supplier item match set to Exact Items (supplier Amazon UK); keep only light, unbranded or non-VeRO items, then run the full workflow.
10. **Where to look (user rule 2026-10-13):** niche or fitment-specific accessories, replacement parts, car accessories for a particular model and small branded-look pet and garden items, where eBay prices exceed Amazon's; avoid saturated generic lines (spice racks, packing cubes, foam rollers, car boot organisers) unless the eBay price clears the profit test.
11. **Christmas timing (user rule 2026-10-13):** Amazon prices are stable into Christmas while eBay prices and demand rise from mid-November; check Keepa for a stable price and the eBay price trend, then prepare listings ahead of the rise. Branded Christmas merchandise stays banned (§4).
12. **Source routing (user rule 2026-10-13):** Amazon is for branded (non-VeRO) items and items not available elsewhere; generic items are routed to Go Dropship and AliExpress first (§17a).

