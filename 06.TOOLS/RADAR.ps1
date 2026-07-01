<#
.SYNOPSIS
    RADAR generator for CloseReport -- produces 6 outputs per SKILL.RADAR v1.4 contract.

.DESCRIPTION
    Active outputs written to 05.DOCS\:
      RADAR.LITE.CloseReport.txt
      RADAR.INDEX.CloseReport.txt
      RADAR.CORE.CloseReport.txt
      RADAR.FULL.CloseReport.txt
      RADAR.FULL.HUMAN.CloseReport.txt
      RADAR.FULL.SKILLS.CloseReport.txt

    HIST structure -- one subfolder per run (no mixing between runs):
      05.DOCS\HIST\<RunTimestamp>\
        RADAR.LITE.CloseReport.txt
        RADAR.INDEX.CloseReport.txt
        RADAR.CORE.CloseReport.txt
        RADAR.FULL.CloseReport.txt
        RADAR.FULL.HUMAN.CloseReport.txt
        RADAR.FULL.SKILLS.CloseReport.txt

    Note: 05.DOCS\HIST\ is gitignored (local archive only).
          Active 05.DOCS\RADAR.*.txt files ARE tracked in git.

    Exclusions: .git\, 90.TEMP\, 03.DATA\raw\, 04.REPORTS\outputs\, __pycache__\
    Compatible: Windows PowerShell 5.1+
    Exit 0 = all 6 outputs written. Exit 1 = failure.

.USAGE
    .\06.TOOLS\RADAR.ps1
    .\06.TOOLS\RADAR.ps1 -NoHist
#>

[CmdletBinding()]
param(
    [switch]$NoHist
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
$ProjectRoot     = (Resolve-Path "$PSScriptRoot\..").Path
$ProjectName     = "CloseReport"
$DocsDir         = Join-Path $ProjectRoot "05.DOCS"
$HistDir         = Join-Path $DocsDir "HIST"
$HashThresholdMB = 50
$RunTS           = Get-Date -Format "yyyyMMdd_HHmmss"
$RunTSHuman      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Sep64           = "=" * 64

$ExcludeDirs = @(".git", "90.temp", "03.data\raw", "04.reports\outputs", "__pycache__")

$KnownPurpose = @{
    "WHOAMI.CloseReport.txt"             = "Human-readable project identity and current state"
    "BATON.STATE.CloseReport.txt"        = "AI handoff snapshot -- upload to blank AI to resume work"
    "HUMAN.CloseReport.txt"              = "Deep documentation -- decisions, architecture, conventions"
    "RADAR.LITE.CloseReport.txt"         = "RADAR output -- inventory summary (active, tracked in git)"
    "RADAR.INDEX.CloseReport.txt"        = "RADAR output -- full file inventory with SHA256 (active, tracked)"
    "RADAR.CORE.CloseReport.txt"         = "RADAR output -- text content by layer (active, tracked)"
    "RADAR.FULL.CloseReport.txt"         = "RADAR output -- INDEX + CORE consolidated (active, tracked)"
    "RADAR.FULL.HUMAN.CloseReport.txt"   = "RADAR output -- compiled HUMAN content for AI (active, tracked)"
    "RADAR.FULL.SKILLS.CloseReport.txt"  = "RADAR output -- compiled SKILLS content for AI (active, tracked)"
    "ROADMAP.md"                         = "Phase roadmap with criteria for done"
    "SCHEMA.md"                          = "Database table descriptions"
    "clean_bases.py"                     = "Phase 0 ETL -- normalize Bases categories and entry types"
    "load_movements.py"                  = "Phase 1 ETL -- export movements.csv from clean Bases"
    "validate_totals.py"                 = "Gate tool -- compare CSV totals vs frozen Excel reference"
    "copy_skills.ps1"                    = "Tool -- copy SkillsMachine bundles to 07.SKILLS\"
    "RADAR.ps1"                          = "Tool -- generate all 6 RADAR outputs (this script)"
    "run_etl.ps1"                        = "Orchestrator -- runs full ETL pipeline"
    "requirements.txt"                   = "Python dependencies"
    "README.md"                          = "Project overview and quick start"
    ".gitignore"                         = "Git exclusion rules -- HIST and raw\ are local-only"
    ".gitattributes"                     = "Line ending policy -- LF in repo, CRLF for .ps1 on checkout"
    "movements.csv"                      = "Phase 1 output -- normalized movements in staging\"
    ".gitkeep"                           = "Placeholder to keep folder tracked in git"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Get-RelPath([string]$full) {
    return $full.Substring($ProjectRoot.Length).TrimStart("\")
}

function Get-FileType([string]$ext) {
    switch ($ext.ToLower()) {
        { $_ -in @(".txt",".md",".ps1",".py",".sql",".csv",".json",".gitignore",".gitattributes",".gitkeep") } { return "text" }
        { $_ -in @(".xlsx",".xlsm",".xls") } { return "xlsx" }
        ".pdf"                                { return "pdf" }
        { $_ -in @(".zip",".gz",".tar") }    { return "archive" }
        { $_ -in @(".png",".jpg",".svg") }   { return "image" }
        default                               { return "binary" }
    }
}

function Get-SHA256([string]$path, [long]$sizeBytes) {
    $threshold = $HashThresholdMB * 1MB
    if ($sizeBytes -gt $threshold) { return "HASH_OMITIDO_POR_TAMANO" }
    try   { return (Get-FileHash -Path $path -Algorithm SHA256).Hash }
    catch { return "HASH_ERROR" }
}

function Test-Excluded([string]$relPath) {
    $rel = $relPath.ToLower()
    foreach ($excl in $ExcludeDirs) {
        if ($rel -eq $excl -or $rel.StartsWith($excl + "\")) { return $true }
    }
    return $false
}

function New-Utf8Writer([string]$path) {
    return [System.IO.StreamWriter]::new($path, $false, [System.Text.Encoding]::UTF8)
}

function Write-WbsHeader([System.IO.StreamWriter]$sw, [string]$type) {
    $sw.WriteLine("==========")
    $sw.WriteLine("00.00_METADATOS")
    $sw.WriteLine("==========")
    $sw.WriteLine("")
    $sw.WriteLine("RADAR_TYPE........: $type")
    $sw.WriteLine("PROYECTO..........: $ProjectName")
    $sw.WriteLine("ROOT..............: $ProjectRoot")
    $sw.WriteLine("GENERADO..........: $RunTSHuman")
    $sw.WriteLine("SCRIPT............: 06.TOOLS\RADAR.ps1")
    $sw.WriteLine("SKILL_REF.........: 09.SKILL.RADAR.txt v1.4")
    $sw.WriteLine("HASH_UMBRAL_MB....: $HashThresholdMB")
    $sw.WriteLine("EXCLUSIONES.......: .git\, 90.TEMP\, 03.DATA\raw\, 04.REPORTS\outputs\, __pycache__\")
    $sw.WriteLine("HIST_ESTRUCTURA...: 05.DOCS\HIST\<RunTimestamp>\ (un subfolder por run)")
    $sw.WriteLine("HIST_GIT..........: IGNORADO (gitignore) -- solo archivos activos van a git")
    $sw.WriteLine("ENCODING..........: UTF-8")
    $sw.WriteLine("")
}

# ---------------------------------------------------------------------------
# Ensure output dirs
# ---------------------------------------------------------------------------
if (-not (Test-Path $DocsDir)) { New-Item -ItemType Directory -Path $DocsDir -Force | Out-Null }
if (-not (Test-Path $HistDir))  { New-Item -ItemType Directory -Path $HistDir  -Force | Out-Null }

$OutLite       = Join-Path $DocsDir "RADAR.LITE.$ProjectName.txt"
$OutIndex      = Join-Path $DocsDir "RADAR.INDEX.$ProjectName.txt"
$OutCore       = Join-Path $DocsDir "RADAR.CORE.$ProjectName.txt"
$OutFull       = Join-Path $DocsDir "RADAR.FULL.$ProjectName.txt"
$OutFullHuman  = Join-Path $DocsDir "RADAR.FULL.HUMAN.$ProjectName.txt"
$OutFullSkills = Join-Path $DocsDir "RADAR.FULL.SKILLS.$ProjectName.txt"

Write-Host ""
Write-Host $Sep64
Write-Host "  RADAR.ps1 -- $ProjectName"
Write-Host "  Run: $RunTSHuman"
Write-Host $Sep64
Write-Host ""

# ---------------------------------------------------------------------------
# [1/7] Scan
# ---------------------------------------------------------------------------
Write-Host "  [1/7] Scanning $ProjectRoot ..."

$AllFiles = @(
    Get-ChildItem -Path $ProjectRoot -Recurse -File |
    Where-Object { -not (Test-Excluded (Get-RelPath $_.FullName)) } |
    Sort-Object FullName
)

$FileData = @(foreach ($f in $AllFiles) {
    $rel  = Get-RelPath $f.FullName
    $ext  = $f.Extension
    $type = Get-FileType $ext
    $sha  = Get-SHA256 $f.FullName $f.Length
    $purp = if ($KnownPurpose.ContainsKey($f.Name)) { $KnownPurpose[$f.Name] } else { "" }

    [PSCustomObject]@{
        FullPath = $f.FullName
        RelPath  = $rel
        Name     = $f.Name
        Ext      = if ($ext) { $ext } else { "(none)" }
        SizeB    = $f.Length
        Modified = $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        Type     = $type
        SHA256   = $sha
        Purpose  = $purp
        Folder   = (Split-Path $rel -Parent)
    }
})

$HumanFiles  = @($FileData | Where-Object { $_.RelPath -like "00.CANON\*" })
$SkillsFiles = @($FileData | Where-Object { $_.RelPath -like "07.SKILLS\*" })
$TextFiles   = @($FileData | Where-Object { $_.Type -eq "text" })
$TotalFiles  = $FileData.Count
$TotalSizeKB = [math]::Round(($FileData | Measure-Object -Property SizeB -Sum).Sum / 1KB, 2)
$UniqFolders = @($FileData | Select-Object -ExpandProperty Folder | Sort-Object -Unique)
$TotalFolders = $UniqFolders.Count

Write-Host ("      Found $TotalFiles files in ~$TotalFolders folders ($TotalSizeKB KB)")

# ---------------------------------------------------------------------------
# [2/7] LITE
# ---------------------------------------------------------------------------
Write-Host "  [2/7] Writing RADAR.LITE ..."
$sw = New-Utf8Writer $OutLite
Write-WbsHeader $sw "RADAR_LITE"
$sw.WriteLine("==========")
$sw.WriteLine("01.00_ESTADO_CONTROL_CAMBIOS")
$sw.WriteLine("==========")
$sw.WriteLine("")
$sw.WriteLine("ESTADO............: version_0 -- no aplica control de cambios")
$sw.WriteLine("EJECUCION_PREVIA..: ninguna")
$sw.WriteLine("")
$sw.WriteLine("==========")
$sw.WriteLine("02.00_RESUMEN")
$sw.WriteLine("==========")
$sw.WriteLine("")
$sw.WriteLine("TOTAL_ARCHIVOS....: $TotalFiles")
$sw.WriteLine("TOTAL_CARPETAS....: $TotalFolders")
$sw.WriteLine("TOTAL_PESO_KB.....: $TotalSizeKB")
$sw.WriteLine("ARCHIVOS_HUMAN....: $($HumanFiles.Count)")
$sw.WriteLine("ARCHIVOS_SKILLS...: $($SkillsFiles.Count)")
$sw.WriteLine("ARCHIVOS_TEXTO....: $($TextFiles.Count)")
$sw.WriteLine("")
$sw.WriteLine("HUMAN_CAMBIOS_DETECTADOS: NO (version_0)")
$sw.WriteLine("")
$sw.WriteLine("==========")
$sw.WriteLine("03.00_PUNTEROS")
$sw.WriteLine("==========")
$sw.WriteLine("")
$sw.WriteLine("RADAR_INDEX.......: 05.DOCS\RADAR.INDEX.$ProjectName.txt")
$sw.WriteLine("RADAR_CORE........: 05.DOCS\RADAR.CORE.$ProjectName.txt")
$sw.WriteLine("RADAR_FULL........: 05.DOCS\RADAR.FULL.$ProjectName.txt")
$sw.WriteLine("RADAR_FULL.HUMAN..: 05.DOCS\RADAR.FULL.HUMAN.$ProjectName.txt")
$sw.WriteLine("RADAR_FULL.SKILLS.: 05.DOCS\RADAR.FULL.SKILLS.$ProjectName.txt")
$sw.WriteLine("HIST_DIR..........: 05.DOCS\HIST\$RunTS\ (este run)")
$sw.WriteLine("HIST_GIT..........: IGNORADO -- local only")
$sw.WriteLine("RUN_TIMESTAMP.....: $RunTS")
$sw.WriteLine("")
$sw.WriteLine("==========")
$sw.WriteLine("04.00_ARBOL_RESUMEN")
$sw.WriteLine("==========")
$sw.WriteLine("")
foreach ($folder in $UniqFolders) {
    $cnt   = @($FileData | Where-Object { $_.Folder -eq $folder }).Count
    $label = if ($folder) { $folder } else { "(root)" }
    $sw.WriteLine(("  " + $label.PadRight(44) + "$cnt file(s)"))
}
$sw.Close()

# ---------------------------------------------------------------------------
# [3/7] INDEX
# ---------------------------------------------------------------------------
Write-Host "  [3/7] Writing RADAR.INDEX ..."
$sw = New-Utf8Writer $OutIndex
Write-WbsHeader $sw "RADAR_INDEX"
$sw.WriteLine("==========")
$sw.WriteLine("01.00_INVENTARIO_COMPLETO")
$sw.WriteLine("==========")
$sw.WriteLine("")
$sw.WriteLine(("  " + "RUTA".PadRight(60) + "  " + "BYTES".PadLeft(8) + "  MODIFICADO            EXT        TIPO_LOGICO  SHA256"))
$sw.WriteLine(("  " + ("-" * 150)))
foreach ($f in $FileData) {
    $sw.WriteLine(("  " + $f.RelPath.PadRight(60) + "  " +
                   $f.SizeB.ToString().PadLeft(8) + "  " +
                   $f.Modified + "  " +
                   $f.Ext.PadRight(10) + "  " +
                   $f.Type.PadRight(12) + "  " +
                   $f.SHA256))
}
$sw.WriteLine("")
$sw.WriteLine("==========")
$sw.WriteLine("02.00_TOTALES")
$sw.WriteLine("==========")
$sw.WriteLine("")
$sw.WriteLine("TOTAL_ARCHIVOS: $TotalFiles")
$sw.WriteLine("TOTAL_PESO_KB : $TotalSizeKB")
$sw.Close()

# ---------------------------------------------------------------------------
# [4/7] CORE
# ---------------------------------------------------------------------------
Write-Host "  [4/7] Writing RADAR.CORE ..."
$sw = New-Utf8Writer $OutCore
Write-WbsHeader $sw "RADAR_CORE"
$sw.WriteLine("==========")
$sw.WriteLine("01.00_CONTENIDO_POR_CAPA")
$sw.WriteLine("==========")
$sw.WriteLine("")
$groupedFolders = @($FileData | Group-Object -Property Folder | Sort-Object Name)
foreach ($group in $groupedFolders) {
    $folderLabel = if ($group.Name) { $group.Name } else { "(root)" }
    $sw.WriteLine("==========")
    $sw.WriteLine("CAPA: $folderLabel")
    $sw.WriteLine("==========")
    $sw.WriteLine("")
    foreach ($f in ($group.Group | Sort-Object Name)) {
        $sw.WriteLine("----------")
        $sw.WriteLine("ARCHIVO...: $($f.Name)")
        $sw.WriteLine("RUTA......: $($f.RelPath)")
        $sw.WriteLine("TIPO......: $($f.Type)")
        $sw.WriteLine("TAMANO....: $($f.SizeB) bytes")
        $sw.WriteLine("MODIFICADO: $($f.Modified)")
        if ($f.Purpose) { $sw.WriteLine("PROPOSITO.: $($f.Purpose)") }
        if ($f.Type -eq "text") {
            $sw.WriteLine("CONTENIDO.:")
            try { foreach ($line in (Get-Content -Path $f.FullPath -Encoding UTF8 -ErrorAction Stop)) { $sw.WriteLine("  $line") } }
            catch { $sw.WriteLine("  [ERROR reading: $_]") }
        } else { $sw.WriteLine("CONTENIDO.: [BINARIO -- omitido]") }
        $sw.WriteLine("")
    }
}
$sw.Close()

# ---------------------------------------------------------------------------
# [5/7] FULL
# ---------------------------------------------------------------------------
Write-Host "  [5/7] Writing RADAR.FULL ..."
$sw = New-Utf8Writer $OutFull
Write-WbsHeader $sw "RADAR_FULL"
$sw.WriteLine("==========")
$sw.WriteLine("01.00_NOTA")
$sw.WriteLine("==========")
$sw.WriteLine("")
$sw.WriteLine("Consolida INDEX + CORE. Alto costo de tokens -- usar con criterio.")
$sw.WriteLine("")
foreach ($l in (Get-Content -Path $OutIndex -Encoding UTF8)) { $sw.WriteLine($l) }
$sw.WriteLine("")
foreach ($l in (Get-Content -Path $OutCore  -Encoding UTF8)) { $sw.WriteLine($l) }
$sw.Close()

# ---------------------------------------------------------------------------
# [6/7] FULL.HUMAN
# ---------------------------------------------------------------------------
Write-Host "  [6/7] Writing RADAR.FULL.HUMAN ..."
$sw = New-Utf8Writer $OutFullHuman
Write-WbsHeader $sw "RADAR_FULL.HUMAN"
$sw.WriteLine("==========")
$sw.WriteLine("01.00_PROPOSITO")
$sw.WriteLine("==========")
$sw.WriteLine("")
$sw.WriteLine("Compilacion de 00.CANON\. Sube en lugar de archivos individuales.")
$sw.WriteLine("")
foreach ($f in ($HumanFiles | Sort-Object Name)) {
    $sw.WriteLine(("=" * 64))
    $sw.WriteLine("SOURCE_FILE: $($f.RelPath)")
    $sw.WriteLine("SHA256    : $($f.SHA256)")
    $sw.WriteLine(("=" * 64))
    $sw.WriteLine("")
    if ($f.Type -eq "text") {
        try { foreach ($line in (Get-Content -Path $f.FullPath -Encoding UTF8 -ErrorAction Stop)) { $sw.WriteLine($line) } }
        catch { $sw.WriteLine("[ERROR reading: $_]") }
    }
    $sw.WriteLine("")
}
$sw.Close()

# ---------------------------------------------------------------------------
# [7/7] FULL.SKILLS
# ---------------------------------------------------------------------------
Write-Host "  [7/7] Writing RADAR.FULL.SKILLS ..."
$sw = New-Utf8Writer $OutFullSkills
Write-WbsHeader $sw "RADAR_FULL.SKILLS"
$sw.WriteLine("==========")
$sw.WriteLine("01.00_PROPOSITO")
$sw.WriteLine("==========")
$sw.WriteLine("")
$sw.WriteLine("Compilacion de 07.SKILLS\. Sube en lugar de bundles individuales.")
$sw.WriteLine("")
foreach ($f in ($SkillsFiles | Sort-Object Name)) {
    $sw.WriteLine(("=" * 64))
    $sw.WriteLine("SOURCE_FILE: $($f.RelPath)")
    $sw.WriteLine("SHA256    : $($f.SHA256)")
    $sw.WriteLine(("=" * 64))
    $sw.WriteLine("")
    if ($f.Type -eq "text") {
        try { foreach ($line in (Get-Content -Path $f.FullPath -Encoding UTF8 -ErrorAction Stop)) { $sw.WriteLine($line) } }
        catch { $sw.WriteLine("[ERROR reading: $_]") }
    }
    $sw.WriteLine("")
}
$sw.Close()

# ---------------------------------------------------------------------------
# HIST -- per-run subfolder (no mixing between runs)
# ---------------------------------------------------------------------------
if (-not $NoHist) {
    $RunHistDir = Join-Path $HistDir $RunTS
    if (-not (Test-Path $RunHistDir)) {
        New-Item -ItemType Directory -Path $RunHistDir -Force | Out-Null
    }
    Write-Host ("  [+]   Writing HIST\$RunTS\ ...")
    foreach ($src in @($OutLite, $OutIndex, $OutCore, $OutFull, $OutFullHuman, $OutFullSkills)) {
        $leaf = [System.IO.Path]::GetFileName($src)   # e.g. RADAR.LITE.CloseReport.txt
        Copy-Item -Path $src -Destination (Join-Path $RunHistDir $leaf) -Force
    }
    Write-Host ("        --> 05.DOCS\HIST\$RunTS\ (6 files, gitignored)")
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host $Sep64
Write-Host ("  RESULT: OK -- 6 active outputs in 05.DOCS\") -ForegroundColor Green
Write-Host ""
Write-Host "    RADAR.LITE.$ProjectName.txt     (tracked in git)"
Write-Host "    RADAR.INDEX.$ProjectName.txt    (tracked in git)"
Write-Host "    RADAR.CORE.$ProjectName.txt     (tracked in git)"
Write-Host "    RADAR.FULL.$ProjectName.txt     (tracked in git)"
Write-Host "    RADAR.FULL.HUMAN.$ProjectName.txt  (tracked in git)"
Write-Host "    RADAR.FULL.SKILLS.$ProjectName.txt (tracked in git)"
if (-not $NoHist) {
    Write-Host ""
    Write-Host "    HIST\$RunTS\ --> 6 files (local only, gitignored)"
}
Write-Host ""
Write-Host "  Files scanned : $TotalFiles"
Write-Host "  Total size KB : $TotalSizeKB"
Write-Host ""
exit 0
