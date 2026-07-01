<#
.SYNOPSIS
    Copies required SkillsMachine bundles and skills to CloseReport/07.SKILLS/

.DESCRIPTION
    Source: C:\01. GitHub\Skills
    Dest:   C:\01. GitHub\CloseReport\07.SKILLS\

    Copies:
      - 4 delivery bundles from 90.USECASE\01.NEW_PROJECT\
      - 12 individual skills from SkillsLake\01.SKILLS\

    Safe: never overwrites silently. Reports OK / MISSING / COPIED per file.
    Exit 0 = all files present in dest. Exit 1 = one or more missing in source.

.USAGE
    From project root:
        .\06.TOOLS\copy_skills.ps1
    Force overwrite of existing:
        .\06.TOOLS\copy_skills.ps1 -Force
#>

[CmdletBinding()]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$SkillsRoot   = "C:\01. GitHub\Skills"
$BundleSource = "$SkillsRoot\90.USECASE\01.NEW_PROJECT"
$SkillSource  = "$SkillsRoot\SkillsLake\01.SKILLS"
$Dest         = (Resolve-Path "$PSScriptRoot\..\07.SKILLS").Path

# ---------------------------------------------------------------------------
# File manifest: key → [Folder, File]
# ---------------------------------------------------------------------------
$Manifest = [ordered]@{
    "BUNDLE_MENU"                   = @{ Folder = $BundleSource; File = "00.SKILL.MENU.ACTIVE.txt"                              }
    "BUNDLE_CORE"                   = @{ Folder = $BundleSource; File = "00.BUNDLE.CORE.txt"                                    }
    "BUNDLE_CONTINUITY"             = @{ Folder = $BundleSource; File = "01.BUNDLE.CONTINUITY.txt"                              }
    "BUNDLE_GOVERNANCE"             = @{ Folder = $BundleSource; File = "02.BUNDLE.GOVERNANCE.txt"                              }
    "SKILL_WBS"                     = @{ Folder = $SkillSource;  File = "06.SKILL.WBS.txt"                                      }
    "SKILL_FILE_CONTENT"            = @{ Folder = $SkillSource;  File = "07.SKILL.FILE_CONTENT.txt"                             }
    "SKILL_RADAR"                   = @{ Folder = $SkillSource;  File = "09.SKILL.RADAR.txt"                                    }
    "SKILL_BATON"                   = @{ Folder = $SkillSource;  File = "10.SKILL.BATON.txt"                                    }
    "SKILL_HUMAN_README"            = @{ Folder = $SkillSource;  File = "11.SKILL.HUMAN_README.txt"                             }
    "SKILL_DRAG_AND_DROP"           = @{ Folder = $SkillSource;  File = "12.SKILL.DRAG_AND_DROP.txt"                            }
    "SKILL_PROJECT_BOOTSTRAP"       = @{ Folder = $SkillSource;  File = "20.SKILL.PROJECT_BOOTSTRAP_POLICY.txt"                 }
    "SKILL_OPERATIONAL_ARTIFACTS"   = @{ Folder = $SkillSource;  File = "21.SKILL.OPERATIONAL_ARTIFACTS_POLICY.txt"             }
    "SKILL_PROJECT_LIFECYCLE"       = @{ Folder = $SkillSource;  File = "22.SKILL.PROJECT_LIFECYCLE_POLICY.txt"                 }
    "SKILL_WHOAMI_POLICY"           = @{ Folder = $SkillSource;  File = "23.SKILL.WHOAMI_POLICY.txt"                            }
    "SKILL_PROMPT_ENGINEERING"      = @{ Folder = $SkillSource;  File = "30.SKILL.PROMPT_ENGINEERING_DISCOVERY_CHALLENGE.txt"   }
    "SKILL_MARKDOWN_SAFETY"         = @{ Folder = $SkillSource;  File = "31.SKILL.MARKDOWN_FILE_CREATION_SAFETY.txt"            }
}

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
$Sep       = "=" * 60
$SepDash   = "  " + ("-" * 56)
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Ok        = 0
$Copied    = 0
$Skipped   = 0
$Missing   = 0
$Errors    = @()

Write-Host ""
Write-Host $Sep
Write-Host "  copy_skills.ps1 -- CloseReport"
Write-Host "  $Timestamp"
Write-Host $Sep
Write-Host "  Source bundles : $BundleSource"
Write-Host "  Source skills  : $SkillSource"
Write-Host "  Destination    : $Dest"
Write-Host "  Force overwrite: $Force"
Write-Host ""

# Ensure destination exists
if (-not (Test-Path $Dest)) {
    New-Item -ItemType Directory -Path $Dest -Force | Out-Null
    Write-Host "  [INFO] Created $Dest"
}

# Validate source roots
foreach ($src in @($BundleSource, $SkillSource)) {
    if (-not (Test-Path $src)) {
        Write-Host "  [ERROR] Source not found: $src" -ForegroundColor Red
        Write-Host "          Verify C:\01. GitHub\Skills is present and up to date."
        exit 1
    }
}

Write-Host "  FILE                                           STATUS"
Write-Host $SepDash

foreach ($key in $Manifest.Keys) {
    $entry   = $Manifest[$key]
    $srcFile = Join-Path $entry.Folder $entry.File
    $dstFile = Join-Path $Dest $entry.File
    $label   = $entry.File.PadRight(48)

    if (-not (Test-Path $srcFile)) {
        Write-Host ("  $label  MISSING in source") -ForegroundColor Red
        $Errors += "MISSING: $srcFile"
        $Missing++
        continue
    }

    if ((Test-Path $dstFile) -and (-not $Force)) {
        Write-Host ("  $label  OK (already present)") -ForegroundColor Green
        $Ok++
        $Skipped++
        continue
    }

    try {
        Copy-Item -Path $srcFile -Destination $dstFile -Force
        Write-Host ("  $label  COPIED") -ForegroundColor Cyan
        $Copied++
    }
    catch {
        Write-Host ("  $label  ERROR: $_") -ForegroundColor Red
        $Errors += "COPY_ERROR: $srcFile -- $_"
        $Missing++
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host $Sep
$Total = $Manifest.Count
Write-Host "  Total files in manifest : $Total"
Write-Host "  Already present (skip)  : $Skipped"
Write-Host "  Copied this run         : $Copied"
Write-Host "  Missing in source       : $Missing"
Write-Host ""

if ($Missing -gt 0) {
    Write-Host ("  RESULT: FAIL -- $Missing file(s) not found in source.") -ForegroundColor Red
    foreach ($e in $Errors) { Write-Host "    $e" -ForegroundColor Red }
    Write-Host ""
    Write-Host "  Check that Skills repo is at: $SkillsRoot"
    Write-Host "  and 90.USECASE\01.NEW_PROJECT\ has been built (run BUILD.ps1)."
    exit 1
}
else {
    Write-Host ("  RESULT: OK -- all $Total skills present in 07.SKILLS\") -ForegroundColor Green
    Write-Host "  Next: commit 07.SKILLS\ to git, then run RADAR.ps1"
    Write-Host ""
    exit 0
}
