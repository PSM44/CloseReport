# PKO R01 F.CMC period UF schema policy

- MB_ID: `CR-DB-0126-PLAN-AND-PREPARE-DB-SCHEMA-FOR-FCMC-PERIOD-UF-DEPENDENCY`
- Generated: `20260710_141914`

## Policy

- `F.CMC` must be generated from DB/rules/generator only.
- `main.xlsx` is benchmark-only and cannot seed the productive solution directly.
- `R01_E.01_FORMAT_CONTROL.xlsx` can contribute style only after F.CMC exists as DB-generated content.
- The proposed SQL is non-destructive and not applied in this run.
- No generator or workbook changes are accepted before the schema, seeding strategy, and rule contract are approved.

## Approval gate

1. Approve `dim_period` and `dim_period_rate` as the monthly period/UF contract.
2. Approve direct `F.CMC` staging/rule tables.
3. Approve a controlled seed strategy for monthly period rows and UF rates.
4. Only then implement the dedicated `R01_B` dependency builder.

## This run

- DB modified: `NO`
- Workbook modified: `NO`
- Generator modified: `NO`
- Proposed SQL path: `C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\control\CR_DB_0126_PROPOSED_FCMC_PERIOD_UF_SCHEMA.20260710_141914.sql`
