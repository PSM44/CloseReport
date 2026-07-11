# ACCUMULATED_D1_QUESTIONS.CloseReport

---

## D1-Q-0001 — Semántica de diferencia de financiamiento en F.D.KUM.01

- Status: OPEN
- Owner: D1
- Created by: CR-HUMAN-0083-PARALLEL-RUN-AND-D1-QUESTIONS-POLICY-NO-DB-LOAD
- Created at: 2026-07-05 15:53:46
- Source workbook: main.xlsx
- Source cells:
  - main.xlsx > F.D.KUM.01!E44:AC44
  - main.xlsx > F.D.KUM.01!E51:AC51
  - main.xlsx > F.D.KMT.01!E57:AC57
- Current known formula:
  - F.D.KUM.01!E44:AC44 = F.D.KUM.01!E51:AC51 - F.D.KMT.01!E57:AC57
- Known facts:
  - main.xlsx > F.D.KMT.01!D57:AD57 contains financing by period and year accumulated hard numbers.
  - main.xlsx > F.D.KMT.01!D57 is total financing for year 2024.
  - main.xlsx > F.D.KMT.01!Q57 is total financing for year 2025.
  - main.xlsx > F.D.KUM.01!E51:AC51 contains financing-related hard numbers.
  - Annual columns are year accumulations; monthly columns are period values.
  - Reports use CLP, UF and USD; specific unit must be captured per value.
- Question for D1:
  - What is the operational/business name and meaning of the difference between F.D.KUM.01!E51:AC51 and F.D.KMT.01!E57:AC57?
- Why it matters:
  - Defines metric_code, metric_name, DB calculation label, validation rule and report explanation.
- Temporary treatment:
  - Calculation may be reproduced for semi-clone validation, but business semantics remain OPEN_FOR_D1.

