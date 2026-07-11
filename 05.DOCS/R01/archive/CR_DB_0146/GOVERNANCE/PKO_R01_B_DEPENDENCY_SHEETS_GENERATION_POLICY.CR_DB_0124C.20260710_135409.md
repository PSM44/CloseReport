# R01_B dependency sheets generation policy - CR-DB-0124C

- MB_ID: CR-DB-0124C-PLAN-R01-B-DB-GENERATED-DEPENDENCY-SHEETS-IMPLEMENTATION-NOREGEX
- Status: ACTIVE

## Policy
Each R01_B dependency sheet must be generated from DB/rules/generator.

## Required dependency sheets
- F.CMC
- D.BB
- Detalle Koke
- . F.BS2.01
- F.D.KMT.01

## Acceptance
R01_B is not DB-first complete until:
1. All required dependency sheets exist in R01_B.xlsx.
2. Each dependency sheet has DB/rules/generator lineage.
3. No formulas point to absent sheets.
4. No REF errors remain in the operational dependency chain.
5. E.01 is used only for visual style.

## Implementation method
Start with DB mapping for referenced output rows, then recursively audit upstream dependencies inside each generated dependency sheet.
