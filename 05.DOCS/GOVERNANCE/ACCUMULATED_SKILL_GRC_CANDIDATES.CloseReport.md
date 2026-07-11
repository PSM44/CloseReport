
========== CR-CLOSE-0081_SKILL_GRC_CANDIDATES_20260705_141014 ==========

- NEW_GRC_CANDIDATE: GRC.LONG_RUNNING_ANALYSIS_BUDGET.
- SKILL_IMPROVEMENT: HUMAN_CONTROLLED_SCRIPT_EXECUTION debe exigir heartbeat/elapsed/progress.
- SKILL_IMPROVEMENT: RADAR debe separarse de Workbook/PDF semantic atlas.
- GRC_IMPROVEMENT: SCRIPT_EXECUTION_STAGING debe advertir sobre backticks/triple fences en PowerShell.
- OPERATIONAL_RULE: No usar Markdown triple-backtick fences dentro de scripts PowerShell generados.


---

## CR-SKILL-GRC-0082 — Formalizar ejecutable descargable + Temp + AI_TAIL + paquete IA <=10 archivos

- Detected at: 2026-07-05 14:43:35
- Source project: PS.CierreMES / CloseReport
- Source minibattle: CR-HUMAN-0082-REVIEW-REPORT-01-FIVE-BLOCKERS-WITH-SKILL-GRC-GATE-NO-DB-LOAD
- Status: CANDIDATE_NOT_CANON
- Target:
  - SKILL.HUMAN_CONTROLLED_SCRIPT_EXECUTION
  - SKILL.COMPACT_UPLOAD_PACK_EXECUTION
  - GRC.COMPACT_UPLOAD_PACK_ONLY
  - SKILL.POWERSHELL_INTERACTIVE_SAFETY
  - SKILL.LOGGING_AUDIT
  - SKILL.GIT_STRUCTURAL_CHANGE_GOVERNANCE
- Problem:
  The method existed operationally, but the IA did not explicitly declare the active Skill/GRC set before delivering the executable.
- Proposed patch:
  Add mandatory visible pre-execution checklist:
  1. Skills/GRC applied.
  2. TEMP_PATH confirmed.
  3. Runner type.
  4. Canon modified yes/no.
  5. Upload pack policy.
  6. AI_TAIL contract.
- Canon policy:
  Do not patch generated usecase bundles directly. Patch canonical SkillsLake/GRCLake/registry/build source, then regenerate usecase packages.
- Evidence:
  CloseReport CR-SESSION-0074 produced a valid executable/upload pack, but with missing explicit Skill/GRC gate in the assistant response.


---

## CR-SKILL-GRC-0083 — Semantic-owner question before dependency classification

- Status: CANDIDATE_NOT_CANON
- Created by: CR-HUMAN-0083-PARALLEL-RUN-AND-D1-QUESTIONS-POLICY-NO-DB-LOAD
- Rule candidate:
  Before classifying an Excel dependency as DB view, upstream report, benchmark, formula, hard number, or blocker, the assistant must ask or verify what the referenced cells mean economically/operationally.


---

## CR-SKILL-GRC-0084 — Parallel-run legacy truth migration pattern

- Status: CANDIDATE_NOT_CANON
- Created by: CR-HUMAN-0083-PARALLEL-RUN-AND-D1-QUESTIONS-POLICY-NO-DB-LOAD
- Rule candidate:
  When legacy Excel/PDF remains temporary corporate truth, classify report values as ROOT_CONFIRMED, TRANSITIONAL_LEGACY, FORMULA_PENDING, or FORMULA_DERIVED, preserving source-cell traceability while DB-generated semi-clones are validated over the first 3 months after all semi-clone reports are operational.


---

## CR-SKILL-GRC-0085 — PowerShell markdown generation escaping safety

- Status: CANDIDATE_NOT_CANON
- Created by: CR-HUMAN-0083B-FIX-PARALLEL-RUN-POLICY-ESCAPING-NO-DB-LOAD
- Rule candidate:
  When a PowerShell runner generates markdown containing backticks or code identifiers, use single-quoted here-strings (@' ... '@) or explicit escaping. Validate generated markdown for control-character corruption before marking PASS.
- Evidence:
  CR-HUMAN-0083 generated corrupted field names in PARALLEL_RUN_LEGACY_TRUTH_AND_VALUE_CLASSIFICATION.CloseReport.md because unescaped PowerShell backticks converted parts of identifiers into control characters.


==========
CR-SKILL-GRC-0086_GPT_UPLOAD_LOCK
==========
CANDIDATE_ID: CR-SKILL-GRC-0086
TITLE: Modo GPT.Upload.Lock para trabajo sin uploads y maximo 9000 caracteres
TYPE: Skill/GRC improvement
STATUS: CANDIDATE_NOT_CANON
SOURCE_MB_ID: CR-DB-0086B-GPT-UPLOAD-LOCK-FIX-BUILD-PARAMETRIC-TRIGGER-AND-EXCEL-DRYRUN-TEXT-ONLY
PROBLEM: El humano puede quedar sin capacidad de subir archivos; la continuidad debe funcionar por texto copiable menor a 9000 caracteres.
RULE: Todo runner debe producir TOVS_SUMMARY_START/TOVS_SUMMARY_END menor o igual a 9000 caracteres, no exigir uploads por defecto, y dejar archivos localmente con resumen compacto.
BEHAVIOR: Si se necesita mas detalle, pedir un bloque puntual menor a 9000 caracteres, no archivos completos.
TARGET: SKILL.HUMAN_CONTROLLED_SCRIPT_EXECUTION | GRC.CROSS_RUNTIME_EXECUTION_CONTRACT | SESSION_CONTINUE | CloseReport runners
CREATED_AT: 2026-07-06 16:36:04
==========
