[CmdletBinding()]
param(
  [string]$ProjectRoot = "C:\01. GitHub\CloseReport",
  [string]$PeriodId = "2026-06"
)

$ErrorActionPreference = "Stop"
$Trigger = Join-Path $ProjectRoot "06.BUILDERS\triggers\REPORT_01.INDEPENDENT_DB_TEMPLATE.BUILD.ps1"
if (-not (Test-Path -LiteralPath $Trigger -PathType Leaf)) {
  throw "CANONICAL_REPORT_01_TRIGGER_NOT_FOUND: $Trigger"
}

& pwsh.exe -NoProfile -ExecutionPolicy Bypass -File $Trigger -ProjectRoot $ProjectRoot -PeriodId $PeriodId