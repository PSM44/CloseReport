# DB-native rule mapping policy — PKO.R01

- MB_ID: CR-DB-0108C-FORMULA-FAMILY-TO-RULE-MAP

## Policy
PKO.R01.A final and PKO.R01.B cannot be considered DB-native unless formula cells map to explicit DB rule/query definitions.

## Minimum evidence
- formula cell to rule map
- formula family to rule map
- normalized pattern to rule map
- rule registry profile
- readiness summary

## Current implication
If any cells are unmapped or weak candidates, the next step is rule normalization, not output generation.
