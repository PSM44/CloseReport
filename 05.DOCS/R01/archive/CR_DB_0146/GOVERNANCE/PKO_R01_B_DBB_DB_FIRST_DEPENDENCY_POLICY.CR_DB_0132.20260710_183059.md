# PKO R01 B D.BB DB-first dependency policy

- MB_ID: `CR-DB-0132-DBB-DEPENDENCY-SHEET-DB-FIRST-PLAN-AND-IMPLEMENTATION-READINESS`
- main.xlsx can be used only as controlled bootstrap benchmark.
- Runtime dependency must remain DB/rules/workbook internal only.
- R01_E.01_FORMAT_CONTROL.xlsx is not used as data source.
- DB and workbook changes require backups and schema-aware inserts only.