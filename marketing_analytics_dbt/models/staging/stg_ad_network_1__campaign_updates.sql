{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ ref('ae_ad_network_1_campaign_updates') }}
),

renamed as (
    select
        campaign_id::bigint as campaign_id,
        update_date::date as update_date,
        name as campaign_name

    from source
)

select * from renamed
