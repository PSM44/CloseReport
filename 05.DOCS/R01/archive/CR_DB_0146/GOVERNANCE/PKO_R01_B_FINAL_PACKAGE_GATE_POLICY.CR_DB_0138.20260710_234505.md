# PKO R01 B final package gate policy

- MB_ID: `CR-DB-0138-NUMERIC-VALIDATION-STYLE-GATE-FINAL-PACKAGE`
- Validation is read-only over target workbook, DB hash, benchmark workbook, and style reference workbook.
- `main.xlsx` is benchmark-only and must not remain a runtime dependency.
- `R01_E.01_FORMAT_CONTROL.xlsx` is style-reference-only and must not provide values or formulas.
- openpyxl does not recalculate formulas; formula-only review items are handled as review gates, not fabricated values.