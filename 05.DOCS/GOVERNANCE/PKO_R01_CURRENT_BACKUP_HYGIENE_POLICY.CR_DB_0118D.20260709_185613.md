# PKO.R01 current backup hygiene policy - CR-DB-0118D

- MB_ID: CR-DB-0118D-MOVE-CURRENT-BAK-FILES-TO-BACKUPS-WITH-MANIFEST
- Status: ACTIVE

Backups are necessary before mutating Excel PKO outputs, but backups must not remain in the current folder.

## Folder roles
- current: active user-reviewable outputs only.
- backups: technical runner backups.
- legacy: superseded/obsolete outputs and discarded attempts.
- control: manifests and registers.
- evidence: audit CSVs and patch evidence.

## Required current contents
- R01_A.xlsx
- R01_B.xlsx
- R01_C.xlsx
- R01_D.xlsx
