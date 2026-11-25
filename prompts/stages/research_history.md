# Research History and Rejection Tracking

**Stage:** keeps a permanent record of every researched product, its status and every rejection, and prevents unnecessary repeat research.
**Workflow position:** runs **before** the hunters (duplicate check) and **after** each day's stages (ingest).
**Governing rules:** CLAUDE.md §19 (never delete history), §20 (rejection tracking), §21 (lifecycle), §23 (user approval), §24–§26. Business rules are not changed here.
**Tool:** `tools/history.ps1`, which does all the bookkeeping, so the logic is consistent and auditable.

This module does NOT buy, list or publish anything, and does not research products by itself.

---

## 1. Files
| File | Kind | Content |
|---|---|---|
| `data/history/status_log.csv` | **append-only** | every status event for every product (who, when, why, recheck date, prices seen) |
| `data/history/rejection_history.csv` | **append-only** | one row per failed criterion per rejection, with evidence |
| `data/history/product_register.csv` | derived view | the current status per product, rebuilt from the status log (contains no original research) |

The append-only files are never edited or deleted. A correction is a new event with a reason (§19). The stage files in `data/sources/`, `data/ebay/`, `data/profit/` and `data/seasonal/` stay as they are; the history links back to them (`evidence`, `evidence_ref`).

Layouts: `templates/status_log_template.csv`, `templates/rejection_history_template.csv`, `templates/product_register_template.csv`.

## 2. Product identity
Each product gets a `product_key`, using the strongest identifier available:
1. `GTIN:<EAN/UPC>`
2. a source ID: `AMZ:<ASIN>`, `ALI:<AliExpress item ID>` or `GDS:<supplier SKU>`
3. `TITLE:<normalised title>` (lowercase, letters and digits only)

All the identifiers seen are stored in `alt_keys`. Once a product has a key, any of its identifiers finds it again, even if a stronger ID turns up later.

## 3. Status system
| Status | Meaning | Set by |
|---|---|---|
| `NEW` | Found by a hunter and forwarded; later stages not finished yet | agent |
| `RESEARCHED` | Evaluated, but the outcome is incomplete (UNKNOWN data, e.g. fees not observed) | agent |
| `QUALIFIED` | Passed every gate so far (hunter, eBay, profit, seasonal timing). Awaiting the user. Compliance review is still separate. | agent |
| `APPROVED` | The user approved the product (§23) | **user only** |
| `LISTING_READY` | The user has prepared it for listing | **user only** |
| `LISTED` | The user listed it themselves. The agent never lists (§25); this only records the user's action. | **user only** |
| `WATCH` | Failed a criterion that **may change** (price, stock, delivery, demand, competition, season, fees, access). Rechecked later. | agent |
| `KEEP` | Was QUALIFIED (or user-approved) and still meets the gates at review (§21) | agent |
| `DEPRIORITISE` | Low chance of becoming viable: a failure that only a different variant/pack would fix (weight, variations), or repeated WATCH failures. Rechecked, less often. | agent |
| `RETIRE` | Intrinsic failure under CLAUDE.md §4 (avoid list, brand/VeRO, IP/character, counterfeit). Not rechecked automatically. **Only the user can reopen it.** | agent; reopen by user |

User-only statuses are written only on the user's instruction (`-SetBy USER`); the tool refuses otherwise. When a product has a user status, later automatic research **never overwrites it**. The agent's view is recorded in `recommended_status` and reported to the user (e.g. a LISTED product that now fails ROI → recommended `WATCH`).

## 4. How statuses are decided (`-Action Ingest`)
After each day's stages, run:
```
powershell -File tools\history.ps1 -Action Ingest -Date YYYY-MM-DD
```
For each candidate, the tool follows it through the furthest stage reached: hunter → eBay verification → Profit Engine → seasonal classification. It then sets the status:

| Outcome | Status | Recheck |
|---|---|---|
| any failure that is intrinsic (§4) | `RETIRE` | none (user may reopen) |
| otherwise any weight/variations failure | `DEPRIORITISE` | `deprioritise_recheck_days` |
| otherwise any changeable failure | `WATCH` | `watch_recheck_days`; **seasonal timing** failures: the next occurrence's preferred listing start (from the seasonal engine) |
| a WATCH product failing again after `max_consecutive_watch` WATCH results | `DEPRIORITISE` | `deprioritise_recheck_days` |
| a DEPRIORITISE product failing again | stays `DEPRIORITISE` | `deprioritise_recheck_days` |
| outcome UNKNOWN / incomplete | `RESEARCHED` | `researched_recheck_days` |
| passed every gate | `QUALIFIED`, or `KEEP` if it was already QUALIFIED/KEEP/user-approved | `qualified_review_days` (lifecycle review) |
| forwarded, later stages not run yet | `NEW` | none |

eBay access problems (blocked/CAPTCHA, no evidence) and seasonal-timing failures never escalate a product to DEPRIORITISE, because they say nothing about the product itself.

Re-running Ingest for the same day adds nothing (one event per candidate per stage per day). Running it again after a later stage finishes adds the new stage's event.

**Operational defaults, not business rules.** The recheck intervals and WATCH limit are in `config.yaml` → `history`: 14 / 60 / 7 / 14 days, and 3 WATCH results before DEPRIORITISE.
- They are configurable workflow defaults only. They are not business rules, not product-selection criteria, not eBay requirements, and not part of the user's original product-hunting criteria.
- They control only **when** a product is rechecked, never **whether** it passes.
- Changing them is not a change to the user's business strategy, and needs no CLAUDE.md change or CHANGE_PROPOSAL, unless a permanent business rule is also being changed.

## 5. Rejection history
Every failed criterion becomes one row in `rejection_history.csv`:

| Field | Content |
|---|---|
| `rejected_on`, `candidate_id`, `product_key`, `alt_keys` | when and which product |
| `product_name`, `source`, `source_url`, `ebay_url` | what and where (the eBay competitor listing, or the sold search if no competitor) |
| `stage`, `failed_criterion` | where it failed and which rule (e.g. `SOURCE/stock`, `EBAY/str`, `PROFIT/roi`, `SEASONAL/seasonal_timing`) |
| `rejection_reason`, `observed_value`, `threshold` | why: the observed value against the rule |
| `evidence` | the evidence text/URL, plus `stage file#candidate_id` |
| `failure_may_change` | `YES` (may change) / `LOW` (only with a different variant) / `NO` (intrinsic, §4) |
| `change_triggers` | what would make it viable (e.g. "source price drop", "restock", "eBay demand change", "next event/season occurrence") |
| `resulting_status`, `recheck_due` | WATCH / DEPRIORITISE / RETIRE, and when it is rechecked |
| `product_type`, `seasonality`, `target_event`, `seasonal_phase` | the seasonal classification at the time |
| `notes` | the hunter's notes |

Products dropped as same-day duplicates are still logged in the daily rejections file with `failed_gate = DUPLICATE` (§20).

## 6. Avoiding repeated research (`-Action Check`)
**Before evaluating any product**, each hunter checks it:
```
powershell -File tools\history.ps1 -Action Check -SourceId AMZ:B0XXXXXXX
powershell -File tools\history.ps1 -Action Check -Gtin 5012345678900
powershell -File tools\history.ps1 -Action Check -Title "Product title as shown"
```

| Decision | Meaning | Hunter action |
|---|---|---|
| `RESEARCH` | Never seen | Research normally |
| `RESEARCH_CHECK_POSSIBLE_MATCH` | Not found by ID, but a similar title exists | Compare image/spec with the listed match. If it is the same product, treat it as that product; otherwise research it as new |
| `RECHECK` | Seen before and its recheck date has arrived (or it was left NEW on an earlier day) | Research again with **fresh** evidence (never copy old values) |
| `SKIP unless a recheck trigger is observed` | WATCH / DEPRIORITISE / RESEARCHED / QUALIFIED / KEEP, not yet due | Do not research. **Early recheck is allowed** if a listed trigger is directly observed, e.g. the source price is now lower than `last_source_price`, the item is back in stock, or delivery is faster. Record the trigger in `notes`. |
| `SKIP (RETIRE ...)` | Intrinsic failure | Do not research. Only the user can reopen it. |
| `SKIP (user status ...)` | APPROVED / LISTING_READY / LISTED | Already in the user's pipeline; not re-researched as a new candidate |

Skipped products do not count towards the 5-per-source target. The hunt continues with other products (§17).

## 7. Returning from WATCH / DEPRIORITISE
A product is never blacklisted for failing once. It comes back when:
1. **Its recheck date arrives.** `-Action Due` lists every WATCH, DEPRIORITISE, RESEARCHED, QUALIFIED and KEEP product that is due:
   ```
   powershell -File tools\history.ps1 -Action Due -Date YYYY-MM-DD
   ```
   Due products are researched again through the normal stages.
2. **A trigger is observed early** (see the Check table): e.g. price change, restock, faster delivery, a demand or competition change seen on eBay, or the season changing (seasonal-timing failures are scheduled for the next occurrence's preferred listing start).
3. **The user asks** for a recheck.

The new research is ingested like any other day:
- If it now passes every gate, it becomes `QUALIFIED` (or `KEEP`).
- If it fails a changeable criterion, it goes to `WATCH` again (or `DEPRIORITISE` after repeated failures).

The full history of every attempt stays in the logs.

**RETIRE** products return only when the user reopens them:
```
powershell -File tools\history.ps1 -Action SetStatus -Key <product_key> -Status WATCH -Reason "<why>" -SetBy USER
```

## 8. Manual status changes (`-Action SetStatus`)
- The user's decisions are recorded with `-SetBy USER`: APPROVED, LISTING_READY, LISTED, reopening a RETIRE product, or overriding any status.
- The agent may set agent statuses with a reason (e.g. a WATCH product the user asked to look at). A reason is always required, and the change is appended, never overwritten.

## 9. Report after Ingest
- the number of products by status, and the changes since the previous run
- new rejections, by stage and criterion
- rechecks due tomorrow / this week
- products with a user status whose `recommended_status` differs (e.g. a LISTED product now failing): **these need the user's attention**
