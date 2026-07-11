# PKO.R01.B no legacy sheet references policy - CR-DB-0120B

- MB_ID: CR-DB-0120B-R01-B-REMOVE-BROKEN-LEGACY-SHEET-REFS-AND-RESOLVE-VALUES
- Status: ACTIVE

R01_B is a clean output. It must not contain formulas that reference absent legacy sheets.
Until the DB/generator emits those cells directly, affected cells are output-level resolved values from main.xlsx > F.D.KUM.01 same cell.
This is not the final DB-first solution. It is a containment patch and a generator defect record.

Required future generator behavior:
- Generate values from DB/rules for cross-sheet dependencies.
- Preserve only workbook-internal formulas.
- Block #REF and absent-sheet references before output acceptance.
