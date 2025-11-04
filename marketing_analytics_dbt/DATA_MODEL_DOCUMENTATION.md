# Marketing Analytics Data Model Documentation

## Overview

This DBT project creates a unified marketing performance datamart that combines data from two ad networks (Ad Network 1 and Ad Network 2) with emphasis on providing the most detailed geographic information available.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         DATA SOURCES                         │
├──────────────────────┬──────────────────────────────────────┤
│   Ad Network 1       │        Ad Network 2                  │
│   - Campaigns        │        - Report with                 │
│   - Geo Dictionary   │          embedded country code       │
│   - Country Report   │                                      │
│   - Detailed Report  │                                      │
└──────────┬───────────┴────────────────┬─────────────────────┘
           │                            │
           ▼                            ▼
┌──────────────────────┐    ┌──────────────────────┐
│  STAGING LAYER       │    │  STAGING LAYER       │
│  - Type casting      │    │  - Type casting      │
│  - Column renaming   │    │  - Column renaming   │
└──────────┬───────────┘    └──────────┬───────────┘
           │                            │
           ▼                            ▼
┌──────────────────────┐    ┌──────────────────────┐
│  INTERMEDIATE        │    │  INTERMEDIATE        │
│  - Unify reports     │    │  - Extract country   │
│  - Enrich with geo   │    │    code from name    │
│  - Deduplicate       │    │                      │
└──────────┬───────────┘    └──────────┬───────────┘
           │                            │
           └────────────┬───────────────┘
                        ▼
              ┌────────────────────┐
              │   MARTS LAYER      │
              │   Unified Datamart │
              └────────────────────┘
```

## Layer Descriptions

### Staging Layer

**Purpose**: Raw data cleaning, type casting, and standardization

**Models**:
- `stg_ad_network_1__campaign_updates` - Campaign metadata
- `stg_ad_network_1__geo_dictionary` - Location lookup table
- `stg_ad_network_1__country_report` - Country-level metrics
- `stg_ad_network_1__detailed_report` - State-level metrics
- `stg_ad_network_2__report` - All Ad Network 2 metrics

**Key Transformations**:
- Cast columns to appropriate data types
- Standardize column naming conventions
- Add `report_granularity` field to track data detail level

### Intermediate Layer

**Purpose**: Business logic and data enrichment

**Models**:

1. **`int_ad_network_1__unified`**
   - Unions country and detailed reports
   - Deduplicates records (prefers state-level over country-level)
   - Joins with geo dictionary to get location names
   - Joins with campaign metadata

2. **`int_ad_network_2__with_geo`**
   - Extracts country code from campaign name using regex
   - Pattern: `ad_network_2_iOS_{COUNTRY_CODE}_...`
   - No state-level data available

**Key Logic**:
- **Deduplication**: When both country and state-level data exist for the same date/campaign/country, we keep the state-level record (more detailed)
- **Geo Extraction**: Uses `regexp_extract()` to parse country codes from Ad Network 2 campaign names

### Marts Layer

**Purpose**: Analytics-ready final table

**Model**: `mart_marketing_performance`

**Schema**:
```sql
date              DATE           -- Report date
ad_network        VARCHAR        -- 'ad_network_1' or 'ad_network_2'
campaign_id       BIGINT         -- Campaign identifier
campaign_name     VARCHAR        -- Campaign name
country_code      VARCHAR(2)     -- ISO Alpha-2 country code
country_name      VARCHAR        -- Full country name (Ad Network 1 only)
state_name        VARCHAR        -- State/region name (when available)
state_type        VARCHAR        -- Location type (State, Province, etc.)
geo_granularity   VARCHAR        -- 'country' or 'state'
spend             DECIMAL(18,2)  -- Ad spend in USD
impressions       BIGINT         -- Number of impressions
clicks            BIGINT         -- Number of clicks
cpm               DECIMAL        -- Cost per thousand impressions
cpc               DECIMAL        -- Cost per click
ctr               DECIMAL        -- Click-through rate (%)
```

## Key Design Decisions

### 1. Geographic Detail Priority

Per requirements, **geography is the most important dimension**. Our approach:

- **Ad Network 1**:
  - Prefer state-level data when available
  - Fall back to country-level data
  - Full location names from geo dictionary

- **Ad Network 2**:
  - Only country-level data available
  - Extracted from campaign naming convention
  - No full country names (would require external mapping)

### 2. Deduplication Strategy

The source note mentions: *"third-party tool only includes data where all dimensions are available"*

For Ad Network 1, we have both country and detailed (state) reports. Our logic:
1. Union both reports
2. For each `(date, campaign_id, country_id)` combination, keep the most detailed record
3. Prefer state-level over country-level (using `row_number()` with ordering)

This ensures we don't double-count metrics while preserving maximum detail.

### 3. Data Quality Considerations

The task mentions: *"it is good to double check data from third party"*

We've implemented tests for:
- No negative metrics (spend, impressions, clicks)
- Clicks never exceed impressions
- All Ad Network 1 records have valid geo data
- All Ad Network 2 records have extracted country codes
- No duplicate records at grain level

### 4. Calculated Metrics

Added standard marketing metrics:
- **CPM** (Cost Per Mille): `spend / impressions * 1000`
- **CPC** (Cost Per Click): `spend / clicks`
- **CTR** (Click-Through Rate): `clicks / impressions * 100`

These metrics have safe division handling (return 0 when denominator is 0).

## Grain

The table grain is: **date × ad_network × campaign_id × country_code × state_name (when available)**

- For state-level records: unique by date, campaign, and state
- For country-level records: unique by date, campaign, and country

## Usage Examples

### Compare performance by ad network
```sql
SELECT
    ad_network,
    SUM(spend) as total_spend,
    SUM(impressions) as total_impressions,
    SUM(clicks) as total_clicks,
    AVG(ctr) as avg_ctr
FROM marts.mart_marketing_performance
GROUP BY ad_network;
```

### Top performing countries
```sql
SELECT
    country_code,
    country_name,
    SUM(spend) as total_spend,
    SUM(clicks) as total_clicks,
    SUM(spend) / SUM(clicks) as blended_cpc
FROM marts.mart_marketing_performance
WHERE clicks > 0
GROUP BY country_code, country_name
ORDER BY total_spend DESC
LIMIT 10;
```

### State-level detail analysis
```sql
SELECT
    country_code,
    state_name,
    geo_granularity,
    SUM(spend) as total_spend,
    AVG(ctr) as avg_ctr
FROM marts.mart_marketing_performance
WHERE state_name IS NOT NULL
GROUP BY country_code, state_name, geo_granularity
ORDER BY total_spend DESC;
```

## Future Enhancements

1. **Ad Network 2 Country Names**: Create a mapping table to enrich country codes with full names
2. **Campaign Attributes**: Parse more attributes from Ad Network 2 campaign names (platform, targeting type, etc.)
3. **Time-based Aggregations**: Pre-aggregate by week/month for faster dashboards
4. **Incremental Loading**: Convert staging models to incremental for large data volumes
5. **External Enrichment**: Join with exchange rate data for multi-currency normalization
