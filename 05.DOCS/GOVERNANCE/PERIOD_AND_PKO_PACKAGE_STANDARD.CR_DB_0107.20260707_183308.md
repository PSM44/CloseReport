# Period and PKO package standard

- MB_ID: CR-DB-0107-CREATE-PKO-R01-PACKAGE-SKELETON-FROM-DB-PROOF

## Locked period structure
04.PERIODS\<period>_LOCKED\
- 00_ORIGINAL_PACKAGE
- 01_DB
- 02_TRIGGERS
- 03_PKO
- 04_VALIDATION
- 05_AUDIT

## PKO package structure
PKO.Rxx.<period>.<version>\
- reports
- docs
- _internal

## Rule
Human-facing outputs stay simple. Internal evidence remains available but is separated under _internal.
