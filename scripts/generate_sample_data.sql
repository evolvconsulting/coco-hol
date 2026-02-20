-- ============================================================================
-- CoCo-Financial Fraud Analytics - Sample Data Generation Script
-- ============================================================================
-- This script generates realistic sample data for the fraud analytics tables
-- 
-- IMPORTANT: Run deploy_fraud_dataset.sql FIRST to create the tables
--
-- Data Generated:
--   - 1,000 customers (Premium, Standard, Basic segments)
--   - 500 merchants across various categories
--   - 1,500 accounts (Checking, Savings, Credit, Investment)
--   - 50,000 transactions over 90 days
--   - 50,000 fraud labels (~4% fraud rate)
--   - 2,500 alerts with various severity levels
--
-- Fraud Patterns Included:
--   - Higher fraud rates in Online channel (~6%)
--   - Card-Not-Present fraud (Mobile/Phone channels)
--   - Velocity attacks (rapid transactions)
--   - Geographic anomalies (international transactions)
--   - Account takeover (high-value transactions)
--
-- KEY LEARNING: DO NOT use RANDOM() directly for arithmetic in Snowflake!
-- RANDOM() returns very large numbers that can overflow.
-- 
-- SAFE PATTERNS:
--   - For random ordering: UNIFORM(0::FLOAT, 1::FLOAT, RANDOM())
--   - For bounded random integers: ABS(MOD(HASH(seed), range))
--   - For random selection: Use HASH with MOD for deterministic randomness
--
-- BAD (will overflow):
--   FLOOR(RANDOM() * 900 + 100)
--
-- GOOD (safe bounded random):
--   ABS(MOD(HASH(row_id || 'seed'), 900)) + 100
-- ============================================================================

USE DATABASE COCO_FINANCIAL;
USE SCHEMA FRAUD_ANALYTICS;

-- ============================================================================
-- SECTION 1: GENERATE CUSTOMERS (1,000 records)
-- ============================================================================

INSERT INTO CUSTOMERS
(CUSTOMER_ID, CUSTOMER_NAME, EMAIL, PHONE, ADDRESS, CITY, STATE, POSTAL_CODE, COUNTRY, DATE_OF_BIRTH, CREATED_AT, CUSTOMER_SEGMENT, RISK_SCORE, IS_ACTIVE)
WITH first_names AS (
    SELECT column1 AS fname, ROW_NUMBER() OVER (ORDER BY 1) AS fn_id FROM VALUES 
    ('James'),('Mary'),('John'),('Patricia'),('Robert'),('Jennifer'),('Michael'),('Linda'),('William'),('Elizabeth'),
    ('David'),('Barbara'),('Richard'),('Susan'),('Joseph'),('Jessica'),('Thomas'),('Sarah'),('Charles'),('Karen'),
    ('Christopher'),('Nancy'),('Daniel'),('Lisa'),('Matthew'),('Betty'),('Anthony'),('Margaret'),('Mark'),('Sandra'),
    ('Donald'),('Ashley'),('Steven'),('Kimberly'),('Paul'),('Emily'),('Andrew'),('Donna'),('Joshua'),('Michelle'),
    ('Kenneth'),('Dorothy'),('Kevin'),('Carol'),('Brian'),('Amanda'),('George'),('Melissa'),('Timothy'),('Deborah')
),
last_names AS (
    SELECT column1 AS lname, ROW_NUMBER() OVER (ORDER BY 1) AS ln_id FROM VALUES 
    ('Smith'),('Johnson'),('Williams'),('Brown'),('Jones'),('Garcia'),('Miller'),('Davis'),('Rodriguez'),('Martinez'),
    ('Hernandez'),('Lopez'),('Gonzalez'),('Wilson'),('Anderson'),('Thomas'),('Taylor'),('Moore'),('Jackson'),('Martin'),
    ('Lee'),('Perez'),('Thompson'),('White'),('Harris'),('Sanchez'),('Clark'),('Ramirez'),('Lewis'),('Robinson'),
    ('Walker'),('Young'),('Allen'),('King'),('Wright'),('Scott'),('Torres'),('Nguyen'),('Hill'),('Flores'),
    ('Green'),('Adams'),('Nelson'),('Baker'),('Hall'),('Rivera'),('Campbell'),('Mitchell'),('Carter'),('Roberts')
),
cities AS (
    SELECT column1 AS city, column2 AS state, column3 AS postal, ROW_NUMBER() OVER (ORDER BY 1) AS c_id FROM VALUES
    ('New York','NY','10001'),('Los Angeles','CA','90001'),('Chicago','IL','60601'),('Houston','TX','77001'),('Phoenix','AZ','85001'),
    ('Philadelphia','PA','19101'),('San Antonio','TX','78201'),('San Diego','CA','92101'),('Dallas','TX','75201'),('San Jose','CA','95101'),
    ('Austin','TX','78701'),('Jacksonville','FL','32099'),('Fort Worth','TX','76101'),('Columbus','OH','43085'),('Charlotte','NC','28201'),
    ('Seattle','WA','98101'),('Denver','CO','80201'),('Boston','MA','02101'),('Nashville','TN','37201'),('Portland','OR','97201'),
    ('Miami','FL','33101'),('Atlanta','GA','30301'),('Las Vegas','NV','89101'),('Detroit','MI','48201'),('Minneapolis','MN','55401')
),
customer_base AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY UNIFORM(0::FLOAT, 1::FLOAT, RANDOM())) AS rn,
        fn.fname,
        ln.lname,
        c.city,
        c.state,
        c.postal
    FROM first_names fn
    CROSS JOIN last_names ln
    CROSS JOIN cities c
    LIMIT 1000
)
SELECT 
    UUID_STRING() AS customer_id,
    cb.fname || ' ' || cb.lname AS customer_name,
    LOWER(cb.fname || '.' || cb.lname || cb.rn || '@email.com') AS email,
    '+1-' || LPAD(ABS(MOD(HASH(cb.rn || 'a'), 900) + 100)::VARCHAR, 3, '0') || '-' || 
    LPAD(ABS(MOD(HASH(cb.rn || 'b'), 900) + 100)::VARCHAR, 3, '0') || '-' || 
    LPAD(ABS(MOD(HASH(cb.rn || 'c'), 9000) + 1000)::VARCHAR, 4, '0') AS phone,
    (ABS(MOD(HASH(cb.rn || 'd'), 9000)) + 100)::VARCHAR || ' ' || 
    CASE ABS(MOD(HASH(cb.rn || 'e'), 5))
        WHEN 0 THEN 'Oak' WHEN 1 THEN 'Maple' WHEN 2 THEN 'Pine' WHEN 3 THEN 'Cedar' ELSE 'Elm' 
    END || ' ' ||
    CASE ABS(MOD(HASH(cb.rn || 'f'), 4))
        WHEN 0 THEN 'Street' WHEN 1 THEN 'Avenue' WHEN 2 THEN 'Drive' ELSE 'Boulevard' 
    END AS address,
    cb.city,
    cb.state,
    cb.postal,
    'USA' AS country,
    DATEADD(DAY, -(ABS(MOD(HASH(cb.rn || 'g'), 25000)) + 6570), CURRENT_DATE()) AS date_of_birth,
    DATEADD(DAY, -ABS(MOD(HASH(cb.rn || 'h'), 1800)), CURRENT_TIMESTAMP()) AS created_at,
    CASE 
        WHEN cb.rn <= 200 THEN 'Premium'
        WHEN cb.rn <= 800 THEN 'Standard'
        ELSE 'Basic'
    END AS customer_segment,
    ROUND(ABS(MOD(HASH(cb.rn || 'i'), 10000)) / 100.0, 2) AS risk_score,
    CASE WHEN ABS(MOD(HASH(cb.rn || 'j'), 100)) < 95 THEN TRUE ELSE FALSE END AS is_active
FROM customer_base cb;

-- ============================================================================
-- SECTION 2: GENERATE MERCHANTS (500 records)
-- ============================================================================

INSERT INTO MERCHANTS
(MERCHANT_ID, MERCHANT_NAME, CATEGORY, MCC_CODE, CITY, COUNTRY, RISK_RATING, IS_VERIFIED, REGISTERED_DATE)
WITH merchant_prefixes AS (
    SELECT column1 AS prefix FROM VALUES 
    ('Quick'),('Express'),('Prime'),('Super'),('Mega'),('Ultra'),('Best'),('First'),('Top'),('Royal'),
    ('Golden'),('Silver'),('Blue'),('Red'),('Green'),('Smart'),('Elite'),('Pro'),('Value'),('Budget')
),
merchant_suffixes AS (
    SELECT column1 AS suffix FROM VALUES 
    ('Mart'),('Shop'),('Store'),('Depot'),('Hub'),('Center'),('Place'),('World'),('Zone'),('Spot'),
    ('Direct'),('Plus'),('Max'),('One'),('Point'),('Stop'),('Way'),('Line'),('Net'),('Link')
),
categories AS (
    SELECT column1 AS cat, column2 AS mcc, column3 AS risk_base FROM VALUES 
    ('Retail',5411,1.5),('Restaurant',5812,1.2),('Gas Station',5541,2.0),('Online Shopping',5999,3.5),
    ('Electronics',5732,2.5),('Travel',4722,2.8),('Entertainment',7922,1.8),('Healthcare',8011,1.0),
    ('Grocery',5411,1.0),('Clothing',5651,1.5),('Automotive',5511,2.0),('Hotel',7011,2.2),
    ('Airline',4511,2.5),('Telecom',4812,1.5),('Subscription',5968,3.0),('Gaming',7994,4.0),
    ('Jewelry',5944,3.5),('Furniture',5712,1.8),('Sports',5941,1.5),('Books',5942,1.0)
),
cities AS (
    SELECT column1 AS city, column2 AS country FROM VALUES
    ('New York','USA'),('Los Angeles','USA'),('Chicago','USA'),('Houston','USA'),('Phoenix','USA'),
    ('Miami','USA'),('Seattle','USA'),('Denver','USA'),('Boston','USA'),('Atlanta','USA'),
    ('Toronto','Canada'),('Vancouver','Canada'),('London','UK'),('Manchester','UK'),('Paris','France'),
    ('Berlin','Germany'),('Tokyo','Japan'),('Sydney','Australia'),('Mumbai','India'),('Singapore','Singapore')
),
merchant_base AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY UNIFORM(0::FLOAT, 1::FLOAT, RANDOM())) AS rn,
        p.prefix,
        s.suffix,
        c.cat,
        c.mcc,
        c.risk_base,
        ci.city,
        ci.country
    FROM merchant_prefixes p
    CROSS JOIN merchant_suffixes s
    CROSS JOIN categories c
    CROSS JOIN cities ci
    LIMIT 500
)
SELECT 
    UUID_STRING() AS merchant_id,
    mb.prefix || ' ' || mb.suffix || ' ' || mb.cat AS merchant_name,
    mb.cat AS category,
    mb.mcc::VARCHAR AS mcc_code,
    mb.city,
    mb.country,
    ROUND(mb.risk_base + (ABS(MOD(HASH(mb.rn), 200)) / 100.0), 2) AS risk_rating,
    CASE WHEN ABS(MOD(HASH(mb.rn || 'v'), 100)) < 85 THEN TRUE ELSE FALSE END AS is_verified,
    DATEADD(DAY, -ABS(MOD(HASH(mb.rn || 'r'), 2000)), CURRENT_TIMESTAMP()) AS registered_date
FROM merchant_base mb;

-- ============================================================================
-- SECTION 3: GENERATE ACCOUNTS (1,500 records)
-- ============================================================================

INSERT INTO ACCOUNTS
(ACCOUNT_ID, CUSTOMER_ID, ACCOUNT_TYPE, ACCOUNT_NUMBER, CURRENCY, BALANCE, CREDIT_LIMIT, OPENED_DATE, STATUS, IS_PRIMARY)
WITH customer_ids AS (
    SELECT CUSTOMER_ID, ROW_NUMBER() OVER (ORDER BY CUSTOMER_ID) AS cust_rn
    FROM CUSTOMERS
),
account_base AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY UNIFORM(0::FLOAT, 1::FLOAT, RANDOM())) AS rn,
        c.CUSTOMER_ID,
        c.cust_rn
    FROM customer_ids c,
    LATERAL (SELECT SEQ4() AS n FROM TABLE(GENERATOR(ROWCOUNT => 3))) g
    LIMIT 1500
)
SELECT 
    UUID_STRING() AS account_id,
    ab.CUSTOMER_ID,
    CASE 
        WHEN ab.rn <= 600 THEN 'Checking'
        WHEN ab.rn <= 1050 THEN 'Savings'
        WHEN ab.rn <= 1350 THEN 'Credit'
        ELSE 'Investment'
    END AS account_type,
    LPAD(ABS(MOD(HASH(ab.rn || 'acct'), 100000000))::VARCHAR, 10, '0') AS account_number,
    'USD' AS currency,
    CASE 
        WHEN ab.rn <= 600 THEN ROUND(ABS(MOD(HASH(ab.rn || 'bal'), 50000)) + 500, 2)
        WHEN ab.rn <= 1050 THEN ROUND(ABS(MOD(HASH(ab.rn || 'bal2'), 100000)) + 1000, 2)
        WHEN ab.rn <= 1350 THEN ROUND(ABS(MOD(HASH(ab.rn || 'bal3'), 5000)), 2)
        ELSE ROUND(ABS(MOD(HASH(ab.rn || 'bal4'), 500000)) + 10000, 2)
    END AS balance,
    CASE 
        WHEN ab.rn > 1050 AND ab.rn <= 1350 THEN ROUND(ABS(MOD(HASH(ab.rn || 'cl'), 20000)) + 5000, 2)
        ELSE NULL
    END AS credit_limit,
    DATEADD(DAY, -ABS(MOD(HASH(ab.rn || 'od'), 1500)), CURRENT_TIMESTAMP()) AS opened_date,
    CASE WHEN ABS(MOD(HASH(ab.rn || 'st'), 100)) < 95 THEN 'Active' ELSE 'Inactive' END AS status,
    CASE WHEN MOD(ab.rn, 3) = 1 THEN TRUE ELSE FALSE END AS is_primary
FROM account_base ab;

-- ============================================================================
-- SECTION 4: GENERATE TRANSACTIONS (50,000 records)
-- ============================================================================

INSERT INTO TRANSACTIONS
(TRANSACTION_ID, ACCOUNT_ID, MERCHANT_ID, TRANSACTION_TIMESTAMP, AMOUNT, CURRENCY, TRANSACTION_TYPE, 
 CHANNEL, DESCRIPTION, LOCATION_CITY, LOCATION_COUNTRY, LATITUDE, LONGITUDE, DEVICE_TYPE, IP_ADDRESS, STATUS, REFERENCE_ID)
WITH accounts AS (
    SELECT ACCOUNT_ID, ROW_NUMBER() OVER (ORDER BY ACCOUNT_ID) AS acc_rn
    FROM ACCOUNTS
    WHERE STATUS = 'Active'
),
merchants AS (
    SELECT MERCHANT_ID, CATEGORY, CITY, COUNTRY, ROW_NUMBER() OVER (ORDER BY MERCHANT_ID) AS mer_rn
    FROM MERCHANTS
),
base_transactions AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY UNIFORM(0::FLOAT, 1::FLOAT, RANDOM())) AS rn,
        a.ACCOUNT_ID,
        m.MERCHANT_ID,
        m.CATEGORY,
        m.CITY AS mer_city,
        m.COUNTRY AS mer_country
    FROM accounts a
    CROSS JOIN merchants m
    LIMIT 50000
)
SELECT 
    UUID_STRING() AS transaction_id,
    bt.ACCOUNT_ID,
    bt.MERCHANT_ID,
    -- Spread transactions over last 90 days (7776000 seconds)
    DATEADD(SECOND, 
        -ABS(MOD(HASH(bt.rn || 'ts'), 7776000)),
        CURRENT_TIMESTAMP()
    ) AS transaction_timestamp,
    -- Realistic amount distribution: 60% small, 25% medium, 10% large, 5% very large
    CASE 
        WHEN ABS(MOD(HASH(bt.rn || 'amt'), 100)) < 60 THEN ROUND(ABS(MOD(HASH(bt.rn || 'a1'), 200)) + 5, 2)
        WHEN ABS(MOD(HASH(bt.rn || 'amt'), 100)) < 85 THEN ROUND(ABS(MOD(HASH(bt.rn || 'a2'), 1000)) + 50, 2)
        WHEN ABS(MOD(HASH(bt.rn || 'amt'), 100)) < 95 THEN ROUND(ABS(MOD(HASH(bt.rn || 'a3'), 5000)) + 200, 2)
        ELSE ROUND(ABS(MOD(HASH(bt.rn || 'a4'), 20000)) + 1000, 2)
    END AS amount,
    'USD' AS currency,
    CASE ABS(MOD(HASH(bt.rn || 'tt'), 6))
        WHEN 0 THEN 'Purchase' WHEN 1 THEN 'Withdrawal' WHEN 2 THEN 'Transfer'
        WHEN 3 THEN 'Payment' WHEN 4 THEN 'Refund' ELSE 'Deposit'
    END AS transaction_type,
    -- 40% Online, 30% In-Store, 10% Mobile, 10% ATM, 10% Phone
    CASE ABS(MOD(HASH(bt.rn || 'ch'), 10))
        WHEN 0 THEN 'Online' WHEN 1 THEN 'Online' WHEN 2 THEN 'Online' WHEN 3 THEN 'Online'
        WHEN 4 THEN 'In-Store' WHEN 5 THEN 'In-Store' WHEN 6 THEN 'In-Store'
        WHEN 7 THEN 'Mobile' WHEN 8 THEN 'ATM' ELSE 'Phone'
    END AS channel,
    bt.CATEGORY || ' transaction' AS description,
    bt.mer_city AS location_city,
    bt.mer_country AS location_country,
    ROUND(30 + ABS(MOD(HASH(bt.rn || 'lat'), 2000)) / 100.0, 6) AS latitude,
    ROUND(-120 + ABS(MOD(HASH(bt.rn || 'lon'), 5000)) / 100.0, 6) AS longitude,
    CASE ABS(MOD(HASH(bt.rn || 'dev'), 5))
        WHEN 0 THEN 'Desktop' WHEN 1 THEN 'Mobile' WHEN 2 THEN 'Tablet'
        WHEN 3 THEN 'POS Terminal' ELSE 'ATM'
    END AS device_type,
    ABS(MOD(HASH(bt.rn || 'ip1'), 223) + 1)::VARCHAR || '.' ||
    ABS(MOD(HASH(bt.rn || 'ip2'), 255))::VARCHAR || '.' ||
    ABS(MOD(HASH(bt.rn || 'ip3'), 255))::VARCHAR || '.' ||
    ABS(MOD(HASH(bt.rn || 'ip4'), 255))::VARCHAR AS ip_address,
    CASE WHEN ABS(MOD(HASH(bt.rn || 'stat'), 100)) < 97 THEN 'Completed' 
         WHEN ABS(MOD(HASH(bt.rn || 'stat'), 100)) < 99 THEN 'Pending'
         ELSE 'Failed' 
    END AS status,
    UUID_STRING() AS reference_id
FROM base_transactions bt;

-- ============================================================================
-- SECTION 5: GENERATE FRAUD LABELS (50,000 records, ~4% fraud rate)
-- ============================================================================

INSERT INTO FRAUD_LABELS
(LABEL_ID, TRANSACTION_ID, IS_FRAUD, FRAUD_TYPE, CONFIDENCE_SCORE, DETECTION_METHOD, LABELED_AT, LABELED_BY, NOTES)
WITH transaction_data AS (
    SELECT 
        TRANSACTION_ID,
        AMOUNT,
        CHANNEL,
        DEVICE_TYPE,
        LOCATION_COUNTRY,
        TRANSACTION_TIMESTAMP,
        ROW_NUMBER() OVER (ORDER BY TRANSACTION_ID) AS rn,
        -- Fraud scoring based on realistic patterns
        CASE 
            -- Higher fraud rate for Online channel (5% vs 1% for others)
            WHEN CHANNEL = 'Online' THEN 5
            -- Higher fraud for large amounts
            WHEN AMOUNT > 2000 THEN 4
            -- Card-not-present (Mobile/Phone)
            WHEN CHANNEL IN ('Mobile', 'Phone') THEN 3
            ELSE 1
        END AS fraud_likelihood,
        -- Geographic anomaly - international transactions
        CASE WHEN LOCATION_COUNTRY != 'USA' THEN 2 ELSE 0 END AS geo_risk
    FROM TRANSACTIONS
),
labeled_transactions AS (
    SELECT 
        td.*,
        -- Overall ~4% fraud rate, weighted by risk factors
        CASE 
            WHEN ABS(MOD(HASH(td.TRANSACTION_ID), 100)) < (td.fraud_likelihood + td.geo_risk) THEN TRUE
            ELSE FALSE
        END AS is_fraud_flag
    FROM transaction_data td
)
SELECT 
    UUID_STRING() AS label_id,
    lt.TRANSACTION_ID,
    lt.is_fraud_flag AS is_fraud,
    CASE 
        WHEN NOT lt.is_fraud_flag THEN NULL
        WHEN lt.CHANNEL = 'Online' AND lt.AMOUNT > 1000 THEN 'Card-Not-Present'
        WHEN lt.AMOUNT > 5000 THEN 'Account Takeover'
        WHEN lt.geo_risk > 0 THEN 'Geographic Anomaly'
        WHEN lt.CHANNEL IN ('Mobile', 'Phone') THEN 'Card-Not-Present'
        WHEN ABS(MOD(HASH(lt.TRANSACTION_ID || 'vel'), 3)) = 0 THEN 'Velocity Attack'
        ELSE 'Suspicious Activity'
    END AS fraud_type,
    CASE 
        WHEN NOT lt.is_fraud_flag THEN NULL
        ELSE ROUND(70 + ABS(MOD(HASH(lt.TRANSACTION_ID || 'conf'), 3000)) / 100.0, 2)
    END AS confidence_score,
    CASE 
        WHEN NOT lt.is_fraud_flag THEN 'None'
        WHEN ABS(MOD(HASH(lt.TRANSACTION_ID || 'det'), 5)) = 0 THEN 'ML Model'
        WHEN ABS(MOD(HASH(lt.TRANSACTION_ID || 'det'), 5)) = 1 THEN 'Rule Engine'
        WHEN ABS(MOD(HASH(lt.TRANSACTION_ID || 'det'), 5)) = 2 THEN 'Manual Review'
        WHEN ABS(MOD(HASH(lt.TRANSACTION_ID || 'det'), 5)) = 3 THEN 'Customer Report'
        ELSE 'Behavioral Analysis'
    END AS detection_method,
    DATEADD(MINUTE, ABS(MOD(HASH(lt.TRANSACTION_ID || 'lab'), 60)) + 1, lt.TRANSACTION_TIMESTAMP) AS labeled_at,
    CASE ABS(MOD(HASH(lt.TRANSACTION_ID || 'by'), 5))
        WHEN 0 THEN 'fraud_system'
        WHEN 1 THEN 'analyst_team'
        WHEN 2 THEN 'ml_pipeline'
        WHEN 3 THEN 'review_queue'
        ELSE 'automated_check'
    END AS labeled_by,
    CASE 
        WHEN NOT lt.is_fraud_flag THEN NULL
        ELSE 'Flagged for: ' || 
            CASE 
                WHEN lt.CHANNEL = 'Online' THEN 'online transaction risk'
                WHEN lt.AMOUNT > 2000 THEN 'high value transaction'
                WHEN lt.geo_risk > 0 THEN 'international transaction'
                ELSE 'pattern deviation'
            END
    END AS notes
FROM labeled_transactions lt;

-- ============================================================================
-- SECTION 6: GENERATE ALERTS (2,500 records)
-- ============================================================================

INSERT INTO ALERTS
(ALERT_ID, TRANSACTION_ID, ACCOUNT_ID, CUSTOMER_ID, ALERT_TIMESTAMP, ALERT_TYPE, SEVERITY, STATUS, 
 DESCRIPTION, RISK_SCORE, RESOLVED_AT, RESOLVED_BY, RESOLUTION_NOTES)
WITH fraud_transactions AS (
    SELECT 
        t.TRANSACTION_ID,
        t.ACCOUNT_ID,
        a.CUSTOMER_ID,
        t.TRANSACTION_TIMESTAMP,
        t.AMOUNT,
        t.CHANNEL,
        t.LOCATION_COUNTRY,
        fl.FRAUD_TYPE,
        fl.CONFIDENCE_SCORE,
        ROW_NUMBER() OVER (ORDER BY UNIFORM(0::FLOAT, 1::FLOAT, RANDOM())) AS rn
    FROM TRANSACTIONS t
    JOIN ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
    JOIN FRAUD_LABELS fl ON t.TRANSACTION_ID = fl.TRANSACTION_ID
    WHERE fl.IS_FRAUD = TRUE OR ABS(MOD(HASH(t.TRANSACTION_ID), 50)) = 0
    LIMIT 2500
)
SELECT 
    UUID_STRING() AS alert_id,
    ft.TRANSACTION_ID,
    ft.ACCOUNT_ID,
    ft.CUSTOMER_ID,
    DATEADD(SECOND, ABS(MOD(HASH(ft.TRANSACTION_ID || 'alert'), 300)) + 10, ft.TRANSACTION_TIMESTAMP) AS alert_timestamp,
    CASE 
        WHEN ft.FRAUD_TYPE IS NOT NULL THEN ft.FRAUD_TYPE
        WHEN ft.AMOUNT > 5000 THEN 'High Value Transaction'
        WHEN ft.CHANNEL = 'Online' THEN 'Online Activity Alert'
        WHEN ft.LOCATION_COUNTRY != 'USA' THEN 'International Transaction'
        WHEN ABS(MOD(HASH(ft.TRANSACTION_ID || 'at'), 4)) = 0 THEN 'Unusual Pattern'
        WHEN ABS(MOD(HASH(ft.TRANSACTION_ID || 'at'), 4)) = 1 THEN 'Velocity Alert'
        WHEN ABS(MOD(HASH(ft.TRANSACTION_ID || 'at'), 4)) = 2 THEN 'New Device Login'
        ELSE 'Account Activity Alert'
    END AS alert_type,
    CASE 
        WHEN ft.CONFIDENCE_SCORE > 90 OR ft.AMOUNT > 10000 THEN 'Critical'
        WHEN ft.CONFIDENCE_SCORE > 80 OR ft.AMOUNT > 5000 THEN 'High'
        WHEN ft.CONFIDENCE_SCORE > 70 OR ft.AMOUNT > 2000 THEN 'Medium'
        ELSE 'Low'
    END AS severity,
    CASE ABS(MOD(HASH(ft.TRANSACTION_ID || 'status'), 10))
        WHEN 0 THEN 'Open'
        WHEN 1 THEN 'Open'
        WHEN 2 THEN 'Open'
        WHEN 3 THEN 'Under Review'
        WHEN 4 THEN 'Under Review'
        WHEN 5 THEN 'Escalated'
        WHEN 6 THEN 'Resolved'
        WHEN 7 THEN 'Resolved'
        WHEN 8 THEN 'Resolved'
        ELSE 'Closed'
    END AS status,
    'Alert generated for ' || 
    CASE 
        WHEN ft.FRAUD_TYPE IS NOT NULL THEN 'confirmed fraud: ' || ft.FRAUD_TYPE
        WHEN ft.AMOUNT > 5000 THEN 'high value transaction of $' || ft.AMOUNT::VARCHAR
        WHEN ft.CHANNEL = 'Online' THEN 'suspicious online activity'
        ELSE 'unusual account activity'
    END AS description,
    COALESCE(ft.CONFIDENCE_SCORE, ROUND(40 + ABS(MOD(HASH(ft.TRANSACTION_ID || 'rs'), 5000)) / 100.0, 2)) AS risk_score,
    CASE 
        WHEN ABS(MOD(HASH(ft.TRANSACTION_ID || 'status'), 10)) >= 6 
        THEN DATEADD(HOUR, ABS(MOD(HASH(ft.TRANSACTION_ID || 'res'), 72)) + 1, ft.TRANSACTION_TIMESTAMP)
        ELSE NULL
    END AS resolved_at,
    CASE 
        WHEN ABS(MOD(HASH(ft.TRANSACTION_ID || 'status'), 10)) >= 6 
        THEN CASE ABS(MOD(HASH(ft.TRANSACTION_ID || 'rb'), 4))
            WHEN 0 THEN 'john.smith@bank.com'
            WHEN 1 THEN 'jane.doe@bank.com'
            WHEN 2 THEN 'fraud.team@bank.com'
            ELSE 'auto.resolution@bank.com'
        END
        ELSE NULL
    END AS resolved_by,
    CASE 
        WHEN ABS(MOD(HASH(ft.TRANSACTION_ID || 'status'), 10)) >= 6 
        THEN CASE ABS(MOD(HASH(ft.TRANSACTION_ID || 'rn'), 4))
            WHEN 0 THEN 'Confirmed as legitimate transaction after customer verification'
            WHEN 1 THEN 'Fraud confirmed - account secured and customer notified'
            WHEN 2 THEN 'False positive - normal customer behavior'
            ELSE 'Investigated and cleared - no action required'
        END
        ELSE NULL
    END AS resolution_notes
FROM fraud_transactions ft;

-- ============================================================================
-- SECTION 7: VERIFICATION
-- ============================================================================

SELECT 'Data Generation Complete!' AS status;

SELECT 
    'CUSTOMERS' AS table_name, COUNT(*) AS row_count FROM CUSTOMERS
UNION ALL SELECT 'ACCOUNTS', COUNT(*) FROM ACCOUNTS
UNION ALL SELECT 'MERCHANTS', COUNT(*) FROM MERCHANTS
UNION ALL SELECT 'TRANSACTIONS', COUNT(*) FROM TRANSACTIONS
UNION ALL SELECT 'FRAUD_LABELS', COUNT(*) FROM FRAUD_LABELS
UNION ALL SELECT 'ALERTS', COUNT(*) FROM ALERTS
ORDER BY table_name;

-- Fraud statistics
SELECT 
    'Overall Fraud Rate' AS metric,
    ROUND(SUM(CASE WHEN IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) || '%' AS value
FROM FRAUD_LABELS;

-- Fraud by channel
SELECT 
    t.CHANNEL,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN fl.IS_FRAUD THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(SUM(CASE WHEN fl.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM TRANSACTIONS t
JOIN FRAUD_LABELS fl ON t.TRANSACTION_ID = fl.TRANSACTION_ID
GROUP BY t.CHANNEL
ORDER BY fraud_rate_pct DESC;
