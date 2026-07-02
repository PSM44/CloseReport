$ErrorActionPreference = "Stop"

$MB_ID = "CR-TOOL-0042"
$ScriptRootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRootDir

$BuilderPath = Join-Path $ProjectRoot "06.TOOLS\build_fc_kmt_dual_report.py"
$DatabasePath = Join-Path $ProjectRoot "01.DB\close_report.sqlite"
$WorkbookPath = Join-Path $ProjectRoot "03.DATA\raw\current\main.xlsx"
$ProbePath = Join-Path $ProjectRoot "05.DOCS\FD_KMT_01_BASES_FORMULA_PROBE.CloseReport.csv"

$RequiredOutputs = @(
    (Join-Path $ProjectRoot "04.REPORTS\outputs\CloseReport_FC_KMT_DB_REPORTS.xlsx"),
    (Join-Path $ProjectRoot "05.DOCS\FC_KMT_DUAL_REPORT_BUILD_SUMMARY.CloseReport.txt"),
    (Join-Path $ProjectRoot "05.DOCS\FC_KMT_DUAL_REPORT_VALIDATION.CloseReport.csv"),
    (Join-Path $ProjectRoot "05.DOCS\FC_KMT_DUAL_REPORT_REVIEW_REQUIRED.CloseReport.csv"),
    (Join-Path $ProjectRoot "05.DOCS\FC_KMT_DUAL_REPORT_CELL_CLASSIFICATION.CloseReport.csv"),
    (Join-Path $ProjectRoot "05.DOCS\FC_KMT_DUAL_REPORT_CONTRACT.CloseReport.csv"),
    (Join-Path $ProjectRoot "05.DOCS\DOCS_ACTIVE_INDEX.CloseReport.txt")
)

function Find-PythonRuntime {
    $preferred = "C:\Users\aazcl\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    if (Test-Path -LiteralPath $preferred) {
        return $preferred
    }

    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($null -ne $pythonCommand -and -not [string]::IsNullOrWhiteSpace($pythonCommand.Source)) {
        return $pythonCommand.Source
    }

    throw "No usable Python runtime found. Checked bundled Codex Python and python on PATH."
}

function Assert-PathExists {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Label missing: $Path"
    }
}

function Get-OutputSnapshot {
    param([string[]]$Paths)

    $snapshot = @{}
    foreach ($path in $Paths) {
        if (Test-Path -LiteralPath $path) {
            $item = Get-Item -LiteralPath $path
            $snapshot[$path] = @{
                Exists = $true
                LastWriteUtc = $item.LastWriteTimeUtc
            }
        }
        else {
            $snapshot[$path] = @{
                Exists = $false
                LastWriteUtc = $null
            }
        }
    }
    return $snapshot
}

function Get-RelativeProjectPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    $root = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd("\")
    if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $full.Substring($root.Length).TrimStart("\")
    }
    return $full
}

function Read-BuildStatus {
    $validationPath = Join-Path $ProjectRoot "05.DOCS\FC_KMT_DUAL_REPORT_VALIDATION.CloseReport.csv"
    if (-not (Test-Path -LiteralPath $validationPath)) {
        return "VALIDATION_CSV_MISSING"
    }

    $rows = Import-Csv -LiteralPath $validationPath
    $statusRow = $rows | Where-Object { $_.scope -eq "WORKBOOK" -and $_.item -eq "final_status" } | Select-Object -First 1
    $reviewRow = $rows | Where-Object { $_.scope -eq "WORKBOOK" -and $_.item -eq "review_required_rows" } | Select-Object -First 1

    if ($null -eq $statusRow) {
        return "FINAL_STATUS_ROW_MISSING"
    }

    $reviewText = if ($null -ne $reviewRow) { $reviewRow.actual } else { "UNKNOWN" }
    return "{0};review_required_rows={1}" -f $statusRow.actual, $reviewText
}

$finalStatus = "FAIL"
$blocker = ""
$filesCreated = @()
$filesModified = @()
$validationStatus = "NOT_RUN"
$nextAction = "Review launcher output and git status."

Push-Location $ProjectRoot
try {
    Assert-PathExists -Path $BuilderPath -Label "Builder"
    Assert-PathExists -Path $DatabasePath -Label "Database"
    Assert-PathExists -Path $WorkbookPath -Label "Source workbook"
    Assert-PathExists -Path $ProbePath -Label "Probe CSV"

    $pythonRuntime = Find-PythonRuntime
    $beforeSnapshot = Get-OutputSnapshot -Paths $RequiredOutputs

    & $pythonRuntime $BuilderPath
    if ($LASTEXITCODE -ne 0) {
        throw "Builder execution failed with exit code $LASTEXITCODE."
    }

    foreach ($outputPath in $RequiredOutputs) {
        Assert-PathExists -Path $outputPath -Label "Required output"
        $afterItem = Get-Item -LiteralPath $outputPath
        $beforeItem = $beforeSnapshot[$outputPath]
        $relative = Get-RelativeProjectPath -Path $outputPath
        if (-not $beforeItem.Exists) {
            $filesCreated += $relative
        }
        elseif ($afterItem.LastWriteTimeUtc -gt $beforeItem.LastWriteUtc) {
            $filesModified += $relative
        }
    }

    $validationStatus = Read-BuildStatus
    $finalStatus = if ($validationStatus.StartsWith("PASS")) { "PASS" } else { "FAIL" }
    if ($finalStatus -eq "PASS") {
        $nextAction = "F.C.KMT P0 canonical builder is healthy; next candidate remains F.CKUM without starting it."
    }
    else {
        $blocker = "Validation status did not report PASS."
        $nextAction = "Inspect FC_KMT_DUAL_REPORT_VALIDATION.CloseReport.csv."
    }
}
catch {
    $finalStatus = "FAIL"
    $blocker = $_.Exception.Message
    if ([string]::IsNullOrWhiteSpace($validationStatus) -or $validationStatus -eq "NOT_RUN") {
        $validationStatus = "FAILED_BEFORE_VALIDATION"
    }
    $nextAction = "Fix blocker and rerun 06.TOOLS\run_build_fc_kmt_dual_report.ps1 from project root."
    Write-Error $_
}
finally {
    Pop-Location
    Write-Host "=========="
    Write-Host "AI_TAIL"
    Write-Host "=========="
    Write-Host ("MB_ID={0}" -f $MB_ID)
    Write-Host ("FINAL_STATUS={0}" -f $finalStatus)
    Write-Host ("BLOCKER={0}" -f $(if ([string]::IsNullOrWhiteSpace($blocker)) { "NONE" } else { $blocker }))
    Write-Host ("FILES_CREATED={0}" -f $(if ($filesCreated.Count -gt 0) { $filesCreated -join "|" } else { "NONE" }))
    Write-Host ("FILES_MODIFIED={0}" -f $(if ($filesModified.Count -gt 0) { $filesModified -join "|" } else { "NONE" }))
    Write-Host ("VALIDATION_STATUS={0}" -f $validationStatus)
    Write-Host "COMMIT_PUSH_PERFORMED=NO"
    Write-Host ("NEXT_ACTION={0}" -f $nextAction)
}

if ($finalStatus -eq "PASS") {
    exit 0
}

exit 1
