# Task 1: Marketing Datamart - Solution Summary

## Overview

Created a complete DBT project that unifies marketing data from Ad Network 1 and Ad Network 2 into a single analytics-ready datamart with emphasis on detailed geographic information.

## Deliverables

### Project Structure

```
marketing_analytics_dbt/
├── README.md                          # Setup and usage instructions
├── DATA_MODEL_DOCUMENTATION.md        # Detailed technical documentation
├── dbt_project.yml                    # DBT project configuration
├── profiles.yml                       # DuckDB connection config
├── setup_and_run.sh                   # Automated setup script
├── sample_queries.sql                 # Example analysis queries
│
├── models/
│   ├── staging/                       # Layer 1: Data cleaning
│   │   ├── stg_ad_network_1__campaign_updates.sql
│   │   ├── stg_ad_network_1__geo_dictionary.sql
│   │   ├── stg_ad_network_1__country_report.sql
│   │   ├── stg_ad_network_1__detailed_report.sql
│   │   ├── stg_ad_network_2__report.sql
│   │   └── schema.yml                 # Data tests for staging
│   │
│   ├── intermediate/                  # Layer 2: Business logic
│   │   ├── int_ad_network_1__unified.sql
│   │   └── int_ad_network_2__with_geo.sql
│   │
│   └── marts/                         # Layer 3: Final datamart
│       ├── mart_marketing_performance.sql
│       └── schema.yml                 # Data tests for marts
│
├── tests/                             # Custom data quality tests
│   ├── test_no_negative_metrics.sql
│   ├── test_clicks_not_exceed_impressions.sql
│   ├── test_ad_network_1_geo_integrity.sql
│   ├── test_ad_network_2_country_code_extracted.sql
│   └── test_no_duplicate_records.sql
│
└── seeds/                             # CSV files go here
    └── (copy ae_ad_network_*.csv files here)
```

## Key Features Implemented

### Requirements Met

1. **Unified Datamart**: Single table combining both ad networks
2. **Geographic Detail Priority**: Most detailed geo level available
   - Ad Network 1: State-level when available, country-level otherwise
   - Ad Network 2: Country-level extracted from campaign names
3. **Data Quality**: Comprehensive tests to validate third-party data
4. **Deduplication**: Intelligent logic to prefer detailed over aggregate data

### Technical Highlights

#### 1. Geographic Enrichment
- **Ad Network 1**: Joins with geo dictionary to get full location names
- **Ad Network 2**: Regex extraction of country code from campaign name pattern
- Consistent `country_code`, `country_name`, `state_name` fields across networks

#### 2. Smart Deduplication
```sql
-- Prioritizes state-level over country-level data
row_number() over (
    partition by date, campaign_id, country_id
    order by
        case when report_granularity = 'state' then 1 else 2 end,
        state_id
)
```

#### 3. Calculated Metrics
- CPM (Cost Per Mille)
- CPC (Cost Per Click)
- CTR (Click-Through Rate)
- Safe division handling (no divide-by-zero errors)

#### 4. Data Quality Tests
- ✓ No negative metrics
- ✓ Clicks never exceed impressions
- ✓ All geo data properly populated
- ✓ Country codes successfully extracted
- ✓ No duplicate records at grain level

## Data Model Architecture

```
┌───────────────────────────────────────────────────────┐
│                   STAGING LAYER                       │
│  • Type casting & standardization                     │
│  • Column renaming                                    │
└─────────────────┬─────────────────────────────────────┘
                  ▼
┌───────────────────────────────────────────────────────┐
│                INTERMEDIATE LAYER                     │
│  • Union & deduplicate Ad Network 1 reports          │
│  • Enrich with geo dictionary                        │
│  • Extract country code from Ad Network 2 names      │
└─────────────────┬─────────────────────────────────────┘
                  ▼
┌───────────────────────────────────────────────────────┐
│                   MARTS LAYER                         │
│         mart_marketing_performance                    │
│  • Unified schema across both networks               │
│  • Calculated marketing metrics                      │
│  • Analytics-ready                                   │
└───────────────────────────────────────────────────────┘
```

## Final Table Schema

| Column           | Type          | Description                              |
|------------------|---------------|------------------------------------------|
| date             | DATE          | Report date                              |
| ad_network       | VARCHAR       | 'ad_network_1' or 'ad_network_2'         |
| campaign_id      | BIGINT        | Campaign identifier                      |
| campaign_name    | VARCHAR       | Campaign name                            |
| country_code     | VARCHAR(2)    | ISO Alpha-2 country code                 |
| country_name     | VARCHAR       | Full country name (Network 1 only)       |
| state_name       | VARCHAR       | State/region name (when available)       |
| state_type       | VARCHAR       | Location type (State, Province, etc.)    |
| geo_granularity  | VARCHAR       | 'country' or 'state'                     |
| spend            | DECIMAL(18,2) | Ad spend in USD                          |
| impressions      | BIGINT        | Number of impressions                    |
| clicks           | BIGINT        | Number of clicks                         |
| cpm              | DECIMAL       | Cost per thousand impressions            |
| cpc              | DECIMAL       | Cost per click                           |
| ctr              | DECIMAL       | Click-through rate (%)                   |

**Grain**: date × ad_network × campaign_id × country_code × state_name

## How to Run

### Option 1: Automated Setup (Recommended)
```bash
cd marketing_analytics_dbt
./setup_and_run.sh
```

### Option 2: Manual Steps
```bash
# 1. Install DBT with DuckDB adapter
pip install dbt-duckdb

# 2. Navigate to project
cd marketing_analytics_dbt

# 3. Copy CSV files to seeds directory
cp ../ae_ad_network_*.csv seeds/

# 4. Run DBT commands
dbt seed --profiles-dir .       # Load CSV files
dbt run --profiles-dir .         # Build models
dbt test --profiles-dir .        # Run data quality tests
```

## Usage Examples

### Query the Final Datamart
```sql
-- Connect to DuckDB
duckdb marketing_analytics.duckdb

-- View sample data
SELECT * FROM marts.mart_marketing_performance LIMIT 10;

-- Performance by ad network
SELECT
    ad_network,
    SUM(spend) as total_spend,
    SUM(clicks) as total_clicks,
    AVG(ctr) as avg_ctr
FROM marts.mart_marketing_performance
GROUP BY ad_network;
```

See [sample_queries.sql](marketing_analytics_dbt/sample_queries.sql) for more examples.

## Design Decisions & Trade-offs

### 1. Deduplication Approach
**Decision**: Keep most detailed geo level when duplicates exist
**Rationale**: Requirements emphasize geographic detail; state-level data is more valuable than country-level
**Implementation**: Union + window function with ordering

### 2. Ad Network 2 Country Extraction
**Decision**: Regex extraction from campaign name
**Rationale**: No geo dimension in source; naming convention is consistent
**Pattern**: `ad_network_2_iOS_{COUNTRY_CODE}_...`
**Limitation**: No full country names available (would need external mapping)

### 3. Materialization Strategy
**Staging/Intermediate**: Views (lightweight, no storage)
**Marts**: Table (optimized for querying)
**Rationale**: Final table is query target; upstream layers are transformation steps

### 4. Null Handling
**Decision**: Preserve nulls where data doesn't exist
**Rationale**: Better to show data limitations than fabricate values
**Example**: Ad Network 2 has no `country_name`, left as NULL

## Testing Strategy

### Built-in DBT Tests (schema.yml)
- `not_null`: Critical fields must have values
- `unique`: Location IDs are unique
- `accepted_values`: Enums are constrained

### Custom Tests (tests/*.sql)
- Business rule validation (clicks ≤ impressions)
- Data completeness checks
- Deduplication verification
- Third-party data quality checks

**All tests return 0 rows on success** (failures return problematic records)

## Documentation Files

1. **[README.md](marketing_analytics_dbt/README.md)** - Quick start guide
2. **[DATA_MODEL_DOCUMENTATION.md](marketing_analytics_dbt/DATA_MODEL_DOCUMENTATION.md)** - Detailed technical docs
3. **[sample_queries.sql](marketing_analytics_dbt/sample_queries.sql)** - 8 example analyses
4. **This file** - Solution summary

## Next Steps for Production

1. **Incremental Loading**: Convert to incremental models for large datasets
2. **Ad Network 2 Enrichment**: Add country name mapping table
3. **Campaign Parsing**: Extract more attributes from campaign names
4. **Currency Normalization**: Handle multi-currency if needed
5. **Monitoring**: Add data freshness checks
6. **Documentation**: Generate DBT docs site (`dbt docs generate`)

---
