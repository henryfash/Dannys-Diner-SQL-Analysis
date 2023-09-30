
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
    customer_id, COUNT(DISTINCT order_date) 'Number of days'
FROM
    sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT 
    customer_id, product_name
FROM
    (SELECT 
        s.customer_id, MIN(s.order_date), m.product_name
    FROM
        sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY customer_id) AS first_item;

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
WITH subtab AS (SELECT 
    s.customer_id,
    m.product_name,
    COUNT(m.product_name) AS count_name
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY 1 , 2
ORDER BY 1 , 3 DESC)
SELECT 
    customer_id,
    product_name,
    MAX(count_name) number_of_purchase
FROM
    subtab
GROUP BY 1;

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
    WHERE
        s.order_date > mb.join_date
    GROUP BY 1) subtab;

-- 7. Which item was purchased just before the customer became a member?

    
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?