-- Daily Transaction Volume
SELECT
    DATE_TRUNC('day', block_time) as date,
    COUNT(*) as transactions,
    COUNT(DISTINCT "from") as unique_users,
    SUM(CAST(value AS DOUBLE) / 1e6) as total_volume_usdt,
    AVG(CAST(value AS DOUBLE) / 1e6) as avg_transaction_size
FROM kaia.transactions
WHERE
    "to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    AND block_time >= NOW() - INTERVAL '30' DAY
GROUP BY DATE_TRUNC('day', block_time)
ORDER BY date DESC;