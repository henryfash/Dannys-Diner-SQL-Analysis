
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
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?