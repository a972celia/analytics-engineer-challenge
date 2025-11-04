-- Test that all Ad Network 2 records have country_code extracted from campaign name
-- This ensures our regex extraction is working correctly

select
    date,
    ad_network,
    campaign_id,
    campaign_name,
    country_code
from {{ ref('mart_marketing_performance') }}
where ad_network = 'ad_network_2'
  and country_code is null
