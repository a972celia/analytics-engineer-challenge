{{
    config(
        materialized='view'
    )
}}

with detailed_report as (
    select * from {{ ref('stg_ad_network_1__detailed_report') }}
),

country_report as (
    select * from {{ ref('stg_ad_network_1__country_report') }}
),

geo_dict as (
    select * from {{ ref('stg_ad_network_1__geo_dictionary') }}
),

campaigns as (
    select * from {{ ref('stg_ad_network_1__campaign_updates') }}
),

-- Union detailed and country reports
-- Prioritize detailed (state-level) data when available
all_reports as (
    select
        date,
        campaign_id,
        country_id,
        state_id,
        spend,
        impressions,
        clicks,
        report_granularity
    from detailed_report

    union all

    select
        date,
        campaign_id,
        country_id,
        state_id,
        spend,
        impressions,
        clicks,
        report_granularity
    from country_report
),

-- Deduplicate: prefer state-level data over country-level for the same date/campaign/country
deduplicated as (
    select
        date,
        campaign_id,
        country_id,
        state_id,
        spend,
        impressions,
        clicks,
        report_granularity,
        row_number() over (
            partition by date, campaign_id, country_id
            order by
                case when report_granularity = 'state' then 1 else 2 end,
                state_id
        ) as row_num
    from all_reports
),

-- Join with geo dictionary and campaign metadata
enriched as (
    select
        d.date,
        d.campaign_id,
        c.campaign_name,

        -- Country information
        d.country_id,
        geo_country.country_code,
        geo_country.location_name as country_name,

        -- State information (when available)
        d.state_id,
        geo_state.location_name as state_name,
        geo_state.location_type as state_type,

        -- Determine the most detailed geo level
        case
            when d.state_id is not null then 'state'
            else 'country'
        end as geo_granularity,

        -- Metrics
        d.spend,
        d.impressions,
        d.clicks,

        -- Metadata
        'ad_network_1' as ad_network

    from deduplicated d
    left join campaigns c
        on d.campaign_id = c.campaign_id
    left join geo_dict geo_country
        on d.country_id = geo_country.location_id
    left join geo_dict geo_state
        on d.state_id = geo_state.location_id
    where d.row_num = 1
)

select * from enriched
