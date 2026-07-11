# DB-first source policy with style-only exception - CR-DB-0123

- MB_ID: CR-DB-0123-REGISTER-100-PERCENT-DB-DATA-SOURCE-POLICY-WITH-STYLE-ONLY-EXCEPTION
- Status: ACTIVE

## Mandatory source rule
100 percent of output data must come from DB/rules/generator.
This includes values, formulas, dates, UF values, dependencies, dependency sheets and business rules.

## Style-only exception
R01_E.01_FORMAT_CONTROL.xlsx may be used only as a visual style matrix.
It may supply styles, row heights, column widths, hidden/visible states and page setup.

## Prohibited use of E.01
E.01 must not supply values, formulas, calculations, dates, UF values, dependencies or business logic.

## Legacy workbook role
main.xlsx remains benchmark/evidence/transitional reference only.
It is not an accepted production source once DB-first gates are enforced.

## Acceptance
An R01 output is not fully accepted until DB-first gates pass.
