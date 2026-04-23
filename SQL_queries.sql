CREATE DATABASE ecommerce_sql;
use ecommerce_sql;

# PRIMARY KEY AND FOREIGN KEY SETTING

ALTER TABLE products ADD PRIMARY KEY (product_id);
SET FOREIGN_KEY_CHECKS = 0;
ALTER TABLE sellers ADD PRIMARY KEY (seller_id);
SET FOREIGN_KEY_CHECKS = 0;
ALTER TABLE orders
ADD FOREIGN KEY (product_id) REFERENCES products(product_id),
ADD FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

# adding revenue column

ALTER TABLE orders ADD COLUMN revenue FLOAT;

UPDATE orders
SET revenue = price_usd * sold
WHERE product_id IS NOT NULL;


#   seller revenue view

CREATE VIEW seller_revenue AS
SELECT seller_id,
       SUM(revenue) AS total_revenue
FROM orders
GROUP BY seller_id;

#      sales category view

CREATE VIEW category_sales AS
SELECT p.product_category,
       COUNT(*) AS total_sales
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.sold = 1
GROUP BY p.product_category;


# 1. TOP 10 SELLERS BY REVENUE (VIEW)
SELECT seller_id,
       total_revenue
FROM seller_revenue
ORDER BY total_revenue DESC
LIMIT 10;


# 2. RANK SELLERS (WINDOW + VIEW)
SELECT seller_id,
       total_revenue,
       RANK() OVER (ORDER BY total_revenue DESC) AS rank_num
FROM seller_revenue;


# 3. TOP PRODUCT IN EACH CATEGORY (REVENUE BASED 🔥)
SELECT *
FROM (
    SELECT p.product_category,
           o.product_id,
           SUM(o.revenue) AS total_revenue,
           RANK() OVER (
               PARTITION BY p.product_category 
               ORDER BY SUM(o.revenue) DESC
           ) AS rnk
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    WHERE o.sold = 1
    GROUP BY p.product_category, o.product_id
) t
WHERE rnk = 1;


# 4. CATEGORY REVENUE ANALYSIS 
SELECT p.product_category,
       SUM(o.revenue) AS total_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.product_category
ORDER BY total_revenue DESC;


# 5. SELLER PERFORMANCE (shows quality + revenue + sales)
SELECT s.seller_id,
       s.seller_pass_rate,
       SUM(o.revenue) AS total_revenue,
       SUM(o.sold) AS total_sales
FROM sellers s
JOIN orders o ON s.seller_id = o.seller_id
GROUP BY s.seller_id, s.seller_pass_rate
ORDER BY total_revenue DESC;


# 6. SHIPPING IMPACT (ADVANCED)
SELECT shipping_days,
       COUNT(*) AS total_sales,
       SUM(revenue) AS total_revenue,
       AVG(revenue) AS avg_revenue
FROM orders
WHERE sold = 1
GROUP BY shipping_days
ORDER BY shipping_days;


# 7. REVENUE CONTRIBUTION (USING VIEW)
SELECT seller_id,
       total_revenue,
       ROUND(total_revenue / SUM(total_revenue) OVER () * 100, 2) AS contribution_pct
FROM seller_revenue
ORDER BY total_revenue DESC;


#8. HIGH PERFORMING SELLERS 
SELECT s.seller_id,
       s.seller_pass_rate,
       SUM(o.revenue) AS total_revenue,
       SUM(o.sold) AS total_sales
FROM sellers s
JOIN orders o ON s.seller_id = o.seller_id
GROUP BY s.seller_id, s.seller_pass_rate
HAVING s.seller_pass_rate > 90
ORDER BY total_revenue DESC;


# 9. BONUS: REPEAT SALES (UPGRADED)
SELECT seller_id,
       COUNT(*) AS total_orders,
       SUM(revenue) AS total_revenue
FROM orders
WHERE sold = 1
GROUP BY seller_id
HAVING COUNT(*) > 50
ORDER BY total_revenue DESC;


# 10. TOP 20% SELLERS 
WITH ranked_sellers AS (
    SELECT seller_id,
           total_revenue,
           NTILE(5) OVER (ORDER BY total_revenue DESC) AS bucket FROM seller_revenue)
SELECT *
FROM ranked_sellers
WHERE bucket = 1;




