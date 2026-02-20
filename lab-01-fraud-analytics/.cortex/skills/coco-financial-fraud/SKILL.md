---
name: coco-financial-fraud
description: "Fraud analytics skill for CoCo-Financial. Use for: analyzing fraud patterns, investigating suspicious transactions, generating fraud reports, risk assessment, velocity checks, geographic anomalies, time-based analysis, device fingerprinting. Triggers: fraud analysis, suspicious transactions, fraud patterns, risk assessment, fraud report, investigate fraud, velocity attack, rapid transactions, impossible travel, geographic anomaly, night fraud, time patterns, device fingerprint, device analysis."
---

# CoCo-Financial Fraud Analytics Skill

## Overview

This skill provides workflows for fraud analysis and investigation in the CoCo-Financial fraud analytics dataset. It helps analysts identify patterns, investigate suspicious activity, and generate reports.

## Prerequisites

- COCO_FINANCIAL database deployed
- Access to FRAUD_ANALYTICS schema
- Tables: CUSTOMERS, ACCOUNTS, TRANSACTIONS, MERCHANTS, FRAUD_LABELS, ALERTS

## Workflow Selection

Based on user intent, route to the appropriate workflow:

| Intent | Triggers | Workflow |
|--------|----------|----------|
| Pattern Analysis | "fraud patterns", "trends", "analysis" | [Pattern Analysis](#workflow-1-fraud-pattern-analysis) |
| Investigation | "investigate", "suspicious", "look into" | [Transaction Investigation](#workflow-2-transaction-investigation) |
| Reporting | "report", "summary", "metrics" | [Fraud Reporting](#workflow-3-fraud-reporting) |
| Risk Assessment | "risk", "score", "high risk" | [Risk Assessment](#workflow-4-risk-assessment) |
| Velocity Detection | "velocity", "rapid", "successive", "burst" | [Velocity Analysis](#workflow-5-velocity-analysis) |
| Geographic Anomaly | "geographic", "impossible travel", "location" | [Geographic Anomaly Detection](#workflow-6-geographic-anomaly-detection) |
| Time-Based Analysis | "night", "day", "time pattern", "hourly" | [Time-Based Pattern Analysis](#workflow-7-time-based-pattern-analysis) |
| Device Analysis | "device", "fingerprint", "IP", "browser" | [Device Fingerprint Analysis](#workflow-8-device-fingerprint-analysis) |

---

## Workflow 1: Fraud Pattern Analysis

**Goal:** Identify fraud patterns and trends in the transaction data.

### Step 1: Gather Analysis Parameters

Ask the user:
1. Time period to analyze (default: last 30 days)
2. Specific focus area (channel, merchant category, geography, or all)
3. Minimum transaction threshold (default: 100 transactions)

### Step 2: Run Pattern Analysis Queries

Execute these analyses based on user parameters:

**Channel-based patterns:**
```sql
SELECT 
    t.CHANNEL,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate,
    SUM(CASE WHEN f.IS_FRAUD THEN t.AMOUNT ELSE 0 END) as fraud_amount
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
WHERE t.TRANSACTION_TIMESTAMP >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY t.CHANNEL
ORDER BY fraud_rate DESC;
```

**Time-based patterns (hourly):**
```sql
SELECT 
    HOUR(t.TRANSACTION_TIMESTAMP) as hour_of_day,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
GROUP BY HOUR(t.TRANSACTION_TIMESTAMP)
ORDER BY fraud_rate DESC;
```

**Geographic patterns:**
```sql
SELECT 
    t.LOCATION_COUNTRY,
    t.LOCATION_CITY,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
GROUP BY t.LOCATION_COUNTRY, t.LOCATION_CITY
HAVING COUNT(*) >= 100
ORDER BY fraud_rate DESC
LIMIT 20;
```

### Step 3: Present Findings

Present findings with:
- Key fraud rate metrics by dimension
- Identified high-risk patterns
- Recommendations for rule updates
- Visualizations if requested

---

## Workflow 2: Transaction Investigation

**Goal:** Investigate specific suspicious transactions or customer activity.

### Step 1: Identify Investigation Target

Ask the user for one of:
- Transaction ID
- Customer ID or name
- Account ID
- Alert ID
- Time range + criteria

### Step 2: Gather Transaction Context

**For specific transaction:**
```sql
SELECT 
    t.*,
    c.CUSTOMER_NAME,
    c.CUSTOMER_SEGMENT,
    c.RISK_SCORE as customer_risk,
    m.MERCHANT_NAME,
    m.CATEGORY as merchant_category,
    m.RISK_RATING as merchant_risk,
    f.IS_FRAUD,
    f.FRAUD_TYPE,
    f.CONFIDENCE_SCORE,
    f.DETECTION_METHOD
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.CUSTOMERS c ON a.CUSTOMER_ID = c.CUSTOMER_ID
LEFT JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.MERCHANTS m ON t.MERCHANT_ID = m.MERCHANT_ID
LEFT JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
WHERE t.TRANSACTION_ID = '<transaction_id>';
```

**For customer investigation:**
```sql
-- Recent transactions
SELECT 
    t.TRANSACTION_TIMESTAMP,
    t.AMOUNT,
    t.TRANSACTION_TYPE,
    t.CHANNEL,
    t.LOCATION_CITY,
    m.MERCHANT_NAME,
    f.IS_FRAUD,
    f.FRAUD_TYPE
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.CUSTOMERS c ON a.CUSTOMER_ID = c.CUSTOMER_ID
LEFT JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.MERCHANTS m ON t.MERCHANT_ID = m.MERCHANT_ID
LEFT JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
WHERE c.CUSTOMER_ID = '<customer_id>'
ORDER BY t.TRANSACTION_TIMESTAMP DESC
LIMIT 50;
```

### Step 3: Velocity Check

Check for rapid successive transactions:
```sql
SELECT 
    t1.TRANSACTION_ID,
    t1.TRANSACTION_TIMESTAMP,
    t1.AMOUNT,
    t1.LOCATION_CITY,
    COUNT(*) OVER (
        PARTITION BY a.CUSTOMER_ID 
        ORDER BY t1.TRANSACTION_TIMESTAMP 
        RANGE BETWEEN INTERVAL '1 hour' PRECEDING AND CURRENT ROW
    ) as txn_in_last_hour
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t1
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t1.ACCOUNT_ID = a.ACCOUNT_ID
WHERE a.CUSTOMER_ID = '<customer_id>'
ORDER BY t1.TRANSACTION_TIMESTAMP DESC;
```

### Step 4: Geographic Anomaly Check

Check for impossible travel:
```sql
WITH txn_sequence AS (
    SELECT 
        t.TRANSACTION_ID,
        t.TRANSACTION_TIMESTAMP,
        t.LOCATION_CITY,
        t.LOCATION_COUNTRY,
        LAG(t.LOCATION_CITY) OVER (ORDER BY t.TRANSACTION_TIMESTAMP) as prev_city,
        LAG(t.TRANSACTION_TIMESTAMP) OVER (ORDER BY t.TRANSACTION_TIMESTAMP) as prev_time,
        TIMESTAMPDIFF('minute', 
            LAG(t.TRANSACTION_TIMESTAMP) OVER (ORDER BY t.TRANSACTION_TIMESTAMP),
            t.TRANSACTION_TIMESTAMP
        ) as minutes_since_last
    FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
    WHERE a.CUSTOMER_ID = '<customer_id>'
)
SELECT * FROM txn_sequence
WHERE prev_city IS NOT NULL 
  AND prev_city != LOCATION_CITY 
  AND minutes_since_last < 60;
```

### Step 5: Present Investigation Report

Present:
- Transaction details and context
- Customer profile and history
- Red flags identified
- Related alerts
- Recommended action

---

## Workflow 3: Fraud Reporting

**Goal:** Generate fraud metrics reports for stakeholders.

### Step 1: Determine Report Type

Ask user for:
1. Report type: Daily, Weekly, Monthly, or Custom
2. Time period
3. Report focus: Executive summary, Detailed metrics, or Both

### Step 2: Generate Report Data

**Executive Summary Metrics:**
```sql
SELECT 
    COUNT(DISTINCT t.TRANSACTION_ID) as total_transactions,
    SUM(t.AMOUNT) as total_volume,
    COUNT(CASE WHEN f.IS_FRAUD THEN 1 END) as fraud_count,
    SUM(CASE WHEN f.IS_FRAUD THEN t.AMOUNT ELSE 0 END) as fraud_amount,
    ROUND(COUNT(CASE WHEN f.IS_FRAUD THEN 1 END) * 100.0 / COUNT(*), 4) as fraud_rate_pct,
    COUNT(DISTINCT a.ALERT_ID) as total_alerts,
    COUNT(CASE WHEN a.STATUS = 'Resolved' THEN 1 END) as resolved_alerts,
    COUNT(CASE WHEN a.SEVERITY = 'Critical' THEN 1 END) as critical_alerts
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
LEFT JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
LEFT JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ALERTS a ON t.TRANSACTION_ID = a.TRANSACTION_ID
WHERE t.TRANSACTION_TIMESTAMP >= DATEADD('day', -30, CURRENT_TIMESTAMP());
```

**Fraud by Type:**
```sql
SELECT 
    f.FRAUD_TYPE,
    COUNT(*) as count,
    SUM(t.AMOUNT) as total_amount,
    AVG(t.AMOUNT) as avg_amount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pct_of_total
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t ON f.TRANSACTION_ID = t.TRANSACTION_ID
WHERE f.IS_FRAUD = TRUE
GROUP BY f.FRAUD_TYPE
ORDER BY count DESC;
```

**Daily Trend:**
```sql
SELECT 
    DATE(t.TRANSACTION_TIMESTAMP) as date,
    COUNT(*) as transactions,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 4) as fraud_rate
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
WHERE t.TRANSACTION_TIMESTAMP >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY DATE(t.TRANSACTION_TIMESTAMP)
ORDER BY date;
```

### Step 3: Format and Present Report

Generate a formatted report including:
- Executive summary with key metrics
- Trend charts (if visualization requested)
- Breakdown by fraud type, channel, geography
- Comparison to previous period
- Action items and recommendations

---

## Workflow 4: Risk Assessment

**Goal:** Assess and score risk for customers, merchants, or transactions.

### Step 1: Determine Assessment Scope

Ask user:
1. Assessment type: Customer, Merchant, or Transaction
2. Specific entity or batch assessment
3. Risk threshold for flagging (default: 70)

### Step 2: Run Risk Assessment

**Customer Risk Assessment:**
```sql
SELECT 
    c.CUSTOMER_ID,
    c.CUSTOMER_NAME,
    c.CUSTOMER_SEGMENT,
    c.RISK_SCORE as current_risk_score,
    COUNT(DISTINCT t.TRANSACTION_ID) as total_transactions,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    COUNT(DISTINCT al.ALERT_ID) as alert_count,
    -- Calculated risk factors
    CASE 
        WHEN SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) > 5 THEN 30
        WHEN SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) > 2 THEN 20
        WHEN SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) > 0 THEN 10
        ELSE 0 
    END +
    CASE WHEN COUNT(DISTINCT al.ALERT_ID) > 10 THEN 25 ELSE COUNT(DISTINCT al.ALERT_ID) * 2.5 END +
    c.RISK_SCORE * 0.5 as calculated_risk_score
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.CUSTOMERS c
LEFT JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON c.CUSTOMER_ID = a.CUSTOMER_ID
LEFT JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t ON a.ACCOUNT_ID = t.ACCOUNT_ID
LEFT JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
LEFT JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ALERTS al ON c.CUSTOMER_ID = al.CUSTOMER_ID
GROUP BY c.CUSTOMER_ID, c.CUSTOMER_NAME, c.CUSTOMER_SEGMENT, c.RISK_SCORE
HAVING calculated_risk_score >= 70
ORDER BY calculated_risk_score DESC;
```

**Merchant Risk Assessment:**
```sql
SELECT 
    m.MERCHANT_ID,
    m.MERCHANT_NAME,
    m.CATEGORY,
    m.RISK_RATING as current_risk,
    m.IS_VERIFIED,
    COUNT(t.TRANSACTION_ID) as total_transactions,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as fraud_rate
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.MERCHANTS m
LEFT JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t ON m.MERCHANT_ID = t.MERCHANT_ID
LEFT JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
GROUP BY m.MERCHANT_ID, m.MERCHANT_NAME, m.CATEGORY, m.RISK_RATING, m.IS_VERIFIED
HAVING fraud_rate >= 5 OR fraud_count >= 10
ORDER BY fraud_rate DESC;
```

### Step 3: Present Risk Assessment

Present findings with:
- List of high-risk entities
- Risk score breakdown
- Contributing factors
- Recommended actions

---

## Workflow 5: Velocity Analysis

**Goal:** Detect rapid successive transactions that indicate potential fraud (velocity attacks).

### Step 1: Define Velocity Parameters

Ask the user for:
1. Time window (default: 1 hour)
2. Transaction count threshold (default: 5+ transactions)
3. Scope: All customers, specific segment, or specific customer
4. Amount threshold (optional: flag if total exceeds X)

### Step 2: Detect Velocity Patterns

**Find customers with high transaction velocity:**
```sql
WITH velocity_analysis AS (
    SELECT 
        c.CUSTOMER_ID,
        c.CUSTOMER_NAME,
        c.CUSTOMER_SEGMENT,
        t.TRANSACTION_ID,
        t.TRANSACTION_TIMESTAMP,
        t.AMOUNT,
        t.CHANNEL,
        t.LOCATION_CITY,
        COUNT(*) OVER (
            PARTITION BY c.CUSTOMER_ID 
            ORDER BY t.TRANSACTION_TIMESTAMP 
            RANGE BETWEEN INTERVAL '1 hour' PRECEDING AND CURRENT ROW
        ) as txn_in_window,
        SUM(t.AMOUNT) OVER (
            PARTITION BY c.CUSTOMER_ID 
            ORDER BY t.TRANSACTION_TIMESTAMP 
            RANGE BETWEEN INTERVAL '1 hour' PRECEDING AND CURRENT ROW
        ) as amount_in_window
    FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.CUSTOMERS c ON a.CUSTOMER_ID = c.CUSTOMER_ID
    WHERE t.TRANSACTION_TIMESTAMP >= DATEADD('day', -30, CURRENT_TIMESTAMP())
)
SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CUSTOMER_SEGMENT,
    TRANSACTION_TIMESTAMP,
    txn_in_window,
    amount_in_window,
    CHANNEL,
    LOCATION_CITY
FROM velocity_analysis
WHERE txn_in_window >= 5
ORDER BY txn_in_window DESC, TRANSACTION_TIMESTAMP DESC
LIMIT 100;
```

**Velocity attack correlation with fraud:**
```sql
WITH velocity_flags AS (
    SELECT 
        c.CUSTOMER_ID,
        t.TRANSACTION_ID,
        COUNT(*) OVER (
            PARTITION BY c.CUSTOMER_ID 
            ORDER BY t.TRANSACTION_TIMESTAMP 
            RANGE BETWEEN INTERVAL '1 hour' PRECEDING AND CURRENT ROW
        ) as txn_in_hour
    FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.CUSTOMERS c ON a.CUSTOMER_ID = c.CUSTOMER_ID
)
SELECT 
    CASE 
        WHEN v.txn_in_hour >= 10 THEN 'Extreme (10+)'
        WHEN v.txn_in_hour >= 5 THEN 'High (5-9)'
        WHEN v.txn_in_hour >= 3 THEN 'Moderate (3-4)'
        ELSE 'Normal (1-2)'
    END as velocity_category,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate
FROM velocity_flags v
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON v.TRANSACTION_ID = f.TRANSACTION_ID
GROUP BY velocity_category
ORDER BY fraud_rate DESC;
```

**Burst pattern detection (multiple transactions in minutes):**
```sql
WITH txn_gaps AS (
    SELECT 
        c.CUSTOMER_ID,
        c.CUSTOMER_NAME,
        t.TRANSACTION_ID,
        t.TRANSACTION_TIMESTAMP,
        t.AMOUNT,
        LAG(t.TRANSACTION_TIMESTAMP) OVER (
            PARTITION BY c.CUSTOMER_ID 
            ORDER BY t.TRANSACTION_TIMESTAMP
        ) as prev_txn_time,
        TIMESTAMPDIFF('second', 
            LAG(t.TRANSACTION_TIMESTAMP) OVER (
                PARTITION BY c.CUSTOMER_ID 
                ORDER BY t.TRANSACTION_TIMESTAMP
            ),
            t.TRANSACTION_TIMESTAMP
        ) as seconds_since_last
    FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.CUSTOMERS c ON a.CUSTOMER_ID = c.CUSTOMER_ID
)
SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME,
    COUNT(*) as burst_transactions,
    MIN(seconds_since_last) as min_gap_seconds,
    AVG(seconds_since_last) as avg_gap_seconds,
    SUM(AMOUNT) as total_burst_amount
FROM txn_gaps
WHERE seconds_since_last IS NOT NULL AND seconds_since_last < 60
GROUP BY CUSTOMER_ID, CUSTOMER_NAME
HAVING burst_transactions >= 3
ORDER BY burst_transactions DESC;
```

### Step 3: Present Velocity Findings

Present findings with:
- List of customers exhibiting velocity patterns
- Correlation between velocity and fraud rates
- Time windows with highest velocity activity
- Recommended velocity rules/thresholds

---

## Workflow 6: Geographic Anomaly Detection

**Goal:** Detect impossible travel and geographic inconsistencies indicating fraud.

### Step 1: Define Geographic Parameters

Ask the user for:
1. Impossible travel threshold (default: transactions in different cities within 60 minutes)
2. Scope: All customers or specific investigation
3. High-risk country list (optional)
4. Cross-border transaction analysis (yes/no)

### Step 2: Detect Geographic Anomalies

**Impossible travel detection:**
```sql
WITH txn_locations AS (
    SELECT 
        c.CUSTOMER_ID,
        c.CUSTOMER_NAME,
        t.TRANSACTION_ID,
        t.TRANSACTION_TIMESTAMP,
        t.AMOUNT,
        t.LOCATION_CITY,
        t.LOCATION_COUNTRY,
        LAG(t.LOCATION_CITY) OVER (
            PARTITION BY c.CUSTOMER_ID 
            ORDER BY t.TRANSACTION_TIMESTAMP
        ) as prev_city,
        LAG(t.LOCATION_COUNTRY) OVER (
            PARTITION BY c.CUSTOMER_ID 
            ORDER BY t.TRANSACTION_TIMESTAMP
        ) as prev_country,
        LAG(t.TRANSACTION_TIMESTAMP) OVER (
            PARTITION BY c.CUSTOMER_ID 
            ORDER BY t.TRANSACTION_TIMESTAMP
        ) as prev_time,
        TIMESTAMPDIFF('minute', 
            LAG(t.TRANSACTION_TIMESTAMP) OVER (
                PARTITION BY c.CUSTOMER_ID 
                ORDER BY t.TRANSACTION_TIMESTAMP
            ),
            t.TRANSACTION_TIMESTAMP
        ) as minutes_between
    FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.CUSTOMERS c ON a.CUSTOMER_ID = c.CUSTOMER_ID
)
SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME,
    TRANSACTION_ID,
    prev_city || ', ' || prev_country as from_location,
    LOCATION_CITY || ', ' || LOCATION_COUNTRY as to_location,
    prev_time as first_txn_time,
    TRANSACTION_TIMESTAMP as second_txn_time,
    minutes_between,
    AMOUNT,
    CASE 
        WHEN prev_country != LOCATION_COUNTRY AND minutes_between < 120 THEN 'CRITICAL: Cross-country < 2hrs'
        WHEN prev_city != LOCATION_CITY AND minutes_between < 60 THEN 'HIGH: Different city < 1hr'
        WHEN prev_city != LOCATION_CITY AND minutes_between < 180 THEN 'MEDIUM: Different city < 3hrs'
        ELSE 'LOW'
    END as risk_level
FROM txn_locations
WHERE prev_city IS NOT NULL 
  AND (prev_city != LOCATION_CITY OR prev_country != LOCATION_COUNTRY)
  AND minutes_between < 180
ORDER BY 
    CASE 
        WHEN prev_country != LOCATION_COUNTRY AND minutes_between < 120 THEN 1
        WHEN minutes_between < 60 THEN 2
        ELSE 3
    END,
    minutes_between ASC
LIMIT 50;
```

**Geographic anomaly fraud correlation:**
```sql
WITH geo_flags AS (
    SELECT 
        t.TRANSACTION_ID,
        t.LOCATION_CITY,
        t.LOCATION_COUNTRY,
        LAG(t.LOCATION_CITY) OVER (
            PARTITION BY a.CUSTOMER_ID 
            ORDER BY t.TRANSACTION_TIMESTAMP
        ) as prev_city,
        LAG(t.LOCATION_COUNTRY) OVER (
            PARTITION BY a.CUSTOMER_ID 
            ORDER BY t.TRANSACTION_TIMESTAMP
        ) as prev_country,
        TIMESTAMPDIFF('minute', 
            LAG(t.TRANSACTION_TIMESTAMP) OVER (
                PARTITION BY a.CUSTOMER_ID 
                ORDER BY t.TRANSACTION_TIMESTAMP
            ),
            t.TRANSACTION_TIMESTAMP
        ) as minutes_between
    FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
)
SELECT 
    CASE 
        WHEN prev_country IS NOT NULL AND prev_country != LOCATION_COUNTRY AND minutes_between < 120 
            THEN 'Cross-country impossible travel'
        WHEN prev_city IS NOT NULL AND prev_city != LOCATION_CITY AND minutes_between < 60 
            THEN 'Same-country impossible travel'
        WHEN prev_city IS NOT NULL AND prev_city != LOCATION_CITY 
            THEN 'Location change (normal)'
        ELSE 'Same location'
    END as geo_pattern,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate
FROM geo_flags g
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON g.TRANSACTION_ID = f.TRANSACTION_ID
WHERE prev_city IS NOT NULL
GROUP BY geo_pattern
ORDER BY fraud_rate DESC;
```

**High-risk country analysis:**
```sql
SELECT 
    t.LOCATION_COUNTRY,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate,
    SUM(CASE WHEN f.IS_FRAUD THEN t.AMOUNT ELSE 0 END) as fraud_amount,
    COUNT(DISTINCT a.CUSTOMER_ID) as unique_customers
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
GROUP BY t.LOCATION_COUNTRY
HAVING COUNT(*) >= 50
ORDER BY fraud_rate DESC;
```

### Step 3: Present Geographic Findings

Present findings with:
- List of impossible travel incidents
- High-risk geographic corridors
- Country-level fraud rates
- Recommended geographic rules

---

## Workflow 7: Time-Based Pattern Analysis

**Goal:** Analyze fraud patterns by time of day, day of week, and identify high-risk time windows.

### Step 1: Define Time Analysis Parameters

Ask the user for:
1. Granularity: Hourly, Day of week, Monthly, or All
2. Time zone consideration (default: UTC)
3. Compare periods (e.g., weekday vs weekend, business hours vs off-hours)
4. Specific time windows of interest

### Step 2: Run Time-Based Analysis

**Day vs Night fraud analysis:**
```sql
SELECT 
    CASE 
        WHEN HOUR(t.TRANSACTION_TIMESTAMP) BETWEEN 6 AND 11 THEN 'Morning (6AM-12PM)'
        WHEN HOUR(t.TRANSACTION_TIMESTAMP) BETWEEN 12 AND 17 THEN 'Afternoon (12PM-6PM)'
        WHEN HOUR(t.TRANSACTION_TIMESTAMP) BETWEEN 18 AND 22 THEN 'Evening (6PM-11PM)'
        ELSE 'Night (11PM-6AM)'
    END as time_period,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate,
    SUM(CASE WHEN f.IS_FRAUD THEN t.AMOUNT ELSE 0 END) as fraud_amount,
    ROUND(AVG(CASE WHEN f.IS_FRAUD THEN t.AMOUNT END), 2) as avg_fraud_amount
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
GROUP BY time_period
ORDER BY fraud_rate DESC;
```

**Hourly fraud heatmap:**
```sql
SELECT 
    HOUR(t.TRANSACTION_TIMESTAMP) as hour_of_day,
    DAYNAME(t.TRANSACTION_TIMESTAMP) as day_of_week,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
GROUP BY HOUR(t.TRANSACTION_TIMESTAMP), DAYNAME(t.TRANSACTION_TIMESTAMP)
ORDER BY fraud_rate DESC
LIMIT 20;
```

**Weekday vs Weekend analysis:**
```sql
SELECT 
    CASE 
        WHEN DAYOFWEEK(t.TRANSACTION_TIMESTAMP) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END as day_type,
    CASE 
        WHEN HOUR(t.TRANSACTION_TIMESTAMP) BETWEEN 9 AND 17 THEN 'Business Hours'
        ELSE 'Off Hours'
    END as hour_type,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate,
    SUM(CASE WHEN f.IS_FRAUD THEN t.AMOUNT ELSE 0 END) as fraud_amount
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
GROUP BY day_type, hour_type
ORDER BY fraud_rate DESC;
```

**Time-based fraud type analysis:**
```sql
SELECT 
    CASE 
        WHEN HOUR(t.TRANSACTION_TIMESTAMP) BETWEEN 0 AND 5 THEN 'Late Night (12AM-6AM)'
        WHEN HOUR(t.TRANSACTION_TIMESTAMP) BETWEEN 6 AND 11 THEN 'Morning (6AM-12PM)'
        WHEN HOUR(t.TRANSACTION_TIMESTAMP) BETWEEN 12 AND 17 THEN 'Afternoon (12PM-6PM)'
        ELSE 'Evening (6PM-12AM)'
    END as time_window,
    f.FRAUD_TYPE,
    COUNT(*) as fraud_count,
    SUM(t.AMOUNT) as fraud_amount,
    ROUND(AVG(t.AMOUNT), 2) as avg_amount
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
WHERE f.IS_FRAUD = TRUE
GROUP BY time_window, f.FRAUD_TYPE
ORDER BY time_window, fraud_count DESC;
```

**Peak fraud hours identification:**
```sql
SELECT 
    HOUR(t.TRANSACTION_TIMESTAMP) as hour,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate,
    ROUND(AVG(CASE WHEN f.IS_FRAUD THEN t.AMOUNT END), 2) as avg_fraud_amount,
    CASE 
        WHEN SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 5 THEN '⚠️ HIGH RISK'
        WHEN SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 4 THEN '⚡ ELEVATED'
        ELSE '✓ NORMAL'
    END as risk_level
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
GROUP BY HOUR(t.TRANSACTION_TIMESTAMP)
ORDER BY hour;
```

### Step 3: Present Time-Based Findings

Present findings with:
- Day vs Night fraud comparison
- Peak fraud hours and days
- Fraud type distribution by time
- Recommended time-based rules
- Visualization (if requested): Heatmap of hour x day fraud rates

---

## Workflow 8: Device Fingerprint Analysis

**Goal:** Analyze device and network attributes to identify suspicious patterns.

### Step 1: Define Device Analysis Parameters

Ask the user for:
1. Focus area: IP address, device type, or combined analysis
2. Scope: All transactions, specific channel, or specific customer
3. Threshold for flagging (e.g., multiple accounts from same IP)
4. Time window for analysis (default: 30 days)

### Step 2: Run Device Fingerprint Analysis

**IP address risk analysis:**
```sql
SELECT 
    t.IP_ADDRESS,
    COUNT(DISTINCT a.CUSTOMER_ID) as unique_customers,
    COUNT(DISTINCT a.ACCOUNT_ID) as unique_accounts,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate,
    SUM(t.AMOUNT) as total_amount,
    CASE 
        WHEN COUNT(DISTINCT a.CUSTOMER_ID) > 5 THEN 'HIGH: Multiple customers'
        WHEN SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 10 THEN 'HIGH: High fraud rate'
        WHEN COUNT(*) > 100 THEN 'MEDIUM: High volume'
        ELSE 'NORMAL'
    END as risk_flag
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
WHERE t.IP_ADDRESS IS NOT NULL
  AND t.TRANSACTION_TIMESTAMP >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY t.IP_ADDRESS
HAVING COUNT(*) >= 10
ORDER BY fraud_rate DESC, unique_customers DESC
LIMIT 50;
```

**Device type fraud analysis:**
```sql
SELECT 
    t.DEVICE_TYPE,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate,
    SUM(CASE WHEN f.IS_FRAUD THEN t.AMOUNT ELSE 0 END) as fraud_amount,
    COUNT(DISTINCT a.CUSTOMER_ID) as unique_customers
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
WHERE t.DEVICE_TYPE IS NOT NULL
GROUP BY t.DEVICE_TYPE
ORDER BY fraud_rate DESC;
```

**IP address sharing detection (account compromise indicator):**
```sql
WITH ip_customer_mapping AS (
    SELECT 
        t.IP_ADDRESS,
        a.CUSTOMER_ID,
        c.CUSTOMER_NAME,
        COUNT(*) as txn_count,
        MIN(t.TRANSACTION_TIMESTAMP) as first_seen,
        MAX(t.TRANSACTION_TIMESTAMP) as last_seen
    FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.CUSTOMERS c ON a.CUSTOMER_ID = c.CUSTOMER_ID
    WHERE t.IP_ADDRESS IS NOT NULL
    GROUP BY t.IP_ADDRESS, a.CUSTOMER_ID, c.CUSTOMER_NAME
),
shared_ips AS (
    SELECT 
        IP_ADDRESS,
        COUNT(DISTINCT CUSTOMER_ID) as customer_count
    FROM ip_customer_mapping
    GROUP BY IP_ADDRESS
    HAVING customer_count > 1
)
SELECT 
    m.IP_ADDRESS,
    s.customer_count as customers_sharing_ip,
    m.CUSTOMER_NAME,
    m.txn_count,
    m.first_seen,
    m.last_seen
FROM ip_customer_mapping m
JOIN shared_ips s ON m.IP_ADDRESS = s.IP_ADDRESS
ORDER BY s.customer_count DESC, m.IP_ADDRESS, m.txn_count DESC
LIMIT 100;
```

**Device + Channel combination analysis:**
```sql
SELECT 
    t.DEVICE_TYPE,
    t.CHANNEL,
    COUNT(*) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate,
    ROUND(AVG(t.AMOUNT), 2) as avg_txn_amount,
    ROUND(AVG(CASE WHEN f.IS_FRAUD THEN t.AMOUNT END), 2) as avg_fraud_amount
FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
WHERE t.DEVICE_TYPE IS NOT NULL
GROUP BY t.DEVICE_TYPE, t.CHANNEL
ORDER BY fraud_rate DESC;
```

**New device detection for existing customers:**
```sql
WITH customer_devices AS (
    SELECT 
        a.CUSTOMER_ID,
        t.DEVICE_TYPE,
        t.IP_ADDRESS,
        MIN(t.TRANSACTION_TIMESTAMP) as first_use,
        COUNT(*) as usage_count
    FROM COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t
    JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
    WHERE t.DEVICE_TYPE IS NOT NULL
    GROUP BY a.CUSTOMER_ID, t.DEVICE_TYPE, t.IP_ADDRESS
),
device_history AS (
    SELECT 
        CUSTOMER_ID,
        COUNT(DISTINCT DEVICE_TYPE) as device_count,
        COUNT(DISTINCT IP_ADDRESS) as ip_count
    FROM customer_devices
    GROUP BY CUSTOMER_ID
)
SELECT 
    c.CUSTOMER_ID,
    c.CUSTOMER_NAME,
    dh.device_count,
    dh.ip_count,
    COUNT(t.TRANSACTION_ID) as total_txn,
    SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) as fraud_count,
    ROUND(SUM(CASE WHEN f.IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as fraud_rate
FROM device_history dh
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.CUSTOMERS c ON dh.CUSTOMER_ID = c.CUSTOMER_ID
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.ACCOUNTS a ON c.CUSTOMER_ID = a.CUSTOMER_ID
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.TRANSACTIONS t ON a.ACCOUNT_ID = t.ACCOUNT_ID
JOIN COCO_FINANCIAL.FRAUD_ANALYTICS.FRAUD_LABELS f ON t.TRANSACTION_ID = f.TRANSACTION_ID
WHERE dh.device_count > 3 OR dh.ip_count > 5
GROUP BY c.CUSTOMER_ID, c.CUSTOMER_NAME, dh.device_count, dh.ip_count
ORDER BY fraud_rate DESC, device_count DESC
LIMIT 50;
```

### Step 3: Present Device Fingerprint Findings

Present findings with:
- High-risk IP addresses
- Device type risk comparison
- Shared IP/device anomalies
- New device fraud correlation
- Recommended device-based rules

---

## Stopping Points

Pause and confirm with user at these points:

1. **Before running queries** - Confirm analysis parameters
2. **After initial analysis** - Verify findings make sense before deep dive
3. **Before generating reports** - Confirm report format and recipients
4. **After risk assessment** - Verify threshold before flagging entities

---

## Output Formats

Depending on user request, output can be:

1. **Interactive** - Display results in conversation
2. **SQL** - Provide queries for user to run
3. **Report** - Formatted markdown report
4. **Export** - CSV or JSON data export

---

## Sample Questions This Skill Can Answer

### Pattern Analysis
- "What are the fraud patterns in online transactions?"
- "Compare fraud rates this month vs last month"
- "What's our current fraud rate by channel?"

### Investigation
- "Investigate customer John Smith's recent activity"
- "Look into transaction TXN-12345"
- "Show me all critical alerts from the last 24 hours"

### Reporting
- "Generate a weekly fraud report"
- "Create an executive summary of fraud metrics"

### Risk Assessment
- "Which merchants have the highest fraud rates?"
- "Identify high-risk customers in the Premium segment"

### Velocity Analysis (NEW)
- "Detect velocity attacks in the last 30 days"
- "Find customers with rapid successive transactions"
- "Show me burst transaction patterns"
- "What's the correlation between transaction velocity and fraud?"

### Geographic Anomaly Detection (NEW)
- "Find impossible travel incidents"
- "Detect geographic anomalies in customer transactions"
- "Which countries have the highest fraud rates?"
- "Show cross-border transactions under 2 hours"

### Time-Based Analysis (NEW)
- "Compare night vs day fraud rates"
- "What are the peak fraud hours?"
- "Analyze weekday vs weekend fraud patterns"
- "Show me the hourly fraud heatmap"

### Device Fingerprint Analysis (NEW)
- "Analyze IP address fraud patterns"
- "Find shared IP addresses across multiple customers"
- "Which device types have the highest fraud rates?"
- "Detect customers using multiple devices"
- "Show high-risk IP addresses"
