-- User Retention Analysis
WITH first_purchases AS (
    SELECT
        "from" as user_address,
        MIN(block_time) as first_purchase_date,
        MIN(CAST(value AS DOUBLE) / 1e6) as first_purchase_amount
    FROM kaia.transactions
    WHERE "to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    GROUP BY "from"
),
user_cohorts AS (
    SELECT
        DATE_TRUNC('week', first_purchase_date) as cohort_week,
        COUNT(*) as new_users,
        AVG(first_purchase_amount) as avg_first_purchase
    FROM first_purchases
    WHERE first_purchase_date >= NOW() - INTERVAL '12' WEEK
    GROUP BY DATE_TRUNC('week', first_purchase_date)
),
returning_users AS (
    SELECT
        fp.user_address,
        DATE_TRUNC('week', fp.first_purchase_date) as cohort_week,
        COUNT(t.*) as total_purchases
    FROM first_purchases fp
    LEFT JOIN kaia.transactions t ON fp.user_address = t."from"
        AND t."to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
        AND t.block_time > fp.first_purchase_date
    WHERE fp.first_purchase_date >= NOW() - INTERVAL '12' WEEK
    GROUP BY fp.user_address, DATE_TRUNC('week', fp.first_purchase_date)
)
SELECT
    uc.cohort_week,
    uc.new_users,
    uc.avg_first_purchase,
    COUNT(CASE WHEN ru.total_purchases > 0 THEN 1 END) as returning_users,
    COUNT(CASE WHEN ru.total_purchases > 0 THEN 1 END) * 100.0 / uc.new_users as retention_rate_percent
FROM user_cohorts uc
LEFT JOIN returning_users ru ON uc.cohort_week = ru.cohort_week
GROUP BY uc.cohort_week, uc.new_users, uc.avg_first_purchase
ORDER BY cohort_week DESC;