# R1 DB-to-Excel MVP Stabilization

- MB_ID: CR-DB-0104-R1-DB-TO-EXCEL-MVP-STABILIZATION-AND-NEXT-HARDENING-TEXT-ONLY
- Status: MVP_PROVEN_DRYRUN_NOT_PRODUCT_LOCKED
- Report: R1 = main.xlsx > F.D.KUM.01!C3:AF67
- Demo locked period: 2026-05
- Next editable period: 2026-06

## Proven
- No-COM ZIP/XML build path works.
- Dry-run SQLite DB exists.
- Trigger contract exists: RUN_REPORT_R1_FD_KUM_01_C3_AF67.
- Output workbook exists.
- Validation passed: 1950/1950 value matches.
- Output has no formulas after generation.
- Output has no external workbook references after generation.
- June input table exists in DB with hard-number input candidates.

## Evidence
- DB dry-run: C:\Users\aazcl\Downloads\GlobalTemp.CierreMes\GPT_UPLOAD_LOCK.CR-DB-0102D.20260707_105712\R1_CONTROLLED_DB_ZIPXML_DRYRUN.2026-05.20260707_105712.sqlite
- Output workbook: C:\Users\aazcl\Downloads\GlobalTemp.CierreMes\GPT_UPLOAD_LOCK.CR-DB-0102D.20260707_105712\R1_FD_KUM_01_C3_AF67_ZIPXML_DB_DEMO_OUTPUT.2026-05.20260707_105712.xlsx
- Seed CSV: C:\Users\aazcl\Downloads\GlobalTemp.CierreMes\GPT_UPLOAD_LOCK.CR-DB-0102D.20260707_105712\R1_zipxml_seed_cells.CR_DB_0102D.20260707_105712.csv
- Rule CSV: C:\Users\aazcl\Downloads\GlobalTemp.CierreMes\GPT_UPLOAD_LOCK.CR-DB-0102D.20260707_105712\R1_zipxml_formula_rules.CR_DB_0102D.20260707_105712.csv
- Validation CSV: C:\Users\aazcl\Downloads\GlobalTemp.CierreMes\GPT_UPLOAD_LOCK.CR-DB-0103.20260707_110411\R1_zipxml_output_validation.CR_DB_0103.20260707_110411.csv
- Evidence register: C:\Users\aazcl\Downloads\GlobalTemp.CierreMes\GPT_UPLOAD_LOCK.CR-DB-0104.20260707_111614\R1_mvp_evidence_register.CR_DB_0104.20260707_111614.csv

## Metrics
- TOTAL_CELLS: 1950
- VALUE_MATCHES: 1950
- VALUE_MISMATCHES: 0
- SOURCE_FORMULA_CELLS: 163
- FORMULA_AFTER: 0
- EXTERNAL_REFS_AFTER: 0
- SEED_ROWS: 859
- RULE_ROWS: 163
- JUNE_INPUT_ROWS: 632

## Limits
- Product DB is not modified.
- Temp artifacts are not permanent unless promoted.
- Numeric typed hardening remains pending.
- Formula perfection remains pending for non-core branches.
- Full production trigger runner remains pending.
- Catalog lock for all reports remains pending.
