# PKO R01 B PowerShell Excel COM calculation closure policy

- MB_ID: `CR-DB-0141-POWERSHELL-EXCEL-COM-CALCULATION-CLOSURE`
- Excel COM is invoked only from PowerShell over the calc-candidate copy.
- The original workbook and DB must remain unchanged.
- If Excel COM is unavailable or blocked by user state, the run degrades to PASS_WITH_REVIEW without touching the original workbook.