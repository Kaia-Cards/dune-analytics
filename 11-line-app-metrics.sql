-- LINE App Usage Metrics
WITH daily_activity AS (
    SELECT
        DATE_TRUNC('day', block_time) as date,
        "from" as user_address,
        COUNT(*) as transactions_per_user,
        SUM(CAST(value AS DOUBLE) / 1e6) as daily_spend_per_user
    FROM kaia.transactions
    WHERE "to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    AND block_time >= NOW() - INTERVAL '30' DAY
    GROUP BY DATE_TRUNC('day', block_time), "from"
),
user_engagement AS (
    SELECT
        user_address,
        COUNT(DISTINCT date) as active_days,
        SUM(transactions_per_user) as total_transactions,
        SUM(daily_spend_per_user) as total_spend,
        MAX(daily_spend_per_user) as max_daily_spend,
        AVG(daily_spend_per_user) as avg_daily_spend
    FROM daily_activity
    GROUP BY user_address
)
SELECT
    CASE
        WHEN active_days >= 20 THEN 'Daily Active (20+ days)'
        WHEN active_days >= 10 THEN 'Regular (10-19 days)'
        WHEN active_days >= 5 THEN 'Occasional (5-9 days)'
        WHEN active_days >= 2 THEN 'Returning (2-4 days)'
        ELSE 'One-time (1 day)'
    END as user_engagement_level,
    COUNT(*) as user_count,
    AVG(total_transactions) as avg_transactions_per_user,
    AVG(total_spend) as avg_spend_per_user,
    SUM(total_spend) as total_category_revenue,
    AVG(active_days) as avg_active_days,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM user_engagement) as user_distribution_percent
FROM user_engagement
GROUP BY user_engagement_level
ORDER BY
    CASE user_engagement_level
        WHEN 'Daily Active (20+ days)' THEN 1
        WHEN 'Regular (10-19 days)' THEN 2
        WHEN 'Occasional (5-9 days)' THEN 3
        WHEN 'Returning (2-4 days)' THEN 4
        WHEN 'One-time (1 day)' THEN 5
    END;