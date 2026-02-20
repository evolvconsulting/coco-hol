# CoCo-Financial Hands-on Labs

Welcome to the **CoCo-Financial** Hands-on Lab series! These labs teach you how to use **Cortex Code CLI** to build fraud analytics solutions for a fictional financial services company.

---

## Available Labs

| Lab | Duration | Description | Prerequisites |
|-----|----------|-------------|---------------|
| [Lab 01: Fraud Analytics](lab-01-fraud-analytics/README.md) | ~60-90 min | Set up authentication, deploy fraud dataset, create semantic views, build custom skills | Snowflake account, Cortex Code CLI |
| [Lab 02: Advanced Fraud Detection](lab-02-advanced-detection/README.md) | ~45-60 min | Build ML models, velocity detection, real-time alerting, Streamlit dashboards | **Completion of Lab 01** |

---

## Lab 01: Fraud Analytics (Start Here)

**Recommended for all users.** This foundational lab covers:

- Installing and configuring Cortex Code CLI
- Setting up Key-Pair or PAT authentication with Snowflake
- Deploying the CoCo-Financial fraud analytics dataset
- Creating semantic views for natural language queries
- Building custom Cortex Code skills

**[Start Lab 01 →](lab-01-fraud-analytics/README.md)**

---

## Lab 02: Advanced Fraud Detection (Follow-on)

**Requires Lab 01 completion.** This advanced lab builds on the fraud dataset to cover:

- Velocity-based fraud detection
- Geographic anomaly detection
- Time-based pattern analysis
- Device fingerprint analysis
- Building and deploying Streamlit dashboards to Snowflake
- Real-time fraud alerting systems

**[Start Lab 02 →](lab-02-advanced-detection/README.md)**

---

## Quick Start

### Prerequisites

1. **Snowflake Account** with CREATE DATABASE permissions
2. **Snowflake CLI** (`snow`) installed
3. **Cortex Code CLI** (`cortex`) installed
4. **macOS or Linux** (Windows users: use WSL)

### Don't Have a Snowflake Account?

Sign up for a **free Cortex Code trial**:

**https://signup.snowflake.com/cortex-code?utm_cta=pushdown-signup**

### Verify Installation

```bash
snow --version
cortex --version
```

---

## Project Structure

```
CoCo_HOL/
├── README.md                      # This file
├── lab-01-fraud-analytics/        # Foundational lab
│   ├── README.md
│   ├── README.pdf
│   ├── .cortex/skills/
│   ├── data/
│   ├── scripts/
│   └── assets/
└── lab-02-advanced-detection/     # Follow-on lab
    ├── README.md
    ├── .cortex/skills/
    ├── data/
    ├── scripts/
    └── assets/
```

---

## Getting Help

- In Cortex Code: Type `?` or `/help`
- Documentation: https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-cli
- Trial signup: https://signup.snowflake.com/cortex-code?utm_cta=pushdown-signup

---

**Version:** 2.0  
**Last Updated:** February 2026  
**Author:** CoCo-Financial HOL Team
