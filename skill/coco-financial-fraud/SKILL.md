---
name: coco-financial-fraud
description: "Fraud analytics skill for CoCo-Financial. Use for: analyzing fraud patterns, investigating suspicious transactions, generating fraud reports, risk assessment. Triggers: fraud analysis, suspicious transactions, fraud patterns, risk assessment, fraud report, investigate fraud."
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

- "What are the fraud patterns in online transactions?"
- "Investigate customer John Smith's recent activity"
- "Generate a weekly fraud report"
- "Which merchants have the highest fraud rates?"
- "Show me all critical alerts from the last 24 hours"
- "What's our current fraud rate by channel?"
- "Identify customers with suspicious velocity patterns"
- "Compare fraud rates this month vs last month"
