-- Top Users by Volume
SELECT
    "from" as user_address,
    COUNT(*) as transaction_count,
    SUM(CAST(value AS DOUBLE) / 1e6) as total_spent_usdt,
    AVG(CAST(value AS DOUBLE) / 1e6) as avg_transaction_size,
    MAX(block_time) as last_transaction,
    MIN(block_time) as first_transaction,
    EXTRACT(days FROM (MAX(block_time) - MIN(block_time))) as customer_lifespan_days
FROM kaia.transactions
WHERE
    "to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    AND block_time >= NOW() - INTERVAL '30' DAY
GROUP BY "from"
HAVING COUNT(*) > 1
ORDER BY total_spent_usdt DESC
LIMIT 100;