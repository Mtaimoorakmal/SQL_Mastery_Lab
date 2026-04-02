-- Q1: Find duplicate records in a table
-- PostgreSQL
-- Goal: practice multiple ways to detect duplicates in a realistic staging/import table.

-- =========================================================
-- 0) Why use a staging table?
-- =========================================================
-- In the main practice schema, many columns are protected by PK/UNIQUE constraints,
-- so true duplicates are less likely in cleaned tables.
-- In real projects, duplicates usually appear in raw/staging/import tables.

DROP TABLE IF EXISTS customer_staging;

CREATE TABLE customer_staging (
    row_id         SERIAL PRIMARY KEY,
    customer_name  VARCHAR(100),
    email          VARCHAR(150),
    signup_date    DATE,
    region_id      INT
);

INSERT INTO customer_staging (customer_name, email, signup_date, region_id) VALUES
('Customer A', 'ca@example.com', '2022-12-20', 1),
('Customer B', 'cb@example.com', '2023-01-05', 1),
('Customer C', 'cc@example.com', '2023-02-15', 2),
('Customer A', 'ca@example.com', '2022-12-20', 1), -- duplicate
('Customer D', 'cd@example.com', '2023-03-10', 3),
('Customer E', 'ce@example.com', '2023-04-12', 4),
('Customer B', 'cb@example.com', '2023-01-05', 1), -- duplicate
('Customer B', 'cb@example.com', '2023-01-05', 1), -- duplicate again
('Customer F', NULL, '2023-05-18', 1),
('Customer F', NULL, '2023-05-18', 1), -- duplicate with NULL email
('Customer G', 'cg@example.com', '2023-06-01', 2),
('Customer G', 'cg@example.com', '2023-06-02', 2); -- not exact duplicate

-- =========================================================
-- 1) Find duplicate combinations (most common interview answer)
-- =========================================================
SELECT
    customer_name,
    email,
    signup_date,
    region_id,
    COUNT(*) AS duplicate_count
FROM customer_staging
GROUP BY customer_name, email, signup_date, region_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, customer_name;

-- =========================================================
-- 2) Show full duplicate rows using GROUP BY + JOIN
-- =========================================================
WITH duplicate_keys AS (
    SELECT
        customer_name,
        email,
        signup_date,
        region_id
    FROM customer_staging
    GROUP BY customer_name, email, signup_date, region_id
    HAVING COUNT(*) > 1
)
SELECT cs.*
FROM customer_staging cs
JOIN duplicate_keys dk
    ON cs.customer_name IS NOT DISTINCT FROM dk.customer_name
   AND cs.email         IS NOT DISTINCT FROM dk.email
   AND cs.signup_date   IS NOT DISTINCT FROM dk.signup_date
   AND cs.region_id     IS NOT DISTINCT FROM dk.region_id
ORDER BY cs.customer_name, cs.email, cs.signup_date, cs.row_id;

-- =========================================================
-- 3) Show duplicates using ROW_NUMBER()
-- Keeps the first occurrence and marks later rows as duplicates.
-- =========================================================
SELECT *
FROM (
    SELECT
        cs.*,
        ROW_NUMBER() OVER (
            PARTITION BY customer_name, email, signup_date, region_id
            ORDER BY row_id
        ) AS rn
    FROM customer_staging cs
) t
WHERE rn > 1
ORDER BY customer_name, email, signup_date, row_id;

-- =========================================================
-- 4) Show duplicates using a self-join
-- Useful for understanding pairwise duplicate logic.
-- =========================================================
SELECT
    a.row_id AS original_row_id,
    b.row_id AS duplicate_row_id,
    a.customer_name,
    a.email,
    a.signup_date,
    a.region_id
FROM customer_staging a
JOIN customer_staging b
    ON a.row_id < b.row_id
   AND a.customer_name IS NOT DISTINCT FROM b.customer_name
   AND a.email         IS NOT DISTINCT FROM b.email
   AND a.signup_date   IS NOT DISTINCT FROM b.signup_date
   AND a.region_id     IS NOT DISTINCT FROM b.region_id
ORDER BY a.customer_name, a.row_id, b.row_id;

-- =========================================================
-- 5) Show duplicates using EXISTS
-- =========================================================
SELECT cs.*
FROM customer_staging cs
WHERE EXISTS (
    SELECT 1
    FROM customer_staging x
    WHERE x.row_id < cs.row_id
      AND x.customer_name IS NOT DISTINCT FROM cs.customer_name
      AND x.email         IS NOT DISTINCT FROM cs.email
      AND x.signup_date   IS NOT DISTINCT FROM cs.signup_date
      AND x.region_id     IS NOT DISTINCT FROM cs.region_id
)
ORDER BY cs.customer_name, cs.row_id;

-- =========================================================
-- 6) Count total duplicate rows excluding the first occurrence
-- Example: if a record appears 3 times, duplicates counted = 2
-- =========================================================
SELECT SUM(cnt - 1) AS total_extra_duplicate_rows
FROM (
    SELECT COUNT(*) AS cnt
    FROM customer_staging
    GROUP BY customer_name, email, signup_date, region_id
    HAVING COUNT(*) > 1
) d;

-- =========================================================
-- 7) Delete duplicates and keep only the first row
-- IMPORTANT: review with SELECT first before running DELETE
-- =========================================================
WITH ranked AS (
    SELECT
        row_id,
        ROW_NUMBER() OVER (
            PARTITION BY customer_name, email, signup_date, region_id
            ORDER BY row_id
        ) AS rn
    FROM customer_staging
)
-- DELETE FROM customer_staging
-- WHERE row_id IN (
--     SELECT row_id
--     FROM ranked
--     WHERE rn > 1
-- );
SELECT *
FROM ranked
WHERE rn > 1
ORDER BY row_id;

-- =========================================================
-- 8) Variant: duplicates by business key only (email)
-- Sometimes exact rows differ, but business key should be unique.
-- =========================================================
SELECT
    email,
    COUNT(*) AS duplicate_count
FROM customer_staging
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, email;

-- =========================================================
-- 9) Add a UNIQUE constraint after cleanup
-- =========================================================
-- ALTER TABLE customer_staging
-- ADD CONSTRAINT uq_customer_staging_email UNIQUE (email);
