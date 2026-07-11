# Report Definition Correction — Plural Excel Outputs

- MB_ID: CR-DB-0098I-CORRECT-REPORT-DEFINITION-PLURAL-WORKBOOKS-AND-CONFIRM-FDKUM01-C3AF67-TEXT-ONLY
- PeriodId: 2026-05
- Status: CONFIRMED_BY_USER

## Correction
The prior wording Output Excel/workbook in singular was incorrect.

## Correct report definition
A report is the set of 3 files/artifacts that homologate a defined section of a sheet from a workbook in the base Excel package.

## Correct output wording
The Excel output component must be treated as plural when applicable: output Excel files/workbooks, not a single workbook by default.

## Report artifact set
For each report section, the homologation pack must consider:
1. Data/DB representation and source/control metadata.
2. Output Excel files/workbooks required to homologate the defined section.
3. Validation/control artifacts proving equivalence against the base Excel package.

## Scope rule
A report is not an arbitrary set of cells. A report is a defined section/range of a sheet.

## Confirmed first report
- main.xlsx > F.D.KUM.01!C3:AF67
