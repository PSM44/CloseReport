# PKO.R01 A0 transitional classification

- MB_ID: CR-DB-0108B-CLASSIFY-A0-AND-PROFILE-DB-RULE-READINESS

## Policy
Any workbook that preserves formulas from the original Excel package is transitional. It cannot be classified as the final DB-native formula output.

## Target architecture
DB hard numbers + DB rules/queries -> generator -> PKO outputs.

## Consequence
PKO.R01.A final and PKO.R01.B must be generated from explicit DB rule/query mappings. Excel original formulas may be used as benchmark/reference, not as the operational formula engine.
