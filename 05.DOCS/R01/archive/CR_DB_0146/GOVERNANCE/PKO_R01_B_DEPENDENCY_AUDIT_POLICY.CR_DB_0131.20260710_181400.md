# PKO R01 B dependency audit policy

- MB_ID: `CR-DB-0131-R01B-POST-FCMC-DEPENDENCY-AUDIT`
- Post-generation audits must be read-only against workbook and DB.
- `main.xlsx` remains prohibited as runtime source.
- `R01_E.01_FORMAT_CONTROL.xlsx` remains prohibited as data source.
- Missing internal sheets should move to the next dependency implementation WBS.