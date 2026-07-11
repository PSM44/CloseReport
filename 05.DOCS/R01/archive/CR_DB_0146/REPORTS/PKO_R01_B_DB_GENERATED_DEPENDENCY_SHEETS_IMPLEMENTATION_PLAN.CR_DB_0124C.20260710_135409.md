# R01_B DB-generated dependency sheets implementation plan - CR-DB-0124C

- MB_ID: CR-DB-0124C-PLAN-R01-B-DB-GENERATED-DEPENDENCY-SHEETS-IMPLEMENTATION-NOREGEX
- Period: 2026-05
- Package version: v001
- Feedback source: C:\Users\aazcl\Downloads\GlobalTemp.CierreMes\CR_DB_0120D_FEEDBACK.json
- Scope source: C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\control\PKO_R01_B_DB_GENERATED_DEPENDENCY_SCOPE.CR_DB_0121.20260710_104951.csv
- DB-first policy source: C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\control\PKO_R01_100_PERCENT_DB_DATA_SOURCE_POLICY.CR_DB_0123.20260710_133023.csv

## Decision
The 5 R01_B dependency sheets must be implemented as DB/rules/generator outputs before R01_B can be accepted as DB-first complete.

## Implementation order
1. F.CMC - PARTIAL_MINIMUM_RANGE_FIRST_UF_PERIOD_HEADERS - main.xlsx > F.D.KUM.01!E3:AF3
2. D.BB - PARTIAL_MINIMUM_RANGE_FIRST_BARNES_DEPENDENCY - main.xlsx > F.D.KUM.01!W9:AC9 | main.xlsx > F.D.KUM.01!W23:AC23
3. Detalle Koke - PARTIAL_MINIMUM_RANGE_FIRST_KOKE_DETAIL_DEPENDENCY - main.xlsx > F.D.KUM.01!W24:AC24
4. . F.BS2.01 - PARTIAL_MINIMUM_RANGE_FIRST_BESMART2_DEPENDENCY - main.xlsx > F.D.KUM.01!R26:AC26
5. F.D.KMT.01 - PARTIAL_MINIMUM_RANGE_FIRST_FINANCING_DEPENDENCY - main.xlsx > F.D.KUM.01!E44:P44 | main.xlsx > F.D.KUM.01!R44:AC44

## Rule
No dependency sheet may be copied manually from main.xlsx as final architecture.
Legacy workbook may be used only as benchmark/evidence for validation during transition.

## Technical note
This runner intentionally avoids dynamic PowerShell regex after CR-DB-0124B failed due to escaped variable interpretation.
Minimum ranges are marked REVIEW_FROM_DB_MAPPING and must be finalized during implementation.

## Evidence created
- Implementation plan CSV: C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\control\PKO_R01_B_DEPENDENCY_SHEETS_IMPLEMENTATION_PLAN.CR_DB_0124C.20260710_135409.csv
- Minimum ranges CSV: C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\control\PKO_R01_B_DEPENDENCY_SHEETS_MINIMUM_RANGES.CR_DB_0124C.20260710_135409.csv
- Generator tasks CSV: C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\control\PKO_R01_B_DEPENDENCY_SHEETS_GENERATOR_TASKS.CR_DB_0124C.20260710_135409.csv
- Risk CSV: C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\evidence\PKO_R01_B_DEPENDENCY_SHEETS_IMPLEMENTATION_RISKS.CR_DB_0124C.20260710_135409.csv
