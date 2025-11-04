{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ ref('ae_ad_network_1_detailed_report') }}
),

renamed as (
    select
        date::date as date,
        campaign_id::bigint as campaign_id,
        country_id::bigint as country_id,
        state_id::bigint as state_id,
        spend::decimal(18,2) as spend,
        impressions::bigint as impressions,
        clicks::bigint as clicks,
        'state' as report_granularity

    from source
)

select * from renamed
