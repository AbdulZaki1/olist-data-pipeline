"""Export tabel mart DuckDB -> CSV buat Power BI.

Jalanin dari root repo:  python scripts/export_marts.py
Output: data/export/*.csv
"""
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "data" / "olist.duckdb"
OUT = ROOT / "data" / "export"
OUT.mkdir(parents=True, exist_ok=True)

# kolom tambahan khusus BI ditulis di sini, mart tetap bersih
QUERIES = {
    "dim_customer": """
        SELECT *, state || ', Brazil' AS map_location FROM mart.dim_customer
    """,
    "dim_product": "SELECT * FROM mart.dim_product",
    "dim_seller": "SELECT * FROM mart.dim_seller",
    "dim_date": "SELECT * FROM mart.dim_date",
    "fact_order_items": "SELECT * FROM mart.fact_order_items",
}

con = duckdb.connect(str(DB), read_only=True)
for name, sql in QUERIES.items():
    path = OUT / f"{name}.csv"
    con.execute(f"COPY ({sql}) TO '{path.as_posix()}' (HEADER, DELIMITER ',')")
    n = con.execute(f"SELECT count(*) FROM ({sql})").fetchone()[0]
    print(f"{name:<18} {n:>8,} rows -> {path.relative_to(ROOT)}")
con.close()
print("Done.")
