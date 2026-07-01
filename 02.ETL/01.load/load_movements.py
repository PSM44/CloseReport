"""
load_movements.py
CloseReport -- 02.ETL/01.load
MB_ID: CR-ETL-001

Phase 1: Produce final movements.csv from movements_clean.csv.

Steps:
  1. Read movements_clean.csv  (Phase 0 output)
  2. Infer entry_type for 21 confirmed NULL rows (approved by Pablo 2026-06-30)
  3. Add entry_type_source column  (Mapped | Inferred)
  4. Validate: zero NULL entry_types remain
  5. Write movements.csv to staging   (4 decimal places, UTF-8-sig)

Input:  03.DATA/staging/movements_clean.csv
Output: 03.DATA/staging/movements.csv

Usage:
    python 02.ETL/01.load/load_movements.py
    python 02.ETL/01.load/load_movements.py --input path/to/clean.csv
"""

import sys
import argparse
from pathlib import Path

import pandas as pd

# ---------------------------------------------------------------------------
# ai_tail
# ---------------------------------------------------------------------------
_TOOLS = Path(__file__).resolve().parents[2] / "06.TOOLS"
sys.path.insert(0, str(_TOOLS))
from ai_tail import print_ai_tail

MB_ID = "CR-ETL-001"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
ROOT           = Path(__file__).resolve().parents[2]
DEFAULT_INPUT  = ROOT / "03.DATA" / "staging" / "movements_clean.csv"
DEFAULT_OUTPUT = ROOT / "03.DATA" / "staging" / "movements.csv"

# ---------------------------------------------------------------------------
# Inference rules for 21 NULL entry_type rows
# Approved: Pablo 2026-06-30 (BATON.STATE.CloseReport.txt DEC-011)
#
# Each rule: (label, condition_fn, entry_type)
# Applied in order; first match wins. Unmapped -> 'Unknown' + warning.
# ---------------------------------------------------------------------------

def _has(s: str, val: str) -> bool:
    """Safe case-insensitive substring check on possibly-null strings."""
    return isinstance(s, str) and val.lower() in s.lower()


INFER_RULES = [
    # 1. cost_center = Traspaso -> Transfer
    ("cc=Traspaso",
     lambda r: r["cost_center"] == "Traspaso",
     "Transfer"),

    # 2. cost_center = Otros ingresos -> Income  (KUM bank credits)
    ("cc=Otros ingresos",
     lambda r: r["cost_center"] == "Otros ingresos",
     "Income"),

    # 3. cost_center = Clientes -> Income  (client payment received)
    ("cc=Clientes",
     lambda r: r["cost_center"] == "Clientes",
     "Income"),

    # 4. supplier = TRASPASO FONDOS -> Transfer
    ("supplier=TRASPASO FONDOS",
     lambda r: _has(r["supplier"], "TRASPASO FONDOS"),
     "Transfer"),

    # 5. supplier starts with 'Devolucion' -> Income  (reimbursement received)
    ("supplier=Devolucion*",
     lambda r: _has(r["supplier"], "devolucion"),
     "Income"),

    # 6. detail contains 'Devolucion' -> Income
    ("detail=Devolucion*",
     lambda r: _has(str(r.get("detail", "")), "devolucion"),
     "Income"),

    # 7. supplier = 'Depósito...' -> Income  (bank deposit)
    ("supplier=Deposito",
     lambda r: _has(r["supplier"], "dep"),
     "Income"),

    # 8. supplier = 'PAGO EFECTUADO A PROVEEDORES', amount < 0 -> Transfer
    #    (bank debit that moved funds elsewhere)
    ("supplier=PAGO EFECTUADO, amount<0",
     lambda r: _has(r["supplier"], "PAGO EFECTUADO") and r["amount_clp"] < 0,
     "Transfer"),

    # 9. supplier = 'PAGO EFECTUADO A PROVEEDORES', amount > 0 -> Expense
    #    (bank statement debit shown as positive in KUM books)
    ("supplier=PAGO EFECTUADO, amount>0",
     lambda r: _has(r["supplier"], "PAGO EFECTUADO") and r["amount_clp"] > 0,
     "Expense"),

    # 10. supplier = 'PAGOS DE PROVEEDORES', amount < 0 -> Expense  (bulk payment)
    ("supplier=PAGOS DE PROVEEDORES, amount<0",
     lambda r: _has(r["supplier"], "PAGOS DE PROVEEDORES") and r["amount_clp"] < 0,
     "Expense"),

    # 11. supplier = 'PAGO PROVEEDOR...', amount < 0 -> Expense
    ("supplier=PAGO PROVEEDOR, amount<0",
     lambda r: _has(r["supplier"], "PAGO PROVEEDOR") and r["amount_clp"] < 0,
     "Expense"),

    # 12. supplier = 'PAGO PROVEEDOR...', amount > 0 -> Income (reintegro caja chica)
    ("supplier=PAGO PROVEEDOR, amount>0",
     lambda r: _has(r["supplier"], "PAGO PROVEEDOR") and r["amount_clp"] > 0,
     "Income"),

    # 13. supplier = 'Pago Proveedores...' (KUM format), amount > 0 -> Income
    ("supplier=Pago Proveedores, amount>0",
     lambda r: _has(r["supplier"], "Pago Proveedores") and r["amount_clp"] > 0,
     "Income"),

    # 14. supplier contains 'TRANSF. DE' -> Income  (transfer received)
    ("supplier=TRANSF. DE",
     lambda r: _has(r["supplier"], "TRANSF. DE"),
     "Income"),

    # 15. supplier contains 'Transf a' -> Expense  (outbound transfer)
    ("supplier=Transf a",
     lambda r: _has(r["supplier"], "Transf a"),
     "Expense"),

    # 16. supplier = 'Gestora KMT Santander' -> Income  (internal credit)
    ("supplier=Gestora KMT Santander",
     lambda r: _has(r["supplier"], "Gestora KMT Santander"),
     "Income"),

    # 17. supplier contains 'aporte de capital' -> Income
    ("supplier=aporte de capital",
     lambda r: _has(r["supplier"], "aporte de capital"),
     "Income"),
]


def infer_entry_type(row) -> tuple:
    """
    Returns (entry_type, source) where source is 'Inferred:<label>' or 'Mapped'.
    Called only when entry_type is NULL.
    """
    for label, condition, canonical in INFER_RULES:
        try:
            if condition(row):
                return canonical, f"Inferred:{label}"
        except Exception:
            continue
    return "Unknown", "Inferred:UNMATCHED"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def load_movements(input_path: Path, output_path: Path):
    sep = "=" * 60
    print(f"\n{sep}")
    print(f"  load_movements.py -- CloseReport  [{MB_ID}]")
    print(f"  Input : {input_path}")
    print(f"  Output: {output_path}")
    print(f"{sep}\n")

    # ------------------------------------------------------------------
    # 1. Read
    # ------------------------------------------------------------------
    print("[1/5] Reading movements_clean.csv ...")
    if not input_path.exists():
        print(f"  ERROR: {input_path} not found. Run clean_bases.py first.")
        print_ai_tail(
            mb_id=MB_ID, status="FAIL",
            blocker="MOVEMENTS_CLEAN_NOT_FOUND",
            next_action="Run clean_bases.py first (CR-ETL-000)",
        )
        sys.exit(1)

    df = pd.read_csv(input_path, dtype=str)
    df["amount_clp"]   = pd.to_numeric(df["amount_clp"],   errors="coerce")
    df["amount_clp_2"] = pd.to_numeric(df["amount_clp_2"], errors="coerce")
    df["amount_uf"]    = pd.to_numeric(df["amount_uf"],    errors="coerce")
    df["year"]         = pd.to_numeric(df["year"],         errors="coerce").astype("Int64")
    df["month"]        = pd.to_numeric(df["month"],        errors="coerce").astype("Int64")
    print(f"      {len(df):,} rows loaded")

    # ------------------------------------------------------------------
    # 2. Add entry_type_source column + infer NULLs
    # ------------------------------------------------------------------
    print("[2/5] Resolving entry_type for NULL rows ...")

    null_mask = df["entry_type"].isna()
    null_count_before = null_mask.sum()
    print(f"      {null_count_before} rows with NULL entry_type")

    # Add source column
    df["entry_type_source"] = df["entry_type"].apply(
        lambda v: "Mapped" if pd.notna(v) and str(v).strip() else None
    )

    inferred_log = []
    for idx in df[null_mask].index:
        row = df.loc[idx]
        et, source = infer_entry_type(row)
        df.at[idx, "entry_type"]        = et
        df.at[idx, "entry_type_source"] = source
        inferred_log.append((idx, et, source, row["entity_code"], row["date"], str(row["supplier"])[:40]))

    # Fill remaining source for already-mapped rows
    df["entry_type_source"] = df["entry_type_source"].fillna("Mapped")

    print(f"\n      INFERRED ROWS:")
    for idx, et, source, entity, date, supplier in inferred_log:
        tag = "OK " if et != "Unknown" else "WARN"
        print(f"      [{tag}] idx={idx:4d} {entity} {date} -> {et:20s} ({source})")

    # ------------------------------------------------------------------
    # 3. Validate
    # ------------------------------------------------------------------
    print("\n[3/5] Validating ...")
    null_after  = df["entry_type"].isna().sum()
    unknown     = (df["entry_type"] == "Unknown").sum()

    valid_types = {"Income", "Expense", "Transfer", "Financing", "Opening Balance"}
    invalid     = df[~df["entry_type"].isin(valid_types)]

    status_ok = null_after == 0 and unknown == 0 and len(invalid) == 0

    print(f"      NULL entry_type remaining : {null_after}  (expect 0)")
    print(f"      Unknown entry_type         : {unknown}   (expect 0)")
    print(f"      Invalid entry_type values  : {len(invalid)}  (expect 0)")
    print(f"      entry_type counts:")
    for k, v in df["entry_type"].value_counts().items():
        print(f"        {k:<20} {v:>6,}")

    # ------------------------------------------------------------------
    # 4. Ensure 4 decimal precision
    # ------------------------------------------------------------------
    print("\n[4/5] Applying 4-decimal precision to amount_uf ...")
    df["amount_uf"] = df["amount_uf"].round(4)

    # ------------------------------------------------------------------
    # 5. Export
    # ------------------------------------------------------------------
    print("[5/5] Exporting movements.csv ...")
    output_path.parent.mkdir(parents=True, exist_ok=True)

    col_order = [
        "entity", "entity_code", "date", "supplier", "invoice", "detail",
        "amount_clp", "payment_method", "cost_center", "category",
        "entry_type", "entry_type_source", "amount_clp_2",
        "amount_uf", "year", "month", "currency", "record_type",
    ]
    col_order = [c for c in col_order if c in df.columns]
    df[col_order].to_csv(
        output_path, index=False, encoding="utf-8-sig",
        float_format="%.4f", date_format="%Y-%m-%d",
    )

    # ------------------------------------------------------------------
    # Summary
    # ------------------------------------------------------------------
    print(f"\n{sep}")
    if status_ok:
        print("  RESULT: OK")
    else:
        print("  RESULT: FAIL -- validation errors above")
    print(f"  Rows exported  : {len(df):,}")
    print(f"  Inferred rows  : {len(inferred_log)}")
    print(f"  Output         : {output_path}")
    print(f"{sep}")

    status = "PASS" if status_ok else "FAIL"
    blocker = "NONE" if status_ok else f"NULL_ENTRY_TYPE={null_after} UNKNOWN={unknown}"
    next_action = (
        "Run validate_totals.py (CR-VAL-000) to confirm 0.0000 tolerance"
        if status_ok
        else "Fix inference rules in load_movements.py then re-run"
    )

    print_ai_tail(
        mb_id=MB_ID,
        status=status,
        blocker=blocker,
        files=[str(output_path)],
        next_action=next_action,
        extra={"ROWS_TOTAL": str(len(df)), "ROWS_INFERRED": str(len(inferred_log))},
    )

    sys.exit(0 if status_ok else 1)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="CloseReport Phase 1 -- produce movements.csv")
    parser.add_argument("--input",  default=str(DEFAULT_INPUT))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()
    load_movements(Path(args.input), Path(args.output))
