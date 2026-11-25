# Panduan Dashboard Power BI – Olist

## Step 1 – Export CSV
1. Tutup/restart kernel notebook (DuckDB dikunci kalau notebook masih connect).
2. Terminal VS Code (root repo, .venv aktif):
   ```powershell
   python scripts/export_marts.py
   ```
3. Cek folder `data\export\` → 5 file CSV.

## Step 2 – Import ke Power BI
1. Power BI Desktop → **Get data → Folder**? Jangan. Pakai **Get data → Text/CSV**, pilih `fact_order_items.csv` → **Transform Data** (masuk Power Query).
2. Ulangi untuk 4 dim lainnya (Home → New Source → Text/CSV).
3. Di Power Query cek tipe kolom:
   - `date_key` (fact & dim_date) → **Date**
   - `price, freight_value, total_value` → **Decimal Number**
   - `delivery_days, review_score` → **Whole Number**
   - `is_late` → **True/False**
4. **Close & Apply**.

## Step 3 – Relasi (Model view, ikon paling kiri bawah ke-3)
Tarik kolom dari dim ke fact (1 → *, single direction):
| Dim | Kolom | → Fact |
|---|---|---|
| dim_customer | customer_id | fact_order_items.customer_id |
| dim_product | product_id | fact_order_items.product_id |
| dim_seller | seller_id | fact_order_items.seller_id |
| dim_date | date_key | fact_order_items.date_key |

Lalu klik kanan `dim_date` → **Mark as date table** → pilih `date_key`.
Ini star schema: 1 fact di tengah, 4 dim di sekeliling.

## Step 4 – DAX measures
Klik kanan `fact_order_items` → **New measure**, paste satu-satu:
```DAX
Revenue = SUM ( fact_order_items[price] )

Total Orders = DISTINCTCOUNT ( fact_order_items[order_id] )

AOV = DIVIDE ( [Revenue], [Total Orders] )

Avg Delivery Days =
AVERAGEX (
    SUMMARIZE (
        FILTER ( fact_order_items, NOT ISBLANK ( fact_order_items[delivery_days] ) ),
        fact_order_items[order_id], fact_order_items[delivery_days]
    ),
    fact_order_items[delivery_days]
)

Late Rate % =
DIVIDE (
    CALCULATE ( DISTINCTCOUNT ( fact_order_items[order_id] ), fact_order_items[is_late] = TRUE () ),
    CALCULATE ( DISTINCTCOUNT ( fact_order_items[order_id] ), NOT ISBLANK ( fact_order_items[is_late] ) )
)

Avg Review = AVERAGE ( fact_order_items[review_score] )
```
Kenapa Avg Delivery pakai AVERAGEX per order? Fact = 1 baris per *item*. Order isi 3 item jangan dihitung 3x.
Format: Revenue → Currency (R$), Late Rate % → Percentage.

## Step 5 – Visual (1 halaman)
Filter halaman: `dim_date[year]` ≥ 2017 (Filters pane → Filters on this page) dan `order_status` ≠ canceled, unavailable.

| Posisi | Visual | Isi |
|---|---|---|
| Atas | 4 **Card** | Revenue, Total Orders, AOV, Avg Delivery Days |
| Tengah kiri | **Line chart** | X: dim_date[date_key] (hierarchy Year→Month), Y: Revenue |
| Tengah kanan | **Bar chart** (horizontal) | Y: dim_product[category], X: Revenue, Top N = 10 |
| Bawah kiri | **Map** / Filled map | Location: dim_customer[map_location], Bubble size: Total Orders, tooltip: Avg Delivery Days |
| Bawah kanan | **Bar chart** | dim_customer[state] vs Avg Delivery Days (sort desc) |
| Samping | **Slicer** | dim_date[year], dim_customer[state] |

Kalau Map gak muncul: File → Options → Security → centang "Use Map and Filled Map visuals".

## Step 6 – Simpan
`File → Save as` → `dashboard/olist_dashboard.pbix` + screenshot ke `docs/dashboard.png` (buat README).
