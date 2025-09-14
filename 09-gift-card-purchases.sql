-- Gift Card Purchase Analysis
WITH purchase_amounts AS (
    SELECT
        DATE_TRUNC('day', block_time) as date,
        "from" as buyer,
        CAST(value AS DOUBLE) / 1e6 as purchase_amount_usdt,
        CASE
            WHEN CAST(value AS DOUBLE) / 1e6 >= 500 THEN 'Premium Cards (500+ USDT)'
            WHEN CAST(value AS DOUBLE) / 1e6 >= 100 THEN 'High Value (100-500 USDT)'
            WHEN CAST(value AS DOUBLE) / 1e6 >= 25 THEN 'Standard (25-100 USDT)'
            WHEN CAST(value AS DOUBLE) / 1e6 >= 5 THEN 'Basic (5-25 USDT)'
            ELSE 'Micro (<5 USDT)'
        END as card_tier,
        EXTRACT(hour FROM block_time) as purchase_hour
    FROM kaia.transactions
    WHERE "to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    AND block_time >= NOW() - INTERVAL '30' DAY
)
SELECT
    card_tier,
    COUNT(*) as total_purchases,
    COUNT(DISTINCT buyer) as unique_buyers,
    SUM(purchase_amount_usdt) as total_revenue,
    AVG(purchase_amount_usdt) as avg_card_value,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM purchase_amounts) as purchase_share_percent,
    SUM(purchase_amount_usdt) * 100.0 / (SELECT SUM(purchase_amount_usdt) FROM purchase_amounts) as revenue_share_percent,
    AVG(purchase_hour) as avg_purchase_hour
FROM purchase_amounts
GROUP BY card_tier
ORDER BY
    CASE card_tier
        WHEN 'Premium Cards (500+ USDT)' THEN 1
        WHEN 'High Value (100-500 USDT)' THEN 2
        WHEN 'Standard (25-100 USDT)' THEN 3
        WHEN 'Basic (5-25 USDT)' THEN 4
        WHEN 'Micro (<5 USDT)' THEN 5
    END;