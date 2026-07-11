# PKO.R01 date period full trace rule policy - CR-DB-0114B

- MB_ID: CR-DB-0114B-DATE-PERIOD-FULL-TRACE-DB-PATCH-AND-PKO-REGEN
- Status: ACTIVE

## Rule
Do not patch isolated date header ranges manually. Detect date-period cells from original benchmark lineage and register each cell as a DB rule.

## Formula pattern
For month-end date cells, use DATE(year, month+1, 0).

## Scope
main.xlsx > F.D.KUM.01!C3:AF67 is audited for date serial cells row by row. Rows with at least two date serial cells become date-period candidate rows.
