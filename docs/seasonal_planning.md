# Seasonal Planning

Use a rolling calendar rather than a permanent Christmas-only strategy.

Preferred event listing lead time: 60 days.
Minimum event listing lead time: 30 days.

These are business planning assumptions supplied by the user, not eBay ranking guarantees.

Maintain:
- evergreen research
- current-event research
- next-event preparation

Default mix: 50% / 30% / 20%.

For Christmas on 25 December, the 60-day preferred start is 26 October and the 30-day minimum start is 25 November. The agent must calculate dates from the current year rather than hard-code this example.

## Phases
Phase definitions are set in CLAUDE.md §15; this is a summary.

- more than 60 days: PREPARE_EARLY
- 30–60 days: START_NOW
- 0–29 days: LATE_EVENT_WINDOW
- event passed / season window ended: POST_EVENT
- IN_SEASON (date-window seasons only): the seasonal window has started and today is on or before the season's end date. Continue researching while there is evidence of demand. Prioritise products that can still reasonably sell within the remaining season. Do not stop just because the preferred/minimum preparation date has passed. Apply all normal criteria. Report the remaining days in the season.

Never delete historical candidate research. Reassess candidates as KEEP, WATCH, DEPRIORITISE or RETIRE.

## Tools
- `tools/seasonal_dates.ps1` calculates the dates, days until, listing starts, phases, priority (`Not defined` unless set in the calendar) and allocation role from `data/event_calendar.yaml`.
- Product-level classification (evergreen / seasonal / hybrid) is in `prompts/stages/seasonal_classification.md`.
