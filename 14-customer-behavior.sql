WITH customer_segments AS (
    SELECT
        "from" as customer_address,
        COUNT(*) as total_purchases,
        SUM(CAST(value AS DOUBLE) / 1e6) as lifetime_value,
        AVG(CAST(value AS DOUBLE) / 1e6) as avg_purchase_amount,
        MAX(block_time) as last_purchase_date,
        MIN(block_time) as first_purchase_date,
        EXTRACT(days FROM (MAX(block_time) - MIN(block_time))) as customer_lifespan_days,
        STDDEV(CAST(value AS DOUBLE) / 1e6) as purchase_amount_variance
    FROM kaia.transactions
    WHERE "to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    AND block_time >= NOW() - INTERVAL '90' DAY
    GROUP BY "from"
),
purchase_frequency AS (
    SELECT
        customer_address,
        total_purchases,
        lifetime_value,
        avg_purchase_amount,
        customer_lifespan_days,
        CASE
            WHEN customer_lifespan_days > 0 THEN total_purchases / (customer_lifespan_days / 7.0)
            ELSE total_purchases
        END as purchases_per_week,
        CASE
            WHEN total_purchases >= 10 AND lifetime_value >= 500 THEN 'VIP Customer'
            WHEN total_purchases >= 5 AND lifetime_value >= 200 THEN 'Loyal Customer'
            WHEN total_purchases >= 3 AND lifetime_value >= 100 THEN 'Regular Customer'
            WHEN total_purchases = 2 THEN 'Repeat Customer'
            ELSE 'New Customer'
        END as customer_segment,
        EXTRACT(days FROM (NOW() - last_purchase_date)) as days_since_last_purchase
    FROM customer_segments
)
SELECT
    customer_segment,
    COUNT(*) as customer_count,
    AVG(lifetime_value) as avg_lifetime_value,
    AVG(total_purchases) as avg_total_purchases,
    AVG(avg_purchase_amount) as avg_purchase_size,
    AVG(purchases_per_week) as avg_weekly_frequency,
    AVG(days_since_last_purchase) as avg_days_since_last_purchase,
    SUM(lifetime_value) as total_segment_revenue,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM purchase_frequency) as segment_distribution_percent
FROM purchase_frequency
GROUP BY customer_segment
ORDER BY avg_lifetime_value DESC;