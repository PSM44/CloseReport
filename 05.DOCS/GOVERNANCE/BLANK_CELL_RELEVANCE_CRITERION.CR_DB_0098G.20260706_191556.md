# Blank Cell Relevance Criterion

- MB_ID: CR-DB-0098G-STANDALONE-REGISTER-BLANK-IRRELEVANCE-CRITERION-AND-STATUS-TEXT-ONLY
- PeriodId: 2026-05
- Status: CONFIRMED_BY_USER

## Rule
If a cell is blank and has no precedents and no dependents, do not consider it for calculations, DB facts, SOURCE_GAP, or D1 operational questions.

## Visual exception
Such a blank cell may still be relevant only for presentation layout/style/dimensions. Presentation visual handling does not use the cell value.

## Implication
Do not ask D1 about isolated blank cells. D1 questions are only for blanks with calculation lineage, operational control relevance, or known business meaning.

## Related financing decision
For Report 01 financing blanks in main.xlsx > F.D.KUM.01 row 51: base blanks remain blank until actual financing is known. BLANK_AS_ZERO_EXCEL_ARITHMETIC applies only inside derived formula/recalc logic.
