-- Test that there are no duplicate records at the grain level
-- Grain: date, ad_network, campaign_id, country_code, state_name (when available)
-- This ensures our deduplication logic is working correctly

with record_counts as (
    select
        date,
        ad_network,
        campaign_id,
        country_code,
        coalesce(state_name, 'NO_STATE') as state_name,
        count(*) as record_count
    from {{ ref('mart_marketing_performance') }}
    group by 1, 2, 3, 4, 5
)

select *
from record_counts
where record_count > 1
