-- Test that clicks never exceed impressions
-- This would indicate data quality issues from third-party sources

select
    date,
    ad_network,
    campaign_id,
    impressions,
    clicks
from {{ ref('mart_marketing_performance') }}
where clicks > impressions
