"""
load_movements.py
CloseReport -- 02.ETL/01.load
MB_ID: CR-ETL-001

Phase 1 loader.

Input:
    03.DATA/staging/movements_clean.csv

Output:
    03.DATA/staging/movements.csv

Purpose:
    Produce Power Query-ready movements table.

Required final schema includes:
    movement_id
    amount
    day
    year
    month

Date policy:
    Monthly reporting uses day = 1.
    Excel English target: DATE(year, month, day)
    Power Query target: #date([year], [month], [day])
"""

import sys
from pathlib import Path

import pandas as pd

_TOOLS = Path(__file__).resolve().parents[2] / "06.TOOLS"
sys.path.insert(0, str(_TOOLS))
from ai_tail import print_ai_tail

MB_ID = "CR-ETL-001"

ROOT = Path(__file__).resolve().parents[2]
INPUT = ROOT / "03.DATA" / "staging" / "movements_clean.csv"
OUTPUT = ROOT / "03.DATA" / "staging" / "movements.csv"

ENTRY_TYPE_MAP = {
    "Ingreso": "Income",
    "ingreso": "Income",
    "Egreso": "Expense",
    "egreso": "Expense",
    "Traspaso": "Transfer",
    "traspaso": "Transfer",
    "trapaso": "Transfer",
    "Prestamo": "Financing",
    "prestamo": "Financing",
    "Prestamo SN": "Financing",
    "Fondo Mutuo": "Financing",
    "Mutuo": "Financing",
    "Saldo Inicio": "Opening Balance",
}

FINAL_COLUMNS = [
    "movement_id",
    "entity",
    "entity_code",
    "date",
    "year",
    "month",
    "day",
    "supplier",
    "invoice",
    "detail",
    "amount",
    "amount_uf",
    "payment_method",
    "cost_center",
    "category",
    "entry_type",
    "entry_type_source",
    "currency",
    "record_type",
]


def normalize_text(value):
    if pd.isna(value) or value is None:
        return None
    text = str(value).strip()
    if text == "":
        return None
    return text


def infer_entry_type(row):
    current = normalize_text(row.get("entry_type"))
    if current:
        mapped = ENTRY_TYPE_MAP.get(current, current)
        return mapped, "source"

    category = normalize_text(row.get("category"))
    detail = normalize_text(row.get("detail"))
    payment = normalize_text(row.get("payment_method"))

    combined = " ".join([x for x in [category, detail, payment] if x]).lower()

    if "saldo inicio" in combined:
        return "Opening Balance", "inferred"
    if "fondo mutuo" in combined or "mutuo" in combined or "prestamo" in combined:
        return "Financing", "inferred"
    if "traspaso" in combined or "trapaso" in combined:
        return "Transfer", "inferred"

    amount_uf = pd.to_numeric(row.get("amount_uf"), errors="coerce")
    if pd.notna(amount_uf):
        if amount_uf >= 0:
            return "Income", "inferred"
        return "Expense", "inferred"

    return "Unknown", "inferred"


def select_amount_column(df):
    # Preferred order:
    #   amount if already present
    #   amount_clp if present
    #   amount_clp_2 if amount_clp is absent
    # The prior profiler showed amount_clp and amount_clp_2.
    if "amount" in df.columns:
        return "amount"
    if "amount_clp" in df.columns:
        return "amount_clp"
    if "amount_clp_2" in df.columns:
        return "amount_clp_2"
    return None


def main():
    sep = "=" * 60
    print(f"\n{sep}")
    print(f"  load_movements.py -- CloseReport Phase 1 [{MB_ID}]")
    print(f"  Input : {INPUT}")
    print(f"  Output: {OUTPUT}")
    print(f"{sep}\n")

    if not INPUT.exists():
        print(f"[ERROR] movements_clean.csv not found: {INPUT}")
        print_ai_tail(
            mb_id=MB_ID,
            status="FAIL",
            blocker="MOVEMENTS_CLEAN_NOT_FOUND",
            next_action="Run clean_bases.py first",
        )
        sys.exit(1)

    print("[1/5] Loading movements_clean.csv ...")
    df = pd.read_csv(INPUT, dtype=str)
    print(f"      {len(df):,} rows loaded | {len(df.columns)} columns")

    print("[2/5] Normalizing Power Query schema ...")
    amount_source = select_amount_column(df)
    if amount_source is None:
        print(f"[ERROR] No amount column found. Available columns: {list(df.columns)}")
        print_ai_tail(
            mb_id=MB_ID,
            status="FAIL",
            blocker="AMOUNT_COLUMN_NOT_FOUND",
            extra={"AVAILABLE_COLUMNS": ",".join(df.columns)},
            next_action="Patch clean_bases.py to output amount or amount_clp",
        )
        sys.exit(1)

    df["amount"] = pd.to_numeric(df[amount_source], errors="coerce").fillna(0).round(4)
    df["amount_uf"] = pd.to_numeric(df["amount_uf"], errors="coerce").fillna(0).round(4)

    if "date" in df.columns:
        parsed = pd.to_datetime(df["date"], errors="coerce")
        if "year" not in df.columns:
            df["year"] = parsed.dt.year
        if "month" not in df.columns:
            df["month"] = parsed.dt.month

    df["year"] = pd.to_numeric(df["year"], errors="coerce").astype("Int64")
    df["month"] = pd.to_numeric(df["month"], errors="coerce").astype("Int64")
    df["day"] = 1

    df.insert(0, "movement_id", range(1, len(df) + 1))

    print("[3/5] Normalizing entry_type and entry_type_source ...")
    inferred_count = 0
    out_entry = []
    out_source = []
    for _, row in df.iterrows():
        value, source = infer_entry_type(row)
        out_entry.append(value)
        out_source.append(source)
        if source == "inferred":
            inferred_count += 1
    df["entry_type"] = out_entry
    df["entry_type_source"] = out_source

    bad = df["entry_type"].isna() | (df["entry_type"].astype(str).str.strip() == "") | (df["entry_type"] == "Unknown")
    bad_count = int(bad.sum())
    if bad_count > 0:
        print(f"[ERROR] Invalid entry_type rows: {bad_count}")
        print_ai_tail(
            mb_id=MB_ID,
            status="FAIL",
            blocker="ENTRY_TYPE_INVALID",
            extra={"BAD_ROWS": str(bad_count)},
            next_action="Review entry_type inference rules",
        )
        sys.exit(1)

    print("[4/5] Selecting final columns ...")
    for col in FINAL_COLUMNS:
        if col not in df.columns:
            df[col] = None

    final = df[FINAL_COLUMNS].copy()

    print("[5/5] Exporting movements.csv ...")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    final.to_csv(OUTPUT, index=False, encoding="utf-8-sig")

    print("")
    print(sep)
    print("  RESULT: OK")
    print(f"  Rows exported : {len(final):,}")
    print(f"  Output        : {OUTPUT}")
    print(f"  amount_source : {amount_source}")
    print(f"  rows_inferred : {inferred_count}")
    print("  day_policy    : day=1 for monthly reporting")
    print(sep)

    print_ai_tail(
        mb_id=MB_ID,
        status="PASS",
        blocker="NONE",
        extra={
            "FILES_CHANGED": "1",
            "FILES": str(OUTPUT),
            "ROWS_TOTAL": str(len(final)),
            "ROWS_INFERRED": str(inferred_count),
            "AMOUNT_SOURCE": amount_source,
            "DAY_POLICY": "day=1",
            "FINAL_COLUMNS": ",".join(FINAL_COLUMNS),
        },
        next_action="Run validate_totals.py and profile movements.csv for Power Query",
    )
    sys.exit(0)


if __name__ == "__main__":
    main()