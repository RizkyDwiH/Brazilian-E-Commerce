-- DATA UNDERSTANDING & EXPLORATION


-- STEP 1: UNDERSTAND WHAT DATA WE HAVE
-- count how many rows in each table
SELECT 'customers' as table_name, COUNT(*) as total_rows FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset]
UNION ALL
SELECT 'orders', COUNT(*) FROM [Brazilian e - commerce].[dbo].[olist_orders_dataset]
UNION ALL  
SELECT 'order_items', COUNT(*) FROM [Brazilian e - commerce].[dbo].[olist_order_items_dataset]
UNION ALL
SELECT 'reviews', COUNT(*) FROM [Brazilian e - commerce].[dbo].[olist_order_reviews_dataset];



-- STEP 2: BASIC BUSINESS QUESTIONS
-- We want to answer 3 simple questions:
-- How many customers do we have?
-- How much are they spending?
-- Are they happy? (review scores)



-- Step 3: Basic Business Metrics
-- Query 1: Basic Customer Count
-- How many unique customers?
SELECT COUNT(DISTINCT customer_unique_id) as total_customers
FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset];


-- Query 2: Total Revenue
-- How much money did we make?
SELECT SUM(price) as total_revenue
FROM [Brazilian e - commerce].[dbo].[olist_order_items_dataset];

-- Total Revenue by daily
SELECT 
    CAST(shipping_limit_date AS DATE) AS order_date,
    SUM(price) AS total_revenue
FROM [Brazilian e - commerce].[dbo].[olist_order_items_dataset]
GROUP BY CAST(shipping_limit_date AS DATE)
ORDER BY order_date;

-- Total Revenue by month
SELECT 
    YEAR(shipping_limit_date) AS year,
    MONTH(shipping_limit_date) AS month,
    SUM(price) AS total_revenue
FROM [Brazilian e - commerce].[dbo].[olist_order_items_dataset]
GROUP BY YEAR(shipping_limit_date), MONTH(shipping_limit_date)
ORDER BY year, month;

-- Total Revenue by year
SELECT 
    YEAR(shipping_limit_date) AS year,
    SUM(price) AS total_revenue
FROM [Brazilian e - commerce].[dbo].[olist_order_items_dataset]
GROUP BY YEAR(shipping_limit_date)
ORDER BY year;


-- Query 3: Average Review Score
-- Are customers happy?
SELECT AVG(CAST(review_score as FLOAT)) as average_rating
FROM [Brazilian e - commerce].[dbo].[olist_order_reviews_dataset];



-- STEP 4: COMBINE EVERYTHING
-- Simple customer spending overview
SELECT 
    c.customer_unique_id,
    COUNT(o.order_id) as order_count,
    SUM(oi.price) as total_spent,
    AVG(CAST(r.review_score as FLOAT)) as avg_rating
FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset] c
JOIN [Brazilian e - commerce].[dbo].[olist_orders_dataset] o ON c.customer_id = o.customer_id
JOIN [Brazilian e - commerce].[dbo].[olist_order_items_dataset] oi ON o.order_id = oi.order_id
LEFT JOIN [Brazilian e - commerce].[dbo].[olist_order_reviews_dataset] r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC;

-- Big Spenders with Low Satisfaction
-- Customers who spent a lot but gave low ratings
SELECT TOP 5
    c.customer_unique_id,
    COUNT(o.order_id) as order_count,
    SUM(oi.price) as total_spent,
    AVG(CAST(r.review_score as FLOAT)) as avg_rating
FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset] c
JOIN [Brazilian e - commerce].[dbo].[olist_orders_dataset] o ON c.customer_id = o.customer_id
JOIN [Brazilian e - commerce].[dbo].[olist_order_items_dataset] oi ON o.order_id = oi.order_id
LEFT JOIN [Brazilian e - commerce].[dbo].[olist_order_reviews_dataset] r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
AND CAST(r.review_score as FLOAT) <= 2  -- Low ratings
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC;

-- Happy Loyal Customers
-- Customers who spent a lot and are happy
SELECT 
    c.customer_unique_id,
    COUNT(o.order_id) as order_count,
    SUM(oi.price) as total_spent,
    AVG(CAST(r.review_score as FLOAT)) as avg_rating
FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset] c
JOIN [Brazilian e - commerce].[dbo].[olist_orders_dataset]o ON c.customer_id = o.customer_id
JOIN [Brazilian e - commerce].[dbo].[olist_order_items_dataset] oi ON o.order_id = oi.order_id
LEFT JOIN [Brazilian e - commerce].[dbo].[olist_order_reviews_dataset] r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
AND CAST(r.review_score as FLOAT) >= 4  -- High ratings
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC;

-- Simple Customer Segmentation
WITH customer_summary AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count,
        SUM(oi.price) AS total_spent,
        AVG(CAST(r.review_score AS FLOAT)) AS avg_rating
    FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset] AS c
    JOIN [Brazilian e - commerce].[dbo].[olist_orders_dataset] AS o
        ON c.customer_id = o.customer_id
    JOIN [Brazilian e - commerce].[dbo].[olist_order_items_dataset] AS oi
        ON o.order_id = oi.order_id
    LEFT JOIN [Brazilian e - commerce].[dbo].[olist_order_reviews_dataset] AS r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT 
    CASE 
        WHEN order_count > 3 THEN 'VIP'
        WHEN total_spent > 100000 THEN 'Big Spender'
        ELSE 'Regular'
    END AS customer_type,
    COUNT(*) AS customer_count,
    AVG(order_count) AS avg_orders,
    AVG(total_spent) AS avg_spending,
    AVG(avg_rating) AS avg_rating
FROM customer_summary
GROUP BY 
    CASE 
        WHEN order_count > 3 THEN 'VIP'
        WHEN total_spent > 100000 THEN 'Big Spender'
        ELSE 'Regular'
    END
ORDER BY customer_type;



-- NEXT STEP: Customer Behavior Analysis

-- Query 1: Order Frequency Distribution
-- How many orders do most customers make?
SELECT 
    order_count,
    COUNT(*) AS customer_count,
    CAST(COUNT(*) * 1.0 / (SELECT COUNT(DISTINCT customer_unique_id) 
                           FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset]) 
         AS DECIMAL(10,6)) AS percentage
FROM (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset] c
    JOIN [Brazilian e - commerce].[dbo].[olist_orders_dataset] o 
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) AS customer_orders
GROUP BY order_count
ORDER BY order_count;



-- Query 2: Spending Range Analysis
-- How much do customers typically spend?
SELECT 
    CASE 
        WHEN total_spent > 1000000 THEN 'Over 1M'
        WHEN total_spent > 500000 THEN '500K-1M'
        WHEN total_spent > 100000 THEN '100K-500K'
        WHEN total_spent > 50000 THEN '50K-100K'
        WHEN total_spent > 10000 THEN '10K-50K'
        ELSE 'Under 10K'
    END as spending_range,
    COUNT(*) as customer_count,
    AVG(total_spent) as avg_spending
FROM (
    SELECT 
        c.customer_unique_id,
        SUM(oi.price) as total_spent
    FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset] c
    JOIN [Brazilian e - commerce].[dbo].[olist_orders_dataset] o ON c.customer_id = o.customer_id
    JOIN [Brazilian e - commerce].[dbo].[olist_order_items_dataset] oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) as customer_spending
GROUP BY 
    CASE 
        WHEN total_spent > 1000000 THEN 'Over 1M'
        WHEN total_spent > 500000 THEN '500K-1M'
        WHEN total_spent > 100000 THEN '100K-500K'
        WHEN total_spent > 50000 THEN '50K-100K'
        WHEN total_spent > 10000 THEN '10K-50K'
        ELSE 'Under 10K'
    END
ORDER BY customer_count DESC;


-- Are one-time customers unhappy? Check their ratings
SELECT 
    'One-Time Customers' AS customer_type,
    COUNT(DISTINCT c.customer_unique_id) AS customer_count,
    AVG(CAST(r.review_score AS FLOAT)) AS avg_rating,
    COUNT(r.review_id) AS review_count
FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset] c
JOIN [Brazilian e - commerce].[dbo].[olist_orders_dataset] o ON c.customer_id = o.customer_id
LEFT JOIN [Brazilian e - commerce].[dbo].[olist_order_reviews_dataset] r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
AND c.customer_unique_id IN (
    SELECT customer_unique_id
    FROM (
        SELECT 
            c.customer_unique_id,
            COUNT(DISTINCT o.order_id) AS order_count
        FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset] c
        JOIN [Brazilian e - commerce].[dbo].[olist_orders_dataset] o ON c.customer_id = o.customer_id
        WHERE o.order_status = 'delivered'
        GROUP BY c.customer_unique_id
    ) AS order_counts
    WHERE order_count = 1
)

UNION ALL


-- Repeat customers (more than 1 order)
SELECT 
    'Repeat Customers' AS customer_type,
    COUNT(DISTINCT c.customer_unique_id) AS customer_count,
    AVG(CAST(r.review_score AS FLOAT)) AS avg_rating,
    COUNT(r.review_id) AS review_count
FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset] c
JOIN [Brazilian e - commerce].[dbo].[olist_orders_dataset] o ON c.customer_id = o.customer_id
LEFT JOIN [Brazilian e - commerce].[dbo].[olist_order_reviews_dataset] r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
AND c.customer_unique_id IN (
    SELECT customer_unique_id
    FROM (
        SELECT 
            c.customer_unique_id,
            COUNT(DISTINCT o.order_id) AS order_count
        FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset] c
        JOIN [Brazilian e - commerce].[dbo].[olist_orders_dataset] o ON c.customer_id = o.customer_id
        WHERE o.order_status = 'delivered'
        GROUP BY c.customer_unique_id
    ) AS order_counts
    WHERE order_count > 1
);


-- Where are our customers located? (Top 10 states)
SELECT TOP 10
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) as total_customers,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(oi.price) as total_revenue,
    AVG(CAST(r.review_score as FLOAT)) as avg_rating
FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset] c
JOIN [Brazilian e - commerce].[dbo].[olist_orders_dataset] o ON c.customer_id = o.customer_id
JOIN [Brazilian e - commerce].[dbo].[olist_order_items_dataset] oi ON o.order_id = oi.order_id
LEFT JOIN [Brazilian e - commerce].[dbo].[olist_order_reviews_dataset] r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


-- What products are customers buying? (Top 10 categories)
SELECT TOP 10
    p.product_category_name,
    COUNT(DISTINCT o.order_id) as order_count,
    COUNT(DISTINCT c.customer_unique_id) as customer_count,
    SUM(oi.price) as total_revenue,
    AVG(CAST(r.review_score as FLOAT)) as avg_rating
FROM [Brazilian e - commerce].[dbo].[olist_customers_dataset] c
JOIN [Brazilian e - commerce].[dbo].[olist_orders_dataset] o ON c.customer_id = o.customer_id
JOIN [Brazilian e - commerce].[dbo].[olist_order_items_dataset] oi ON o.order_id = oi.order_id
JOIN [Brazilian e - commerce].[dbo].[olist_products_dataset] p ON oi.product_id = p.product_id
LEFT JOIN [Brazilian e - commerce].[dbo].[olist_order_reviews_dataset] r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;
