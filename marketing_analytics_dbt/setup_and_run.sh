#!/bin/bash

# Script to setup and run the marketing analytics DBT project

echo "=== Marketing Analytics DBT Setup ==="
echo ""

# Check if dbt is installed
if ! command -v dbt &> /dev/null; then
    echo "ERROR: dbt is not installed."
    echo "Please install it with: pip install dbt-duckdb"
    exit 1
fi

echo "✓ dbt is installed"

# Copy CSV files to seeds directory
echo ""
echo "Copying CSV files to seeds directory..."
cp ../ae_ad_network_*.csv seeds/ 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ CSV files copied successfully"
else
    echo "WARNING: Could not copy CSV files. Make sure they are in the parent directory."
fi

# Run dbt commands
echo ""
echo "=== Running DBT Commands ==="
echo ""

echo "1. Loading seed data (CSV files)..."
dbt seed --profiles-dir .

if [ $? -ne 0 ]; then
    echo "ERROR: dbt seed failed"
    exit 1
fi

echo ""
echo "2. Building models..."
dbt run --profiles-dir .

if [ $? -ne 0 ]; then
    echo "ERROR: dbt run failed"
    exit 1
fi

echo ""
echo "3. Running data quality tests..."
dbt test --profiles-dir .

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Your marketing datamart is ready!"
echo "Database location: marketing_analytics.duckdb"
echo "Final table: marts.mart_marketing_performance"
echo ""
echo "To query the data, use DuckDB:"
echo "  duckdb marketing_analytics.duckdb"
echo "  SELECT * FROM marts.mart_marketing_performance LIMIT 10;"
