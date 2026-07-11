# PKO.R01.A original formula policy

- MB_ID: CR-DB-0108-BUILD-PKO-R01-A-ORIGINAL-FORMULAS-FROM-DB

## Definition
PKO.R01.A preserves original workbook formulas and writes only non-formula seed cells from DB.

## Purpose
This branch provides transition compatibility with the original Excel model while proving DB-controlled inputs.

## Important limitation
PKO.R01.A intentionally preserves legacy formula structure. It is not the efficient-formula output. PKO.R01.B will address formula simplification and normalization.
