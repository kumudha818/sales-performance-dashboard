-- =============================================================================
-- 02_create_tables.sql
-- Purpose : Define all dimension and fact tables using a star schema.
-- Target  : MySQL 8.0
-- Run after: 01_create_database.sql
-- =============================================================================

USE sales_performance;

-- ---------------------------------------------------------------------------
-- DIM: dim_customer
-- One row per unique customer. Avoids duplicating customer data in the fact.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_customer;
CREATE TABLE dim_customer (
    customer_id   VARCHAR(20)  NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    segment       VARCHAR(30)  NOT NULL,   -- Consumer | Corporate | Home Office
    CONSTRAINT pk_dim_customer PRIMARY KEY (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_customer_segment ON dim_customer (segment);

-- ---------------------------------------------------------------------------
-- DIM: dim_product
-- One row per unique product SKU.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product (
    product_id   VARCHAR(20)  NOT NULL,
    category     VARCHAR(50)  NOT NULL,
    sub_category VARCHAR(50)  NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    CONSTRAINT pk_dim_product PRIMARY KEY (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_product_category     ON dim_product (category);
CREATE INDEX idx_product_sub_category ON dim_product (sub_category);

-- ---------------------------------------------------------------------------
-- DIM: dim_date
-- Calendar dimension; supports time-intelligence queries.
-- Populated by 03_import_validation.sql (INSERT INTO ... SELECT).
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date (
    date_key   INT         NOT NULL,   -- YYYYMMDD integer key
    full_date  DATE        NOT NULL,
    year       SMALLINT    NOT NULL,
    quarter    TINYINT     NOT NULL,   -- 1–4
    month      TINYINT     NOT NULL,   -- 1–12
    month_name VARCHAR(10) NOT NULL,
    week       TINYINT     NOT NULL,   -- ISO week 1–53
    day_of_week TINYINT    NOT NULL,   -- 1=Monday … 7=Sunday
    is_weekend  TINYINT    NOT NULL,   -- 0 or 1
    CONSTRAINT pk_dim_date PRIMARY KEY (date_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE UNIQUE INDEX idx_date_full ON dim_date (full_date);

-- ---------------------------------------------------------------------------
-- FACT: fact_sales
-- One row per order line item (granularity = order_id + product_id).
-- row_id preserves the original CSV row for traceability.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS fact_sales;
CREATE TABLE fact_sales (
    row_id         INT           NOT NULL,
    order_id       VARCHAR(30)   NOT NULL,
    order_date_key INT           NOT NULL,   -- FK → dim_date.date_key
    ship_date_key  INT           NOT NULL,   -- FK → dim_date.date_key
    ship_mode      VARCHAR(30)   NOT NULL,
    customer_id    VARCHAR(20)   NOT NULL,   -- FK → dim_customer.customer_id
    country        VARCHAR(50)   NOT NULL DEFAULT 'United States',
    state          VARCHAR(50)   NOT NULL,
    city           VARCHAR(100)  NOT NULL,
    region         VARCHAR(20)   NOT NULL,
    product_id     VARCHAR(20)   NOT NULL,   -- FK → dim_product.product_id
    sales          DECIMAL(12,2) NOT NULL,
    quantity       SMALLINT      NOT NULL,
    discount       DECIMAL(5,4)  NOT NULL,
    profit         DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_fact_sales PRIMARY KEY (row_id),
    CONSTRAINT fk_fact_customer   FOREIGN KEY (customer_id)    REFERENCES dim_customer (customer_id),
    CONSTRAINT fk_fact_product    FOREIGN KEY (product_id)     REFERENCES dim_product  (product_id),
    CONSTRAINT fk_fact_orderdate  FOREIGN KEY (order_date_key) REFERENCES dim_date     (date_key),
    CONSTRAINT fk_fact_shipdate   FOREIGN KEY (ship_date_key)  REFERENCES dim_date     (date_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes to speed up common filters and joins
CREATE INDEX idx_fact_order_id     ON fact_sales (order_id);
CREATE INDEX idx_fact_region       ON fact_sales (region);
CREATE INDEX idx_fact_state        ON fact_sales (state);
CREATE INDEX idx_fact_orderdate    ON fact_sales (order_date_key);
CREATE INDEX idx_fact_customer     ON fact_sales (customer_id);
CREATE INDEX idx_fact_product      ON fact_sales (product_id);

SELECT 'Tables created successfully.' AS status;
