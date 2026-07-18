# Skills / GRC accumulated lessons — CloseReport

## Scope

This document records reusable lessons, proposed Skills, and proposed GRCs detected during PS.CierreMES / CloseReport execution.

It is not a production implementation. It is a governance backlog and accumulated learning register.

## CR-DB-0200 PowerShell / Excel COM lessons

### Incident summary

During the May vs June 2026 Excel structure collector workstream, multiple PowerShell scripts failed before producing usable workbook structure data.

Observed failures:

1. PowerShell parser error caused by string interpolation with a variable immediately followed by a colon.
   - Bad pattern: `"$var:"`
   - Correct patterns: `"$($var):"` or explicit concatenation.
   - Examples affected:
     - `"$r1:..."`
     - `"open_workbook:$period:$path"`
     - `"used_range:$period:$path:$sheet"`

2. Excel COM / PowerShell type coercion failure while doing arithmetic over values returned by COM.
   - Error pattern: `[System.Object[]] does not contain a method named 'op_Subtraction'`
   - Required mitigation: cast UsedRange members explicitly before arithmetic:
     - `[int]$used.Row`
     - `[int]$used.Column`
     - `[int]$used.Rows.Count`
     - `[int]$used.Columns.Count`

3. Column-number to Excel-letter conversion failed due direct Double-to-Char conversion.
   - Error pattern: `Cannot convert value "66" to type "System.Char"`
   - Required mitigation: use explicit int cast before char cast:
     - `[char]([int]65 + [int]$rem)`

4. Hardening-only review was insufficient when it only validated parser/preflight and did not exercise real Excel reading.
   - Preflight PASS does not prove workbook logic PASS.
   - Business logic must be validated with at least one actual workbook open + UsedRange read.

5. Temp path policy correction.
   - `C:\Users\aazcl\Downloads\GlobalTemp.CierreMes` is flat, temporary, and disposable.
   - Do not create subfolders inside this Temp path unless the user explicitly overrides the policy.
   - Do not clean Temp when it contains user-provided upload/input files for the current run.
   - Flat outputs should use unique filename prefixes.

### Mandatory PowerShell guardrails

Before delivering or executing any generated `.ps1`, apply these checks:

- Parser check:
  - Run PowerShell parser validation.
  - Reject if any parse error exists.

- String interpolation checks:
  - Search for `"$var:"`, `"$script:var:"`, `"$period:"`, `"$path:"`, and any variable directly followed by colon.
  - Replace with `$($var):` or explicit concatenation.

- Excel COM checks:
  - Avoid ambiguous `Range($addr)` when `Cells.Item(row,col)` is safer.
  - Wrap workbook open, sheet access, UsedRange access, and close/release in try/catch.
  - Release COM objects explicitly.
  - Track `LAST_STAGE`.
  - Add `-PreflightOnly` but do not confuse preflight with full business validation.

- Type coercion checks:
  - Cast COM values to `[int]`, `[double]`, or `[string]` before arithmetic/string operations.
  - Never assume Excel COM scalar returns a native scalar; it can behave like Object/Object[].

- Temp policy checks:
  - Respect flat temp policy for `GlobalTemp.CierreMes`.
  - Do not create nested input/output folders in Temp.
  - Do not wipe Temp unless the script owns the run and no user-provided current inputs are stored there.

## Proposed Skills

### SKILL.PowerShellScriptHardeningForExcelCOM

Purpose:
Harden generated PowerShell scripts that automate Excel, CSV, manifest, and control-file workflows.

Required capabilities:
- Parser validation.
- Interpolation-risk detection.
- COM object lifecycle management.
- Excel UsedRange safe reading.
- A1/range string safety.
- Preflight plus minimal real-world probe.
- TOVS-compatible failure reporting.

Acceptance gates:
- Parser valid.
- No unsafe `$var:` interpolation.
- `LAST_STAGE` implemented.
- `-PreflightOnly` implemented where appropriate.
- At least one representative workbook read probe passes when Excel logic is required.

### SKILL.FlatTempUploadPackBuilder

Purpose:
Build upload packs under flat temp constraints for ChatGPT handoff.

Required capabilities:
- No subfolder creation under configured flat Temp.
- Unique run prefix.
- Flat output names.
- Manifest.
- File count and size summary.
- No destructive cleanup unless explicitly allowed.

Acceptance gates:
- All outputs are files directly under Temp.
- No subdirectories created.
- Existing user input files preserved.
- TOVS reports prefix and files created.

### SKILL.ExcelWorkbookStructureCollector

Purpose:
Collect workbook, sheet, and section-candidate metadata from Excel files for period comparison.

Required capabilities:
- Read multiple workbooks.
- Inventory files, sheets, UsedRange, formula counts, blank counts, comments if available.
- Build section candidates from used ranges or configured report ranges.
- Compare periods by file/sheet/section.
- Preserve source file identity despite different names across periods.

Acceptance gates:
- `SHEET_ROWS > 0`.
- `SECTION_CANDIDATE_ROWS > 0`.
- `SHEET_COMPARE_ROWS > 0` when two periods exist.
- Workbook read failures reported per workbook, not as silent success.

### SKILL.PeriodWorkbookComparison

Purpose:
Compare May vs June or other closing periods across files, sheets, and report sections.

Required capabilities:
- Canonical report identity mapping.
- File-name-independent matching.
- Sheet and section comparison.
- Classification of structural changes.
- Formula-change relevance even when values match.
- Visual differences as informational unless promoted.

Acceptance gates:
- Explicit period baseline.
- May locked/no mutation.
- June editable/work-in-progress.
- Differences classified as intentional, error, pending review, or not applicable.

### SKILL.D1FeedbackQuestionBuilder

Purpose:
Convert technical diff evidence into business-readable D1 questions.

Required capabilities:
- Spanish Chile business language.
- Avoid technical cell grids unless necessary.
- Group questions by report/section.
- Distinguish data correction, visual correction, criterion change, operational observation, and unresolved ambiguity.

Acceptance gates:
- D1-facing questions are short, concrete, and answerable.
- No formula lineage dump unless explicitly requested.
- Every question references a report/section and why it matters.

## Proposed GRCs

### GRC.PowerShellGeneratedScriptSafety

Policy:
Any generated PowerShell script must pass parser and risky-pattern checks before user execution.

Required rules:
- No unsafe `$var:` interpolation.
- Explicit COM type casts.
- `LAST_STAGE` in TOVS.
- `PreflightOnly` for complex workflows.
- No full-run recommendation until parser and representative logic are safe.

### GRC.FlatTempPolicy.CloseReport

Policy:
`C:\Users\aazcl\Downloads\GlobalTemp.CierreMes` is flat, temporary, and disposable.

Required rules:
- No subfolders.
- Do not clean Temp when current user-supplied files live there.
- Use unique file prefixes.
- Outputs meant for upload remain flat files.
- Useful long-term artifacts must be promoted to repo/docs, not depend on Temp.

### GRC.MayLockedJuneEditable

Policy:
May 2026 is locked benchmark evidence. June 2026 is operational work-in-progress.

Required rules:
- Do not mutate May.
- June may be edited if defects/conflicts are detected.
- May-vs-June comparison must preserve this status distinction.
- Differences in June are not automatically errors; classify them.

### GRC.ReportCanonicalIdentity

Policy:
Reports require canonical IDs independent from legacy workbook/sheet names.

Recommended identity:
- `BUILD_ORDER_ID`
- `PACKAGE_ORDER_ID`
- `CANONICAL_REPORT_ID`
- `LEGACY_SOURCE`

Current recommendation:
- Use `R02.03` as human-facing ID for second report by difficulty / third package report.
- Preserve `R3` as legacy/technical alias for artifacts already generated.

### GRC.NoUnboundedReverseEngineeringWithoutModuleBoundary

Policy:
Auditing upstream to hard numbers is required, but large feeders must be declared as governed modules when dependency depth expands.

Clarification:
This does not stop upstream audit. It prevents uncontrolled embedding of a full feeder model inside a single report task.

Required rules:
- Continue upstream until hard numbers are found.
- If a dependency opens a substantial submodel, register it as `FEEDER_MODULE`.
- Decide whether the feeder is:
  - direct DB source,
  - governed subreport,
  - transitional benchmark-only,
  - future module,
  - out of current report scope.

### GRC.FeedbackDecisionRegister

Policy:
D1 feedback must become formal period evidence.

Required rules:
- Capture feedback per period/report/section.
- Classify after D1 answers:
  - data correction,
  - visual correction,
  - business criterion change,
  - operational observation,
  - unresolved ambiguity.
- Keep May decisions locked when approved.
- Allow June corrections while work-in-progress.

## Current CR-DB-0200 status

The first useful May/June collector result was obtained with flat Temp policy:

- `MB_ID=CR-DB-0200F-MAY-JUNE-FLAT-TEMP-COLLECTOR`
- `FINAL_STATUS=PASS_WITH_REVIEW`
- `SHEET_ROWS=146`
- `SHEET_COMPARE_ROWS=74`
- `WORKBOOK_ROWS=12`
- `MAY_FILES=9`
- `JUNE_FILES=3`
- `SECTION_CANDIDATE_ROWS=146`
- `SECTION_COMPARE_ROWS=45`
- `NEXT_SCOPE=CR-DB-0201-MAY-JUNE-CANONICAL-SECTION-MAP`

Next operational step:
Upload/analyze the flat `CR_DB_0200F_20260713_112550_0200F_*` files, then define canonical section map and D1 feedback questions.
## CR-SGRC-OPP-20260718-001 — Project context identity gate

### Incident

A CloseReport conversation continued technical and session-close work against the DeveFact/HIA root without first stopping on the project mismatch.

### Candidate GRC

GRC.PROJECT_CONTEXT_IDENTITY_GATE

### Mandatory control

Before commands, canon mutation, audit, commit, push, or session close, compare:

- conversation project;
- expected project and canonical root;
- operative root shown in commands, logs, TOVS, or files;
- MB_ID or TASK_ID;
- target artifacts.

An unexplained mismatch produces:

PROJECT_CONTEXT_GATE=FAIL

and a hard stop before modification or closure.

Cross-project work requires explicit authorization identifying both projects, both roots, the reason, authorized artifacts, and the project that owns the final close.

### Acceptance target

- wrong-root TOVS is stopped before modification;
- wrong-project session close is blocked;
- commit/push requires root and project identity confirmation;
- session closure requires BATON, close artifact, commit, and root to belong to the same project.
