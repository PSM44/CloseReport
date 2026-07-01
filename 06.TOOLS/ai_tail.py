"""
ai_tail.py
CloseReport -- 06.TOOLS
Shared AI_TAIL output contract for Python scripts.

Per: SKILL.SCRIPT_OUTPUT_AI_TAIL_CONTRACT v1.0
     CONTROL.SCRIPT_OUTPUT_AI_TAIL v1.1
     MB-GRC-034B (safe launcher)

Usage:
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "06.TOOLS"))
    from ai_tail import print_ai_tail

    print_ai_tail(
        mb_id       = "CR-ETL-000",
        status      = "PASS",
        next_action = "Run validate_totals.py",
        files       = ["03.DATA/staging/movements_clean.csv"],
    )
"""

import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Union

# Delimiter per CONTROL.SCRIPT_OUTPUT_AI_TAIL section 03
_DELIM    = "*" * 22
_TAIL_STA = f"{_DELIM} AI_TAIL_START {_DELIM}"
_TAIL_END = f"{_DELIM} AI_TAIL_END {'*' * 20}"


# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------

def _git(cmd: List[str]) -> str:
    """Run a git command, return stdout or empty string on failure."""
    try:
        return subprocess.check_output(
            ["git"] + cmd, stderr=subprocess.DEVNULL, text=True
        ).strip()
    except Exception:
        return ""


def _git_info():
    """Return (branch, head_oneliner, dirty_str)."""
    branch = _git(["rev-parse", "--abbrev-ref", "HEAD"]) or "NA"
    head   = _git(["log", "-1", "--format=%h %s"])       or "NA"
    st     = _git(["status", "--short"])
    dirty  = "true" if st else "false"
    return branch, head, dirty


# ---------------------------------------------------------------------------
# Main public function
# ---------------------------------------------------------------------------

def print_ai_tail(
    mb_id:       str,
    status:      str,
    blocker:     str                              = "NONE",
    next_action: str                              = "NONE",
    report:      Optional[Union[Path, str]]       = None,
    files:       Optional[List[str]]              = None,
    commit:      str                              = "NONE",
    push:        str                              = "NO",
    validation:  Optional[str]                   = None,
    extra:       Optional[Dict[str, str]]         = None,
) -> None:
    """
    Print the standard AI_TAIL block to stdout.

    Parameters
    ----------
    mb_id       script identifier          e.g. "CR-ETL-000"
    status      PASS | FAIL | PASS_WITH_WARNINGS | COMMIT_FAILED
    blocker     NONE  or short reason string
    next_action operational next step for human or IA
    report      path to log file in 90.TEMP (or None)
    files       list of files written/changed (triggers FILES_CHANGED block)
    commit      git commit hash or NONE
    push        OK | NO | FAILED
    validation  PASS | FAIL | NA  (for validation scripts)
    extra       additional key=value pairs appended before NEXT_ACTION
    """
    branch, head, dirty = _git_info()
    report_str = str(report) if report else "NONE"

    # 6 blank lines before AI_TAIL_START (per contract section 02 / 05)
    print("\n\n\n\n\n")

    print(_TAIL_STA)
    print(f"AI_TAIL_SCHEMA=v1")
    print(f"MB_ID={mb_id}")
    print(f"FINAL_STATUS={status}")
    print(f"BLOCKER={blocker}")
    print(f"BRANCH={branch}")
    print(f"HEAD={head}")
    print(f"DIRTY={dirty}")
    print(f"REPORT={report_str}")

    if files is not None:
        print(f"FILES_CHANGED={len(files)}")
        print(f"FILES={'|'.join(str(f) for f in files) if files else 'NONE'}")
        print(f"COMMIT={commit}")
        print(f"PUSH={push}")

    if validation is not None:
        print(f"VALIDATION={validation}")

    if extra:
        for k, v in extra.items():
            print(f"{k}={v}")

    print(f"NEXT_ACTION={next_action}")
    print(_TAIL_END)
    print("END")
