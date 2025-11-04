{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ ref('ae_ad_network_2_report') }}
),

renamed as (
    select
        id::bigint as campaign_id,
        campaign_name,
        date::date as date,
        spend::decimal(18,2) as spend,
        impressions::bigint as impressions,
        clicks::bigint as clicks

    from source
)

select * from renamed
