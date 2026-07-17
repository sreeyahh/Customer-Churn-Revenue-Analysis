create database EcommerceAnalytics

use EcommerceAnalytics

select db_name() as CurrentDatabase

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

select * from customers

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,

    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

select * from orders

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)

    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
)

select * from order_items

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    products_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
)

select * from products

CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2),

    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
)

select * from order_payments

CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message VARCHAR(MAX),
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,

    PRIMARY KEY (review_id),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
)

select * from order_reviews

BULK INSERT customers
FROM '/var/opt/mssql/data/olist_customers_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2
);

select count(*) [Total Customers] from customers;

SELECT TOP 10 * FROM customers;

BULK INSERT products
FROM '/var/opt/mssql/data/olist_products_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2
);

select count(*) [Total Products] from products;

SELECT TOP 10 * FROM products;

BULK INSERT orders
FROM '/var/opt/mssql/data/olist_orders_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2
);

select count(*) [Total Orders] from orders;

SELECT TOP 10 * FROM orders;

BULK INSERT order_items
FROM '/var/opt/mssql/data/olist_order_items_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2
);

select count(*) [Total items] from order_items;

SELECT TOP 10 * FROM order_items;

BULK INSERT order_payments
FROM '/var/opt/mssql/data/olist_order_payments_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2
);

select count(*) [Total payments] from order_payments;

SELECT TOP 10 * FROM order_payments;

BULK INSERT order_reviews
FROM '/var/opt/mssql/data/olist_order_reviews_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    tablock
);

select count(*) as total_reviews from order_reviews;

select count(*) [Total reviews] from order_reviews;

SELECT TOP 20 * FROM order_reviews;

SELECT 'customers' AS Table_Name, COUNT(*) AS Total_Rows FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews;

select sum(payment_value) as total_revenue from order_payments;

select count(distinct order_id) as total_orders from orders;

select avg(order_total) as avg_order_value from (
    select order_id,
    sum(payment_value) 
    as order_total 
    from order_payments
    group by order_id
) as order_summary;

select year(o.order_purchase_timestamp) as order_year,
month(o.order_purchase_timestamp) as order_month,
SUM(op.payment_value) as monthly_revenue
from orders o join order_payments op on o.order_id = op.order_id
group by year(o.order_purchase_timestamp), month(o.order_purchase_timestamp)
order by order_year, order_month

select top 10 oi.product_id, count(*) as units_sold, sum(oi.price) as total_revenue 
from order_items oi group by oi.product_id 
order by total_revenue desc

select top 10 c.customer_id, c.customer_city, c.customer_state, sum(op.payment_value) 
as customer_lifetime_value_clv
from customers c join orders o on c.customer_id=o.customer_id
join order_payments op on o.order_id=op.order_id
group by c.customer_id, c.customer_city, c.customer_state
order by customer_lifetime_value_clv desc

select count(*) as total_customers, count(distinct customer_id) as unique_customers
from orders;

SELECT
    c.customer_unique_id,
    COUNT(o.order_id) AS Total_Orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1
ORDER BY Total_Orders DESC;

select cast(count(
    case 
    when total_orders>1
    then 1 
    end) *100.0/count(*) as decimal(5,2)
) as returning_customer_percentage from (
    select c.customer_unique_id, count(o.order_id) as total_orders
    from customers c join orders o on c.customer_id=o.customer_id
    group by c.customer_unique_id 
) as customer_orders

select c.customer_state, sum(op.payment_value) as total_revenue from customers c join orders o  
on c.customer_id=o.customer_id join order_payments op on o.order_id=op.order_id
group by c.customer_state
order by total_revenue desc

select top 10 p.product_category_name, sum(oi.price) as total_revenue, count(oi.order_id) as total_items_sold
from order_items oi join products p on oi.product_id=p.product_id 
group by p.product_category_name
order by total_revenue desc

with customer_clv as (
    select c.customer_unique_id, sum(op.payment_value) as CLV 
    from customers c join orders o on c.customer_id=o.customer_id
    join order_payments op on o.order_id=op.order_id
    group by c.customer_unique_id
) select top 10 customer_unique_id, CLV from customer_clv 
order by CLV desc

with customer_clv as (
    select c.customer_unique_id, sum(op.payment_value) as CLV 
    from customers c join orders o on c.customer_id=o.customer_id
    join order_payments op on o.order_id=op.order_id
    group by c.customer_unique_id
) select customer_unique_id, CLV, rank() over (order by CLV desc) as customer_rank
from customer_clv

with customer_clv as (
    select c.customer_unique_id, sum(op.payment_value) as CLV 
    from customers c join orders o on c.customer_id=o.customer_id
    join order_payments op on o.order_id=op.order_id
    group by c.customer_unique_id
) select customer_unique_id, CLV,
case 
    when CLV>=1000 then 'High Value'
    when CLV>=500 then 'Medium Value'
    else 'Low Value'
end as customer_segment from customer_clv order by CLV DESC

WITH MonthlyRevenue AS
(
    SELECT
        YEAR(o.order_purchase_timestamp) AS Order_Year,
        MONTH(o.order_purchase_timestamp) AS Order_Month,
        SUM(op.payment_value) AS Revenue
    FROM orders o
    JOIN order_payments op
        ON o.order_id = op.order_id
    GROUP BY
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp)
)
SELECT
    Order_Year,
    Order_Month,
    Revenue,
    LAG(Revenue) OVER (
        ORDER BY Order_Year, Order_Month
    ) AS Previous_Month_Revenue,
    Revenue -
    LAG(Revenue) OVER (
        ORDER BY Order_Year, Order_Month
    ) AS Revenue_Growth
FROM MonthlyRevenue;

WITH ProductRevenue AS
(
    SELECT
        p.product_category_name,
        oi.product_id,
        SUM(oi.price) AS Total_Revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY
        p.product_category_name,
        oi.product_id
),
RankedProducts AS
(
    SELECT
        product_category_name,
        product_id,
        Total_Revenue,
        ROW_NUMBER() OVER
        (
            PARTITION BY product_category_name
            ORDER BY Total_Revenue DESC
        ) AS Product_Rank
    FROM ProductRevenue
)
SELECT
    product_category_name,
    product_id,
    Total_Revenue
FROM RankedProducts
WHERE Product_Rank = 1
ORDER BY Total_Revenue DESC;

SELECT
    c.customer_state,
    AVG(CAST(r.review_score AS DECIMAL(3,2))) AS Average_Review_Score,
    COUNT(r.review_id) AS Total_Reviews
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_reviews r
    ON o.order_id = r.order_id
GROUP BY c.customer_state
ORDER BY Average_Review_Score DESC;
