# PKO R01_B F.CMC DB-generated dependency implementation

- MB_ID: `CR-DB-0125-IMPLEMENT-R01-B-FCMC-DB-GENERATED-DEPENDENCY-SHEET`
- Generated: `20260710_140739`
- Mode: `PLAN_ONLY`
- Final status: `PASS_WITH_REVIEW`
- Main workbook usage: `BENCHMARK_ONLY`
- Format control usage: `NOT_USED`

## Decision

F.CMC is not implemented into `R01_B.xlsx` in this run because the repo does not yet provide a safe DB/rules/generator mapping for the dependency sheet itself. The current controlled DB contains downstream UF values for `F.D.KUM.01!E3:AF3`, but not direct `F.CMC` generator rows or approved period-rate coverage sufficient to emit the dependency sheet as DB-native.

## Evidence

- `C:\01. GitHub\CloseReport\06.TOOLS\build_fc_kum_dual_report.py` | `GENERATOR_SCOPE` | Existing Python builder targets FC_KUM dual report output, not R01_B dependency sheets.
- `C:\01. GitHub\CloseReport\01.DB\close_report.sqlite` | `DB_SCHEMA` | Applied live DB tables: fd_kmt_01_bases_formula_probe, load_batches, movements, report_contracts, report_outputs_contract, validation_results.
- `C:\01. GitHub\CloseReport\03.DATA\db\current\CloseReport_CierreMes.sqlite` | `PARTIAL_DB_MAPPING` | Current staging DB tables: formula_rule, period, report_run, sqlite_sequence, staging_value, validation_result.
- `C:\01. GitHub\CloseReport\03.DATA\db\current\CloseReport_CierreMes.sqlite` | `PERIOD_COVERAGE` | Current period table rows: 1.
- `C:\01. GitHub\CloseReport\03.DATA\raw\current\main.xlsx` | `BENCHMARK_ONLY` | Benchmark main.xlsx has F.CMC and F.D.KUM.01 formulas referencing it.
- `C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\current\R01_B.xlsx` | `CURRENT_WORKBOOK_STATE` | R01_B sheets after inspection: _TRACE_NOTES_ROUTES, F.D.KUM.01, _CONTROL, _PROJECT_CATALOG.
- `C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\format_control\R01_E.01_FORMAT_CONTROL.xlsx` | `STYLE_ONLY_EXCEPTION` | Format-control sheets: _TRACE_NOTES_ROUTES, _FORMAT_CONTROL_README, F.D.KUM.01, _CONTROL, _PROJECT_CATALOG.
- `C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\control\PKO_R01_B_DEPENDENCY_SHEETS_IMPLEMENTATION_PLAN.CR_DB_0124C.20260710_135409.csv` | `IMPLEMENTATION_POLICY` | 0124C marks F.CMC as implementation order 1 with DB/rules/generator-only policy.

## Gaps

- `GAP_FCMC_001` | `DB_SCHEMA` | Applied live DB does not contain dim_period_rate or equivalent approved period-rate table.
- `GAP_FCMC_002` | `GENERATOR_RULE` | No formula_rule rows target F.CMC. Existing rules only cover F.D.KUM.01 financing cells.
- `GAP_FCMC_003` | `STAGING_MAPPING` | No staging_value rows target F.CMC directly. Only downstream UF_CLP_MONTH_END values exist on F.D.KUM.01.
- `GAP_FCMC_004` | `PERIOD_COVERAGE` | Period table has only 1 row(s); insufficient to reconstruct benchmark-style monthly headers E:AF.
- `GAP_FCMC_005` | `STYLE_CONTROL` | Format-control workbook has no F.CMC sheet, so style-only propagation path is not prepared for this dependency.

## Metrics

- FCMC cells generated: `0`
- FDKUM01 E3:AF3 cells checked: `28`
- Missing sheet refs after: `0`
- REF errors after: `0`

## Next implementation slice

1. Approve DB schema for period-rate/header support in the applied source of truth.
2. Add `F.CMC`-scoped rows to `formula_rule` and `staging_value` or an equivalent approved generator contract.
3. Implement a dedicated `R01_B` dependency-sheet generator that emits `F.CMC` before any style-only pass.
4. Back up `R01_B.xlsx`, generate `F.CMC`, then rerun the NON-COM dependency audit.

## Outputs

- Audit CSV: `C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\evidence\PKO_R01_B_FCMC_IMPLEMENTATION_AUDIT.CR_DB_0125.20260710_140739.csv`
- Gap CSV: `C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\control\PKO_R01_B_FCMC_DB_MAPPING_GAPS.CR_DB_0125.20260710_140739.csv`
- Feedback JSON: `C:\Users\aazcl\Downloads\GlobalTemp.CierreMes\CR_DB_0125_FEEDBACK.json`
