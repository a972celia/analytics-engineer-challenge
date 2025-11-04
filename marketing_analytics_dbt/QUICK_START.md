# Quick Start Guide

## Prerequisites

```bash
# Install DBT with DuckDB adapter
pip install dbt-duckdb
```

## Run the Project (3 Steps)

### Step 1: Copy CSV Files
```bash
cd marketing_analytics_dbt
cp ../ae_ad_network_*.csv seeds/
```

### Step 2: Run Setup Script
```bash
./setup_and_run.sh
```

That's it! The script will:
- Load CSV files into DuckDB
- Build all data models
- Run data quality tests
- Create `marketing_analytics.duckdb` database

### Step 3: Query Your Data
```bash
# Open DuckDB
duckdb marketing_analytics.duckdb

# Run queries
SELECT * FROM marts.mart_marketing_performance LIMIT 10;
```

## What You Get

**Final Table**: `marts.mart_marketing_performance`

Contains unified data from both ad networks with:
- Daily performance metrics (spend, impressions, clicks)
- Geographic details (country + state when available)
- Calculated metrics (CPM, CPC, CTR)
- Campaign information

## Sample Queries

See `sample_queries.sql` for 8 ready-to-run analysis queries including:
1. Overall performance by ad network
2. Top performing countries
3. State-level detail analysis
4. Time series trends
5. Campaign comparisons
6. And more...

## Project Structure

```
Staging Layer (5 models)
  ↓
Intermediate Layer (2 models)
  ↓
Marts Layer (1 table)
  ← mart_marketing_performance
```

## Need Help?

- Full technical docs: `DATA_MODEL_DOCUMENTATION.md`
- Solution summary: `../TASK_1_SOLUTION_SUMMARY.md`
- DBT basics: https://docs.getdbt.com/

## Troubleshooting

**Error: "dbt: command not found"**
```bash
pip install dbt-duckdb
```

**Error: "No such file: ae_ad_network_*.csv"**
```bash
# Make sure you're in the right directory and CSV files exist
ls ../ae_ad_network_*.csv
```

**Want to rebuild everything?**
```bash
rm marketing_analytics.duckdb  # Delete database
./setup_and_run.sh              # Run again
```
