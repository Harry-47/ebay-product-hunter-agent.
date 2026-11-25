# Seasonal Product Classification — product-level seasonal layer

**Stage:** classifies each researched candidate as `evergreen`, `seasonal` or `hybrid`, and attaches its event/season timing.
**Workflow position:** source hunters (provisional classification) → eBay verification (sales-timing evidence) → Profit Engine → **Seasonal Classification** → [hand-off] → scoring / compliance / daily report.
**Governing rules:** CLAUDE.md §4, §12–§16, §19, §21, §26. It uses the existing Seasonal Planning Engine and `data/event_calendar.yaml` exactly as they are, and changes neither.

This module does NOT:
- create priority labels, scores or new gates
- change the calendar, the phases, the lead times or the 50/30/20 mix
- make a poor product acceptable because it is seasonal
- research products, buy, list or publish anything

> **Lead times:** the 60-day preferred and 30-day minimum listing starts are the **user's business planning assumption**, not an eBay requirement or ranking guarantee. Never present them as an official eBay rule.

---

## 1. Inputs
1. **Today's engine output**: run `tools/seasonal_dates.ps1` (step 2).
2. **Candidates**:
   - every row in `data/ebay/YYYY-MM-DD_ebay_verification.csv`, whether it passed or failed;
   - its Profit Engine row in `data/profit/YYYY-MM-DD_profit.csv`, if one exists.
   Hunter-rejected products keep the provisional classification already in their hunter stage file.
3. For each candidate, carry forward:
   - from the hunter: the provisional classification (`product_type`, `seasonality`, `allocation_bucket`, `target_event`)
   - from eBay verification: sales-timing evidence (`trend_window`, `trend_direction`, `trend_months_with_sales`, `seasonality_confirmed`, evidence URLs)
   - from the source: delivery days (Amazon `delivery_days`, AliExpress `delivery_days_max`, Go Dropship `delivery_days`)
   - `exceptions`, and the latest `acceptance_status` from the Profit Engine (or `ebay_verification_status` if there is no profit row)

## 2. Seasonal dates (the existing engine)
```
powershell -File tools\seasonal_dates.ps1 -OutputFile data\seasonal\YYYY-MM-DD_calendar.csv
```
The script implements `data/event_calendar.yaml` and CLAUDE.md §13–§15 as written:
- **Events:** the date comes from the calendar rule (fixed date, Easter, Easter − 21 days, third Sunday of June, the day after the fourth Thursday of November, the Monday after Black Friday). The next occurrence on or after today is used.
- **Windows:** the occurrence whose end date is today or later. The `anchor` date is where the lead times count back from.
- **Days until** = anchor/event date − today (UK).
- **Preferred listing start** = anchor/event date − `planning.preferred_listing_lead_days` (60). **Minimum listing start** = anchor/event date − `planning.minimum_listing_lead_days` (30).
- **Phase** (§15): more than 60 days = `PREPARE_EARLY`; 30–60 = `START_NOW`; 0–29 = `LATE_EVENT_WINDOW`; window start ≤ today ≤ window end = `IN_SEASON` (takes precedence, with days remaining in the season); event passed / window ended = `POST_EVENT`.
- **Priority:** only the `priority` value written in `data/event_calendar.yaml`. Otherwise `Not defined`.
- **Allocation role** (§13 step 7, §16):
  - `CURRENT_EVENT` = IN_SEASON, START_NOW or LATE_EVENT_WINDOW
  - `NEXT_EVENT_PREPARATION` = the earliest upcoming PREPARE_EARLY entry
  - `NOT_ALLOCATED` = anything else (no share of today's mix)

The calendar file is append-only history: an existing day's file is never overwritten (§19).

## 3. Classification
| `product_type` | Definition | Typical evidence |
|---|---|---|
| `evergreen` | Steady demand across the year, not tied to an event or season | Sales in most observed months, no event-linked uplift (§12) |
| `seasonal` | Demand concentrated around one event/season, with little demand outside it | Sales clustered before/during the event; little or none outside it |
| `hybrid` | Year-round demand, with a clear uplift around an event/season, and still useful afterwards | Sales across months plus an uplift before the event |

Rules:
1. **Evidence first.** Use the eBay sales-timing evidence. The product's nature, themes or the source's seasonal range are supporting context only. If they conflict with the sales evidence, the sales evidence wins and the conflict is noted.
2. **Target event.** For seasonal or hybrid products, pick the calendar entry whose themes and observed sales timing match. If several fit (e.g. gifting fits Christmas and Valentine's Day), the target is the **earliest upcoming entry that is not POST_EVENT and that the product can still reach in time** (step 5). List the others in `secondary_events`.
3. **`seasonality` label** (§13): evergreen → `evergreen`; seasonal → `<event>` (e.g. `christmas`); hybrid → `<event>_plus_evergreen` (e.g. `christmas_plus_evergreen`). If the evidence cannot separate the types → `unclear`, with the closest `product_type` and `seasonal_confidence` = LOW.
4. **Existing candidates.** If a candidate's recorded target occurrence has now passed, its phase is `POST_EVENT` for that occurrence. §15 action: clearance review, KEEP if hybrid, otherwise RETIRE. Historical rows are never edited; the new classification is a new row (§19).

## 4. Seasonal confidence and reason
`seasonal_confidence` describes how sure the **classification** is. It is not a priority or a score.
- `HIGH`: eBay sales-timing evidence covering the relevant period confirms the pattern. For seasonal products this includes the previous occurrence of the event (e.g. from a long Product Research window).
- `MEDIUM`: partial timing evidence (e.g. only recent months of sold dates) that is consistent with the classification.
- `LOW`: based on product nature/themes only, or the evidence is conflicting or insufficient.

`classification_basis` = `SALES_EVIDENCE` / `PARTIAL_EVIDENCE` / `PRODUCT_NATURE_ONLY`. `classification_reason` states, in plain words, why the type and target were chosen, and cites `sales_timing_evidence` (URLs and date windows).

## 5. Timing checks (existing rules only)
For seasonal and hybrid products, against the target occurrence:

| Check | Rule | Result |
|---|---|---|
| Can it arrive in time? | §4 "cannot realistically arrive before the event"; §13 | `order_cutoff_date` = event date (or window end) − source delivery days. If the cutoff is today or earlier → `timing_status` FAIL (no exception: §4 avoid rule). If source delivery days are UNKNOWN → `timing_status` UNKNOWN. |
| Demand lasts only a few days | §4 | From eBay verification: a spike of only a few days → FAIL (no exception). |
| New seasonal-only product for a passed event | §15 POST_EVENT "do not source new event-only products" | FAIL for that occurrence. It may be re-targeted to the next occurrence (usually PREPARE_EARLY, `NOT_ALLOCATED`). |
| LATE_EVENT_WINDOW | §15 | `timing_flags` += `LATE_TIMING`. Only fast UK-delivery products; prefer hybrid. A flag, not a gate. |
| After the minimum listing start | §14 (planning assumption) | `timing_flags` += `AFTER_MINIMUM_LISTING_START`. A flag, not a gate, because the lead time is a planning assumption. |
| IN_SEASON | §15 | Report `days_remaining_in_season`. Continue only while demand is evidenced. |

For evergreen products, `timing_status` = `N/A`.

## 6. Allocation bucket (existing 50/30/20 buckets only)
| product_type | Target's allocation role | `allocation_bucket` |
|---|---|---|
| evergreen | — | `evergreen` |
| seasonal / hybrid | CURRENT_EVENT | `current_event` |
| seasonal / hybrid | NEXT_EVENT_PREPARATION | `next_event_preparation` |
| hybrid | NOT_ALLOCATED, with year-round demand evidenced (confidence MEDIUM or HIGH) | `evergreen` (note the later event in `secondary_events`) |
| seasonal (or hybrid without year-round evidence) | NOT_ALLOCATED | `not_allocated`: kept for a later run; §15 phase action applies (e.g. PREPARE_EARLY: research and shortlist) |

This module only labels the bucket. The final mix (default 50/30/20, adjusted only with a recorded reason, §16) is applied by the later report stage.

`recommended_action` = the §15 default action for the phase (or `N/A (evergreen)`).

## 7. Seasonal products still have to pass every normal check
- `carried_acceptance_status` is copied unchanged from the Profit Engine (or eBay verification).
- `overall_status` = the worst of `carried_acceptance_status` and `timing_status`, in the order FAIL > EXCEPTION > UNKNOWN > PASS. `timing_status` N/A is ignored.
- Seasonal fit **never** turns a FAIL or UNKNOWN into a PASS, and it never raises a status.
- Compliance (`COMPLIANCE_REVIEW`) and scoring are decided in later stages.

## 8. Seasonal exceptions
- This layer never creates exceptions automatically.
- An exception for a seasonal product must be recorded **at the stage where the gate failed**, using that stage's process:
  - hunter: `exceptions` column
  - eBay verification: `exceptions`
  - Profit Engine: `data/profit/YYYY-MM-DD_profit_exceptions.csv`
  Each exception names the rule, the observed value vs the threshold, and the reason. Seasonal timing may be part of the reason, but never the only reason.
- Those exceptions are carried here unchanged in `exceptions`, so a seasonal product with an exception always shows `EXCEPTION`, never PASS.
- Timing failures based on §4 (cannot arrive in time; demand of only a few days) can never be excepted.
- Acting on any exception requires the user's approval (§23).

## 9. Output
One row per classified candidate:

`data/seasonal/YYYY-MM-DD_seasonal_classification.csv`

Use the column layout in `templates/seasonal_classification_template.csv`. Write `UNKNOWN` / `N/A` as appropriate; never leave a field silently blank. Append-only (§19).

Every row includes `lead_time_note` = "60/30-day listing lead times are the user's business planning assumption, not an eBay requirement."

At the end, report:
- counts by `product_type` and by `allocation_bucket`
- seasonal/hybrid products by target event and phase
- every `timing_status` FAIL/UNKNOWN, with its reason
- every LATE_TIMING / AFTER_MINIMUM_LISTING_START flag
- every exception carried
- every classification with LOW confidence, with the reason
