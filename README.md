# CloseReport

Financial close reporting system for SN Holding (Kumquat + KMT).

Replaces the manual monthly Finance Committee report assembly process
(~10 disconnected Excel files) with a single data pipeline:

```
Raw Excel → ETL Python → CSV staging → Power Query → CloseReport.xlsm
```

## Quick start (new session)

1. Upload `00.CANON/BATON.STATE.CloseReport.txt` to the AI
2. Upload `07.SKILLS/00.BUNDLE.CORE.txt`
3. Upload `07.SKILLS/01.BUNDLE.CONTINUITY.txt`
4. State the session objective in one line

## Project structure

```
CloseReport/
├── 00.CANON/          Continuity artifacts (WHOAMI, BATON, HUMAN)
├── 01.DB/             Schema DDL and migrations
├── 02.ETL/            Python ETL scripts
├── 03.DATA/
│   ├── raw/           Source Excel files — READ ONLY — not in git
│   └── staging/       Normalized CSVs (output of ETL)
├── 04.REPORTS/
│   └── templates/     CloseReport.xlsm with Power Query
├── 05.DOCS/           Technical documentation
├── 06.TOOLS/          Validation and utility scripts
├── 07.SKILLS/         SkillsMachine bundles
└── 99.TEMP/           Temporary files — not in git
```

## Phase roadmap

| Phase | Table(s)        | Slides | Status  |
|-------|-----------------|--------|---------|
| 0     | (cleanup)       | 3,4,5  | PENDING |
| 1     | movements       | 3,4,5  | PENDING |
| 2     | usa_cashflow    | 12-18  | BACKLOG |
| 3     | units + sales   | 8,10,11| BACKLOG |
| 4     | loans_ep        | 9      | BACKLOG |
| 5     | budget_bs2      | 6      | BACKLOG |
| 6     | BS1 flow (view) | 7      | BACKLOG |

## Key conventions

- **Language**: Excel, SQL, Python variables → English. Docs → Spanish.
- **Precision**: 4 decimal places fixed in all CSV exports.
- **Reference**: frozen Excel `2026_Mayo__2_.xlsx` is the validation benchmark.
- **Sensitive data**: `03.DATA/raw/` is in `.gitignore` — never commit.

## Setup

```powershell
# Create virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt
```

## Running the ETL (Phase 0 → 1)

```powershell
# Phase 0: normalize Bases
python 02.ETL/00.clean/clean_bases.py

# Phase 1: export movements CSV
python 02.ETL/01.load/load_movements.py

# Validate against frozen Excel
python 06.TOOLS/validate_totals.py
```

<!-- TEMP_POLICY_CR_TEMP_0010 -->
## Temporary workspace policy

`99.TEMP/` is the local temporary workspace. It is not committed to Git.

Operational rule:
- One-shot scripts may be saved in `99.TEMP/`.
- Before adding new temporary artifacts, scripts must clean previous `99.TEMP/` contents while preserving the running one-shot.
- Runtime evidence goes under `EVIDENCE.<timestamp>/`.
- RADAR outputs generated for local context go under `RADAR_ACTIVE.<timestamp>/`.

<!-- GENERATED_ARTIFACTS_POLICY_CR_TEMP_0011 -->
## Generated artifacts policy

The following paths are local-only and should not be committed:

- `99.TEMP/`
- `05.DOCS/RADAR.*.txt`
- `05.DOCS/HIST/`
- `03.DATA/staging/*.csv`

Reason:
- RADAR outputs are reproducible.
- Staging CSVs are derived from sensitive source Excel files.
- Upload contexts and runtime evidence are temporary.

<!-- PHASE1_VALIDATION_POLICY_CR_TEMP_0018 -->
## Phase 1 validation policy

Phase 1 validates `movements.csv` against the frozen Excel `Bases` sheet.

Accepted validation modes:

- `PASS_STRICT`: all totals match within 0.0001 UF.
- `PASS_SOFT_ROUNDING_ONLY`: accepted when all differences are immaterial rounding deltas:
  - `total_delta_uf <= 0.0010`
  - `max_delta_abs <= 0.0010`
  - `over_soft_group = 0`

Current accepted run:

- rows movements: 4501
- rows reference: 4501
- groups movements: 588
- groups reference: 588
- total delta UF: 0.0003
- max group delta UF: 0.0004
- over soft group: 0
