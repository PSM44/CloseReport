# PKO R01_B Dependency Sheet Policy

- MB_ID: `CR-DB-0120D-R01-B-DEPENDENCY-SHEET-AUDIT-NONCOM`
- Generated: `20260710_101451`
- Workbook under audit: `C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\current\R01_B.xlsx`
- Audited sheet/range: `F.D.KUM.01!C3:AF67`

## Allowed

- Formulas that reference `R01_B.xlsx` sheets already present in the workbook
- Self-sheet references within `F.D.KUM.01`
- Dependencies that are generated from DB/rules/generator lineage

## Not allowed

- `#REF!` formulas
- References to sheets absent from `R01_B.xlsx`
- Manual legacy sheet copies without DB lineage
- External workbook references without explicit review

## Policy action

- Keep existing dependency sheets only when they are DB-generated dependencies
- Generate missing dependency sheets from DB before including them in `R01_B.xlsx`
- Review external workbook references separately before any packaging decision
