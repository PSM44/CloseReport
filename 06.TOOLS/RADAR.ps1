# RADAR.ps1 -- CloseReport
# Safe repaired version from CR-TEMP-0006
# Compatible: Windows PowerShell 5.1 and PowerShell 7+
#
# Contract:
# - Cleans 99.TEMP BEFORE creating any new TEMP artifact.
# - When called by a TEMP one-shot, preserves paths listed in CR_TEMP_PRESERVE_PATHS.
# - Writes RADAR outputs to isolated 99.TEMP\RADAR_ACTIVE.<timestamp>.
# - Excludes previous RADAR outputs under 05.DOCS and 99.TEMP from scan.
# - Handles locked/unreadable files as warnings, not red terminal errors.
# - Emits visible AI_TAIL banners and machine-readable AI_TAIL lines.

param(
    [switch]$NoHist,
    [string]$Root,
    [string]$OutDir
)

$ErrorActionPreference = "Stop"
$MB_ID = "CR-SYS-000-RADAR"

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

$TempRoot = Join-Path $Root "99.TEMP"

function Test-SamePath {
    param(
        [Parameter(Mandatory=$true)][string]$A,
        [Parameter(Mandatory=$true)][string]$B
    )
    try {
        $ra = [System.IO.Path]::GetFullPath($A).TrimEnd("\")
        $rb = [System.IO.Path]::GetFullPath($B).TrimEnd("\")
        return $ra.Equals($rb, [System.StringComparison]::OrdinalIgnoreCase)
    }
    catch {
        return $false
    }
}

function Clear-TempPreserve {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string[]]$PreservePaths = @()
    )

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        return
    }

    foreach ($item in @(Get-ChildItem -LiteralPath $Path -Force)) {
        $preserve = $false
        foreach ($p in $PreservePaths) {
            if (-not [string]::IsNullOrWhiteSpace($p)) {
                if (Test-SamePath -A $item.FullName -B $p) {
                    $preserve = $true
                    break
                }
            }
        }

        if (-not $preserve) {
            Remove-Item -LiteralPath $item.FullName -Recurse -Force
        }
    }
}

$preservePaths = @()
if (-not [string]::IsNullOrWhiteSpace($env:CR_TEMP_PRESERVE_PATHS)) {
    $preservePaths = @($env:CR_TEMP_PRESERVE_PATHS -split "\|" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

# Hard operational rule:
# Before adding any new artifact to TEMP, delete previous TEMP contents.
Clear-TempPreserve -Path $TempRoot -PreservePaths $preservePaths

if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $TempRoot "RADAR_ACTIVE.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
}

$ProjectName = "CloseReport"
$RunStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$RunHuman = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$HashThresholdBytes = 50MB
$Warnings = New-Object System.Collections.Generic.List[string]

$ExcludedDirFragments = @(
    "\.git\",
    "\99.TEMP\",
    "\90.TEMP\",
    "\03.DATA\raw\",
    "\04.REPORTS\outputs\",
    "\05.DOCS\HIST\",
    "\__pycache__\"
)

$ExcludedFilePatterns = @(
    "05.DOCS\RADAR.LITE.CloseReport.txt",
    "05.DOCS\RADAR.INDEX.CloseReport.txt",
    "05.DOCS\RADAR.CORE.CloseReport.txt",
    "05.DOCS\RADAR.FULL.CloseReport.txt",
    "05.DOCS\RADAR.FULL.HUMAN.CloseReport.txt",
    "05.DOCS\RADAR.FULL.SKILLS.CloseReport.txt"
)

$TextExtensions = @(
    ".txt", ".md", ".ps1", ".py", ".json", ".csv", ".sql", ".m",
    ".yml", ".yaml", ".xml", ".ini", ".cfg", ".gitignore", ".gitattributes", ".gitkeep"
)

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Content
    )
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

function Get-RelPath {
    param([Parameter(Mandatory=$true)][string]$FullPath)
    return $FullPath.Substring($Root.Length).TrimStart("\", "/")
}

function Is-Excluded {
    param([Parameter(Mandatory=$true)][string]$FullPath)

    $rel = (Get-RelPath -FullPath $FullPath).Replace("/", "\")
    $normalized = "\" + $rel

    foreach ($pattern in $ExcludedFilePatterns) {
        if ($rel.Equals($pattern, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    foreach ($frag in $ExcludedDirFragments) {
        if ($normalized.ToLowerInvariant().Contains($frag.ToLowerInvariant())) {
            return $true
        }
    }

    return $false
}

function Get-LogicalType {
    param([Parameter(Mandatory=$true)][System.IO.FileInfo]$File)
    $ext = $File.Extension.ToLowerInvariant()
    if ($TextExtensions -contains $ext) { return "text" }
    if ($ext -eq ".xlsx" -or $ext -eq ".xlsm" -or $ext -eq ".xls") { return "xlsx" }
    if ($ext -eq ".pdf") { return "pdf" }
    if (@(".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg") -contains $ext) { return "image" }
    return "binary"
}

function Get-ShaSafe {
    param([Parameter(Mandatory=$true)][System.IO.FileInfo]$File)

    if ($File.Length -gt $HashThresholdBytes) {
        return "HASH_OMITIDO_POR_TAMANO"
    }

    try {
        return (Get-FileHash -Algorithm SHA256 -LiteralPath $File.FullName -ErrorAction Stop).Hash
    }
    catch {
        $rel = Get-RelPath -FullPath $File.FullName
        $Warnings.Add("HASH_ERROR: $rel -- $($_.Exception.Message)") | Out-Null
        return "HASH_ERROR_LOCKED_OR_UNREADABLE"
    }
}

function Write-RadarHeader {
    param(
        [Parameter(Mandatory=$true)][System.Text.StringBuilder]$Sb,
        [Parameter(Mandatory=$true)][string]$RadarType
    )
    [void]$Sb.AppendLine("==========")
    [void]$Sb.AppendLine("00.00_METADATOS")
    [void]$Sb.AppendLine("==========")
    [void]$Sb.AppendLine("")
    [void]$Sb.AppendLine("RADAR_TYPE........: $RadarType")
    [void]$Sb.AppendLine("PROYECTO..........: $ProjectName")
    [void]$Sb.AppendLine("ROOT..............: $Root")
    [void]$Sb.AppendLine("OUTDIR............: $OutDir")
    [void]$Sb.AppendLine("GENERADO..........: $RunHuman")
    [void]$Sb.AppendLine("SCRIPT............: 06.TOOLS\RADAR.ps1")
    [void]$Sb.AppendLine("SKILL_REF.........: 09.SKILL.RADAR.txt v1.4")
    [void]$Sb.AppendLine("HASH_UMBRAL_MB....: 50")
    [void]$Sb.AppendLine("EXCLUSIONES.......: .git\, 99.TEMP\, 90.TEMP\, 03.DATA\raw\, 04.REPORTS\outputs\, 05.DOCS\HIST\, 05.DOCS\RADAR.*.txt, __pycache__\")
    [void]$Sb.AppendLine("TEMP_POLICY.......: CLEAN_99_TEMP_BEFORE_CREATE")
    [void]$Sb.AppendLine("ENCODING..........: UTF-8")
    [void]$Sb.AppendLine("")
}

function Append-Warnings {
    param([Parameter(Mandatory=$true)][System.Text.StringBuilder]$Sb)
    [void]$Sb.AppendLine("")
    [void]$Sb.AppendLine("==========")
    [void]$Sb.AppendLine("99.00_WARNINGS")
    [void]$Sb.AppendLine("==========")
    if ($Warnings.Count -eq 0) {
        [void]$Sb.AppendLine("WARNINGS_COUNT: 0")
    }
    else {
        [void]$Sb.AppendLine("WARNINGS_COUNT: $($Warnings.Count)")
        foreach ($w in $Warnings) { [void]$Sb.AppendLine("- $w") }
    }
}

function Append-FileContent {
    param(
        [Parameter(Mandatory=$true)][System.Text.StringBuilder]$Sb,
        [Parameter(Mandatory=$true)][System.IO.FileInfo]$File,
        [string]$Label = "FILE",
        [int64]$MaxTextBytes = 2000000
    )
    $rel = Get-RelPath -FullPath $File.FullName
    [void]$Sb.AppendLine("")
    [void]$Sb.AppendLine("----------------------------------------------------------------------")
    [void]$Sb.AppendLine(("{0}: {1}" -f $Label, $rel))
    [void]$Sb.AppendLine("BYTES: $($File.Length)")
    [void]$Sb.AppendLine("MODIFIED: $($File.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))")
    [void]$Sb.AppendLine("----------------------------------------------------------------------")
    if ($File.Length -gt $MaxTextBytes) {
        [void]$Sb.AppendLine("SKIPPED_TOO_LARGE")
        return
    }
    try {
        [void]$Sb.AppendLine((Get-Content -LiteralPath $File.FullName -Raw -Encoding UTF8 -ErrorAction Stop))
    }
    catch {
        $Warnings.Add("READ_ERROR: $rel -- $($_.Exception.Message)") | Out-Null
        [void]$Sb.AppendLine("READ_ERROR: $($_.Exception.Message)")
    }
}

function Save-Output {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Content
    )
    $activePath = Join-Path $OutDir $Name
    Write-Utf8NoBom -Path $activePath -Content $Content
    return $activePath
}

$sep = "=" * 64
Write-Host ""
Write-Host $sep
Write-Host "  RADAR.ps1 -- CloseReport  [CR-SYS-000]"
Write-Host "  Run: $RunHuman"
Write-Host "  Out: $OutDir"
Write-Host $sep
Write-Host ""

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

Write-Host "  [1/7] Scanning $Root ..."
$allFilesRaw = @(Get-ChildItem -Path $Root -Recurse -File -Force -ErrorAction Stop)
$allFiles = @($allFilesRaw | Where-Object { -not (Is-Excluded -FullPath $_.FullName) } | Sort-Object FullName)
$folders = @($allFiles | ForEach-Object { Split-Path -Parent (Get-RelPath -FullPath $_.FullName) } | Sort-Object -Unique)
$totalBytes = 0
foreach ($f in $allFiles) { $totalBytes += $f.Length }
$totalKb = [math]::Round($totalBytes / 1KB, 2)
Write-Host "      Found $($allFiles.Count) files in ~$($folders.Count) folders ($totalKb KB)"

$fileRows = @()
foreach ($file in $allFiles) {
    $fileRows += [PSCustomObject]@{
        RelPath = Get-RelPath -FullPath $file.FullName
        Bytes = $file.Length
        Modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        Extension = $file.Extension
        LogicalType = Get-LogicalType -File $file
        Sha256 = Get-ShaSafe -File $file
        File = $file
    }
}

Write-Host "  [2/7] Writing RADAR.LITE ..."
$lite = New-Object System.Text.StringBuilder
Write-RadarHeader -Sb $lite -RadarType "RADAR_LITE"
[void]$lite.AppendLine("==========")
[void]$lite.AppendLine("01.00_RESUMEN")
[void]$lite.AppendLine("==========")
[void]$lite.AppendLine("TOTAL_ARCHIVOS.......: $($allFiles.Count)")
[void]$lite.AppendLine("TOTAL_CARPETAS.......: $($folders.Count)")
[void]$lite.AppendLine("TOTAL_PESO_KB........: $totalKb")
[void]$lite.AppendLine("")
[void]$lite.AppendLine("ARCHIVOS_CLAVE:")
foreach ($r in @($fileRows | Where-Object {
    $_.RelPath -like "00.CANON\*" -or
    $_.RelPath -eq "README.md" -or
    $_.RelPath -eq "requirements.txt" -or
    $_.RelPath -like "06.TOOLS\*" -or
    $_.RelPath -like "02.ETL\*" -or
    $_.RelPath -like "01.DB\schema\*"
})) {
    [void]$lite.AppendLine("- $($r.RelPath)")
}
Append-Warnings -Sb $lite
$litePath = Save-Output -Name "RADAR.LITE.CloseReport.txt" -Content $lite.ToString()

Write-Host "  [3/7] Writing RADAR.INDEX ..."
$index = New-Object System.Text.StringBuilder
Write-RadarHeader -Sb $index -RadarType "RADAR_INDEX"
[void]$index.AppendLine("==========")
[void]$index.AppendLine("01.00_INVENTARIO_COMPLETO")
[void]$index.AppendLine("==========")
[void]$index.AppendLine(("  {0,-72} {1,12}  {2,-19}  {3,-10}  {4,-12}  {5}" -f "RUTA", "BYTES", "MODIFICADO", "EXT", "TIPO_LOGICO", "SHA256"))
[void]$index.AppendLine("  " + ("-" * 160))
foreach ($r in $fileRows) {
    [void]$index.AppendLine(("  {0,-72} {1,12}  {2,-19}  {3,-10}  {4,-12}  {5}" -f $r.RelPath, $r.Bytes, $r.Modified, $r.Extension, $r.LogicalType, $r.Sha256))
}
[void]$index.AppendLine("")
[void]$index.AppendLine("==========")
[void]$index.AppendLine("02.00_TOTALES")
[void]$index.AppendLine("==========")
[void]$index.AppendLine("TOTAL_ARCHIVOS: $($allFiles.Count)")
[void]$index.AppendLine("TOTAL_PESO_KB : $totalKb")
Append-Warnings -Sb $index
$indexPath = Save-Output -Name "RADAR.INDEX.CloseReport.txt" -Content $index.ToString()

Write-Host "  [4/7] Writing RADAR.CORE ..."
$core = New-Object System.Text.StringBuilder
Write-RadarHeader -Sb $core -RadarType "RADAR_CORE"
[void]$core.AppendLine("==========")
[void]$core.AppendLine("01.00_CONTENIDO_TEXTO")
[void]$core.AppendLine("==========")
$textRows = @($fileRows | Where-Object { $_.LogicalType -eq "text" })
foreach ($r in $textRows) {
    Append-FileContent -Sb $core -File $r.File -Label "TEXT_FILE"
}
Append-Warnings -Sb $core
$corePath = Save-Output -Name "RADAR.CORE.CloseReport.txt" -Content $core.ToString()

Write-Host "  [5/7] Writing RADAR.FULL ..."
$full = New-Object System.Text.StringBuilder
Write-RadarHeader -Sb $full -RadarType "RADAR_FULL"
[void]$full.AppendLine("==========")
[void]$full.AppendLine("01.00_INDEX")
[void]$full.AppendLine("==========")
[void]$full.AppendLine($index.ToString())
[void]$full.AppendLine("")
[void]$full.AppendLine("==========")
[void]$full.AppendLine("02.00_CORE")
[void]$full.AppendLine("==========")
[void]$full.AppendLine($core.ToString())
[void]$full.AppendLine("")
[void]$full.AppendLine("==========")
[void]$full.AppendLine("03.00_TREE_SIZE")
[void]$full.AppendLine("==========")
$grouped = @($allFiles | Group-Object { Split-Path -Parent (Get-RelPath -FullPath $_.FullName) } | Sort-Object Name)
foreach ($g in $grouped) {
    $sum = 0
    foreach ($f in $g.Group) { $sum += $f.Length }
    [void]$full.AppendLine(("{0,-80} {1,12}" -f $g.Name, $sum))
}
Append-Warnings -Sb $full
$fullPath = Save-Output -Name "RADAR.FULL.CloseReport.txt" -Content $full.ToString()

Write-Host "  [6/7] Writing RADAR.FULL.HUMAN / RADAR.FULL.SKILLS ..."
$human = New-Object System.Text.StringBuilder
Write-RadarHeader -Sb $human -RadarType "RADAR_FULL_HUMAN"
$humanRows = @($textRows | Where-Object { $_.RelPath -like "00.CANON\*" -or $_.RelPath -eq "README.md" })
foreach ($r in $humanRows) {
    Append-FileContent -Sb $human -File $r.File -Label "HUMAN_OR_CANON_FILE"
}
Append-Warnings -Sb $human
$humanPath = Save-Output -Name "RADAR.FULL.HUMAN.CloseReport.txt" -Content $human.ToString()

$skills = New-Object System.Text.StringBuilder
Write-RadarHeader -Sb $skills -RadarType "RADAR_FULL_SKILLS"
$skillRows = @($textRows | Where-Object { $_.RelPath -like "07.SKILLS\*" })
foreach ($r in $skillRows) {
    Append-FileContent -Sb $skills -File $r.File -Label "SKILL_FILE"
}
Append-Warnings -Sb $skills
$skillsPath = Save-Output -Name "RADAR.FULL.SKILLS.CloseReport.txt" -Content $skills.ToString()

Write-Host "  [7/7] Done."
Write-Host ""

Write-Host ""
Write-Host ""
Write-Host ""
Write-Host "++++++++++++++++++++++++++++++AI_TAIL_START++++++++++++++++++"
Write-Host "AI_TAIL_START"
Write-Host "AI_TAIL_SCHEMA=v1"
Write-Host "MB_ID=$MB_ID"
Write-Host "RUNTIME=PowerShell"
Write-Host "ROOT=$Root"
Write-Host "OUTDIR=$OutDir"
Write-Host "FINAL_STATUS=PASS"
Write-Host "BLOCKER=NONE"
Write-Host "WARNINGS_COUNT=$($Warnings.Count)"
Write-Host "FILES_CREATED=$litePath | $indexPath | $corePath | $fullPath | $humanPath | $skillsPath"
Write-Host "VALIDATION_STATUS=RADAR_OUTPUTS_CREATED"
Write-Host "TEMP_POLICY=CLEAN_99_TEMP_BEFORE_CREATE"
Write-Host "COMMIT_PUSH_PERFORMED=NO"
Write-Host "NEXT_ACTION=Use current RADAR output folder or run compile context script"
Write-Host "AI_TAIL_END"
Write-Host "++++++++++++++++++++++++++++++AI_TAIL_END++++++++++++++++++++"
Write-Host ""
Write-Host ""
Write-Host ""