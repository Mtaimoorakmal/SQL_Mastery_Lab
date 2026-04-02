-- Sanity checks after seeding

SELECT 'regions' AS table_name, COUNT(*) AS row_count FROM regions
UNION ALL
SELECT 'departments', COUNT(*) FROM departments
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'returns', COUNT(*) FROM returns
UNION ALL
SELECT 'website_events', COUNT(*) FROM website_events;

-- Products never sold
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- Employees without department
SELECT employee_id, employee_name
FROM employees
WHERE department_id IS NULL;

-- Customers with returns
SELECT DISTINCT c.customer_id, c.customer_name
FROM customers c
JOIN returns r ON c.customer_id = r.customer_id
ORDER BY c.customer_id;

-- Orders per year
SELECT EXTRACT(YEAR FROM order_date) AS order_year, COUNT(*) AS orders, SUM(order_amount) AS revenue
FROM orders
GROUP BY 1
ORDER BY 1;
