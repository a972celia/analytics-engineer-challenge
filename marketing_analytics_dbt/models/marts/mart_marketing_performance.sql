{{
    config(
        materialized='table'
    )
}}

with ad_network_1 as (
    select
        date,
        ad_network,
        campaign_id,
        campaign_name,
        country_code,
        country_name,
        state_name,
        state_type,
        geo_granularity,
        spend,
        impressions,
        clicks
    from {{ ref('int_ad_network_1__unified') }}
),

ad_network_2 as (
    select
        date,
        ad_network,
        campaign_id,
        campaign_name,
        country_code,
        null as country_name,  -- Ad Network 2 doesn't provide full country name
        state_name,
        state_type,
        geo_granularity,
        spend,
        impressions,
        clicks
    from {{ ref('int_ad_network_2__with_geo') }}
),

unified as (
    select * from ad_network_1
    union all
    select * from ad_network_2
),

final as (
    select
        -- Primary dimensions
        date,
        ad_network,
        campaign_id,
        campaign_name,

        -- Geographic dimensions (most important per requirements)
        country_code,
        country_name,
        state_name,
        state_type,
        geo_granularity,

        -- Metrics
        spend,
        impressions,
        clicks,

        -- Calculated metrics
        case
            when impressions > 0 then spend / impressions
            else 0
        end as cpm,  -- Cost per thousand impressions

        case
            when clicks > 0 then spend / clicks
            else 0
        end as cpc,  -- Cost per click

        case
            when impressions > 0 then (clicks::decimal / impressions) * 100
            else 0
        end as ctr  -- Click-through rate (%)

    from unified
)

select * from final
