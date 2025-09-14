-- Treasury Wallet Activity
SELECT
    DATE_TRUNC('day', block_time) as date,
    COUNT(CASE WHEN "to" = 0xAAf08E36E2a8e91D4bA34C1A51a92b08D329cbF8 THEN 1 END) as incoming_transactions,
    COUNT(CASE WHEN "from" = 0xAAf08E36E2a8e91D4bA34C1A51a92b08D329cbF8 THEN 1 END) as outgoing_transactions,
    SUM(CASE WHEN "to" = 0xAAf08E36E2a8e91D4bA34C1A51a92b08D329cbF8 THEN CAST(value AS DOUBLE) / 1e18 ELSE 0 END) as kaia_received,
    SUM(CASE WHEN "from" = 0xAAf08E36E2a8e91D4bA34C1A51a92b08D329cbF8 THEN CAST(value AS DOUBLE) / 1e18 ELSE 0 END) as kaia_sent,
    COUNT(DISTINCT CASE WHEN "to" = 0xAAf08E36E2a8e91D4bA34C1A51a92b08D329cbF8 THEN "from" END) as unique_senders,
    COUNT(DISTINCT CASE WHEN "from" = 0xAAf08E36E2a8e91D4bA34C1A51a92b08D329cbF8 THEN "to" END) as unique_recipients
FROM kaia.transactions
WHERE
    ("to" = 0xAAf08E36E2a8e91D4bA34C1A51a92b08D329cbF8 OR "from" = 0xAAf08E36E2a8e91D4bA34C1A51a92b08D329cbF8)
    AND block_time >= NOW() - INTERVAL '30' DAY
GROUP BY DATE_TRUNC('day', block_time)
ORDER BY date DESC;