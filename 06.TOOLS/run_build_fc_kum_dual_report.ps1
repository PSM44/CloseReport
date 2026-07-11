$ErrorActionPreference = "Stop"

$MB_ID = "CR-TEMP-0049-FCKUM-TRIGGER"
$ScriptRootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRootDir

$BuilderPath = Join-Path $ProjectRoot "06.TOOLS\build_fc_kum_dual_report.py"
$DatabasePath = Join-Path $ProjectRoot "01.DB\close_report.sqlite"
$WorkbookPath = Join-Path $ProjectRoot "03.DATA\raw\current\main.xlsx"

$RequiredOutputs = @(
    (Join-Path $ProjectRoot "04.REPORTS\outputs\CloseReport_FC_KUM_DB_REPORTS.xlsx"),
    (Join-Path $ProjectRoot "05.DOCS\FC_KUM_VALIDATION.CloseReport.csv"),
    (Join-Path $ProjectRoot "05.DOCS\FC_KUM_REVIEW_REQUIRED.CloseReport.csv"),
    (Join-Path $ProjectRoot "05.DOCS\FC_KUM_REPORT_CONTRACT.CloseReport.csv")
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
    $validationPath = Join-Path $ProjectRoot "05.DOCS\FC_KUM_VALIDATION.CloseReport.csv"
    if (-not (Test-Path -LiteralPath $validationPath)) {
        return "VALIDATION_CSV_MISSING", "UNKNOWN"
    }
    $rows = Import-Csv -LiteralPath $validationPath
    $statusRow = $rows | Where-Object { $_.scope -eq "WORKBOOK" -and $_.item -eq "final_status" } | Select-Object -First 1
    $reviewRow = $rows | Where-Object { $_.scope -eq "WORKBOOK" -and $_.item -eq "review_required_rows" } | Select-Object -First 1
    if ($null -eq $statusRow) {
        return "FINAL_STATUS_ROW_MISSING", "UNKNOWN"
    }
    $reviewText = if ($null -ne $reviewRow) { $reviewRow.actual } else { "UNKNOWN" }
    return $statusRow.actual, $reviewText
}

$finalStatus = "FAIL"
$blocker = ""
$filesCreated = @()
$filesModified = @()
$validationStatus = "FAILED"
$reviewRows = "UNKNOWN"
$nextAction = "Review FC_KUM_VALIDATION.CloseReport.csv."

Push-Location $ProjectRoot
try {
    Assert-PathExists -Path $BuilderPath -Label "Builder"
    Assert-PathExists -Path $DatabasePath -Label "Database"
    Assert-PathExists -Path $WorkbookPath -Label "Source workbook"

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

    $buildStatus, $reviewRows = Read-BuildStatus
    $validationStatus = $buildStatus
    if ($buildStatus -eq "PASS" -or $buildStatus -eq "PASS_WITH_REVIEW") {
        $finalStatus = $buildStatus
        $blocker = "NONE"
        $nextAction = "Open FC_KUM_VALIDATION.CloseReport.csv and review F.CKUM.OS against main.xlsx and PDF page 4."
    }
    else {
        $finalStatus = "FAIL"
        $blocker = "Validation status did not report PASS or PASS_WITH_REVIEW."
    }
}
catch {
    $finalStatus = "FAIL"
    $blocker = $_.Exception.Message
    $validationStatus = "FAILED"
}
finally {
    Pop-Location
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host "AI_TAIL_START"
    Write-Host "AI_TAIL_SCHEMA=v1"
    Write-Host "MB_ID=$MB_ID"
    Write-Host "RUNTIME=PowerShell"
    Write-Host "PROJECT_ROOT=$ProjectRoot"
    Write-Host "BUILDER_PATH=$BuilderPath"
    Write-Host "OUTPUT_WORKBOOK=$(Join-Path $ProjectRoot '04.REPORTS\outputs\CloseReport_FC_KUM_DB_REPORTS.xlsx')"
    Write-Host "FINAL_STATUS=$finalStatus"
    Write-Host "BLOCKER=$(if ([string]::IsNullOrWhiteSpace($blocker)) { 'NONE' } else { $blocker })"
    Write-Host "REVIEW_REQUIRED_ROWS=$reviewRows"
    Write-Host "FILES_CREATED=$(if ($filesCreated.Count -gt 0) { $filesCreated -join '|' } else { 'NONE' })"
    Write-Host "FILES_MODIFIED=$(if ($filesModified.Count -gt 0) { $filesModified -join '|' } else { 'NONE' })"
    Write-Host "VALIDATION_STATUS=$validationStatus"
    Write-Host "COMMIT_PUSH_PERFORMED=NO"
    Write-Host "NEXT_ACTION=$nextAction"
    Write-Host "AI_TAIL_END"
}

if ($finalStatus -eq "PASS" -or $finalStatus -eq "PASS_WITH_REVIEW") {
    exit 0
}

exit 1
