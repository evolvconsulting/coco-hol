# Lab 02: Advanced Fraud Detection

## Overview

This follow-on lab builds on the CoCo-Financial fraud analytics dataset deployed in Lab 01. You will implement advanced fraud detection techniques using Cortex Code.

> **Prerequisite:** Complete [Lab 01: Fraud Analytics](../lab-01-fraud-analytics/README.md) before starting this lab.

---

## Learning Objectives

By the end of this lab, you will be able to:

- Implement velocity-based fraud detection (rapid successive transactions)
- Detect geographic anomalies (impossible travel scenarios)
- Analyze time-based fraud patterns (night vs day fraud rates)
- Perform device fingerprint analysis
- Build and deploy Streamlit dashboards to Snowflake (SiS)
- Create real-time fraud alerting systems

---

## Time Estimate

| Section | Duration |
|---------|----------|
| Module 1: Velocity Detection | 10 min |
| Module 2: Geographic Anomalies | 10 min |
| Module 3: Time-Based Analysis | 10 min |
| Module 4: Device Fingerprinting | 10 min |
| Module 5: Streamlit Dashboard | 15 min |
| Module 6: Real-Time Alerting | 10 min |
| **Total** | **~60 min** |

---

## Prerequisites

Before starting this lab, ensure you have:

1. **Completed Lab 01** - The COCO_FINANCIAL database must exist with sample data
2. **Active Cortex Code session** connected to your Snowflake account

### Verify Lab 01 Completion

Launch Cortex Code and run:

```
Show me the row counts for all tables in COCO_FINANCIAL.FRAUD_ANALYTICS
```

You should see data in CUSTOMERS, ACCOUNTS, TRANSACTIONS, MERCHANTS, FRAUD_LABELS, and ALERTS tables.

---

## Module 1: Velocity Detection

Velocity-based fraud detection identifies rapid successive transactions that may indicate automated attacks or stolen credentials.

### Step 1.1: Understand Velocity Patterns

In Cortex Code:

```
$coco-financial-fraud analyze velocity patterns - find customers 
with more than 3 transactions within a 5-minute window.
```

### Step 1.2: Create Velocity Detection View

```
Create a view called VW_VELOCITY_ALERTS that identifies:
- Customers with 3+ transactions in 5 minutes
- Total amount in the burst
- Channel used
- Flag if any transaction in the burst was fraudulent
```

---

## Module 2: Geographic Anomaly Detection

Detect "impossible travel" scenarios where a customer appears to transact from distant locations in an impossibly short time.

### Step 2.1: Analyze Geographic Patterns

```
$coco-financial-fraud detect geographic anomalies - find transactions 
from the same customer in different countries within 1 hour.
```

### Step 2.2: Create Geographic Risk Scoring

```
Create a geographic risk score based on:
- Distance between consecutive transaction locations
- Time between transactions
- Historical customer location patterns
```

---

## Module 3: Time-Based Pattern Analysis

Analyze how fraud rates vary by time of day and day of week.

### Step 3.1: Hourly Fraud Analysis

```
$coco-financial-fraud analyze time patterns - compare fraud rates 
by hour of day and identify high-risk time windows.
```

### Step 3.2: Create Time-Risk Model

```
Create a view that scores transaction risk based on:
- Hour of day (night transactions = higher risk)
- Day of week (weekend patterns)
- Deviation from customer's normal transaction times
```

---

## Module 4: Device Fingerprint Analysis

Analyze device and IP patterns to detect suspicious behavior.

### Step 4.1: Device Pattern Analysis

```
$coco-financial-fraud analyze device patterns - identify accounts 
accessed from multiple devices or IPs in a short timeframe.
```

### Step 4.2: Create Device Risk Indicators

```
Create indicators for:
- New device on account
- Multiple accounts from same device
- IP address changes
- Device/location mismatch
```

---

## Module 5: Streamlit Dashboard

Build and deploy a fraud monitoring dashboard to Snowflake.

### Step 5.1: Read the SiS Skill (CRITICAL)

**Before writing any Streamlit code**, read the deployment skill:

```
$streamlit-in-snowflake
```

This skill contains critical API limitations that will prevent runtime errors.

### Step 5.2: Create Dashboard

```
Create a Streamlit dashboard for fraud monitoring that includes:
- KPI metrics (fraud rate, total fraud amount, affected customers)
- Daily fraud trend chart
- Fraud by channel breakdown
- High-risk customer table
- Recent alerts feed

IMPORTANT: Use only SiS-compatible APIs as documented in the 
streamlit-in-snowflake skill.
```

### Step 5.3: Deploy to Snowflake

```
Deploy the Streamlit dashboard to Snowflake in the 
COCO_FINANCIAL.FRAUD_ANALYTICS schema.
```

---

## Module 6: Real-Time Alerting

Create an alerting system for fraud detection.

### Step 6.1: Define Alert Rules

```
Create alert rules for:
- High-value transactions (>$5000)
- Velocity violations (3+ txns in 5 min)
- Geographic anomalies
- After-hours high-risk transactions
```

### Step 6.2: Create Alert Generation Procedure

```
Create a stored procedure that:
- Evaluates new transactions against alert rules
- Inserts alerts into the ALERTS table
- Assigns severity based on risk score
```

---

## Cleanup

This lab uses the same database as Lab 01. If you want to clean up:

```sql
DROP DATABASE IF EXISTS COCO_FINANCIAL;
```

---

## Summary

Congratulations! You've completed the Advanced Fraud Detection lab. You learned:

- Velocity-based fraud detection techniques
- Geographic anomaly detection (impossible travel)
- Time-based pattern analysis
- Device fingerprint analysis
- Building SiS-compatible Streamlit dashboards
- Real-time fraud alerting systems

---

## Next Steps

1. **Customize detection rules** for your organization's risk tolerance
2. **Integrate with ML models** using Snowflake Cortex ML functions
3. **Set up scheduled tasks** for automated alert generation
4. **Connect to notification systems** (email, Slack, PagerDuty)

---

**Lab Version:** 1.0  
**Last Updated:** February 2026  
**Author:** CoCo-Financial HOL Team
