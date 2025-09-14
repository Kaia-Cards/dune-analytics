-- Gas Usage and Optimization
SELECT
    DATE_TRUNC('day', block_time) as date,
    COUNT(*) as transaction_count,
    AVG(gas_price / 1e9) as avg_gas_price_gwei,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gas_price / 1e9) as median_gas_price_gwei,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY gas_price / 1e9) as p95_gas_price_gwei,
    AVG(gas_used) as avg_gas_used,
    SUM(gas_used * gas_price / 1e18) as total_gas_cost_kaia,
    AVG(gas_used * gas_price / 1e18) as avg_gas_cost_per_txn,
    COUNT(CASE WHEN success = false THEN 1 END) as failed_transactions,
    COUNT(CASE WHEN success = false THEN 1 END) * 100.0 / COUNT(*) as failure_rate_percent
FROM kaia.transactions
WHERE
    "to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    AND block_time >= NOW() - INTERVAL '30' DAY
GROUP BY DATE_TRUNC('day', block_time)
ORDER BY date DESC;