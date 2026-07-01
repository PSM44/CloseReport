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
└── 90.TEMP/           Temporary files — not in git
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
