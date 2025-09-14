SELECT
    COUNT(*) as total_transactions,
    COUNT(DISTINCT "to") as unique_contracts,
    COUNT(DISTINCT "from") as unique_users,
    MIN(block_time) as earliest_transaction,
    MAX(block_time) as latest_transaction
FROM kaia.transactions
WHERE block_time >= NOW() - INTERVAL '7' DAY
LIMIT 10;