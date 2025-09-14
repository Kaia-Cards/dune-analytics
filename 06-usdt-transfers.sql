-- USDT Transfer Analysis
SELECT
    DATE_TRUNC('day', block_time) as date,
    COUNT(*) as usdt_transfers,
    SUM(CAST(data AS DOUBLE) / 1e6) as total_usdt_volume,
    AVG(CAST(data AS DOUBLE) / 1e6) as avg_transfer_amount,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(data AS DOUBLE) / 1e6) as median_transfer_amount,
    COUNT(DISTINCT SUBSTRING(topic1, 3, 40)) as unique_senders,
    COUNT(DISTINCT SUBSTRING(topic2, 3, 40)) as unique_receivers,
    MAX(CAST(data AS DOUBLE) / 1e6) as largest_transfer,
    MIN(CAST(data AS DOUBLE) / 1e6) as smallest_transfer
FROM kaia.logs
WHERE
    contract_address = 0x1577dE52bF5D6a7f455FC19d87c728d4bE3e1377
    AND topic0 = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
    AND CAST(data AS DOUBLE) > 0
    AND block_time >= NOW() - INTERVAL '30' DAY
GROUP BY DATE_TRUNC('day', block_time)
ORDER BY date DESC;