# PKO R01 B Detalle Koke DB-first dependency policy

- MB_ID: `CR-DB-0134-DETALLE-KOKE-DEPENDENCY-SHEET-DB-FIRST-PLAN-AND-IMPLEMENTATION-READINESS`
- Do not bootstrap or generate `Detalle Koke` unless the active workbook scope proves a real contract.
- `main.xlsx` remains benchmark/bootstrap only and was not read in this run.
- `R01_E.01_FORMAT_CONTROL.xlsx` is never a data source.