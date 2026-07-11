# REPORT_01 OUTPUT CONTRACT

Generated: 2026-07-06 13:47:51
MB_ID: CR-SYSTEM-0096B-REPORT-01-CANONICAL-TRIGGER-OUTPUT-PACKAGE-PLAN

## Canonical trigger

Primary trigger:
C:\01. GitHub\CloseReport\06.BUILDERS\triggers\REPORT_01.INDEPENDENT_DB_TEMPLATE.BUILD.ps1

Wrapper:
C:\01. GitHub\CloseReport\06.BUILDERS\triggers\RUN.REPORT_01.ps1

## Canonical generation flow

DB / governed staging
↓
controlled system-owned Excel template
↓
canonical builder trigger
↓
generated report package
↓
validation against original Excel package benchmark

## Operational source

DB:
C:\01. GitHub\CloseReport\03.DATA\db\current\CloseReport_CierreMes.sqlite

Controlled template:
C:\01. GitHub\CloseReport\04.REPORTS\templates\REPORT_01\CloseReport_Report01_F.D.KUM.01_CONTROLLED_TEMPLATE.xlsx

Benchmark:
C:\01. GitHub\CloseReport\03.DATA\raw\current\main.xlsx > F.D.KUM.01

## Required output package after trigger

01_EXCEL_CASI_CLON:
CloseReport_Report01_F.D.KUM.01_CLONE_<period>_<timestamp>.xlsx

02_EXCEL_FORMULAS_EFICIENTES:
CloseReport_Report01_F.D.KUM.01_EFFICIENT_<period>_<timestamp>.xlsx

03_EXCEL_AUDIT_VISUAL:
CloseReport_Report01_F.D.KUM.01_AUDIT_VISUAL_<period>_<timestamp>.xlsx

## Audit visual must distinguish

- HARD_NUMBER
- FORMULA_DERIVED
- REFERENCE_DERIVED
- DB_STAGED_VALUE
- FORECAST_EDITABLE
- BASELINE_LOCKED
- CURRENT_PERIOD_EDITABLE
- REVIEW_REQUIRED

## Validation

Primary benchmark is the original Excel package.
PDF is not a blocking primary source because PDFs derive from the original Excel package.

Currently proven ranges:
- F.D.KUM.01!E3:AG3
- F.D.KUM.01!E44:AC44
- F.D.KUM.01!E51:AC51
- F.D.KUM.01!W9:AC9
- F.D.KUM.01!W23:AC23
- F.D.KUM.01!R26:AC26
- F.D.KUM.01!W24:AC24

Current proven numeric gate:
PASS_112_OF_112