# R01_B DB-generated dependency scope policy - CR-DB-0121

- MB_ID: CR-DB-0121-REGISTER-R01-B-DEPENDENCY-SHEETS-AS-DB-GENERATED-OUTPUT-SCOPE
- Status: ACTIVE

## Policy
R01_B.xlsx may contain cross-sheet formulas if and only if the referenced sheets exist inside R01_B.xlsx and are generated from DB/rules/generator.

## Forbidden
- #REF! in operational dependency chain.
- Formulas pointing to absent sheets.
- Manual legacy sheet copies without DB lineage.
- Using E format-control workbook as source of values or formulas.

## Required current dependency scope
- ". F.BS2.01" — referenced from: main.xlsx:F.D.KUM.01!AA26 | main.xlsx:F.D.KUM.01!AB26 | main.xlsx:F.D.KUM.01!AC26 | main.xlsx:F.D.KUM.01!R26 | main.xlsx:F.D.KUM.01!S26 | main.xlsx:F.D.KUM.01!T26 | main.xlsx:F.D.KUM.01!U26 | main.xlsx:F.D.KUM.01!V26 | main.xlsx:F.D.KUM.01!W26 | main.xlsx:F.D.KUM.01!X26 | main.xlsx:F.D.KUM.01!Y26 | main.xlsx:F.D.KUM.01!Z26
- "D.BB" — referenced from: main.xlsx:F.D.KUM.01!AA23 | main.xlsx:F.D.KUM.01!AA9 | main.xlsx:F.D.KUM.01!AB23 | main.xlsx:F.D.KUM.01!AB9 | main.xlsx:F.D.KUM.01!AC23 | main.xlsx:F.D.KUM.01!AC9 | main.xlsx:F.D.KUM.01!W23 | main.xlsx:F.D.KUM.01!W9 | main.xlsx:F.D.KUM.01!X23 | main.xlsx:F.D.KUM.01!X9 | main.xlsx:F.D.KUM.01!Y23 | main.xlsx:F.D.KUM.01!Y9 | main.xlsx:F.D.KUM.01!Z23 | main.xlsx:F.D.KUM.01!Z9
- "Detalle Koke" — referenced from: main.xlsx:F.D.KUM.01!AA24 | main.xlsx:F.D.KUM.01!AB24 | main.xlsx:F.D.KUM.01!AC24 | main.xlsx:F.D.KUM.01!W24 | main.xlsx:F.D.KUM.01!X24 | main.xlsx:F.D.KUM.01!Y24 | main.xlsx:F.D.KUM.01!Z24
- "F.CMC" — referenced from: main.xlsx:F.D.KUM.01!AA3 | main.xlsx:F.D.KUM.01!AB3 | main.xlsx:F.D.KUM.01!AC3 | main.xlsx:F.D.KUM.01!AD3 | main.xlsx:F.D.KUM.01!AE3 | main.xlsx:F.D.KUM.01!AF3 | main.xlsx:F.D.KUM.01!E3 | main.xlsx:F.D.KUM.01!F3 | main.xlsx:F.D.KUM.01!G3 | main.xlsx:F.D.KUM.01!H3 | main.xlsx:F.D.KUM.01!I3 | main.xlsx:F.D.KUM.01!J3 | main.xlsx:F.D.KUM.01!K3 | main.xlsx:F.D.KUM.01!L3 | main.xlsx:F.D.KUM.01!M3 | main.xlsx:F.D.KUM.01!N3 | main.xlsx:F.D.KUM.01!O3 | main.xlsx:F.D.KUM.01!P3 | main.xlsx:F.D.KUM.01!Q3 | main.xlsx:F.D.KUM.01!R3 | main.xlsx:F.D.KUM.01!S3 | main.xlsx:F.D.KUM.01!T3 | main.xlsx:F.D.KUM.01!U3 | main.xlsx:F.D.KUM.01!V3 | main.xlsx:F.D.KUM.01!W3 | main.xlsx:F.D.KUM.01!X3 | main.xlsx:F.D.KUM.01!Y3 | main.xlsx:F.D.KUM.01!Z3
- "F.D.KMT.01" — referenced from: main.xlsx:F.D.KUM.01!AA44 | main.xlsx:F.D.KUM.01!AB44 | main.xlsx:F.D.KUM.01!AC44 | main.xlsx:F.D.KUM.01!E44 | main.xlsx:F.D.KUM.01!F44 | main.xlsx:F.D.KUM.01!G44 | main.xlsx:F.D.KUM.01!H44 | main.xlsx:F.D.KUM.01!I44 | main.xlsx:F.D.KUM.01!J44 | main.xlsx:F.D.KUM.01!K44 | main.xlsx:F.D.KUM.01!L44 | main.xlsx:F.D.KUM.01!M44 | main.xlsx:F.D.KUM.01!N44 | main.xlsx:F.D.KUM.01!O44 | main.xlsx:F.D.KUM.01!P44 | main.xlsx:F.D.KUM.01!R44 | main.xlsx:F.D.KUM.01!S44 | main.xlsx:F.D.KUM.01!T44 | main.xlsx:F.D.KUM.01!U44 | main.xlsx:F.D.KUM.01!V44 | main.xlsx:F.D.KUM.01!W44 | main.xlsx:F.D.KUM.01!X44 | main.xlsx:F.D.KUM.01!Y44 | main.xlsx:F.D.KUM.01!Z44

## Gate
Future R01_B acceptance is blocked until dependency sheets missing from B equals zero.
