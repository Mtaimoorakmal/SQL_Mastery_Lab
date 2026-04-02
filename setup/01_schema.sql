-- SQL Mastery Lab Schema (PostgreSQL)
-- Run this after creating and connecting to database: sql_mastery_lab

DROP TABLE IF EXISTS website_events CASCADE;
DROP TABLE IF EXISTS returns CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS regions CASCADE;

CREATE TABLE regions (
    region_id      SERIAL PRIMARY KEY,
    region_name    VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE departments (
    department_id  SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    region_id      INT REFERENCES regions(region_id)
);

CREATE TABLE employees (
    employee_id    SERIAL PRIMARY KEY,
    employee_name  VARCHAR(100) NOT NULL,
    email          VARCHAR(150) UNIQUE,
    department_id  INT REFERENCES departments(department_id),
    hire_date      DATE NOT NULL,
    salary         NUMERIC(12,2) NOT NULL CHECK (salary > 0)
);

CREATE TABLE customers (
    customer_id    SERIAL PRIMARY KEY,
    customer_name  VARCHAR(100) NOT NULL,
    email          VARCHAR(150) UNIQUE,
    signup_date    DATE NOT NULL,
    region_id      INT REFERENCES regions(region_id)
);

CREATE TABLE products (
    product_id     SERIAL PRIMARY KEY,
    product_name   VARCHAR(120) NOT NULL,
    category       VARCHAR(80) NOT NULL,
    unit_price     NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    is_active      BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE orders (
    order_id       SERIAL PRIMARY KEY,
    customer_id    INT NOT NULL REFERENCES customers(customer_id),
    order_date     DATE NOT NULL,
    order_status   VARCHAR(30) NOT NULL DEFAULT 'completed',
    order_amount   NUMERIC(12,2) NOT NULL CHECK (order_amount >= 0),
    region_id      INT REFERENCES regions(region_id)
);

CREATE TABLE order_items (
    order_item_id  SERIAL PRIMARY KEY,
    order_id       INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id     INT NOT NULL REFERENCES products(product_id),
    quantity       INT NOT NULL CHECK (quantity > 0),
    unit_price     NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    line_amount    NUMERIC(12,2) NOT NULL CHECK (line_amount >= 0)
);

CREATE TABLE returns (
    return_id      SERIAL PRIMARY KEY,
    order_id       INT NOT NULL REFERENCES orders(order_id),
    customer_id    INT NOT NULL REFERENCES customers(customer_id),
    product_id     INT NOT NULL REFERENCES products(product_id),
    return_date    DATE NOT NULL,
    return_reason  VARCHAR(150)
);

CREATE TABLE website_events (
    event_id       SERIAL PRIMARY KEY,
    customer_id    INT REFERENCES customers(customer_id),
    event_type     VARCHAR(30) NOT NULL CHECK (event_type IN ('visit', 'signup', 'purchase')),
    event_date     DATE NOT NULL,
    session_id     VARCHAR(60) NOT NULL,
    order_id       INT REFERENCES orders(order_id)
);

CREATE INDEX idx_employees_department_id ON employees(department_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_returns_customer_id ON returns(customer_id);
CREATE INDEX idx_returns_order_id ON returns(order_id);
CREATE INDEX idx_website_events_customer_id ON website_events(customer_id);
CREATE INDEX idx_website_events_event_date ON website_events(event_date);
