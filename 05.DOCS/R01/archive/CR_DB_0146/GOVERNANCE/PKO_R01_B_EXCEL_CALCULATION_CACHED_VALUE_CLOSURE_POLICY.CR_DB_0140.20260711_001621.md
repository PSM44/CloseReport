# PKO R01 B Excel calculation cached value closure policy

- MB_ID: `CR-DB-0140-EXCEL-CALCULATION-CACHED-VALUE-CLOSURE`
- Excel COM is used only on the calc-candidate copy, never on the original workbook.
- DB remains read-only.
- main.xlsx is benchmark-only and cannot become a runtime dependency.
- If Excel COM or pywin32 is unavailable, the run must degrade to PASS_WITH_REVIEW without touching the original workbook.