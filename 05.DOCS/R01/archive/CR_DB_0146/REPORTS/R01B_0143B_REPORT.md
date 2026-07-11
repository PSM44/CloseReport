# R01B 0143B recalc retry report

- Original issue: `R26:AC26` in 0142 had hard numbers instead of internal `. F.BS2.01` lineage formulas.
- CR-DB-0143 corrected lineage but remained `PASS_WITH_REVIEW` because Excel COM left `12` cached values missing in `R26:AC26`.
- 0143B retried the Excel COM calculation on a new copy only.
- Excel COM used: `False`
- Calc candidate modified by Excel: `False`
- R26:AC26 cached values available: `0/12`
- Final 0143B workbook: ``
- Recommended decision: `REVIEW_EXCEL_LOCKS`