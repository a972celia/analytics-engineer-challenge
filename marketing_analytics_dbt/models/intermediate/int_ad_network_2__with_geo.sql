{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ ref('stg_ad_network_2__report') }}
),

-- Extract country code from campaign name
-- Pattern: ad_network_2_iOS_{COUNTRY_CODE}_...
-- Examples: ad_network_2_iOS_CA_All_Exact_CPT, ad_network_2_iOS_US_All_Match
with_geo as (
    select
        date,
        campaign_id,
        campaign_name,

        -- Extract country code (2-letter code after "iOS_")
        regexp_extract(campaign_name, '_([A-Z]{2})_', 1) as country_code,

        -- No state-level information available
        null as state_name,
        null as state_type,

        'country' as geo_granularity,

        -- Metrics
        spend,
        impressions,
        clicks,

        -- Metadata
        'ad_network_2' as ad_network

    from source
)

select * from with_geo
