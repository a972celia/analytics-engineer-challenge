-- Sample Analysis Queries for Marketing Performance Datamart
-- Run these queries after building the DBT project

-- ============================================================================
-- 1. OVERALL PERFORMANCE BY AD NETWORK
-- ============================================================================
-- Compare the two ad networks across key metrics

SELECT
    ad_network,
    COUNT(DISTINCT campaign_id) as num_campaigns,
    COUNT(DISTINCT country_code) as num_countries,
    SUM(spend) as total_spend,
    SUM(impressions) as total_impressions,
    SUM(clicks) as total_clicks,
    ROUND(SUM(spend) / NULLIF(SUM(clicks), 0), 2) as blended_cpc,
    ROUND((SUM(clicks)::DECIMAL / NULLIF(SUM(impressions), 0)) * 100, 2) as blended_ctr
FROM marts.mart_marketing_performance
GROUP BY ad_network
ORDER BY total_spend DESC;


-- ============================================================================
-- 2. TOP PERFORMING COUNTRIES
-- ============================================================================
-- Identify which countries drive the most value

SELECT
    country_code,
    MAX(country_name) as country_name,  -- May be NULL for Ad Network 2
    COUNT(DISTINCT campaign_id) as num_campaigns,
    SUM(spend) as total_spend,
    SUM(impressions) as total_impressions,
    SUM(clicks) as total_clicks,
    ROUND(SUM(spend) / NULLIF(SUM(clicks), 0), 2) as cpc,
    ROUND((SUM(clicks)::DECIMAL / NULLIF(SUM(impressions), 0)) * 100, 2) as ctr
FROM marts.mart_marketing_performance
GROUP BY country_code
ORDER BY total_spend DESC
LIMIT 10;


-- ============================================================================
-- 3. STATE-LEVEL DETAIL ANALYSIS
-- ============================================================================
-- Deep dive into state-level performance (only available for Ad Network 1)

SELECT
    country_code,
    state_name,
    state_type,
    COUNT(DISTINCT campaign_id) as num_campaigns,
    SUM(spend) as total_spend,
    SUM(clicks) as total_clicks,
    ROUND((SUM(clicks)::DECIMAL / NULLIF(SUM(impressions), 0)) * 100, 2) as ctr
FROM marts.mart_marketing_performance
WHERE geo_granularity = 'state'
  AND state_name IS NOT NULL
GROUP BY country_code, state_name, state_type
ORDER BY total_spend DESC
LIMIT 20;


-- ============================================================================
-- 4. GEOGRAPHIC GRANULARITY COVERAGE
-- ============================================================================
-- Understand what percentage of data has state-level detail

SELECT
    ad_network,
    geo_granularity,
    COUNT(*) as num_records,
    SUM(spend) as total_spend,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY ad_network), 2) as pct_records,
    ROUND(100.0 * SUM(spend) / SUM(SUM(spend)) OVER (PARTITION BY ad_network), 2) as pct_spend
FROM marts.mart_marketing_performance
GROUP BY ad_network, geo_granularity
ORDER BY ad_network, geo_granularity;


-- ============================================================================
-- 5. CAMPAIGN PERFORMANCE COMPARISON
-- ============================================================================
-- Top and bottom performing campaigns

WITH campaign_metrics as (
    SELECT
        campaign_id,
        campaign_name,
        ad_network,
        SUM(spend) as total_spend,
        SUM(clicks) as total_clicks,
        ROUND((SUM(clicks)::DECIMAL / NULLIF(SUM(impressions), 0)) * 100, 2) as ctr
    FROM marts.mart_marketing_performance
    GROUP BY campaign_id, campaign_name, ad_network
    HAVING SUM(spend) > 100  -- Focus on campaigns with meaningful spend
)

SELECT * FROM (
    -- Top 5 by spend
    SELECT 'Top by Spend' as category, *
    FROM campaign_metrics
    ORDER BY total_spend DESC
    LIMIT 5
)
UNION ALL
SELECT * FROM (
    -- Top 5 by CTR
    SELECT 'Top by CTR' as category, *
    FROM campaign_metrics
    WHERE total_clicks > 50  -- Ensure statistical significance
    ORDER BY ctr DESC
    LIMIT 5
);


-- ============================================================================
-- 6. TIME SERIES ANALYSIS
-- ============================================================================
-- Daily spend and performance trends

SELECT
    date,
    ad_network,
    SUM(spend) as daily_spend,
    SUM(impressions) as daily_impressions,
    SUM(clicks) as daily_clicks,
    ROUND((SUM(clicks)::DECIMAL / NULLIF(SUM(impressions), 0)) * 100, 2) as daily_ctr
FROM marts.mart_marketing_performance
GROUP BY date, ad_network
ORDER BY date DESC, ad_network
LIMIT 30;


-- ============================================================================
-- 7. DATA QUALITY CHECK
-- ============================================================================
-- Verify data completeness and identify potential issues

SELECT
    'Total Records' as metric,
    COUNT(*) as value
FROM marts.mart_marketing_performance

UNION ALL

SELECT
    'Records with State Detail',
    COUNT(*)
FROM marts.mart_marketing_performance
WHERE state_name IS NOT NULL

UNION ALL

SELECT
    'Records with Missing Country Name',
    COUNT(*)
FROM marts.mart_marketing_performance
WHERE country_name IS NULL

UNION ALL

SELECT
    'Records with Zero Spend',
    COUNT(*)
FROM marts.mart_marketing_performance
WHERE spend = 0

UNION ALL

SELECT
    'Records with Zero Impressions',
    COUNT(*)
FROM marts.mart_marketing_performance
WHERE impressions = 0;


-- ============================================================================
-- 8. CROSS-NETWORK GEO COMPARISON
-- ============================================================================
-- Compare how each ad network performs in the same countries

SELECT
    country_code,
    MAX(CASE WHEN ad_network = 'ad_network_1' THEN total_spend END) as network_1_spend,
    MAX(CASE WHEN ad_network = 'ad_network_2' THEN total_spend END) as network_2_spend,
    MAX(CASE WHEN ad_network = 'ad_network_1' THEN ctr END) as network_1_ctr,
    MAX(CASE WHEN ad_network = 'ad_network_2' THEN ctr END) as network_2_ctr
FROM (
    SELECT
        country_code,
        ad_network,
        SUM(spend) as total_spend,
        ROUND((SUM(clicks)::DECIMAL / NULLIF(SUM(impressions), 0)) * 100, 2) as ctr
    FROM marts.mart_marketing_performance
    GROUP BY country_code, ad_network
) sub
GROUP BY country_code
HAVING MAX(CASE WHEN ad_network = 'ad_network_1' THEN total_spend END) IS NOT NULL
   AND MAX(CASE WHEN ad_network = 'ad_network_2' THEN total_spend END) IS NOT NULL
ORDER BY
    COALESCE(MAX(CASE WHEN ad_network = 'ad_network_1' THEN total_spend END), 0) +
    COALESCE(MAX(CASE WHEN ad_network = 'ad_network_2' THEN total_spend END), 0) DESC;
