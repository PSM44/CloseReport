# PKO R01 B F.D.KMT.01 DB-first dependency policy

- MB_ID: `CR-DB-0136-FDKMT01-DEPENDENCY-SHEET-DB-FIRST-PLAN-AND-IMPLEMENTATION-READINESS`
- `main.xlsx` may be read only as controlled bootstrap benchmark and must never remain a runtime dependency.
- `R01_B.xlsx` must be self-contained after implementation.
- `R01_E.01_FORMAT_CONTROL.xlsx` is never a source of values, formulas, or logic.
- DB inserts are schema-aware and limited to dependency staging/rule tables.
- Workbook edits require backup first and must not introduce external references or `#REF!` formulas.