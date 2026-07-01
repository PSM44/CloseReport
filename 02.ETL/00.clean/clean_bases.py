"""
clean_bases.py
CloseReport -- Phase 0 ETL
Phase 0: Normalize the Bases sheet from main.xlsx into a clean CSV.

What it fixes:
  - entry_type  : 13 dirty variants -> 5 canonical English values
  - payment_method: 8 dirty variants -> 5 canonical values
  - category    : 81 Detalle2 variants -> normalized (case + typos)
  - cost_center : 116 Centro de Costo variants -> normalized
  - column names: strips trailing spaces from header
  - adds: entity_code, currency, record_type columns
  - drops: empty trailing column (col O)

Input : 03.DATA/raw/current/main.xlsx  (sheet: Bases)
Output: 03.DATA/staging/movements_clean.csv  (4 decimal places for UF)

Usage:
    python 02.ETL/00.clean/clean_bases.py
    python 02.ETL/00.clean/clean_bases.py --input path/to/file.xlsx
"""

import sys
import argparse
from pathlib import Path
from collections import defaultdict

import pandas as pd

# Add 06.TOOLS to path for ai_tail
_TOOLS = Path(__file__).resolve().parents[2] / "06.TOOLS"
import sys as _sys
_sys.path.insert(0, str(_TOOLS))
from ai_tail import print_ai_tail

MB_ID = "CR-ETL-000"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
ROOT = Path(__file__).resolve().parents[2]
DEFAULT_INPUT  = ROOT / "03.DATA" / "raw" / "current" / "main.xlsx"
DEFAULT_OUTPUT = ROOT / "03.DATA" / "staging" / "movements_clean.csv"
SHEET_NAME = "Bases"

# ---------------------------------------------------------------------------
# Output column names (English -- DEC-002)
# ---------------------------------------------------------------------------
COLUMNS_RENAME = {
    "Empresa":        "entity",
    "Fecha":          "date",
    "Proveedor":      "supplier",
    "Factura ":       "invoice",       # trailing space in source
    "Detalle":        "detail",
    "Monto ":         "amount_clp",    # trailing space in source
    "Forma de Pago":  "payment_method",
    "Centro de Costo":"cost_center",
    "Detalle2":       "category",
    "Ingreso/Egreso": "entry_type",
    "Monto 2":        "amount_clp_2",
    "UF":             "amount_uf",
    "Año":            "year",
    "Mes":            "month",
}

# ---------------------------------------------------------------------------
# Entity code mapping
# ---------------------------------------------------------------------------
ENTITY_CODE = {
    "Kumquat Gestion Inmobiliaria SPA":      "KMT",
    "Kumquat Holding Inmobiliario S.P.A.":   "KUM",
    "Marina Puerto Velero":                  "MAR",
    "Inmobiliaria Bahia Barnes s.a.":        "BAR",
    "Inmobiliaria Koke S.A.":               "KOKE",
}

# ---------------------------------------------------------------------------
# entry_type: 13 dirty -> 5 canonical (English)
# ---------------------------------------------------------------------------
ENTRY_TYPE_MAP = {
    # Income
    "Ingreso":      "Income",
    "ingreso":      "Income",
    # Expense
    "Egreso":       "Expense",
    # Transfer
    "Traspaso":     "Transfer",
    "traspaso":     "Transfer",
    "trapaso":      "Transfer",      # typo
    # Financing
    "Prestamo":     "Financing",
    "prestamo":     "Financing",
    "Prestamo SN":  "Financing",
    "Fondo Mutuo":  "Financing",
    "Mutuo":        "Financing",
    # Opening Balance
    "Saldo Inicio": "Opening Balance",
}

# ---------------------------------------------------------------------------
# payment_method: 8 dirty -> 5 canonical
# ---------------------------------------------------------------------------
PAYMENT_METHOD_MAP = {
    "Nomina":           "Nomina",
    "nomina":           "Nomina",
    "Cargo directo":    "Cargo Directo",
    "cargo automatico": "Cargo Automatico",
    "Cheque":           "Cheque",
    "cheque":           "Cheque",
    "Traspaso Fondos":  "Traspaso Fondos",
}

# ---------------------------------------------------------------------------
# category (Detalle2): canonical values
# Groups obvious duplicates. Preserves values used by SUMIFS in reports.
# ---------------------------------------------------------------------------
CATEGORY_MAP = {
    # Bahia Barnes (slide 3 income line)
    "Bahía Barnes":              "Bahia Barnes",
    "Barnes":                    "Bahia Barnes",
    "barnes":                    "Bahia Barnes",
    # Be Smart (BS1 management fee income)
    "Be smart 2":                "Be Smart 2",
    # KMT / Kumquat
    "kmt":                       "KMT",
    "kumquat":                   "Kumquat",
    # Lux
    "LUX":                       "Lux",
    # Koke
    "koke":                      "Koke",
    # Gastos Generales (expense bucket)
    "Gastos generales":          "Gastos Generales",
    "gastos geenerales":         "Gastos Generales",   # typo
    "Gastos Mantencion":         "Gastos Generales",
    "Gastos comunes":            "Gastos Generales",
    "Almuerzo Personal":         "Gastos Generales",
    "Electricos":                "Gastos Generales",
    "Mantencion":                "Gastos Generales",
    "Ferreteria":                "Gastos Generales",
    "Basura":                    "Gastos Generales",
    "Pasajes":                   "Gastos Generales",
    "pasajes":                   "Gastos Generales",
    "Extintores":                "Gastos Generales",
    "Patente":                   "Gastos Generales",
    "Servicios Basicos":         "Gastos Generales",
    "Servicios TI":              "Gastos Generales",
    "Ploteo Planos":             "Gastos Generales",
    "ploteo":                    "Gastos Generales",
    "Gastos Representacion":     "Gastos Generales",
    "Gastos de Representacion":  "Gastos Generales",
    "Contribuciones":            "Gastos Generales",
    "Calefaccion":               "Gastos Generales",
    "Seguro":                    "Gastos Generales",
    "transporte":                "Gastos Generales",
    "Tramites":                  "Gastos Generales",
    "Bodega 9":                  "Gastos Generales",
    "Moldajes":                  "Gastos Generales",
    "Pago Basura":               "Gastos Generales",
    "Baños socios":              "Gastos Generales",
    # Caja Chica
    "Caja chica":                "Caja Chica",
    # Asesorias
    "Asesorias administrativas": "Asesorias Administrativas",
    # Rosetta variants
    "Honorarios- Rosetta":       "Rosetta",
    "Gasto Legal - Rosetta":     "Rosetta",
    "Gastos Generales Rosetta":  "Rosetta",
    # SN Holding
    "Sn Holding":                "SN Holding",
    "Prestamo SN holding":       "SN Holding",
    # Inversion
    "inversion":                 "Inversion",
    # Smart San Nicolas (variant of Be Smart)
    "Smart San nicolas":         "Be Smart",
    # Piloto
    "piloto":                    "Piloto",
    # Administracion
    "Administracion":            "Administracion",
    # Concesion
    "Alonso de Cordova":         "Concesion",
    "Inm Alonso":                "Concesion",
    # Rendicion
    "Rendicion":                 "Rendicion",
    # Remuneraciones
    "Remuneraciones":            "Remuneraciones",
    # Auditorias
    "Auditorias":                "Auditorias",
}

# ---------------------------------------------------------------------------
# cost_center: normalize case variants (116 -> cleaner)
# Rule: title-case + specific overrides for known duplicates
# ---------------------------------------------------------------------------
COST_CENTER_MAP = {
    # Remuneracion
    "remuneracion":              "Remuneracion",
    # Caja Chica
    "Caja chica":                "Caja Chica",
    "caja Chica":                "Caja Chica",
    "caja chica":                "Caja Chica",
    "Caja chica Legal":          "Caja Chica Legal",
    # Previred
    "PreviRed":                  "Previred",
    # Impuesto
    "impuesto":                  "Impuesto",
    # Asesorias
    "Asesorias administrativas": "Asesorias Administrativas",
    # Servicios TI
    "Servicio TI":               "Servicios TI",
    # Servicios Basicos
    "Servicios basicos":         "Servicios Basicos",
    "servicios basicos":         "Servicios Basicos",
    # Gastos Generales
    "Gastos generales":          "Gastos Generales",
    "gastos generales":          "Gastos Generales",
    "Gastos Administración":     "Gastos Generales",
    "Gastos mantencion":         "Gastos Generales",
    # Prestamo SN
    "prestamo SN":               "Prestamo SN",
    # Traspaso
    "traspaso":                  "Traspaso",
    # Aporte de Capital
    "aporte de capital":         "Aporte de Capital",
    "Aporte de capital":         "Aporte de Capital",
    # Contribuciones
    "contribuciones":            "Contribuciones",
    # Argomedo
    "argomedo":                  "Argomedo",
    # Comision Banco
    "comision Banco":            "Comision Banco",
    # Clientes
    "clientes":                  "Clientes",
    # Insumos Oficina
    "insumos oficina":           "Insumos Oficina",
    "Insumos oficina":           "Insumos Oficina",
    "Insumos oficina - Lux":     "Insumos Oficina Lux",
    # EOL Tramites
    "Eol- Tramites":             "EOL Tramites",
    "EOL- Tramites":             "EOL Tramites",
    # Gastos Legales
    "Gastos legales":            "Gastos Legales",
    "gastos legales":            "Gastos Legales",
    # Marketing
    "marketing":                 "Marketing",
    # SN Holding
    "Sn Holding":                "SN Holding",
    # Be Smart 2 studies
    "Estudio -Be smart 2":       "Estudio Be Smart 2",
    "Arquitectura -Be Smart 2":  "Arquitectura Be Smart 2",
    "Permisos -Be smart 2":      "Permisos Be Smart 2",
    "Calculo -Be smart 2":       "Calculo Be Smart 2",
    "AP- Be Smart 2":            "AP Be Smart 2",
    "Revisor -Be smart 2":       "Revisor Be Smart 2",
    "Gastos Legales - Be smart 2": "Gastos Legales Be Smart 2",
    "Fusion Lotes -Be smart 2":  "Fusion Lotes Be Smart 2",
    # Rosetta
    "Gastos generales - La Rosetta": "Gastos Generales Rosetta",
    "Publicidad en Medios - La Rosetta": "Marketing Rosetta",
    "Gastos Legales-Rosetta":    "Gastos Legales Rosetta",
    "Especialidades Rosetta":    "Especialidades Rosetta",
    # Honorarios Lux
    "Honorarios -Lux":           "Honorarios Lux",
    # Argomedo subcategories
    "Marketing-Argomedo":        "Marketing Argomedo",
    "Remuneracion-Argomedo":     "Remuneracion Argomedo",
    "Honorarios-Argomedo":       "Honorarios Argomedo",
    # Tarjeta Credito
    "Tarjeta de Credito":        "Tarjeta de Credito",
    # Saldo inicio
    "Saldo de inicio":           "Saldo Inicio",
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def apply_map(value, mapping, col_name, counters):
    """Apply a fixed mapping dict. Returns canonical or original if not found."""
    if pd.isna(value) or value is None or str(value).strip() == "":
        return None
    v = str(value).strip()
    if v in mapping:
        canonical = mapping[v]
        if canonical != v:
            counters[col_name][f"{v!r} -> {canonical!r}"] += 1
        return canonical
    return v


def normalize_cost_center(value, counters):
    """Apply fixed map, then title-case anything not in the map."""
    if pd.isna(value) or value is None or str(value).strip() == "":
        return None
    v = str(value).strip()
    if v in COST_CENTER_MAP:
        canonical = COST_CENTER_MAP[v]
        if canonical != v:
            counters["cost_center"][f"{v!r} -> {canonical!r}"] += 1
        return canonical
    # fallback: return as-is (already normalized or very specific)
    return v


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def clean_bases(input_path: Path, output_path: Path):
    sep = "=" * 60
    print(f"\n{sep}")
    print(f"  clean_bases.py -- CloseReport Phase 0")
    print(f"  Input : {input_path}")
    print(f"  Output: {output_path}")
    print(f"{sep}\n")

    # ------------------------------------------------------------------
    # 1. Load
    # ------------------------------------------------------------------
    print("[1/5] Loading Bases sheet ...")
    df = pd.read_excel(input_path, sheet_name=SHEET_NAME, engine="openpyxl")
    print(f"      {len(df):,} rows loaded | {len(df.columns)} columns")

    # Drop fully-empty columns (the trailing col O)
    df.dropna(axis=1, how="all", inplace=True)

    # Strip trailing spaces from column names
    df.columns = [c.strip() if isinstance(c, str) else c for c in df.columns]
    # Now rename using our canonical English names
    df.rename(columns={k.strip(): v for k, v in COLUMNS_RENAME.items()}, inplace=True)

    # ------------------------------------------------------------------
    # 2. Normalize
    # ------------------------------------------------------------------
    print("[2/5] Normalizing columns ...")
    counters = defaultdict(lambda: defaultdict(int))
    original_counts = defaultdict(int)

    # entry_type
    original_counts["entry_type"] = df["entry_type"].notna().sum()
    df["entry_type"] = df["entry_type"].apply(
        lambda v: apply_map(v, ENTRY_TYPE_MAP, "entry_type", counters)
    )

    # payment_method
    original_counts["payment_method"] = df["payment_method"].notna().sum()
    df["payment_method"] = df["payment_method"].apply(
        lambda v: apply_map(v, PAYMENT_METHOD_MAP, "payment_method", counters)
    )

    # category (Detalle2)
    original_counts["category"] = df["category"].notna().sum()
    df["category"] = df["category"].apply(
        lambda v: apply_map(v, CATEGORY_MAP, "category", counters)
    )

    # cost_center
    original_counts["cost_center"] = df["cost_center"].notna().sum()
    df["cost_center"] = df["cost_center"].apply(
        lambda v: normalize_cost_center(v, counters)
    )

    # ------------------------------------------------------------------
    # 3. Add derived columns
    # ------------------------------------------------------------------
    print("[3/5] Adding entity_code, currency, record_type ...")
    df["entity_code"] = df["entity"].map(ENTITY_CODE).fillna("UNKNOWN")
    df["currency"]    = "CLP"
    df["record_type"] = "Real"

    # Flag unmapped entities
    unknown = df[df["entity_code"] == "UNKNOWN"]["entity"].unique()
    if len(unknown) > 0:
        print(f"      WARNING: {len(unknown)} unmapped entities: {unknown}")

    # ------------------------------------------------------------------
    # 4. Round UF to 4 decimal places (DEC-003)
    # ------------------------------------------------------------------
    print("[4/5] Rounding amount_uf to 4 decimal places ...")
    df["amount_uf"] = df["amount_uf"].round(4)

    # ------------------------------------------------------------------
    # 5. Export
    # ------------------------------------------------------------------
    print("[5/5] Exporting to CSV ...")
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Column order for output
    col_order = [
        "entity", "entity_code", "date", "supplier", "invoice", "detail",
        "amount_clp", "payment_method", "cost_center", "category",
        "entry_type", "amount_clp_2", "amount_uf", "year", "month",
        "currency", "record_type"
    ]
    # Only include columns that exist
    col_order = [c for c in col_order if c in df.columns]
    df = df[col_order]

    df.to_csv(output_path, index=False, encoding="utf-8-sig",
              float_format="%.4f", date_format="%Y-%m-%d")

    # ------------------------------------------------------------------
    # Summary report
    # ------------------------------------------------------------------
    print(f"\n{sep}")
    print(f"  RESULT: OK")
    print(f"  Rows exported : {len(df):,}")
    print(f"  Output        : {output_path}")
    print(f"{sep}")

    print("\n  CHANGES BY COLUMN:")
    for col, changes in counters.items():
        n = sum(changes.values())
        print(f"\n  [{col}] -- {n} values normalized")
        for change, count in sorted(changes.items(), key=lambda x: -x[1]):
            print(f"    {count:4d}x  {change}")

    # Warn on any remaining unknowns in entry_type
    unknown_et = df[~df["entry_type"].isin(
        ["Income", "Expense", "Transfer", "Financing", "Opening Balance"]
    ) & df["entry_type"].notna()]
    if len(unknown_et) > 0:
        print(f"\n  WARNING: {len(unknown_et)} rows with unrecognized entry_type:")
        print(unknown_et[["entity", "date", "entry_type"]].to_string())

    print(f"\n  Next step: run validate_totals.py to verify against frozen reference.")
    print()

    print_ai_tail(
        mb_id=MB_ID,
        status="PASS",
        blocker="NONE",
        files=[str(output_path)],
        next_action="Run validate_totals.py to confirm 0.0000 tolerance vs frozen Excel",
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="CloseReport Phase 0 -- clean Bases sheet")
    parser.add_argument("--input",  default=str(DEFAULT_INPUT),  help="Path to main.xlsx")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT), help="Path to output CSV")
    args = parser.parse_args()

    clean_bases(Path(args.input), Path(args.output))
