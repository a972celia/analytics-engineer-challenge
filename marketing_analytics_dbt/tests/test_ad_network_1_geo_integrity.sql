-- Test that all Ad Network 1 records have valid country_code and country_name
-- Since Ad Network 1 has geo dictionary, all records should have this information

select
    date,
    ad_network,
    campaign_id,
    country_code,
    country_name
from {{ ref('mart_marketing_performance') }}
where ad_network = 'ad_network_1'
  and (country_code is null or country_name is null)
