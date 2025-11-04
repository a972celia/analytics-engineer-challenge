# Marketing Analytics DBT Project

This DBT project creates a unified marketing datamart combining data from Ad Network 1 and Ad Network 2.

## Setup Instructions

1. **Install DBT with DuckDB adapter**:
   ```bash
   pip install dbt-duckdb
   ```

2. **Copy CSV files to seeds directory**:
   ```bash
   cp ae_ad_network_*.csv marketing_analytics_dbt/seeds/
   ```

3. **Run DBT**:
   ```bash
   cd marketing_analytics_dbt
   dbt seed      # Load CSV files
   dbt run       # Build models
   dbt test      # Run data quality tests
   ```

## Project Structure

```
models/
├── staging/          # Raw data cleaning and type casting
│   ├── stg_ad_network_1__campaign_updates.sql
│   ├── stg_ad_network_1__geo_dictionary.sql
│   ├── stg_ad_network_1__country_report.sql
│   ├── stg_ad_network_1__detailed_report.sql
│   └── stg_ad_network_2__report.sql
├── intermediate/     # Business logic transformations
│   ├── int_ad_network_1__unified.sql
│   └── int_ad_network_2__with_geo.sql
└── marts/           # Final analytics-ready tables
    └── mart_marketing_performance.sql
```

## Data Model

The final datamart (`mart_marketing_performance`) combines both ad networks with:
- **Granularity**: date, campaign, most detailed geo level available
- **Metrics**: spend, impressions, clicks
- **Dimensions**: ad network, campaign name, country, state (when available)
