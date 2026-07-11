# SKILL_GRC_CANDIDATE_PATCH_EXCEL_COM_DRYRUN_0088H

Generated: 2026-07-05 22:17:55
MB_ID: CR-HUMAN-0088H-REGISTER-REPORT-01-DRYRUN-PASS-AND-VISUAL-REVIEW-GATE

## Candidate

CR-SKILL-GRC-0088H-EXCEL-COM-DRYRUN-STABLE-PATTERN

## Problem

PowerShell + Excel COM dry-run automation repeatedly failed when using:

- Range.Cells.Item(row,col)
- cell-by-cell Value2
- direct array assignment Range.Value2 = Range.Value2
- descriptive source strings parsed as A1 addresses

## Resolution pattern

Future Excel workbook dry-runs should use:

1. SaveCopyAs from read-only legacy workbook.
2. Generated workbook only for writes.
3. Internal benchmark sheet copied before modifications.
4. Copy/PasteSpecial(xlPasteValues) for range transfers.
5. FormulaR1C1 for formulas.
6. Internal VALIDATION sheet with Excel formulas.
7. CSV export of validation.
8. AI_TAIL and upload pack even on failure.
9. Never modify the legacy workbook.

## Benefit

Avoids repeating the 0088/0088B/0088C/0088D/0088E troubleshooting path and preserves the successful 0088G method as reusable skill/GRC for future report semi-clones.