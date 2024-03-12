CREATE DATABASE aditi_restro;

USE aditi_restro;

CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);

CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);

-- Still works without specifying the column names explicitly
INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09'),
    ('C', '2021-03-09'),
    ('D', '2022-01-09');
    
  
--  total amount each customer spent at the restaurant?
 select 
	sum(price) as total_amnt_spent,
    customer_id 
    from sales as s
 join menu as m on s.product_id = m.product_id
 group by customer_id
 ;

-- How many days has each customer visited the restaurant?
select 
	count(distinct s.order_date) as no_of_days,
	s.customer_id
	from sales as s
    join members as m
    on s.customer_id = m.customer_id
    group by s.customer_id;



--  first item from the menu purchased by each customer?
WITH customer_first_purchase AS(
	SELECT s.customer_id, MIN(s.order_date) AS first_purchase_date
	FROM sales s
	GROUP BY s.customer_id
)
SELECT cfp.customer_id, cfp.first_purchase_date, m.product_name
FROM customer_first_purchase cfp
INNER JOIN sales s ON s.customer_id = cfp.customer_id
AND cfp.first_purchase_date = s.order_date
INNER JOIN menu m on m.product_id = s.product_id;

--  most purchased item on the menu and how many times was it purchased by all customers?
select 
	count(*) as total_purchase,
    m.product_name
	FROM sales s
    join menu m on s.product_id = m.product_id
    group by  m.product_name
    order by total_purchase desc
    limit 1;


-- Which item was the most popular for each customer?
with tq as
(select 
	s.customer_id,
    m.product_name,
    count(*) as count_purchased,
    row_number() over(partition by s.customer_id order by count(*) desc) as rank_value 
	from sales s
    join menu m 
    on s.product_id = m.product_id
    group by s.customer_id, m.product_name)
    
    select 
		customer_id,
        product_name ,
        count_purchased
        from tq
        where rank_value = 1;
		
-- Which item was purchased first by the customer after they became a member?

with first_purchase_item_afterjoined as(
select 	
	s.customer_id,
    min(s.order_date) as first_purchase_date
	from sales s
    join members mb on s.customer_id = mb.customer_id
    where s.order_date >= mb.join_date
    group by s.customer_id )
    
    select m.product_name, fpia.customer_id
		from first_purchase_item_afterjoined as fpia
        join sales s on fpia.customer_id = s.customer_id
        and fpia.first_purchase_date = s.order_date
        join menu m on m.product_id = s.product_id ;
    

-- Which item was purchased just before the customer became a member?

WITH last_purchase_before_membership AS (
    SELECT 
    s.customer_id, 
    MAX(s.order_date) AS last_purchase_date
    FROM sales s
    JOIN members mb 
    ON s.customer_id = mb.customer_id
    WHERE s.order_date < mb.join_date
    GROUP BY s.customer_id
)
SELECT 
	lpbm.customer_id, 
	m.product_name
	FROM last_purchase_before_membership lpbm
	JOIN sales s ON lpbm.customer_id = s.customer_id 
	AND lpbm.last_purchase_date = s.order_date
	JOIN menu m ON s.product_id = m.product_id;

--  What is the total items and amount spent for each member before they became a member?

    SELECT s.customer_id, 
    count(*) AS total_items_count,
    sum(price) as amount_spend
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    join members mb on s.customer_id = mb.customer_id
    WHERE s.order_date < mb.join_date
    GROUP BY s.customer_id;



--  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select 
	s.customer_id,
    sum(
    case when m.product_name ='sushi' then m.price*20
    else m.price*10 end ) as total_points
	from sales s
    join menu m on s.product_id = m.product_id
    group by s.customer_id;


-- Recreate the table output using the available data

SELECT s.customer_id, 
s.order_date, 
m.product_name, 
m.price,
CASE WHEN s.order_date >= mb.join_date THEN 'Y'
ELSE 'N' END AS member
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, s.order_date;

