WITH transaction_flow AS (
    SELECT
        DATE_TRUNC('day', block_time) as date,
        "from" as user_address,
        success,
        CAST(value AS DOUBLE) / 1e6 as amount_usdt,
        gas_used,
        gas_price / 1e9 as gas_price_gwei,
        CASE
            WHEN success = true THEN 'Completed'
            WHEN gas_used = 21000 THEN 'Failed - Insufficient Gas'
            WHEN gas_price / 1e9 < 5 THEN 'Failed - Low Gas Price'
            ELSE 'Failed - Other'
        END as transaction_status
    FROM kaia.transactions
    WHERE "to" = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    AND block_time >= NOW() - INTERVAL '30' DAY
),
daily_funnel AS (
    SELECT
        date,
        COUNT(*) as total_attempts,
        COUNT(CASE WHEN transaction_status = 'Completed' THEN 1 END) as successful_purchases,
        COUNT(CASE WHEN transaction_status LIKE 'Failed%' THEN 1 END) as failed_attempts,
        AVG(CASE WHEN transaction_status = 'Completed' THEN amount_usdt END) as avg_successful_amount,
        AVG(CASE WHEN transaction_status = 'Completed' THEN gas_used END) as avg_gas_successful,
        COUNT(DISTINCT user_address) as unique_users_attempting
    FROM transaction_flow
    GROUP BY date
)
SELECT
    date,
    total_attempts,
    successful_purchases,
    failed_attempts,
    unique_users_attempting,
    successful_purchases * 100.0 / total_attempts as completion_rate_percent,
    avg_successful_amount,
    avg_gas_successful,
    successful_purchases * avg_successful_amount as daily_revenue
FROM daily_funnel
ORDER BY date DESC;