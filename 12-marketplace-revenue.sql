WITH revenue_metrics AS (
    SELECT
        DATE_TRUNC('week', block_time) as week,
        COUNT(*) as total_orders,
        SUM(CAST(value AS DOUBLE) / 1e6) as gross_revenue,
        COUNT(DISTINCT "from") as unique_customers,
        AVG(CAST(value AS DOUBLE) / 1e6) as avg_order_value,
        SUM(CAST(value AS DOUBLE) / 1e6) * 0.05 as estimated_commission,
        LAG(SUM(CAST(value AS DOUBLE) / 1e6)) OVER (ORDER BY DATE_TRUNC('week', block_time)) as prev_week_revenue
    FROM kaia.transactions
    WHERE "to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    AND block_time >= NOW() - INTERVAL '12' WEEK
    GROUP BY DATE_TRUNC('week', block_time)
)
SELECT
    week,
    total_orders,
    gross_revenue,
    unique_customers,
    avg_order_value,
    estimated_commission,
    gross_revenue / unique_customers as revenue_per_customer,
    total_orders / unique_customers as orders_per_customer,
    CASE
        WHEN prev_week_revenue > 0 THEN ((gross_revenue - prev_week_revenue) / prev_week_revenue) * 100
        ELSE 0
    END as week_over_week_growth_percent
FROM revenue_metrics
ORDER BY week DESC;