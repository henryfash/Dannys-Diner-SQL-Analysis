
USE dannys_diner;

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
   s.customer_id, SUM(price) 'Total amount spent'
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id;
    
-- 2. How many days has each customer visited the restaurant?
SELECT 
    customer_id, COUNT(DISTINCT order_date) 'visit days'
FROM
    sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH first_purchase AS (
  SELECT 
    s.customer_id, 
    s.order_date, 
    m.product_name,
    DENSE_RANK() OVER (
      PARTITION BY s.customer_id 
      ORDER BY s.order_date) AS ranks
  FROM sales s
  INNER JOIN menu m
    ON s.product_id = m.product_id
)
SELECT 
  customer_id, 
  product_name
FROM first_purchase
WHERE ranks = 1
GROUP BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
    m.product_name, COUNT(*) number_of_purchase
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY s.product_id
ORDER BY 2 DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH most_popular AS (
  SELECT 
    s.customer_id, 
    m.product_name, 
    COUNT(m.product_id) AS order_count,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS ranks
  FROM menu m
  INNER JOIN sales s
    ON m.product_id = s.product_id
  GROUP BY s.customer_id, m.product_name
)
SELECT 
  customer_id, 
  product_name, 
  order_count
FROM most_popular 
WHERE ranks = 1;

-- 6. Which item was purchased first by the customer after they became a member?

SELECT 
    customer_id, product_name
FROM
    (SELECT 
        s.customer_id, m.product_name, MIN(s.order_date)
    FROM
        sales s
    JOIN menu m ON s.product_id = m.product_id
    JOIN members mb ON s.customer_id = mb.customer_id
    AND
        s.order_date > mb.join_date
    GROUP BY 1) subtab
    ORDER BY customer_id;

-- 7. Which item was purchased just before the customer became a member?
WITH purchased_prior_membership AS (
  SELECT 
    mb.customer_id, 
    s.product_id,
    ROW_NUMBER() OVER (
      PARTITION BY mb.customer_id
      ORDER BY s.order_date DESC) AS ranks
  FROM members mb
  INNER JOIN sales s
    ON mb.customer_id = s.customer_id
    AND s.order_date < mb.join_date
)
SELECT 
  pm.customer_id, 
  m.product_name 
FROM purchased_prior_membership pm
INNER JOIN menu m
  ON pm.product_id = m.product_id
WHERE ranks = 1
ORDER BY pm.customer_id ASC;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
    s.customer_id,
    COUNT(s.order_date) total_items,
    SUM(price) amount_spent
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
        JOIN
    members mb ON s.customer_id = mb.customer_id
WHERE
    s.order_date < mb.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points_gain AS (SELECT 
    s.customer_id,
    CASE
        WHEN s.product_id = 1 THEN price * 10 * 2
        ELSE price * 10
    END AS points
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
)
SELECT 
    customer_id, SUM(points) total_points
FROM
    points_gain
GROUP BY customer_id;

/*
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
- how many points do customer A and B have at the end of January? 
*/

WITH dates_st AS (
  SELECT 
    customer_id, 
    join_date, 
    DATE_ADD(join_date, INTERVAL 6 DAY) AS valid_date, 
    DATE_SUB(DATE_ADD(LAST_DAY('2021-01-31'), INTERVAL 1 MONTH), INTERVAL 1 DAY) AS last_date
  FROM members
)
SELECT 
  s.customer_id, 
  SUM(CASE
    WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
    WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
    ELSE 10 * m.price END) AS total_points
FROM sales s
JOIN dates_st d
  ON s.customer_id = d.customer_id
  AND d.join_date <= s.order_date
  AND s.order_date <= d.last_date
JOIN menu m
  ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;