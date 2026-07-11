# CSV Excel Conversion Warning Policy

- MB_ID: CR-DB-0106A-R1-GENERATE-THREE-VALID-XLSX-VERSIONS-FROM-STABLE-DB-NO-COM-TEXT-ONLY

## Problem
Excel may convert large numbers or strings containing E/e into scientific notation when opening CSV files directly.

## Rule
CSV files remain machine-control artifacts, not manual Excel inspection artifacts.

## Manual inspection
Use the generated XLSX control workbook instead:
- C:\01. GitHub\CloseReport\04.REPORTS\control\2026-05\R1\R1_CONTROL_BRANCHES_NO_CSV_CONVERSION.2026-05.xlsx

## Technical note
The generated XLSX files store cell content as inline strings with text formatting to avoid Excel's CSV auto-conversion warning.
