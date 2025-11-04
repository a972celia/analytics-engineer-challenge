{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ ref('ae_ad_network_1_geo_dictionary') }}
),

renamed as (
    select
        id::bigint as location_id,
        country_code,
        name as location_name,
        location_type

    from source
)

select * from renamed
