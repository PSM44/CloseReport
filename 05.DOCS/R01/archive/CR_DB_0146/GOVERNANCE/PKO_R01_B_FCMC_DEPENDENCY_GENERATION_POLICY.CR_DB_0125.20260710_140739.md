# PKO R01_B F.CMC dependency generation policy

- MB_ID: `CR-DB-0125-IMPLEMENT-R01-B-FCMC-DB-GENERATED-DEPENDENCY-SHEET`
- Generated: `20260710_140739`
- Dependency sheet: `F.CMC`
- Target workbook: `C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\current\R01_B.xlsx`

## Policy

- `F.CMC` must be generated from DB/rules/generator only.
- `main.xlsx` is benchmark/evidence only and cannot be the productive source.
- `R01_E.01_FORMAT_CONTROL.xlsx` may contribute style only and must never contribute values, formulas, or logic.
- No manual legacy copy is accepted as the final solution.
- No `#REF!` or formulas to absent sheets are accepted in the final package.

## Current governance result

- The applied live DB is not yet ready to claim `F.CMC` as DB-native.
- The current staging DB exposes downstream UF outputs, not a full dependency-sheet contract.
- The first safe move is to close the mapping/schema gaps below before modifying `R01_B.xlsx`.

## Blocking gaps

- `GAP_FCMC_001` Applied live DB does not contain dim_period_rate or equivalent approved period-rate table.
- `GAP_FCMC_002` No formula_rule rows target F.CMC. Existing rules only cover F.D.KUM.01 financing cells.
- `GAP_FCMC_003` No staging_value rows target F.CMC directly. Only downstream UF_CLP_MONTH_END values exist on F.D.KUM.01.
- `GAP_FCMC_004` Period table has only 1 row(s); insufficient to reconstruct benchmark-style monthly headers E:AF.
- `GAP_FCMC_005` Format-control workbook has no F.CMC sheet, so style-only propagation path is not prepared for this dependency.
