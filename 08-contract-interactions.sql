-- Contract Interaction Summary
SELECT
    "to" as contract_address,
    CASE
        WHEN "to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c THEN 'K SHOP Marketplace'
        WHEN "to" = 0x1577dE52bF5D6a7f455FC19d87c728d4bE3e1377 THEN 'USDT Token (Testnet)'
        WHEN "to" = 0xd077a400968890eacc75cdc901f0356c943e4fdb THEN 'USDT Token (Mainnet)'
        WHEN "to" = 0xAAf08E36E2a8e91D4bA34C1A51a92b08D329cbF8 THEN 'Treasury Wallet'
        ELSE 'Other Contract'
    END as contract_name,
    COUNT(*) as total_interactions,
    COUNT(DISTINCT "from") as unique_users,
    SUM(CAST(value AS DOUBLE) / 1e18) as total_kaia_value,
    AVG(CAST(value AS DOUBLE) / 1e18) as avg_kaia_per_txn,
    COUNT(CASE WHEN success = true THEN 1 END) as successful_txns,
    COUNT(CASE WHEN success = false THEN 1 END) as failed_txns,
    COUNT(CASE WHEN success = true THEN 1 END) * 100.0 / COUNT(*) as success_rate_percent
FROM kaia.transactions
WHERE
    "to" IN (
        0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c,
        0x1577dE52bF5D6a7f455FC19d87c728d4bE3e1377,
        0xd077a400968890eacc75cdc901f0356c943e4fdb,
        0xAAf08E36E2a8e91D4bA34C1A51a92b08D329cbF8
    )
    AND block_time >= NOW() - INTERVAL '30' DAY
GROUP BY "to"
ORDER BY total_interactions DESC;