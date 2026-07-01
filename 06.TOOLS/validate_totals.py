"""
validate_totals.py
CloseReport -- 06.TOOLS
MB_ID: CR-VAL-000

Validation gate for Phase 0/1.

Uses final Phase 1 output movements.csv and compares it against frozen Excel
reference sheet Bases. Includes strict and soft rounding diagnostics.

ASCII-safe output for Windows console.
"""

import sys
from pathlib import Path
from decimal import Decimal, ROUND_HALF_UP, InvalidOperation

import pandas as pd

_TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(_TOOLS))
from ai_tail import print_ai_tail

_CLEAN = Path(__file__).resolve().parents[1] / "02.ETL" / "00.clean"
sys.path.insert(0, str(_CLEAN))
try:
    from clean_bases import CATEGORY_MAP
except Exception:
    CATEGORY_MAP = {}

MB_ID = "CR-VAL-000"

ROOT = Path(__file__).resolve().parents[1]
MOVEMENTS_CSV = ROOT / "03.DATA" / "staging" / "movements.csv"
REFERENCE_XLSX = ROOT / "03.DATA" / "raw" / "current" / "main.xlsx"
REFERENCE_SHEET = "Bases"

GROUP_TOLERANCE_STRICT = Decimal("0.0001")
GROUP_TOLERANCE_SOFT = Decimal("0.0010")
TOTAL_TOLERANCE_SOFT = Decimal("0.0010")

GROUP_COLS = ["entity", "year", "month", "category"]
VALUE_COL = "amount_uf"

COLUMN_CANDIDATES = {
    "entity": ["Empresa", "empresa", "Entity", "entity"],
    "year": ["A\u00f1o", "A?o", "Ano", "Anio", "Year", "year"],
    "month": ["Mes", "mes", "Month", "month"],
    "category": ["Detalle2", "Detalle 2", "detalle2", "Category", "category"],
    "amount_uf": ["UF", "uf", "Amount UF", "amount_uf"],
}


def safe_decimal(value) -> Decimal:
    if value is None:
        return Decimal("0.0000")
    try:
        if pd.isna(value):
            return Decimal("0.0000")
    except Exception:
        pass
    try:
        return Decimal(str(value)).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)
    except (InvalidOperation, ValueError):
        return Decimal("0.0000")


def normalize_text(value):
    if pd.isna(value) or value is None:
        return None
    text = str(value).strip()
    if text == "":
        return None
    return text


def normalize_category(value):
    text = normalize_text(value)
    if text is None:
        return None
    return CATEGORY_MAP.get(text, text)


def find_column(df: pd.DataFrame, canonical: str) -> str:
    candidates = COLUMN_CANDIDATES[canonical]
    by_exact = {str(c): c for c in df.columns}
    for candidate in candidates:
        if candidate in by_exact:
            return by_exact[candidate]

    normalized = {}
    for col in df.columns:
        key = str(col).strip().lower().replace(" ", "").replace("_", "")
        normalized[key] = col

    for candidate in candidates:
        key = str(candidate).strip().lower().replace(" ", "").replace("_", "")
        if key in normalized:
            return normalized[key]

    available = " | ".join(str(c) for c in df.columns)
    raise KeyError(
        f"Missing required column for {canonical}. "
        f"Candidates={candidates}. Available={available}"
    )


def load_movements() -> pd.DataFrame:
    if not MOVEMENTS_CSV.exists():
        print(f"[ERROR] movements.csv not found: {MOVEMENTS_CSV}")
        print_ai_tail(
            mb_id=MB_ID,
            status="FAIL",
            blocker="MOVEMENTS_CSV_NOT_FOUND",
            validation="FAIL",
            next_action="Run clean_bases.py then load_movements.py first",
        )
        sys.exit(1)

    df = pd.read_csv(MOVEMENTS_CSV, dtype=str)
    required = ["entity", "year", "month", "category", VALUE_COL]
    missing = [col for col in required if col not in df.columns]
    if missing:
        print(f"[ERROR] movements.csv missing columns: {missing}")
        print(f"        Available columns: {list(df.columns)}")
        print_ai_tail(
            mb_id=MB_ID,
            status="FAIL",
            blocker="MOVEMENTS_COLUMNS_MISSING",
            validation="FAIL",
            extra={"MISSING": ",".join(missing)},
            next_action="Review load_movements.py output schema",
        )
        sys.exit(1)

    df[VALUE_COL] = pd.to_numeric(df[VALUE_COL], errors="coerce").fillna(0)
    df["year"] = pd.to_numeric(df["year"], errors="coerce").astype("Int64")
    df["month"] = pd.to_numeric(df["month"], errors="coerce").astype("Int64")
    df["category"] = df["category"].apply(normalize_category)
    return df


def load_reference() -> pd.DataFrame:
    if not REFERENCE_XLSX.exists():
        print(f"[ERROR] Reference Excel not found: {REFERENCE_XLSX}")
        print_ai_tail(
            mb_id=MB_ID,
            status="FAIL",
            blocker="REFERENCE_EXCEL_NOT_FOUND",
            validation="FAIL",
            next_action="Copy frozen 2026 Mayo workbook to 03.DATA/raw/current/main.xlsx",
        )
        sys.exit(1)

    raw = pd.read_excel(
        REFERENCE_XLSX,
        sheet_name=REFERENCE_SHEET,
        dtype=str,
        engine="openpyxl",
    )

    print("      Reference columns detected:")
    print("      " + " | ".join(str(c) for c in raw.columns))

    col_entity = find_column(raw, "entity")
    col_year = find_column(raw, "year")
    col_month = find_column(raw, "month")
    col_category = find_column(raw, "category")
    col_amount = find_column(raw, "amount_uf")

    df = pd.DataFrame({
        "entity": raw[col_entity],
        "year": raw[col_year],
        "month": raw[col_month],
        "category": raw[col_category],
        "amount_uf": raw[col_amount],
    })

    df["amount_uf"] = pd.to_numeric(df["amount_uf"], errors="coerce").fillna(0)
    df["year"] = pd.to_numeric(df["year"], errors="coerce").astype("Int64")
    df["month"] = pd.to_numeric(df["month"], errors="coerce").astype("Int64")
    df["category"] = df["category"].apply(normalize_category)
    return df


def aggregate(df: pd.DataFrame, group_cols) -> pd.DataFrame:
    agg = (
        df.groupby(group_cols, dropna=False)[VALUE_COL]
        .sum()
        .reset_index()
    )
    agg[VALUE_COL] = agg[VALUE_COL].apply(safe_decimal)
    return agg


def compare(csv_agg: pd.DataFrame, ref_agg: pd.DataFrame, group_cols) -> list:
    merged = csv_agg.merge(
        ref_agg,
        on=group_cols,
        how="outer",
        suffixes=("_csv", "_ref"),
    )
    mismatches = []
    for _, row in merged.iterrows():
        csv_val = safe_decimal(row.get(f"{VALUE_COL}_csv", 0))
        ref_val = safe_decimal(row.get(f"{VALUE_COL}_ref", 0))
        delta_signed = csv_val - ref_val
        delta_abs = abs(delta_signed)
        if delta_abs > GROUP_TOLERANCE_STRICT:
            item = {col: row.get(col, None) for col in group_cols}
            item.update({
                "expected": ref_val,
                "got": csv_val,
                "delta_signed": delta_signed,
                "delta_abs": delta_abs,
            })
            mismatches.append(item)
    return mismatches


def summarize_mismatches(mismatches):
    if not mismatches:
        return {
            "count": 0,
            "max_abs": Decimal("0.0000"),
            "sum_abs": Decimal("0.0000"),
            "over_soft": 0,
        }
    max_abs = max(m["delta_abs"] for m in mismatches)
    sum_abs = sum((m["delta_abs"] for m in mismatches), Decimal("0.0000"))
    over_soft = sum(1 for m in mismatches if m["delta_abs"] > GROUP_TOLERANCE_SOFT)
    return {
        "count": len(mismatches),
        "max_abs": max_abs,
        "sum_abs": sum_abs,
        "over_soft": over_soft,
    }


def print_mismatches(mismatches, group_cols, max_rows=80):
    print(f"  Showing first {min(max_rows, len(mismatches))} mismatch(es):")
    for idx, m in enumerate(mismatches[:max_rows], start=1):
        keys = " | ".join(f"{col}={m.get(col)}" for col in group_cols)
        print(
            f"  {idx:04d} | {keys} | "
            f"expected={float(m['expected']):.4f} "
            f"got={float(m['got']):.4f} "
            f"delta_signed={float(m['delta_signed']):.4f} "
            f"delta_abs={float(m['delta_abs']):.4f}"
        )


def main():
    sep = "=" * 60
    print(f"\n{sep}")
    print(f"  validate_totals.py -- CloseReport  [{MB_ID}]")
    print(f"{sep}\n")

    try:
        print("[1/4] Loading movements.csv ...")
        csv_df = load_movements()
        csv_agg = aggregate(csv_df, GROUP_COLS)
        csv_total = safe_decimal(csv_df[VALUE_COL].sum())
        print(f"      {len(csv_df):,} rows -> {len(csv_agg):,} aggregated category groups")

        print("\n[2/4] Loading reference Excel (Bases) ...")
        ref_df = load_reference()
        ref_agg = aggregate(ref_df, GROUP_COLS)
        ref_total = safe_decimal(ref_df[VALUE_COL].sum())
        print(f"      {len(ref_df):,} rows -> {len(ref_agg):,} aggregated category groups")

        print("\n[3/4] Checking total UF conservation ...")
        total_delta = abs(csv_total - ref_total)
        print(f"      reference_total_uf = {float(ref_total):.4f}")
        print(f"      movements_total_uf = {float(csv_total):.4f}")
        print(f"      delta              = {float(total_delta):.4f}")

        print(f"\n[4/4] Comparing category totals (strict tolerance: {GROUP_TOLERANCE_STRICT}) ...")
        mismatches = compare(csv_agg, ref_agg, GROUP_COLS)
        summary = summarize_mismatches(mismatches)

    except Exception as exc:
        print(f"[ERROR] {type(exc).__name__}: {exc}")
        print_ai_tail(
            mb_id=MB_ID,
            status="FAIL",
            blocker=f"{type(exc).__name__}: {exc}",
            validation="FAIL",
            next_action="Use printed file/sheet/column details to fix validation mapping",
        )
        sys.exit(1)

    print()
    print(f"  mismatch_count     = {summary['count']}")
    print(f"  max_delta_abs      = {float(summary['max_abs']):.4f}")
    print(f"  sum_delta_abs      = {float(summary['sum_abs']):.4f}")
    print(f"  over_soft_group    = {summary['over_soft']}")
    print(f"  soft_group_tol     = {float(GROUP_TOLERANCE_SOFT):.4f}")
    print(f"  soft_total_tol     = {float(TOTAL_TOLERANCE_SOFT):.4f}")

    strict_pass = total_delta <= GROUP_TOLERANCE_STRICT and not mismatches
    soft_rounding_pass = (
        total_delta <= TOTAL_TOLERANCE_SOFT
        and summary["over_soft"] == 0
        and summary["max_abs"] <= GROUP_TOLERANCE_SOFT
    )

    if strict_pass:
        print(f"\n  {sep}")
        print("  VALIDATION: PASS_STRICT")
        print("  Total UF and category totals match within strict tolerance.")
        print(f"  {sep}")
        print_ai_tail(
            mb_id=MB_ID,
            status="PASS",
            blocker="NONE",
            validation="PASS_STRICT",
            extra={
                "ROWS_MOVEMENTS": str(len(csv_df)),
                "ROWS_REFERENCE": str(len(ref_df)),
                "GROUPS_MOVEMENTS": str(len(csv_agg)),
                "GROUPS_REFERENCE": str(len(ref_agg)),
                "TOTAL_DELTA_UF": f"{float(total_delta):.4f}",
                "MISMATCHES": "0",
                "MAX_DELTA_ABS": "0.0000",
                "SUM_DELTA_ABS": "0.0000",
            },
            next_action="Open CloseReport.xlsm and refresh Power Query connections",
        )
        sys.exit(0)

    if soft_rounding_pass:
        print(f"\n  {sep}")
        print("  VALIDATION: PASS_SOFT_ROUNDING_ONLY")
        print("  Strict group tolerance failed, but all deltas are within soft rounding policy.")
        print("  Recommendation: accept as Phase 1 validation if management tolerance is 0.0010 UF.")
        print(f"  {sep}\n")
        if mismatches:
            print_mismatches(mismatches, GROUP_COLS, max_rows=80)
        print_ai_tail(
            mb_id=MB_ID,
            status="PASS",
            blocker="NONE",
            validation="PASS_SOFT_ROUNDING_ONLY",
            extra={
                "ROWS_MOVEMENTS": str(len(csv_df)),
                "ROWS_REFERENCE": str(len(ref_df)),
                "GROUPS_MOVEMENTS": str(len(csv_agg)),
                "GROUPS_REFERENCE": str(len(ref_agg)),
                "TOTAL_DELTA_UF": f"{float(total_delta):.4f}",
                "MISMATCHES": str(summary["count"]),
                "MAX_DELTA_ABS": f"{float(summary['max_abs']):.4f}",
                "SUM_DELTA_ABS": f"{float(summary['sum_abs']):.4f}",
                "OVER_SOFT_GROUP": str(summary["over_soft"]),
            },
            next_action="Record DECISION: Phase 1 accepts soft rounding tolerance <=0.0010 UF, then proceed to Power Query setup",
        )
        sys.exit(0)

    print(f"\n  {sep}")
    print("  VALIDATION: FAIL")
    print(f"  TOTAL_DELTA_UF: {float(total_delta):.4f}")
    print(f"  CATEGORY_MISMATCHES: {summary['count']}")
    print(f"  MAX_DELTA_ABS: {float(summary['max_abs']):.4f}")
    print(f"  OVER_SOFT_GROUP: {summary['over_soft']}")
    print(f"  {sep}\n")
    if mismatches:
        print_mismatches(mismatches, GROUP_COLS, max_rows=80)

    blocker = "TOTALS_MISMATCH"
    if total_delta <= TOTAL_TOLERANCE_SOFT and summary["over_soft"] > 0:
        blocker = "CATEGORY_MISMATCH_OVER_SOFT_TOLERANCE"
    elif total_delta > TOTAL_TOLERANCE_SOFT:
        blocker = "TOTAL_UF_MISMATCH_OVER_SOFT_TOLERANCE"

    print_ai_tail(
        mb_id=MB_ID,
        status="FAIL",
        blocker=blocker,
        validation="FAIL",
        extra={
            "ROWS_MOVEMENTS": str(len(csv_df)),
            "ROWS_REFERENCE": str(len(ref_df)),
            "GROUPS_MOVEMENTS": str(len(csv_agg)),
            "GROUPS_REFERENCE": str(len(ref_agg)),
            "TOTAL_DELTA_UF": f"{float(total_delta):.4f}",
            "MISMATCHES": str(summary["count"]),
            "MAX_DELTA_ABS": f"{float(summary['max_abs']):.4f}",
            "SUM_DELTA_ABS": f"{float(summary['sum_abs']):.4f}",
            "OVER_SOFT_GROUP": str(summary["over_soft"]),
        },
        next_action="Review top mismatches. If over_soft_group is high, trace raw rows by entity/year/month/category.",
    )
    sys.exit(1)


if __name__ == "__main__":
    main()