-- Test that spend, impressions, and clicks are never negative
-- This test will fail if any records have negative values

select
    date,
    ad_network,
    campaign_id,
    spend,
    impressions,
    clicks
from {{ ref('mart_marketing_performance') }}
where spend < 0
   or impressions < 0
   or clicks < 0
