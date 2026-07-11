# Report Taxonomy and Scope Rules

- MB_ID: CR-DB-0098H-REGISTER-REPORT-TAXONOMY-SHEET-SECTION-ARTIFACTS-TEXT-ONLY
- PeriodId: 2026-05
- Status: CONFIRMED_BY_USER

## Correct hierarchy
1. Base Excel package
2. Workbook/file inside the package
3. Sheet inside a workbook
4. Sheet section/range
5. Homologation report artifact set

## Definition of report
A report is not a loose partial calculation range. A report is the complete set of artifacts that homologate a defined sheet section of a workbook from the base Excel package.

## Three-file report artifact set
For a defined report section, the homologation report should be represented by three coordinated files/artifacts:
1. Data/DB representation
2. Output Excel/workbook artifact
3. Validation/control artifact

## Definition of sheet section
A sheet section is an explicit range inside one sheet, for example:
- main.xlsx > F.D.KUM.01!C3:AF67

## Naming rule
Do not call E3:AG3, E51:AC51, or E44:AC44 alone a full report. Those are validated ranges/slices. A full report scope requires an explicit section definition such as main.xlsx > F.D.KUM.01!C3:AF67.

## Blank relevance rule
Blank cells with no precedents and no dependents are irrelevant for calculation, DB facts, SOURCE_GAP, and D1 questions. They may matter only for visual layout/dimensions.
