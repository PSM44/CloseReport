<#
MB_ID: CR-DBTEMPLATE-0095B-REPORT-01-INDEPENDENT-DB-TEMPLATE-BUILDER-MVP
PURPOSE:
  Demonstrate operational independence from original Excel files for Report 01 generation.
FIX VS 0095:
  Removes pre-existing technical sheets BENCHMARK_F.D.KUM.01 and VALIDATION before validation copy to avoid Excel sheet-name collision.

DELIVERY CLAIM:
  The generated report is created from:
    1. Governed SQLite DB/staging
    2. Controlled system-owned Excel template

  The original Excel file is NOT used to create the report.
  The original Excel may be used only after generation as benchmark validation.

FLOW:
  1. Locate governed DB:
     C:\01. GitHub\CloseReport\03.DATA\db\current\CloseReport_CierreMes.sqlite
  2. Locate latest successful DB-built workbook from 0093D and use it only to create/update a controlled system template.
     This template becomes the operational template.
  3. Query DB staging values from latest run for PeriodId and Report 01.
  4. Generate a new workbook from controlled template, not from main.xlsx.
  5. Write DB values into F.D.KUM.01.
  6. Validate generated report against original Excel benchmark after generation.
  7. Register proof that original Excel was not used as generation source.

IMPORTANT DISTINCTION:
  - main.xlsx is NOT opened before output workbook is generated and saved.
  - main.xlsx is opened only in validation stage.
  - Data values are queried from DB.
  - Layout comes from controlled template under 04.REPORTS\templates, not from main.xlsx.

SAFETY:
  DB_MODIFIED=NO by default.
  BUILD_EXECUTED=YES.
  COMMIT_PUSH_PERFORMED=NO.
  LEGACY_WORKBOOK_MODIFIED=NO.
  ORIGINAL_EXCEL_USED_FOR_GENERATION=NO.
  ORIGINAL_EXCEL_USED_FOR_VALIDATION=YES.

RECOMMENDED COMMAND:
  pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\aazcl\Downloads\GlobalTemp.CierreMes\CR_DBTEMPLATE_0095B_REPORT_01_INDEPENDENT_DB_TEMPLATE_BUILDER_MVP.ps1" -PeriodId "2026-06"
#>

[CmdletBinding()]
param(
  [string]$ProjectRoot = "C:\01. GitHub\CloseReport",
  [string]$TempPath = "C:\Users\aazcl\Downloads\GlobalTemp.CierreMes",
  [string]$PeriodId = "2026-06",
  [string]$DbPath = "C:\01. GitHub\CloseReport\03.DATA\db\current\CloseReport_CierreMes.sqlite",
  [string]$OriginalBenchmarkWorkbookPath = "C:\01. GitHub\CloseReport\03.DATA\raw\current\main.xlsx",
  [switch]$RecreateControlledTemplate
)

$ErrorActionPreference = "Stop"

$MB_ID = "CR-DBTEMPLATE-0095B-REPORT-01-INDEPENDENT-DB-TEMPLATE-BUILDER-MVP"
$StartedAt = Get-Date
$Timestamp = $StartedAt.ToString("yyyyMMdd_HHmmss")
$FinalStatus = "FAIL"
$Blocker = "UNKNOWN"
$CurrentStage = "INIT"

$Warnings = New-Object System.Collections.Generic.List[string]
$FilesCreated = New-Object System.Collections.Generic.List[string]
$FilesModified = New-Object System.Collections.Generic.List[string]

$DbModified = "NO"
$BuildExecuted = "NO"
$OriginalExcelUsedForGeneration = "NO"
$OriginalExcelUsedForValidation = "NO"
$TemplateCreatedOrUpdated = "NO"
$RunId = ""

$xlCSV = 6
$xlSheetHidden = 0
$xlSheetVisible = -1

function Heartbeat([string]$Stage) {
  $elapsed = [math]::Round(((Get-Date) - $script:StartedAt).TotalSeconds, 1)
  Write-Host ("HEARTBEAT stage={0} elapsed_sec={1}" -f $Stage,$elapsed)
}

function Set-Stage([string]$Stage) {
  $script:CurrentStage = $Stage
  Heartbeat $Stage
  if ($script:StageLog) {
    Add-Content -LiteralPath $script:StageLog -Encoding UTF8 -Value ("`r`n{0}`t{1}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $Stage)
  }
}

function Add-Warning([string]$Msg) {
  $script:Warnings.Add($Msg) | Out-Null
  Write-Host "WARN: $Msg"
}

function Safe-Reset-Temp([string]$Path) {
  $full = [System.IO.Path]::GetFullPath($Path)
  if ($full -notmatch "\\GlobalTemp\.CierreMes\\?$") { throw "TEMP_PATH_GUARD_FAILED: $full" }
  New-Item -ItemType Directory -Force -Path $full | Out-Null
  Get-ChildItem -LiteralPath $full -Force | Remove-Item -Recurse -Force
  return $full
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
  $enc = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

function CsvEscape($v) {
  if ($null -eq $v) { return "" }
  $s = [string]$v
  return '"' + $s.Replace('"','""') + '"'
}

function ColNameToNum([string]$name) {
  $n = 0
  foreach ($ch in $name.ToUpper().ToCharArray()) {
    $n = ($n * 26) + ([int][char]$ch - [int][char]'A' + 1)
  }
  return $n
}

function ColNumToName([int]$num) {
  $name = ""
  while ($num -gt 0) {
    $rem = ($num - 1) % 26
    $name = [char]([int][char]'A' + $rem) + $name
    $num = [math]::Floor(($num - 1) / 26)
  }
  return $name
}

function SetCell($ws, $addr, $value) {
  $addrText = [string]$addr
  if ([string]::IsNullOrWhiteSpace($addrText)) { throw "EMPTY_A1_ADDRESS_IN_SETCELL" }
  $cell = $ws.Range($addrText)
  if ($null -eq $value) {
    $cell.ClearContents() | Out-Null
    return
  }
  if ($value -is [double] -or $value -is [float] -or $value -is [decimal] -or $value -is [int] -or $value -is [long]) {
    $numText = ([double]$value).ToString("R", [System.Globalization.CultureInfo]::InvariantCulture)
    $cell.Formula = "=" + $numText
    return
  }
  $cell.Value2 = [string]$value
}

function SetFormula($ws, $addr, $formula) {
  $addrText = [string]$addr
  $formulaText = [string]$formula
  if ([string]::IsNullOrWhiteSpace($addrText)) { throw "EMPTY_A1_ADDRESS_IN_SETFORMULA" }
  $ws.Range($addrText).Formula = $formulaText
}

function Parse-NullableDoubleInvariant($value) {
  if ($null -eq $value) { return $null }
  $s = ([string]$value).Trim()
  if ($s -eq "" -or $s -eq "NULL" -or $s -eq "NaN") { return $null }
  $d = 0.0
  if ([double]::TryParse($s, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$d)) {
    return [double]$d
  }
  throw "INVALID_NUMERIC_VALUE_FROM_DB_QUERY: $s"
}

function Invoke-SqliteScalar([string]$Sql) {
  $out = & $script:SqliteExe $script:DbPath $Sql 2>&1
  if ($LASTEXITCODE -ne 0) { throw "SQLITE_SCALAR_FAILED: $out" }
  return (($out | Out-String).Trim())
}

function Invoke-SqliteQueryToCsv([string]$Sql, [string]$OutCsv) {
  $out = & $script:SqliteExe -header -csv $script:DbPath $Sql 2>&1
  if ($LASTEXITCODE -ne 0) { throw "SQLITE_QUERY_FAILED: $out" }
  Write-Utf8NoBom $OutCsv (($out | Out-String).TrimEnd())
  return $OutCsv
}

function Find-LatestFile([string]$Dir, [string]$Pattern) {
  if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { return $null }
  $f = Get-ChildItem -LiteralPath $Dir -Filter $Pattern -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($null -eq $f) { return $null }
  return $f.FullName
}

function Remove-SheetIfExists($wb, [string]$SheetName) {
  try {
    $ws = $wb.Worksheets.Item($SheetName)
    if ($null -ne $ws) {
      $ws.Delete() | Out-Null
      return $true
    }
  } catch {
    return $false
  }
  return $false
}

function Safe-CopyToUpload([string]$src,[string]$dst) {
  if ($src -and (Test-Path -LiteralPath $src -PathType Leaf)) {
    Copy-Item -LiteralPath $src -Destination $dst -Force
    $script:FilesCreated.Add($dst) | Out-Null
  }
}

function Add-ValidationRowFormula {
  param(
    $ValWs,
    [int]$Row,
    [string]$MetricCode,
    [string]$MetricName,
    [string]$TargetCell,
    [string]$Unit,
    [string]$ValuePolicy,
    [string]$RecordType
  )

  SetCell $ValWs "A$Row" $MetricCode
  SetCell $ValWs "B$Row" $MetricName
  SetCell $ValWs "C$Row" $TargetCell
  SetFormula $ValWs "D$Row" "='F.D.KUM.01'!$TargetCell"
  SetFormula $ValWs "E$Row" "='BENCHMARK_F.D.KUM.01'!$TargetCell"
  SetFormula $ValWs "F$Row" "=IF(AND(ISNUMBER(D$Row),ISNUMBER(E$Row)),D$Row-E$Row,"""")"
  SetFormula $ValWs "G$Row" "=IF(AND(ISNUMBER(D$Row),ISNUMBER(E$Row)),IF(ABS(D$Row-E$Row)<=0.0001,""MATCH"",""DIFFERENCE_UNEXPLAINED""),IF(D$Row=E$Row,""MATCH"",""DIFFERENCE_UNEXPLAINED""))"
  SetCell $ValWs "H$Row" $Unit
  SetCell $ValWs "I$Row" $ValuePolicy
  SetCell $ValWs "J$Row" $RecordType
}

try {
  Set-Stage "00_PRECHECK"
  if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) { throw "PROJECT_ROOT_NOT_FOUND: $ProjectRoot" }
  if (-not (Test-Path -LiteralPath $DbPath -PathType Leaf)) { throw "DB_NOT_FOUND: $DbPath" }
  if (-not (Test-Path -LiteralPath $OriginalBenchmarkWorkbookPath -PathType Leaf)) { throw "ORIGINAL_BENCHMARK_WORKBOOK_NOT_FOUND: $OriginalBenchmarkWorkbookPath" }
  if ($PeriodId -notmatch '^\d{4}-\d{2}$') { throw "INVALID_PERIOD_ID_EXPECTED_YYYY_MM: $PeriodId" }

  $sqliteCmd = Get-Command sqlite3.exe -ErrorAction SilentlyContinue
  if ($null -eq $sqliteCmd) { $sqliteCmd = Get-Command sqlite3 -ErrorAction SilentlyContinue }
  if ($null -eq $sqliteCmd) { throw "SQLITE3_NOT_FOUND" }
  $script:SqliteExe = $sqliteCmd.Source

  $ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
  $DbPath = [System.IO.Path]::GetFullPath($DbPath)
  $OriginalBenchmarkWorkbookPath = [System.IO.Path]::GetFullPath($OriginalBenchmarkWorkbookPath)
  $script:DbPath = $DbPath
  $TempPath = Safe-Reset-Temp $TempPath

  $TemplateDir = Join-Path $ProjectRoot "04.REPORTS\templates\REPORT_01"
  $OutputDir = Join-Path $ProjectRoot ("04.REPORTS\outputs\independent_dbtemplate\" + $PeriodId)
  $DocsDir = Join-Path $ProjectRoot "05.DOCS\REPORTS\DB_TEMPLATE"
  New-Item -ItemType Directory -Force -Path $TemplateDir | Out-Null
  New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
  New-Item -ItemType Directory -Force -Path $DocsDir | Out-Null

  $UploadDir = Join-Path $TempPath ("IA_UPLOAD.CloseReport.CR-DBTEMPLATE-0095B." + $Timestamp)
  New-Item -ItemType Directory -Force -Path $UploadDir | Out-Null

  $StageLog = Join-Path $DocsDir ("REPORT_01_INDEPENDENT_DB_TEMPLATE_STAGE_LOG." + $Timestamp + ".txt")
  Write-Utf8NoBom $StageLog ("{0}`t{1}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), "INIT")
  $FilesCreated.Add($StageLog) | Out-Null

  $ControlledTemplate = Join-Path $TemplateDir "CloseReport_Report01_F.D.KUM.01_CONTROLLED_TEMPLATE.xlsx"
  $TemplateManifest = Join-Path $TemplateDir "CloseReport_Report01_F.D.KUM.01_CONTROLLED_TEMPLATE.MANIFEST.md"
  $DbQueryCsv = Join-Path $DocsDir ("REPORT_01_INDEPENDENT_DB_TEMPLATE_QUERY." + $PeriodId + "." + $Timestamp + ".csv")
  $ValidationCsv = Join-Path $DocsDir ("REPORT_01_INDEPENDENT_DB_TEMPLATE_VALIDATION." + $PeriodId + "." + $Timestamp + ".csv")
  $ManifestMd = Join-Path $DocsDir ("REPORT_01_INDEPENDENT_DB_TEMPLATE_BUILDER_MANIFEST." + $PeriodId + "." + $Timestamp + ".md")
  $SummaryJson = Join-Path $DocsDir ("REPORT_01_INDEPENDENT_DB_TEMPLATE_BUILDER_SUMMARY." + $PeriodId + "." + $Timestamp + ".json")
  $OutputWorkbook = Join-Path $OutputDir ("CloseReport_Report01_F.D.KUM.01_INDEPENDENT_DB_TEMPLATE_BUILT_" + $PeriodId + "_" + $Timestamp + ".xlsx")

  Set-Stage "01_LOCATE_DB_RUN"
  $RunId = Invoke-SqliteScalar ("SELECT run_id FROM report_run WHERE period_id='" + $PeriodId.Replace("'","''") + "' AND status LIKE 'BUILT_AND_VALIDATED_PASS%' ORDER BY created_at DESC LIMIT 1;")
  if ([string]::IsNullOrWhiteSpace($RunId)) {
    $RunId = Invoke-SqliteScalar ("SELECT run_id FROM staging_value WHERE period_id='" + $PeriodId.Replace("'","''") + "' AND report_id='REPORT_01' GROUP BY run_id ORDER BY MAX(loaded_at) DESC LIMIT 1;")
  }
  if ([string]::IsNullOrWhiteSpace($RunId)) { throw "NO_DB_RUN_FOUND_FOR_PERIOD_REPORT_01: $PeriodId" }

  Set-Stage "02_QUERY_DB_VALUES"
  $query = "SELECT target_sheet,target_cell,metric_code,metric_name,amount_value,unit,value_policy,record_type,source_sheet,source_cell,source_policy FROM staging_value WHERE run_id='" + $RunId.Replace("'","''") + "' AND period_id='" + $PeriodId.Replace("'","''") + "' AND report_id='REPORT_01' ORDER BY target_sheet, target_cell;"
  Invoke-SqliteQueryToCsv $query $DbQueryCsv | Out-Null
  $FilesCreated.Add($DbQueryCsv) | Out-Null
  $dbRows = Import-Csv -LiteralPath $DbQueryCsv
  if (@($dbRows).Count -ne 112) { Add-Warning ("DB_QUERY_ROW_COUNT_EXPECTED_112_ACTUAL_" + @($dbRows).Count) }

  Set-Stage "03_CREATE_OR_REFRESH_CONTROLLED_TEMPLATE"
  if ($RecreateControlledTemplate -and (Test-Path -LiteralPath $ControlledTemplate -PathType Leaf)) {
    Remove-Item -LiteralPath $ControlledTemplate -Force
  }

  if (-not (Test-Path -LiteralPath $ControlledTemplate -PathType Leaf)) {
    $DbBuiltDir = Join-Path $ProjectRoot ("04.REPORTS\outputs\dbbuilder\" + $PeriodId)
    $LatestDbBuilt = Find-LatestFile $DbBuiltDir "CloseReport_Report01_F.D.KUM.01_DB_STAGING_BUILT_*.xlsx"
    if (-not $LatestDbBuilt) { throw "CONTROLLED_TEMPLATE_NOT_FOUND_AND_NO_DB_BUILT_WORKBOOK_AVAILABLE" }

    # Create controlled template from prior DB-built output, not from original Excel.
    Copy-Item -LiteralPath $LatestDbBuilt -Destination $ControlledTemplate -Force
    $FilesCreated.Add($ControlledTemplate) | Out-Null
    $TemplateCreatedOrUpdated = "YES_FROM_PRIOR_DB_BUILT_WORKBOOK"

    $templateManifestText = @"
# CONTROLLED TEMPLATE MANIFEST

Template:
$ControlledTemplate

Created at:
$($StartedAt.ToString("yyyy-MM-dd HH:mm:ss"))

Created from:
$LatestDbBuilt

Important:
This template was created from a DB-built workbook, not from the original legacy Excel file during this run.

Operational claim:
Future Report 01 generation uses:
- DB values from SQLite
- this controlled template

Original Excel is allowed only as benchmark validation source after generation.
"@
    Write-Utf8NoBom $TemplateManifest $templateManifestText
    $FilesCreated.Add($TemplateManifest) | Out-Null
  } else {
    $TemplateCreatedOrUpdated = "NO_EXISTING_TEMPLATE_USED"
  }

  Set-Stage "04_BUILD_FROM_DB_AND_CONTROLLED_TEMPLATE"
  $Excel = $null
  $TemplateWb = $null
  $OutWb = $null
  try {
    $Excel = New-Object -ComObject Excel.Application
    $Excel.Visible = $false
    $Excel.DisplayAlerts = $false
    $Excel.AskToUpdateLinks = $false

    # Original benchmark workbook is intentionally NOT opened in this stage.
    if (Test-Path -LiteralPath $OutputWorkbook -PathType Leaf) { Remove-Item -LiteralPath $OutputWorkbook -Force }
    Copy-Item -LiteralPath $ControlledTemplate -Destination $OutputWorkbook -Force
    $FilesCreated.Add($OutputWorkbook) | Out-Null

    $OutWb = $Excel.Workbooks.Open($OutputWorkbook, $false, $false)
    $reportWs = $OutWb.Worksheets.Item("F.D.KUM.01")

    foreach ($rng in @("E3:AG3","E44:AC44","E51:AC51","W9:AC9","W23:AC23","R26:AC26","W24:AC24")) {
      $reportWs.Range($rng).ClearContents() | Out-Null
    }

    $dbWriteCount = 0
    foreach ($r in $dbRows) {
      if ([string]$r.target_sheet -eq "F.D.KUM.01") {
        $v = Parse-NullableDoubleInvariant $r.amount_value
        SetCell $reportWs ([string]$r.target_cell) $v
        $dbWriteCount += 1
      }
    }

    Add-Content -LiteralPath $StageLog -Encoding UTF8 -Value ("`r`n{0}`tDB_VALUES_WRITTEN_TO_EXCEL_FROM_CONTROLLED_TEMPLATE={1}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $dbWriteCount)

    $Excel.CalculateFullRebuild() | Out-Null
    $OutWb.Save() | Out-Null
    $OutWb.Close($true) | Out-Null
    $OutWb = $null
    $BuildExecuted = "YES"
  }
  finally {
    if ($OutWb -ne $null) { try { $OutWb.Close($true) | Out-Null } catch {} }
    if ($TemplateWb -ne $null) { try { $TemplateWb.Close($false) | Out-Null } catch {} }
    if ($Excel -ne $null) { try { $Excel.Quit() | Out-Null } catch {} }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
  }

  Set-Stage "05_VALIDATE_AGAINST_ORIGINAL_BENCHMARK_AFTER_GENERATION"
  $OriginalExcelUsedForValidation = "YES"
  $ExcelV = $null
  $GenWb = $null
  $BenchWb = $null
  $CsvWb = $null
  try {
    $ExcelV = New-Object -ComObject Excel.Application
    $ExcelV.Visible = $false
    $ExcelV.DisplayAlerts = $false
    $ExcelV.AskToUpdateLinks = $false

    $GenWb = $ExcelV.Workbooks.Open($OutputWorkbook, $false, $false)
    $BenchWb = $ExcelV.Workbooks.Open($OriginalBenchmarkWorkbookPath, $false, $true)

    $genWs = $GenWb.Worksheets.Item("F.D.KUM.01")
    $benchWs = $BenchWb.Worksheets.Item("F.D.KUM.01")

    # 0095B fix:
    # The controlled template may already contain technical sheets from prior DB-built workbooks.
    # Delete them before copying benchmark/creating validation, avoiding "That name is already taken".
    $ExcelV.DisplayAlerts = $false
    $removedBench = Remove-SheetIfExists $GenWb "BENCHMARK_F.D.KUM.01"
    $removedValidation = Remove-SheetIfExists $GenWb "VALIDATION"
    Add-Content -LiteralPath $StageLog -Encoding UTF8 -Value ("`r`n{0}`tREMOVED_EXISTING_TECH_SHEETS benchmark={1} validation={2}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $removedBench, $removedValidation)

    # Copy original benchmark sheet into generated workbook only for validation after generation.
    $benchWs.Copy($genWs)
    $benchCopy = $ExcelV.ActiveSheet
    $benchCopy.Name = "BENCHMARK_F.D.KUM.01"

    $valWs = $GenWb.Worksheets.Add()
    $valWs.Name = "VALIDATION"
    $headers = @("metric_code","metric_name","target_cell","generated_value","benchmark_value","delta","status","currency_or_unit","value_policy","record_type")
    for ($i=0; $i -lt $headers.Count; $i++) { SetCell $valWs ((ColNumToName ($i+1)) + "1") $headers[$i] }

    $vr = 2
    foreach ($r in $dbRows) {
      Add-ValidationRowFormula $valWs $vr ([string]$r.metric_code) ([string]$r.metric_name) ([string]$r.target_cell) ([string]$r.unit) ([string]$r.value_policy) ([string]$r.record_type)
      $vr += 1
    }

    try { $benchCopy.Visible = $xlSheetHidden } catch {}
    $ExcelV.CalculateFullRebuild() | Out-Null
    $GenWb.Save() | Out-Null

    $valWs.Copy()
    $CsvWb = $ExcelV.ActiveWorkbook
    if (Test-Path -LiteralPath $ValidationCsv -PathType Leaf) { Remove-Item -LiteralPath $ValidationCsv -Force }
    $CsvWb.SaveAs($ValidationCsv, $xlCSV) | Out-Null
    $FilesCreated.Add($ValidationCsv) | Out-Null
    $CsvWb.Close($false) | Out-Null
    $CsvWb = $null

    try { $valWs.Visible = $xlSheetHidden } catch {}
    $GenWb.Save() | Out-Null
    $GenWb.Close($true) | Out-Null
    $GenWb = $null
    $BenchWb.Close($false) | Out-Null
    $BenchWb = $null
  }
  finally {
    if ($CsvWb -ne $null) { try { $CsvWb.Close($false) | Out-Null } catch {} }
    if ($GenWb -ne $null) { try { $GenWb.Close($true) | Out-Null } catch {} }
    if ($BenchWb -ne $null) { try { $BenchWb.Close($false) | Out-Null } catch {} }
    if ($ExcelV -ne $null) { try { $ExcelV.Quit() | Out-Null } catch {} }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
  }

  Set-Stage "06_COUNT_VALIDATION"
  $MatchCount = 0
  $DiffCount = 0
  $TotalRows = 0
  $OtherStatusCount = 0
  foreach ($r in (Import-Csv -LiteralPath $ValidationCsv)) {
    $TotalRows += 1
    $st = [string]$r.status
    if ($st -eq "MATCH") { $MatchCount += 1 }
    elseif ($st -eq "DIFFERENCE_UNEXPLAINED") { $DiffCount += 1 }
    else { $OtherStatusCount += 1 }
  }

  $NumericGate = "UNKNOWN"
  if ($TotalRows -eq 112 -and $MatchCount -eq 112 -and $DiffCount -eq 0) { $NumericGate = "PASS_112_OF_112" }
  elseif ($TotalRows -gt 0 -and $DiffCount -eq 0) { $NumericGate = "PASS_NO_DIFFERENCES_COUNT_REVIEW" }
  elseif ($TotalRows -gt 0) { $NumericGate = "REVIEW_REQUIRED_NUMERIC_DIFFERENCES" }

  Set-Stage "07_WRITE_MANIFEST_AND_SUMMARY"
  $manifest = @"
# REPORT_01_INDEPENDENT_DB_TEMPLATE_BUILDER_MVP

Generated: $($StartedAt.ToString("yyyy-MM-dd HH:mm:ss"))
MB_ID: $MB_ID
Period: $PeriodId
DB run used: $RunId

## 01. Delivery definition

This delivery demonstrates operational independence from the original Excel files during generation.

Generation flow:

DB / governed staging
↓
Controlled system-owned Excel template
↓
Builder
↓
Generated report
↓
Validation against original Excel benchmark after generation

## 02. Generation sources

DB:

$DbPath

Controlled template:

$ControlledTemplate

Original Excel used for generation:

$OriginalExcelUsedForGeneration

## 03. Benchmark source

Original Excel benchmark:

$OriginalBenchmarkWorkbookPath

Original Excel used for validation:

$OriginalExcelUsedForValidation

## 04. Generated report

$OutputWorkbook

User-facing sheet:

F.D.KUM.01

## 05. Validation

Validation CSV:

$ValidationCsv

Result:

- TOTAL_VALIDATED_ROWS=$TotalRows
- MATCH_COUNT=$MatchCount
- DIFFERENCE_UNEXPLAINED_COUNT=$DiffCount
- NUMERIC_GATE=$NumericGate

## 06. Target ranges

- F.D.KUM.01!E3:AG3
- F.D.KUM.01!E44:AC44
- F.D.KUM.01!E51:AC51
- F.D.KUM.01!W9:AC9
- F.D.KUM.01!W23:AC23
- F.D.KUM.01!R26:AC26
- F.D.KUM.01!W24:AC24

## 07. Management claim

This is no longer a duplicate of the original workbook as an operational process.

The generated report is built from DB/staging and a controlled system template.

The original Excel is used only to validate that the result matches the legacy corporate truth.
"@
  Write-Utf8NoBom $ManifestMd $manifest
  $FilesCreated.Add($ManifestMd) | Out-Null

  $summaryObj = [ordered]@{
    mb_id=$MB_ID
    generated_at=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    project_root=$ProjectRoot
    temp_path=$TempPath
    period_id=$PeriodId
    db_path=$DbPath
    db_run_used=$RunId
    controlled_template=$ControlledTemplate
    template_created_or_updated=$TemplateCreatedOrUpdated
    original_excel_used_for_generation=$false
    original_excel_used_for_validation=$true
    original_benchmark_workbook=$OriginalBenchmarkWorkbookPath
    output_workbook=$OutputWorkbook
    db_query_csv=$DbQueryCsv
    validation_csv=$ValidationCsv
    total_validated_rows=$TotalRows
    match_count=$MatchCount
    difference_unexplained_count=$DiffCount
    other_status_count=$OtherStatusCount
    numeric_gate=$NumericGate
    delivery_flow="DB_STAGING_TO_CONTROLLED_TEMPLATE_TO_BUILDER_TO_REPORT_TO_ORIGINAL_BENCHMARK_VALIDATION"
    db_modified=$false
    build_executed=$true
    commit_push_performed=$false
    legacy_workbook_modified=$false
    management_claim="Independent operational generation from DB plus controlled template; original Excel only benchmark validation."
    next_action="Visual review generated independent DB-template workbook, then register first independent system delivery gate."
  }
  $summaryObj | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SummaryJson -Encoding UTF8
  $FilesCreated.Add($SummaryJson) | Out-Null

  $FinalStatus = "PASS_WITH_REVIEW"
  $Blocker = "NONE"
}
catch {
  $FinalStatus = "FAIL"
  $Blocker = $_.Exception.Message
  Write-Host "ERROR: $Blocker"
}
finally {
  try {
    if ($null -eq $UploadDir -or $UploadDir -eq "") {
      $TempPath = Safe-Reset-Temp $TempPath
      $UploadDir = Join-Path $TempPath ("IA_UPLOAD.CloseReport.CR-DBTEMPLATE-0095B." + $Timestamp)
      New-Item -ItemType Directory -Force -Path $UploadDir | Out-Null
    }

    $Readme = Join-Path $UploadDir "00_README_UPLOAD_THESE_FILES.CloseReport.txt"
    $Pack = Join-Path $UploadDir "01_CR_DBTEMPLATE_0095B_REPORT_01_PACK.CloseReport.txt"
    $UploadDbQuery = Join-Path $UploadDir "02_REPORT_01_INDEPENDENT_DB_TEMPLATE_QUERY.CloseReport.csv"
    $UploadValidation = Join-Path $UploadDir "03_REPORT_01_INDEPENDENT_DB_TEMPLATE_VALIDATION.CloseReport.csv"
    $UploadSummary = Join-Path $UploadDir "04_CR_DBTEMPLATE_0095B_SUMMARY.CloseReport.json"
    $UploadWorkbook = if ($OutputWorkbook) { Join-Path $UploadDir ("05_" + [System.IO.Path]::GetFileName($OutputWorkbook)) } else { Join-Path $UploadDir "05_NO_WORKBOOK_CREATED.txt" }

    Safe-CopyToUpload $DbQueryCsv $UploadDbQuery
    Safe-CopyToUpload $ValidationCsv $UploadValidation
    Safe-CopyToUpload $SummaryJson $UploadSummary
    if ($OutputWorkbook -and (Test-Path -LiteralPath $OutputWorkbook -PathType Leaf)) {
      Safe-CopyToUpload $OutputWorkbook $UploadWorkbook
    } else {
      "NO_WORKBOOK_CREATED. FINAL_STATUS=$FinalStatus BLOCKER=$Blocker STAGE=$CurrentStage" | Set-Content -LiteralPath $UploadWorkbook -Encoding UTF8
      $FilesCreated.Add($UploadWorkbook) | Out-Null
    }

    $writer = New-Object System.IO.StreamWriter($Pack, $false, [System.Text.UTF8Encoding]::new($false))
    try {
      foreach ($p in @($ManifestMd,$TemplateManifest,$StageLog)) {
        if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) {
          $writer.WriteLine("")
          $writer.WriteLine("--------------------------------------------------")
          $writer.WriteLine("SOURCE_FILE=$p")
          $writer.WriteLine("--------------------------------------------------")
          $writer.WriteLine((Get-Content -LiteralPath $p -Raw -Encoding UTF8))
        }
      }
    } finally { $writer.Close() }
    $FilesCreated.Add($Pack) | Out-Null

    @(
      "========== README_UPLOAD_THESE_FILES =========="
      "MB_ID=$MB_ID"
      "GENERATED_AT=$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
      "UPLOAD_DIR=$UploadDir"
      ""
      "UPLOAD THESE FILES:"
      "- $Pack"
      "- $UploadDbQuery"
      "- $UploadValidation"
      "- $UploadSummary"
      "- $UploadWorkbook"
      ""
      "IF UPLOAD IS NOT AVAILABLE:"
      "- Paste only the AI_TAIL."
      "- Keep local files under: $DocsDir"
      "- Generated independent DB-template workbook: $OutputWorkbook"
      ""
      "NOTES:"
      "- Demonstrates independent operational generation."
      "- DB_MODIFIED=NO."
      "- BUILD_EXECUTED=YES."
      "- ORIGINAL_EXCEL_USED_FOR_GENERATION=NO."
      "- ORIGINAL_EXCEL_USED_FOR_VALIDATION=YES."
      "- LEGACY_WORKBOOK_MODIFIED=NO."
    ) | Set-Content -LiteralPath $Readme -Encoding UTF8
    $FilesCreated.Add($Readme) | Out-Null
  } catch {
    Add-Warning ("UPLOAD_PACK_CREATION_FAILED: " + $_.Exception.Message)
  }

  $EndedAt = Get-Date
  Write-Host ""
  Write-Host "+AI_TAIL_START++++++++++++++++++"
  Write-Host "AI_TAIL_START"
  Write-Host "AI_TAIL_SCHEMA=v1"
  Write-Host "MB_ID=$MB_ID"
  Write-Host "STARTED_AT=$($StartedAt.ToString('yyyy-MM-dd HH:mm:ss'))"
  Write-Host "ENDED_AT=$($EndedAt.ToString('yyyy-MM-dd HH:mm:ss'))"
  Write-Host "FINAL_STATUS=$FinalStatus"
  Write-Host "BLOCKER=$Blocker"
  Write-Host "CURRENT_STAGE=$CurrentStage"
  Write-Host "PROJECT_ROOT=$ProjectRoot"
  Write-Host "TEMP_PATH=$TempPath"
  Write-Host "PERIOD_ID=$PeriodId"
  Write-Host "DB_PATH=$DbPath"
  Write-Host "DB_RUN_USED=$RunId"
  Write-Host "CONTROLLED_TEMPLATE=$ControlledTemplate"
  Write-Host "TEMPLATE_CREATED_OR_UPDATED=$TemplateCreatedOrUpdated"
  Write-Host "ORIGINAL_EXCEL_USED_FOR_GENERATION=$OriginalExcelUsedForGeneration"
  Write-Host "ORIGINAL_EXCEL_USED_FOR_VALIDATION=$OriginalExcelUsedForValidation"
  Write-Host "ORIGINAL_BENCHMARK_WORKBOOK=$OriginalBenchmarkWorkbookPath"
  Write-Host "OUTPUT_WORKBOOK=$OutputWorkbook"
  Write-Host "VALIDATION_CSV=$ValidationCsv"
  Write-Host "NUMERIC_GATE=$NumericGate"
  Write-Host "MATCH_COUNT=$MatchCount"
  Write-Host "DIFFERENCE_UNEXPLAINED_COUNT=$DiffCount"
  Write-Host "TOTAL_VALIDATED_ROWS=$TotalRows"
  Write-Host "DB_MODIFIED=$DbModified"
  Write-Host "CANON_MODIFIED=DOCS_ONLY"
  Write-Host "COMMIT_PUSH_PERFORMED=NO"
  Write-Host "BUILD_EXECUTED=$BuildExecuted"
  Write-Host "LEGACY_WORKBOOK_MODIFIED=NO"
  Write-Host "WARNINGS_COUNT=$($Warnings.Count)"
  if ($Warnings.Count -gt 0) { Write-Host "WARNINGS=$($Warnings -join ' | ')" }
  Write-Host "FILES_CREATED=$($FilesCreated -join ' | ')"
  Write-Host "FILES_MODIFIED=$($FilesModified -join ' | ')"
  Write-Host "NEXT_ACTION=If PASS_112_OF_112, visually review independent DB-template workbook and register first independent system delivery gate."
  Write-Host "AI_TAIL_END"
  Write-Host "++++++++++++++++++AI_TAIL_END"
}
