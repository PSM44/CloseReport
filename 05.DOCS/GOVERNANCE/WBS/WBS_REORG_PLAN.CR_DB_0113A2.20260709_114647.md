# WBS Reorganization Plan - CR-DB-0113A2

- MB_ID: CR-DB-0113A2-WBS-STRUCTURE-AUDIT-AND-REORG-PLAN-PARSER-SAFE
- Status: PROPOSED_READ_ONLY
- Project root: C:\01. GitHub\CloseReport

## Problem
Current paths are too long and mix package versions, reports, internal evidence and obsolete artifacts.
The folder 04.PERIODS competes visually with 04.REPORTS.
The reports folder under PKO.R01 is accumulating obsolete outputs.

## Proposed period root
C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1

## Proposed current output folder
C:\01. GitHub\CloseReport\04.PERIODS\2026-05_LOCKED.V1\PKO\R01\current

## Proposed short names
- WBS.04.2026-05.R01.A -> R01_A.xlsx
- WBS.04.2026-05.R01.B -> R01_B.xlsx
- WBS.04.2026-05.R01.C -> R01_C.xlsx
- WBS.04.2026-05.R01.D -> R01_D.xlsx

## Proposed legacy policy
Do not delete anything in the first pass.
Copy accepted sanitized outputs to current with short names.
Move superseded branch outputs to legacy only after human approval.
Keep evidence CSV/JSON/MD in evidence, not mixed with final Excel outputs.

## Next task
CR-DB-0113B should create the proposed WBS folders and copy current sanitized outputs to short-name locations without deleting sources.
