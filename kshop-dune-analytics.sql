-- kshop dune dashboard

-- 1. Regional Transaction Analysis
SELECT
    CASE
        WHEN t.from IN (
            SELECT DISTINCT wallet_address FROM user_profiles WHERE country = 'Thailand'
        ) THEN 'Thailand'
        WHEN t.from IN (
            SELECT DISTINCT wallet_address FROM user_profiles WHERE country = 'Indonesia'
        ) THEN 'Indonesia'
        WHEN t.from IN (
            SELECT DISTINCT wallet_address FROM user_profiles WHERE country = 'Malaysia'
        ) THEN 'Malaysia'
        WHEN t.from IN (
            SELECT DISTINCT wallet_address FROM user_profiles WHERE country = 'Singapore'
        ) THEN 'Singapore'
        WHEN t.from IN (
            SELECT DISTINCT wallet_address FROM user_profiles WHERE country = 'Philippines'
        ) THEN 'Philippines'
        WHEN t.from IN (
            SELECT DISTINCT wallet_address FROM user_profiles WHERE country = 'Vietnam'
        ) THEN 'Vietnam'
        ELSE 'Other'
    END as region,
    DATE_TRUNC('day', block_time) as date,
    COUNT(*) as transactions,
    COUNT(DISTINCT t.from) as unique_users,
    SUM(CAST(l.data AS DOUBLE) / 1e6) as total_volume_usdt,
    AVG(CAST(l.data AS DOUBLE) / 1e6) as avg_transaction_size
FROM kaia.transactions t
INNER JOIN kaia.logs l ON t.hash = l.transaction_hash
WHERE
    l.contract_address = 0x1577dE52bF5D6a7f455FC19d87c728d4bE3e1377
    AND t.to = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
GROUP BY region, DATE_TRUNC('day', block_time)
ORDER BY date DESC, total_volume_usdt DESC;

-- 2. Shop Category Performance Analysis
SELECT
    CASE
        WHEN l.topic2 LIKE '%gaming%' OR l.topic2 LIKE '%steam%' OR l.topic2 LIKE '%playstation%' THEN 'Gaming'
        WHEN l.topic2 LIKE '%food%' OR l.topic2 LIKE '%grab%' OR l.topic2 LIKE '%foodpanda%' THEN 'Food & Dining'
        WHEN l.topic2 LIKE '%shopping%' OR l.topic2 LIKE '%lazada%' OR l.topic2 LIKE '%shopee%' THEN 'E-commerce'
        WHEN l.topic2 LIKE '%entertainment%' OR l.topic2 LIKE '%netflix%' OR l.topic2 LIKE '%spotify%' THEN 'Entertainment'
        WHEN l.topic2 LIKE '%line%' OR l.topic2 LIKE '%true%' OR l.topic2 LIKE '%ais%' THEN 'Telco & Digital'
        ELSE 'Other'
    END as shop_category,
    DATE_TRUNC('week', block_time) as week,
    COUNT(*) as purchases,
    COUNT(DISTINCT t.from) as unique_buyers,
    SUM(CAST(l.data AS DOUBLE) / 1e6) as total_sales_usdt,
    AVG(CAST(l.data AS DOUBLE) / 1e6) as avg_order_value,
    STDDEV(CAST(l.data AS DOUBLE) / 1e6) as order_value_stddev
FROM kaia.transactions t
INNER JOIN kaia.logs l ON t.hash = l.transaction_hash
WHERE
    l.contract_address = 0x1577dE52bF5D6a7f455FC19d87c728d4bE3e1377
    AND t.to = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
GROUP BY shop_category, DATE_TRUNC('week', block_time)
ORDER BY week DESC, total_sales_usdt DESC;

-- 3. Popular Gift Card Brands by Region
SELECT
    r.region,
    CASE
        WHEN l.topic3 LIKE '%grab%' THEN 'Grab'
        WHEN l.topic3 LIKE '%steam%' THEN 'Steam'
        WHEN l.topic3 LIKE '%lazada%' THEN 'Lazada'
        WHEN l.topic3 LIKE '%shopee%' THEN 'Shopee'
        WHEN l.topic3 LIKE '%line%' THEN 'LINE Store'
        WHEN l.topic3 LIKE '%true%' THEN 'True Money'
        WHEN l.topic3 LIKE '%netflix%' THEN 'Netflix'
        WHEN l.topic3 LIKE '%spotify%' THEN 'Spotify'
        WHEN l.topic3 LIKE '%ais%' THEN 'AIS'
        WHEN l.topic3 LIKE '%foodpanda%' THEN 'FoodPanda'
        ELSE 'Other'
    END as brand,
    COUNT(*) as purchases,
    SUM(CAST(l.data AS DOUBLE) / 1e6) as total_volume,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY r.region) as market_share_percent
FROM kaia.transactions t
INNER JOIN kaia.logs l ON t.hash = l.transaction_hash
INNER JOIN (
    SELECT
        wallet_address,
        CASE
            WHEN country = 'Thailand' THEN 'Thailand'
            WHEN country = 'Indonesia' THEN 'Indonesia'
            WHEN country = 'Malaysia' THEN 'Malaysia'
            WHEN country = 'Singapore' THEN 'Singapore'
            WHEN country = 'Philippines' THEN 'Philippines'
            WHEN country = 'Vietnam' THEN 'Vietnam'
            ELSE 'Other'
        END as region
    FROM user_profiles
) r ON t.from = r.wallet_address
WHERE
    l.contract_address = 0x1577dE52bF5D6a7f455FC19d87c728d4bE3e1377
    AND t.to = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
GROUP BY r.region, brand
ORDER BY r.region, purchases DESC;

-- 4. Time-based Shopping Patterns by Region
SELECT
    r.region,
    EXTRACT(hour FROM block_time) as hour_of_day,
    EXTRACT(dow FROM block_time) as day_of_week,
    COUNT(*) as transactions,
    AVG(CAST(l.data AS DOUBLE) / 1e6) as avg_amount,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY r.region) as time_distribution_percent
FROM kaia.transactions t
INNER JOIN kaia.logs l ON t.hash = l.transaction_hash
INNER JOIN (
    SELECT wallet_address, country as region FROM user_profiles
) r ON t.from = r.wallet_address
WHERE
    l.contract_address = 0x1577dE52bF5D6a7f455FC19d87c728d4bE3e1377
    AND t.to = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    AND block_time >= NOW() - INTERVAL '30' DAY
GROUP BY r.region, EXTRACT(hour FROM block_time), EXTRACT(dow FROM block_time)
ORDER BY r.region, day_of_week, hour_of_day;

-- 5. Customer Lifetime Value by Region
SELECT
    r.region,
    t.from as customer_address,
    COUNT(*) as total_purchases,
    SUM(CAST(l.data AS DOUBLE) / 1e6) as lifetime_value_usdt,
    AVG(CAST(l.data AS DOUBLE) / 1e6) as avg_purchase_amount,
    MAX(block_time) as last_purchase_date,
    MIN(block_time) as first_purchase_date,
    EXTRACT(days FROM (MAX(block_time) - MIN(block_time))) as customer_lifespan_days
FROM kaia.transactions t
INNER JOIN kaia.logs l ON t.hash = l.transaction_hash
INNER JOIN (
    SELECT wallet_address, country as region FROM user_profiles
) r ON t.from = r.wallet_address
WHERE
    l.contract_address = 0x1577dE52bF5D6a7f455FC19d87c728d4bE3e1377
    AND t.to = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
GROUP BY r.region, t.from
HAVING COUNT(*) > 1
ORDER BY lifetime_value_usdt DESC;

-- 6. Market Penetration and Growth by Country
SELECT
    country,
    DATE_TRUNC('month', created_at) as month,
    COUNT(*) as new_users,
    SUM(COUNT(*)) OVER (PARTITION BY country ORDER BY DATE_TRUNC('month', created_at)) as cumulative_users,
    AVG(first_purchase_amount) as avg_first_purchase,
    COUNT(CASE WHEN total_purchases > 1 THEN 1 END) * 100.0 / COUNT(*) as retention_rate_percent
FROM user_profiles up
LEFT JOIN (
    SELECT
        t.from as wallet_address,
        MIN(CAST(l.data AS DOUBLE) / 1e6) as first_purchase_amount,
        COUNT(*) as total_purchases
    FROM kaia.transactions t
    INNER JOIN kaia.logs l ON t.hash = l.transaction_hash
    WHERE l.contract_address = 0x1577dE52bF5D6a7f455FC19d87c728d4bE3e1377
    AND t.to = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    GROUP BY t.from
) purchase_data ON up.wallet_address = purchase_data.wallet_address
WHERE country IN ('Thailand', 'Indonesia', 'Malaysia', 'Singapore', 'Philippines', 'Vietnam')
GROUP BY country, DATE_TRUNC('month', created_at)
ORDER BY month DESC, new_users DESC;

-- 7. Shop Performance Metrics
SELECT
    shop_name,
    shop_category,
    shop_country,
    COUNT(*) as total_orders,
    COUNT(DISTINCT customer_wallet) as unique_customers,
    SUM(order_amount_usdt) as total_revenue,
    AVG(order_amount_usdt) as avg_order_value,
    AVG(processing_time_minutes) as avg_processing_time,
    COUNT(CASE WHEN order_status = 'completed' THEN 1 END) * 100.0 / COUNT(*) as success_rate_percent,
    AVG(customer_rating) as avg_rating,
    DATE_TRUNC('day', MAX(created_at)) as last_order_date
FROM orders o
INNER JOIN gift_cards gc ON o.gift_card_id = gc.id
WHERE created_at >= NOW() - INTERVAL '30' DAY
GROUP BY shop_name, shop_category, shop_country
ORDER BY total_revenue DESC;

-- 8. Cross-Border Shopping Analysis
SELECT
    up.country as customer_country,
    gc.country as shop_country,
    COUNT(*) as cross_border_orders,
    SUM(o.amount) as total_volume_usdt,
    AVG(o.amount) as avg_order_value,
    COUNT(*) * 100.0 / (
        SELECT COUNT(*) FROM orders WHERE customer_email = o.customer_email
    ) as cross_border_percentage
FROM orders o
INNER JOIN gift_cards gc ON o.gift_card_id = gc.id
INNER JOIN user_profiles up ON o.customer_wallet = up.wallet_address
WHERE up.country != gc.country
AND o.created_at >= NOW() - INTERVAL '90' DAY
GROUP BY up.country, gc.country
ORDER BY cross_border_orders DESC;

-- 9. Payment Method and Gas Optimization Analysis
SELECT
    DATE_TRUNC('day', block_time) as date,
    COUNT(*) as total_transactions,
    AVG(gas_price / 1e9) as avg_gas_price_gwei,
    AVG(gas_used) as avg_gas_used,
    AVG(gas_used * gas_price / 1e18) as avg_transaction_cost_kaia,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gas_price / 1e9) as median_gas_price,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY gas_price / 1e9) as p95_gas_price,
    COUNT(CASE WHEN success = false THEN 1 END) as failed_transactions,
    AVG(CAST(l.data AS DOUBLE) / 1e6) as avg_payment_amount_usdt
FROM kaia.transactions t
INNER JOIN kaia.logs l ON t.hash = l.transaction_hash
WHERE
    l.contract_address = 0x1577dE52bF5D6a7f455FC19d87c728d4bE3e1377
    AND t.to = 0xe47BcF7103bBc8d1DDD75f2Ab6813da050443D2c
    AND block_time >= NOW() - INTERVAL '30' DAY
GROUP BY DATE_TRUNC('day', block_time)
ORDER BY date DESC;

-- 10. Revenue Attribution and Channel Analysis
SELECT
    traffic_source,
    referrer_domain,
    utm_campaign,
    region,
    COUNT(DISTINCT customer_wallet) as unique_customers,
    COUNT(*) as total_orders,
    SUM(order_amount_usdt) as total_revenue,
    AVG(order_amount_usdt) as avg_order_value,
    SUM(order_amount_usdt) * 100.0 / (SELECT SUM(order_amount_usdt) FROM orders WHERE created_at >= NOW() - INTERVAL '30' DAY) as revenue_share_percent,
    AVG(time_to_purchase_minutes) as avg_conversion_time
FROM orders o
INNER JOIN user_sessions us ON o.session_id = us.session_id
INNER JOIN user_profiles up ON o.customer_wallet = up.wallet_address
WHERE o.created_at >= NOW() - INTERVAL '30' DAY
GROUP BY traffic_source, referrer_domain, utm_campaign, region
ORDER BY total_revenue DESC;