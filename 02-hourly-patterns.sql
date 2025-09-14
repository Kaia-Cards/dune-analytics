-- Hourly Activity Patterns
SELECT
    EXTRACT(hour FROM block_time) as hour_of_day,
    EXTRACT(dow FROM block_time) as day_of_week,
    COUNT(*) as transactions,
    AVG(CAST(value AS DOUBLE) / 1e6) as avg_amount,
    COUNT(DISTINCT "from") as unique_users
FROM kaia.transactions
WHERE
    "to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    AND block_time >= NOW() - INTERVAL '7' DAY
GROUP BY EXTRACT(hour FROM block_time), EXTRACT(dow FROM block_time)
ORDER BY day_of_week, hour_of_day;