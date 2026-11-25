# Profit Engine — common profit-calculation stage

**Stage:** profit, margin and ROI for candidates that have completed eBay verification.
**Workflow position:** source hunters → eBay verification → **Profit Engine** → [hand-off] → scoring / compliance / daily report.
**Governing rules:** CLAUDE.md §3 (price, profit, ROI), §10 (formulas), §19, §23–§26. This module does not change or relax them. If this file and CLAUDE.md disagree, CLAUDE.md wins.

This module does NOT:
- research products or collect new eBay evidence
- score candidates, decide compliance, or produce the daily report
- buy, list or publish anything

**All arithmetic is done by `tools/profit_calc.ps1`**, so results are reproducible and auditable. Do not calculate by hand.

---

## 1. Input
- Rows in `data/ebay/YYYY-MM-DD_ebay_verification.csv` with `proceed_to_profit` = `YES`.
- `config.yaml`:
  - `fees.*`: user-editable settings. Currently: eBay fees from today's fee table (no fixed rate), not VAT registered (VAT 20% added), insertion fee £0.36 inc. VAT (`include_insertion_fee`), ad rate 3% under a £8 listing price / 5% from £8 (+ VAT = 3.6% / 6%), sourcing buying fee **0% for all sources since 2026-10-13** (`sourcing_buying_fee_rate`, `sourcing_buying_fee_rate_amazon`, `sourcing_buying_fee_rate_godropship`).
- `data/fees/<date>_ebay_business_fees.csv`: today's observed eBay fee table (required for VERIFIED fees).
  - `profit.listed_price_basis`.
- Optional: an ad rate the user gives for this run (`-AdRate`). It is never assumed.
- Optional: user-approved exceptions in `data/profit/YYYY-MM-DD_profit_exceptions.csv` (step 6).

## 2. Value statuses
Every input is labelled:

| Status | Meaning | Examples |
|---|---|---|
| `VERIFIED` | Observed for this product/listing, with evidence | source price seen on the page; fee seen in eBay's fee calculator; median of the matched sold sample |
| `USER_SET` | A rate the user chose (a decision, not a market fact) | ad rate given for this run or set in config |
| `ESTIMATED` | An assumption not observed for this listing | a fee rate from `config.yaml` |
| `UNKNOWN` | Not available | anything not observed and not set |

**eBay fee: always eBay's current fee data (CLAUDE.md §10, user rule 2026-10-03). Never a fixed percentage.**
- Source: today's `data/fees/<date>_ebay_business_fees.csv` (eBay's business-seller fee page, recorded at step 5b). The product's `ebay_category_path` is matched to a fee category (the deepest matching breadcrumb level wins, e.g. Garden & Patio before Home & Garden).
- `ebay_fee_rate_pct` = (category final value fee + regulatory fee) × (1 + VAT). The user is not VAT registered, so VAT is 20% (`config.yaml` `fees.vat_registered: false`, `fee_vat_rate`).
- `ebay_fixed_fee` = per-order fee × (1 + VAT): £0.30 for orders up to £10, £0.40 over £10, or the reduced £0.10 up to £10 where the table marks it (Home, Furniture & DIY).
- The insertion fee (£0.36, already including VAT) is added separately.
- Status VERIFIED when today's table and the category are both present. Otherwise UNKNOWN: no table today, or the category is not recorded or not matched.
- `fee_category` and `fee_vat_applied` are shown in the output.

**Ad rate by listing price, plus VAT (CLAUDE.md §10, user rule 2026-10-08).**
- Listing price under £8: `fees.ad_rate_low_price` (3%). £8 or more: `fees.ad_rate` (5%, never below `fees.ad_rate_minimum`).
- Because the user is not VAT registered, 20% VAT is added (`fees.ad_fee_vat: true`): 3% → 3.6%, 5% → 6% of the listed price. `ad_rate_pct` shows 3.0 or 5.0; `ad_rate_incl_vat_pct` shows 3.6 or 6.0.
- A higher rate can be given for a run with `-AdRate`. It is never used below the tier's rate.
- The ad rate is never 0%.

## 3. Inputs used
| Spreadsheet field | Field | Taken from |
|---|---|---|
| Product name | `product_name` | eBay verification row |
| eBay seller / link / price | `reference_seller_name`, `reference_seller_url`, `reference_seller_price` | eBay verification: the reference competitor (top 20, under 20k feedback, 5+ sales in 30 days, best qualifying price) |
| Source link / item cost | `source_url`, `source_price` (+ status) | **always** the item price on the sourcing website (Amazon UK / AliExpress UK / Go Dropship UK), from the hunter row via eBay verification |
| Sourcing buying fee | `sourcing_buying_fee` (+ status, source) | source page if shown; else config `sourcing_buying_fee` (a fixed £, if set); else config `sourcing_buying_fee_rate` × item cost (0%; Go Dropship 5%; AliExpress 4% FX; ESTIMATED); else UNKNOWN |
| Source delivery charge | `source_delivery_charge` (+ status) | source page (an "other known cost" in §10) |
| eBay fee | `ebay_fee_rate_pct`, `ebay_fixed_fee`, `ebay_fee_amount` | fee priority above |
| Insertion fee | `insertion_fee` (+ status) | config `fees.insertion_fee` (ESTIMATED) when `include_insertion_fee: true`; 0 (USER_SET) when excluded or run with `-NoInsertionFee`. Included in `ebay_fee_amount` |
| Ad rate % | `ad_rate_pct`, `ad_cost` | 3% under a £8 listing price, 5% from £8 (config), or a higher `-AdRate`; VAT added to the ad cost |
| Listed price | `listed_price` | **always** the eBay competitor's listing price (`reference_seller_price`; `profit.listed_price_basis: reference_seller_price`) |

**Listed price (CLAUDE.md §10).** The listed price is the eBay competitor's listing price: the total buyer price (item + postage) of the reference competitor recorded at eBay verification. Fees and ad cost are applied to this same total. If the competitor price is `UNKNOWN`, the listed price is `UNKNOWN`. The median sold price is not substituted; it is still shown as `ebay_market_median_total`, for context only.

## 4. Formulas (CLAUDE.md §10)
With P = listed price (total buyer price), f = eBay fee rate, F = eBay fixed per-order fee, I = insertion fee (0 if excluded), a = ad rate, S = source price, B = sourcing buying fee, O = other known costs (source delivery charge):

```
ebay_fee_amount = f × P + F + I
ad_cost         = a × P
total_cost      = S + B + O + ebay_fee_amount + ad_cost
profit          = P − total_cost
profit_pct      = profit ÷ P                    (profit margin)
roi_pct         = profit ÷ (S + B + O)          (eBay fees and ads excluded from the base, per §10)
```

Pricing tiers by **eBay listing price** (CLAUDE.md §3, §10, user rule 2026-10-08; rounded **up** to the penny):

```
C = S + B + O + F + I
pricing_tier = 1 if listing price P < £8.00;  2 if P ≥ £8.00

tier 1 (a = 3% + VAT):  profit ≥ £1, any margin
tier 2 (a = 5% + VAT):  profit ≥ £1 AND (margin ≥ 30% OR ROI ≥ 20%)

minimum_listing_price = (C + £1) ÷ (1 − f − a3)                      if that is under £8
                        otherwise the higher of £8, (C + £1) ÷ (1 − f − a5) and
                        the lower of  C ÷ (1 − f − a5 − 30%)                  (30% margin)
                                 and  (C + 20% × (S + B + O)) ÷ (1 − f − a5)  (20% ROI)
min_price_all_gates = higher of minimum_listing_price and £2
```

f is the current eBay fee for the category including VAT. The per-order fee for orders up to £10 is tried first; if the result is over £10, the over-£10 fee is used. The listed price stays the competitor's price; it passes the economics only if it is at or above `min_price_all_gates` and no more than £35.

## 5. Calculation status and gates
**`calculation_status`:**
- `VERIFIED`: every input is VERIFIED or USER_SET.
- `ESTIMATED`: no input is UNKNOWN, and at least one is ESTIMATED.
- `UNKNOWN`: at least one input is UNKNOWN.

**When the status is UNKNOWN:**
- Profit, margin, ROI and the minimum prices are **not** reported.
- Instead, an **upper bound** is reported, treating every unknown cost or rate as £0 or 0%: `profit_upper_bound`, `profit_pct_upper_bound`, `roi_pct_upper_bound`.
- Unknown costs can only lower profit, so:
  - if the upper bound already fails a gate, the gate is `FAIL`;
  - if it passes, the gate stays `UNKNOWN`.
- The upper bound is never presented as the profit.

**Gates (CLAUDE.md §3):**

| Gate | PASS | FAIL | Otherwise |
|---|---|---|---|
| `price_gate` | £2.00 ≤ listed price ≤ £35.00 | outside | UNKNOWN if no price |
| `profit_gate` | profit ≥ £1.00 | profit < £1.00 | UNKNOWN (see upper bound) |
| `margin_gate` | tier 2 (listing price ≥ £8.00): margin ≥ 30%, **or** ROI ≥ 20% (then the note "margin X% is less than 30%; passed on ROI" is added). Tier 1: `N/A` | tier 2 with margin < 30% and ROI < 20% | UNKNOWN (see upper bound) |
| `roi_gate` | always `N/A` from 2026-10-08: ROI has no gate of its own; it can only stand in for the margin | | |

From 2026-10-08 the item-cost ROI tiers (under £10 / £10+) no longer apply. ROI is still calculated and reported.

**`acceptance_status`** is the worst of `ebay_verification_status` and the three gates (an `N/A` gate is skipped), in this order: `FAIL` > `EXCEPTION` > `UNKNOWN` > `PASS`.

**`acceptance_basis`** = `calculation_status`:
- A PASS on an ESTIMATED basis must always be reported as **"PASS (ESTIMATED)"**, never as confirmed.
- A FAIL on an ESTIMATED basis is reported as **"FAIL (ESTIMATED)"**.

This is the economics acceptance only. Compliance (`COMPLIANCE_REVIEW`), scoring and final selection are later stages.

## 6. Exceptions
An exception may apply to a gate that FAILED on a completed (VERIFIED or ESTIMATED) calculation, by a minor margin, when the economics are otherwise clearly strong (CLAUDE.md §3).
- Record it in `data/profit/YYYY-MM-DD_profit_exceptions.csv` (`candidate_id,gate,justification`), with gate = `price`, `profit` or `margin`, and the observed value vs the threshold in the justification.
- The script then sets that gate to `EXCEPTION`.
- Exceptions on an UNKNOWN calculation are refused and noted.
- Upstream exceptions (hunter / eBay stage) are carried into `exceptions`.
- Acting on any exception requires the user's approval (§23).

## 7. Run
```
powershell -File tools\profit_calc.ps1                    # today's UK date
powershell -File tools\profit_calc.ps1 -Date 2026-10-02
powershell -File tools\profit_calc.ps1 -AdRate 0.07       # a higher ad rate for this run (never below the tier rate; VAT added)
powershell -File tools\profit_calc.ps1 -NoInsertionFee    # leave the insertion fee out for this run
```

Standalone price check for a single cost (no files written): `powershell -File tools\pricing_calc.ps1 -SupplierCost 8.50` (or `-Test` for the comparison table). It uses the same tier formula.

**Output:** `data/profit/YYYY-MM-DD_profit.csv`, using the layout in `templates/profit_template.csv`.
- **Append-only** (CLAUDE.md §19). A re-run adds new rows with a new `calculated_at_uk`; the latest row per candidate is current.
- Every row records its inputs, their statuses and sources, the formula version, and notes, so it can be audited.

## 8. Report after a run
- the number of candidates calculated
- counts by `calculation_status` and `acceptance_status`
- every UNKNOWN input, and which unknown fee is blocking verified results
- every ESTIMATED result, with the assumption used
- every EXCEPTION applied or refused
- any tool/script mismatch (step 9)

## 9. User-provided profit-calculator tool (when available)
When the user provides browser access and a profit-calculator tool:
1. Open eBay's current fee information for the product's category. Record the final-value fee %, the fixed per-order fee, the fee basis, the URL and the date. These are VERIFIED fees.
2. Enter the inputs into the user's tool exactly: item cost (source price from the sourcing website), sourcing buying fee, source delivery charge, current eBay fee, ad rate (minimum 5%, plus VAT), and listed price (the eBay competitor's listing price).
3. Record the tool's name/URL, every input entered, and every output (fees, profit, margin, ROI), with a timestamp, in `notes` or the evidence file.
4. Run `tools/profit_calc.ps1` with the same inputs, and compare.
   - If they agree (within 1p, allowing for rounding), mark the result as cross-checked.
   - If they disagree, report both results and the difference to the user. Do not pick one silently.
5. The tool is used for calculation only. Never use it, or the browser, to list, buy or publish anything (CLAUDE.md §24, §25). Do not log in anywhere without the user's approval (§23).

## Interpretations to confirm with the user
1. **£1 profit.** CLAUDE.md says "at least £1"; the gate uses ≥ £1.00.
2. **Listed price.** The listed price is the eBay competitor's listing price (item + postage), with fees applied to that total. Whether eBay's fee basis includes postage is recorded by eBay verification (`fee_basis`); if it is not observed, the fee is not VERIFIED.
