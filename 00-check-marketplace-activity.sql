SELECT
    "to" as contract_address,
    COUNT(*) as transaction_count,
    MAX(block_time) as latest_transaction
FROM kaia.transactions
WHERE "to" IN (
    0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c,
    0x1577dE52bF5D6a7f455FC19d87c728d4bE3e1377,
    0xAAf08E36E2a8e91D4bA34C1A51a92b08D329cbF8
)
AND block_time >= NOW() - INTERVAL '90' DAY
GROUP BY "to"
ORDER BY transaction_count DESC;