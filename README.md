# Olist E-Commerce Analytics — End-to-End SQL + Power BI Project

A complete analytics engineering project built on the **Brazilian E-Commerce Public Dataset by Olist**. You will go from raw CSV files to a normalized PostgreSQL database to a Power BI dashboard — following the exact same steps used to build this project.

---

## What You Will Build

By the end of this project you will have:

- A **PostgreSQL relational database** with 9 tables, foreign key constraints, and performance indexes
- **5 analytical SQL views** that clean, join, and pre-aggregate the data for reporting
- A **Power BI dashboard** connected to those views, showing revenue trends, delivery performance, review scores, and geographic breakdowns

No prior experience with analytics engineering is required. You need to know basic SQL and how to install software....

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Get the Dataset](#2-get-the-dataset)
3. [Set Up PostgreSQL](#3-set-up-postgresql)
4. [Create the Schema](#4-create-the-schema)
5. [Add Foreign Key Constraints](#5-add-foreign-key-constraints)
6. [Load the CSV Data](#6-load-the-csv-data)
7. [Create Performance Indexes](#7-create-performance-indexes)
8. [Build the Analytical Views](#8-build-the-analytical-views)
9. [Connect Power BI](#9-connect-power-bi)
10. [Project Structure](#10-project-structure)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Prerequisites

Before starting, install the following:

**PostgreSQL 13 or higher**
Download from https://www.postgresql.org/download/
During installation, note the port (default: `5432`), the superuser name (`postgres`), and the password you set — you will need all three later.

**pgAdmin 4** (optional but recommended for beginners)
Comes bundled with the PostgreSQL installer on Windows. Gives you a visual interface to run SQL and browse tables instead of using the command line.

**Power BI Desktop** (free)
Download from https://powerbi.microsoft.com/desktop
Only available on Windows. Mac users can use a Windows VM or skip the dashboard step.

---

## 2. Get the Dataset

1. Go to https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
2. Create a free Kaggle account if you do not have one
3. Click **Download** — you will get a ZIP file
4. Extract the ZIP. You should have these 9 CSV files:

```
olist_customers_dataset.csv
olist_geolocation_dataset.csv
olist_order_items_dataset.csv
olist_order_payments_dataset.csv
olist_order_reviews_dataset.csv
olist_orders_dataset.csv
olist_products_dataset.csv
olist_sellers_dataset.csv
product_category_name_translation.csv
```

Move all 9 files to a folder you can easily find. For example:
- Windows: `C:\olist_data\`
- Mac/Linux: `/home/yourname/olist_data/`

> The dataset is too large to include in this repository — download it directly from the Kaggle link above.

---

## 3. Set Up PostgreSQL

Create a new database for this project so it stays isolated from everything else.

**Using pgAdmin:**
1. Open pgAdmin and connect to your server
2. Right-click **Databases** → **Create** → **Database**
3. Name it `olist_analytics` → click **Save**

**Using the command line:**
```sql
psql -U postgres
CREATE DATABASE olist_analytics;
\c olist_analytics
```

All SQL commands from this point forward must be run inside the `olist_analytics` database.

---

## 4. Create the Schema

Run `0ST.sql`. This creates all 9 tables with the correct column names and data types.

```bash
psql -U postgres -d olist_analytics -f 0ST.sql
```

Or paste the file contents into the pgAdmin query editor and click **Run**.

**What this creates:**

| Table | Description |
|-------|-------------|
| `olist_customers_dataset` | Customer IDs, city, state |
| `olist_geolocation_dataset` | Lat/lng coordinates by zip code |
| `olist_products_dataset` | Product dimensions, weight, category |
| `olist_sellers_dataset` | Seller location |
| `olist_orders_dataset` | Order status and all timestamps |
| `olist_order_items_dataset` | Line items — price, freight, product, seller per order |
| `olist_order_payments_dataset` | Payment type, installments, value |
| `olist_order_reviews_dataset` | Review score and comments |
| `product_category_name_translation` | Portuguese to English category name mapping |

**Verify it worked:**
```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```
You should see all 9 tables listed.

---

## 5. Add Foreign Key Constraints

Run `1ST.sql`. This links the tables to each other so PostgreSQL enforces data integrity.

```bash
psql -U postgres -d olist_analytics -f 1ST.sql
```

> **Important:** Run this file *after* creating the tables but *before* loading any data. If you run it after loading and there are orphaned records in the CSVs, it will fail.

What gets linked:
- Orders → Customers
- Order Items → Orders, Products, and Sellers
- Order Payments → Orders
- Order Reviews → Orders

---

## 6. Load the CSV Data

Open `2ND.sql` in any text editor **before running it**. You must update every file path to match where you saved the CSVs in Step 2.

Find lines that look like this:
```sql
COPY olist_customers_dataset FROM 'C:\Users\pc\Downloads\archive\olist_customers_dataset.csv' DELIMITER ',' CSV HEADER;
```

Replace the path with your actual path. Examples:

Windows:
```sql
COPY olist_customers_dataset FROM 'C:\olist_data\olist_customers_dataset.csv' DELIMITER ',' CSV HEADER;
```

Mac/Linux:
```sql
COPY olist_customers_dataset FROM '/home/yourname/olist_data/olist_customers_dataset.csv' DELIMITER ',' CSV HEADER;
```

Update every `COPY` statement in the file, then run it:

```bash
psql -U postgres -d olist_analytics -f 2ND.sql
```

> **Note on geolocation:** The geolocation table is commented out in the load script because it contains over 1 million rows and is not used in any of the analytical views. You can load it if you want, but it is not required for the dashboard.

**Verify the data loaded correctly:**
```sql
SELECT COUNT(*) FROM olist_orders_dataset;        -- expect ~99,441
SELECT COUNT(*) FROM olist_order_items_dataset;   -- expect ~112,650
SELECT COUNT(*) FROM olist_customers_dataset;     -- expect ~99,441
SELECT COUNT(*) FROM olist_products_dataset;      -- expect ~32,951
```

---

## 7. Create Performance Indexes

Run `3RD.sql`. This speeds up queries significantly, especially for date-range filters and joins on `order_id`.

```bash
psql -U postgres -d olist_analytics -f 3RD.sql
```

Indexes are created on:
- `order_id` across orders, items, payments, and reviews — speeds up all joins
- `customer_id` in orders and customers
- `product_id` and `seller_id` in order items
- `order_purchase_timestamp` in orders — speeds up monthly and date-range filters
- `customer_state` — speeds up geographic filters in the dashboard

This runs in a few seconds and only needs to be done once.

---

## 8. Build the Analytical Views

Run `4TH.sql`. This is the core of the project — it creates 5 views that Power BI (or any BI tool) will query directly.

```bash
psql -U postgres -d olist_analytics -f 4TH.sql
```

> **Run this file as a whole, not statement by statement.** Some views depend on earlier ones in the same file.

---

### View 1 — `bi_dim_product`

A clean product dimension. Translates Portuguese category names to English using `COALESCE` — if no English translation exists, it falls back to the original Portuguese name. Also calculates `volume_cm3` as length × height × width.

---

### View 2 — `bi_fact_review_latest`

Reviews are messy in this dataset — some orders have multiple review rows. This view uses `DISTINCT ON (order_id)` ordered by `review_creation_date DESC` to keep only the most recent review per order, preventing duplicate rows when joining to the fact table.

---

### View 3 — `bi_fact_order`

Order-level metrics. Calculates two important derived columns:

- `delivery_days` — how many calendar days from purchase to actual delivery (only populated for delivered orders)
- `is_late` — a 1/0 flag for whether the actual delivery date exceeded the estimated delivery date

Also brings in customer city and state directly, so downstream views do not need a separate customer join.

---

### View 4 — `bi_payments_order`

One order can have multiple payment rows (for example a voucher combined with a credit card). This view collapses them into one row per order — summing the total payment value, taking the maximum installments, and selecting the dominant payment type by value using `ARRAY_AGG`.

---

### View 5 — `bi_fact_sales` ← main reporting view

The master fact table. Joins everything together — order line items, order metrics, product category, review score, payment info, and seller location — into a single wide table. **This is the primary view you connect Power BI to.**

Full list of columns:

| Column | Description |
|--------|-------------|
| `order_id`, `order_item_id` | Order and line item identifiers |
| `product_id`, `seller_id` | Product and seller identifiers |
| `price` | Item price |
| `freight_value` | Shipping cost for the item |
| `purchase_date` | Order date at day level |
| `purchase_month` | Order date truncated to month — use this for trend charts |
| `delivered_date` | Actual delivery date |
| `estimated_date` | Estimated delivery date at time of purchase |
| `delivery_days` | Days from purchase to delivery |
| `is_late` | 1 if delivered after estimated date, else 0 |
| `order_status` | delivered, shipped, canceled, etc. |
| `customer_city`, `customer_state` | Customer location |
| `category` | Product category in English |
| `review_score` | 1 to 5 star rating |
| `payment_type` | credit_card, boleto, voucher, debit_card |
| `payment_installments` | Number of installments chosen |
| `payment_value` | Payment amount |
| `seller_city`, `seller_state` | Seller location |

**Verify all 5 views were created:**
```sql
SELECT table_name FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;
```

Test the main view:
```sql
SELECT * FROM bi_fact_sales LIMIT 10;
```

---

## 9. Connect Power BI

**Step 1 — Install the PostgreSQL driver**

Power BI needs the Npgsql driver to connect to PostgreSQL. Without it, PostgreSQL will not appear as a data source option.

Download from: https://github.com/npgsql/npgsql/releases
Get the latest `.msi` installer, run it, then restart Power BI Desktop.

**Step 2 — Connect**

1. Open Power BI Desktop
2. Click **Get Data** → search **PostgreSQL database** → click **Connect**
3. Enter:
   - Server: `localhost`
   - Database: `olist_analytics`
4. Click **OK** — enter your PostgreSQL username and password when prompted
5. In the Navigator, select these views:
   - `bi_fact_sales`
   - `bi_payments_order`
   - `bi_dim_product`
6. Click **Load**

**Step 3 — Build visuals**

Suggested visuals to recreate the dashboard:

- **Line chart** — `purchase_month` on X axis, `SUM(price)` on Y axis → monthly revenue trend
- **Bar chart** — `category` on axis, `SUM(price)` as value → top product categories by revenue
- **Map visual** — `customer_state` with `COUNT(order_id)` → order density across Brazil
- **Card visuals** — Total Orders, Total GMV, Average Review Score, Late Delivery Rate
- **Donut chart** — `payment_type` → payment method breakdown
- **Table** — `customer_state`, average `delivery_days`, `SUM(is_late)` → delivery performance by state

**DAX measures to create:**

```
Total GMV = SUM(bi_fact_sales[price]) + SUM(bi_fact_sales[freight_value])

Late Delivery Rate = DIVIDE(SUM(bi_fact_sales[is_late]), COUNT(bi_fact_sales[order_id]))

Avg Delivery Days = AVERAGE(bi_fact_sales[delivery_days])

Avg Review Score = AVERAGE(bi_fact_sales[review_score])
```

To scope delivery metrics to delivered orders only, add a visual-level filter: `order_status = "delivered"`.

---

## 10. Project Structure

All files are in the root of the repository. Run the SQL files in this exact order:

```
olist-ecommerce-analytics/
│
├── 0ST.sql           # Step 1 — Create all 9 tables
├── 1ST.sql           # Step 2 — Add foreign key constraints
├── 2ND.sql           # Step 3 — Load CSVs (update file paths first)
├── 3RD.sql           # Step 4 — Create performance indexes
├── 4TH.sql           # Step 5 — Build the 5 analytical views
│
├── DONE WORK.pbix    # Completed Power BI dashboard
└── README.md
```

**Run order: `0ST` → `1ST` → `2ND` → `3RD` → `4TH`**

Skipping steps or running out of order will cause errors. Specifically — constraints must be added before data is loaded, and views must be created after all tables and data are in place.

---

## 11. Troubleshooting

**`COPY` fails with "permission denied on file"**
PostgreSQL's server-side `COPY` runs as the PostgreSQL process user, not your Windows or Mac account. Two fixes:
- Use `\copy` (lowercase) instead of `COPY` when running via psql — this runs as your user
- Move the CSV files to a publicly readable folder like `C:\Users\Public\` on Windows

**Foreign key constraint error during data load**
You ran `1ST.sql` after loading data. Drop all tables (`DROP TABLE ... CASCADE` in reverse dependency order) and restart from Step 4, making sure to run `1ST.sql` before `2ND.sql`.

**Power BI does not show PostgreSQL as a data source**
The Npgsql driver is not installed. Download it from https://github.com/npgsql/npgsql/releases and restart Power BI after installing.

**`bi_fact_sales` returns more rows than the order count**
Expected. One order can have multiple payment rows, which fans out when joining. For clean order-level payment analysis, use `bi_payments_order` instead of joining `olist_order_payments_dataset` directly.

**View creation fails with "relation does not exist"**
Run `4TH.sql` as a complete file, not statement by statement. `bi_fact_sales` depends on `bi_fact_order` and `bi_dim_product` — those must exist first. The file is already ordered correctly.

---

## Dataset

**Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
**License:** CC BY-NC-SA 4.0
**Coverage:** September 2016 – October 2018

| Table | Approx. Row Count |
|-------|-------------------|
| Customers | 99,441 |
| Orders | 99,441 |
| Order Items | 112,650 |
| Order Payments | 103,886 |
| Order Reviews | 100,000 |
| Products | 32,951 |
| Sellers | 3,095 |
| Geolocation | 1,000,163 |

---

## Tech Stack

- PostgreSQL 13+
- Power BI Desktop
- SQL — DDL, DML, window functions, analytical views

---

## Author

**Nitin Pandey**
Data Analyst · NLP & Sentiment Intelligence · Business Insights
[LinkedIn](https://www.linkedin.com/in/nitin-pandey-b3ab17271/) · [GitHub](https://github.com/NitinPandey12465) · New Delhi, India
