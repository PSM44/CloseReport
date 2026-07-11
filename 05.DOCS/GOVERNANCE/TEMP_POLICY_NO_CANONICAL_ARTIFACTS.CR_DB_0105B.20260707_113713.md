# Temp Policy — No Canonical Artifacts

- MB_ID: CR-DB-0105B-R1-STABLE-ARTIFACT-AUDIT-AND-TEMP-DEPENDENCY-CLEANUP-TEXT-ONLY
- Applies to: CloseReport / PS.CierreMES

## Rule
C:\Users\aazcl\Downloads\GlobalTemp.CierreMes is disposable staging only.

## Prohibited
- Do not leave useful artifacts only in Temp.
- Do not cite Temp paths as canonical locations after a runner has produced useful outputs.
- Do not build subsequent process steps that depend only on Temp artifacts unless explicitly temporary and immediately promoted.

## Required
- Promote useful outputs to stable project paths before treating a milestone as complete.
- If promotion is not safe, ask the human whether to move manually or keep temporary.
- TOVS must distinguish TEMP_ARTIFACT and STABLE_ARTIFACT.

## Stable R1 roots
- DB: C:\01. GitHub\CloseReport\03.DATA\processed\2026-05\R1
- Outputs: C:\01. GitHub\CloseReport\04.REPORTS\outputs\2026-05\R1
- Control: C:\01. GitHub\CloseReport\04.REPORTS\control\2026-05\R1
- Triggers: C:\01. GitHub\CloseReport\02.CONFIG\triggers\R1
