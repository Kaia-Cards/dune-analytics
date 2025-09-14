-- Network Performance Metrics
WITH block_stats AS (
    SELECT
        block_number,
        block_time,
        COUNT(*) as txns_in_block,
        AVG(gas_price / 1e9) as avg_gas_price_gwei,
        SUM(gas_used) as total_gas_used,
        LAG(block_time) OVER (ORDER BY block_number) as prev_block_time
    FROM kaia.transactions
    WHERE "to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    AND block_time >= NOW() - INTERVAL '7' DAY
    GROUP BY block_number, block_time
)
SELECT
    DATE_TRUNC('hour', block_time) as hour,
    COUNT(*) as blocks_with_kshop_txns,
    AVG(txns_in_block) as avg_txns_per_block,
    AVG(avg_gas_price_gwei) as avg_gas_price,
    AVG(total_gas_used) as avg_gas_per_block,
    AVG(EXTRACT(seconds FROM (block_time - prev_block_time))) as avg_block_time_seconds,
    SUM(txns_in_block) as total_kshop_txns
FROM block_stats
WHERE prev_block_time IS NOT NULL
GROUP BY DATE_TRUNC('hour', block_time)
ORDER BY hour DESC;