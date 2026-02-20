---
name: streamlit-in-snowflake
description: "**[REQUIRED]** Use for ALL Streamlit in Snowflake (SiS) deployments. Contains critical API limitations, deployment patterns, and working code examples. Triggers: deploy streamlit, SiS, streamlit snowflake, snow streamlit deploy. DO NOT deploy Streamlit to Snowflake without reading this skill first."
---

# Streamlit in Snowflake (SiS) Deployment Guide

This skill contains **critical information** for deploying Streamlit apps to Snowflake. SiS has significant API differences from standard Streamlit - ignoring these will cause runtime errors.

## CRITICAL: Unavailable APIs in SiS

The following Streamlit APIs are **NOT AVAILABLE** in Snowflake and will crash your app:

| API | Error | Status |
|-----|-------|--------|
| `st.rerun()` | `AttributeError: module 'streamlit' has no attribute 'rerun'` | **NEVER USE** |
| `st.experimental_rerun()` | `AttributeError` | **NEVER USE** |
| `st.camera_input()` | Not supported | **NEVER USE** |
| `st.file_uploader()` | Limited/broken | Avoid |
| `st.connection("snowflake")` | Not needed | Use `get_active_session()` |

## CRITICAL: APIs That May Not Work

These APIs exist but may fail depending on SiS version:

| API | Issue | Alternative |
|-----|-------|-------------|
| `st.line_chart(df, x="col", y="col")` | x/y params may not exist | Use `df.set_index('col')` pattern |
| `st.bar_chart(df, x="col", y="col")` | x/y params may not exist | Use `df.set_index('col')` pattern |
| `st.column_config.NumberColumn()` | May not be available | Use basic `st.dataframe(df)` |
| `st.button(..., type="primary")` | type param may not exist | Remove `type` parameter |
| `@st.cache_data` | Can cause issues | Test carefully or remove |

---

## Required Connection Pattern

**WRONG - Will fail in SiS:**
```python
# DO NOT USE - st.connection doesn't work in SiS
conn = st.connection("snowflake")
df = conn.query("SELECT * FROM table")
```

**CORRECT - Use get_active_session():**
```python
from snowflake.snowpark.context import get_active_session

session = get_active_session()

def run_query(query: str) -> pd.DataFrame:
    return session.sql(query).to_pandas()
```

---

## Required Refresh Pattern

**WRONG - Will crash in SiS:**
```python
if st.button("Refresh"):
    st.cache_data.clear()
    st.rerun()  # CRASHES - st.rerun() doesn't exist!
```

**CORRECT - Works in SiS:**
```python
if st.button("Refresh"):
    st.cache_data.clear()
    st.success("Cache cleared! Data refreshes on next interaction.")
```

---

## Required Chart Pattern

**WRONG - May fail in SiS:**
```python
# x and y parameters may not exist in SiS Streamlit version
st.line_chart(df, x="DATE", y="VALUE", height=300)
st.bar_chart(df, x="CATEGORY", y="COUNT", height=300)
```

**CORRECT - Works in SiS:**
```python
# Use set_index to define x-axis, select columns for y-axis
chart_data = df.set_index('DATE')[['VALUE']]
st.line_chart(chart_data)

chart_data = df.set_index('CATEGORY')[['COUNT']]
st.bar_chart(chart_data)
```

---

## Required DataFrame Pattern

**WRONG - May fail in SiS:**
```python
st.dataframe(
    df,
    column_config={
        "AMOUNT": st.column_config.NumberColumn("Amount", format="$%.2f"),
        "DATE": st.column_config.DatetimeColumn("Date", format="MMM DD"),
    },
    hide_index=True
)
```

**CORRECT - Works in SiS:**
```python
# Format data in SQL instead, use basic dataframe
st.dataframe(df, use_container_width=True)
```

**Format in SQL:**
```sql
SELECT 
    CUSTOMER_NAME,
    ROUND(AMOUNT, 2) as AMOUNT,
    TO_VARCHAR(CREATED_AT, 'YYYY-MM-DD HH24:MI') as CREATED_AT
FROM my_table
```

---

## Required Layout Pattern

**Avoid:**
```python
st.markdown("---")
st.markdown("### Section Title")
st.button("Click", type="primary")
```

**Prefer:**
```python
st.divider()
st.subheader("Section Title")
st.button("Click")  # No type parameter
```

---

## Sidebar Filter Pattern

**WRONG - Filter defined after queries:**
```python
def get_data():
    # selected_days not defined yet!
    return run_query(f"... WHERE date >= DATEADD('day', -{selected_days}, ...)")

# Sidebar defined AFTER function
with st.sidebar:
    selected_days = st.selectbox("Period", [7, 30, 90])

# This crashes or uses wrong value
data = get_data()
```

**CORRECT - Define sidebar FIRST:**
```python
# Define sidebar and filters FIRST
with st.sidebar:
    date_range = st.selectbox("Period", ["Last 7 days", "Last 30 days", "Last 90 days"])
    days_map = {"Last 7 days": 7, "Last 30 days": 30, "Last 90 days": 90}
    selected_days = days_map[date_range]

# NOW define functions that use the filter
def get_data(days: int):
    return run_query(f"... WHERE date >= DATEADD('day', -{days}, CURRENT_TIMESTAMP())")

# Call with filter value
data = get_data(selected_days)
```

---

## Project Structure for SiS

```
streamlit_app/
├── snowflake.yml          # Deployment manifest
├── environment.yml        # Anaconda dependencies  
└── streamlit_app.py       # Main app (single file preferred)
```

### snowflake.yml (definition_version: 2)

```yaml
definition_version: 2
entities:
  my_app:
    type: streamlit
    identifier:
      name: MY_APP_NAME
    title: "My Dashboard"
    query_warehouse: COMPUTE_WH
    main_file: streamlit_app.py
    stage: STREAMLIT_STAGE
    artifacts:
      - streamlit_app.py
      - environment.yml
```

**DO NOT include:**
- `env_file:` - Not valid in definition_version 2
- `defaults:` - Not valid in definition_version 2
- `pages_dir:` with empty value

### environment.yml (Anaconda packages ONLY)

```yaml
name: sf_env
channels:
  - snowflake
dependencies:
  - pandas
  - snowflake-snowpark-python
```

**DO NOT include pip packages** - they won't install.

---

## Deployment Commands

### Create stage (one-time):
```sql
USE DATABASE MY_DATABASE;
USE SCHEMA MY_SCHEMA;
CREATE STAGE IF NOT EXISTS STREAMLIT_STAGE;
```

### Deploy:
```bash
cd streamlit_app/
snow streamlit deploy --database MY_DATABASE --schema MY_SCHEMA --replace
```

### Redeploy after changes:
```bash
snow streamlit deploy --database MY_DATABASE --schema MY_SCHEMA --replace
```

---

## Complete Working Example

```python
"""
SiS-Compatible Streamlit Dashboard
"""
import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="My Dashboard", layout="wide")

session = get_active_session()

def run_query(query: str) -> pd.DataFrame:
    return session.sql(query).to_pandas()

# SIDEBAR FIRST - define filters before using them
with st.sidebar:
    st.header("Filters")
    period = st.selectbox("Time Period", ["Last 7 days", "Last 30 days", "Last 90 days"], index=1)
    days_map = {"Last 7 days": 7, "Last 30 days": 30, "Last 90 days": 90}
    selected_days = days_map[period]
    st.divider()
    st.caption("Powered by Snowflake")

# QUERIES - now can use selected_days
def get_metrics(days: int):
    return run_query(f"""
        SELECT COUNT(*) as TOTAL, SUM(AMOUNT) as AMOUNT
        FROM MY_TABLE
        WHERE CREATED_AT >= DATEADD('day', -{days}, CURRENT_TIMESTAMP())
    """)

def get_trend(days: int):
    return run_query(f"""
        SELECT TO_VARCHAR(DATE(CREATED_AT), 'MM-DD') as DATE, COUNT(*) as COUNT
        FROM MY_TABLE
        WHERE CREATED_AT >= DATEADD('day', -{days}, CURRENT_TIMESTAMP())
        GROUP BY DATE(CREATED_AT)
        ORDER BY DATE(CREATED_AT)
    """)

# MAIN UI
st.title("My Dashboard")
st.write(f"Showing: **{period}**")

# Metrics
metrics = get_metrics(selected_days)
if not metrics.empty:
    col1, col2 = st.columns(2)
    with col1:
        st.metric("Total Records", f"{int(metrics.iloc[0]['TOTAL']):,}")
    with col2:
        st.metric("Total Amount", f"${int(metrics.iloc[0]['AMOUNT']):,}")

st.divider()

# Chart - use set_index pattern
st.subheader("Trend")
trend = get_trend(selected_days)
if not trend.empty:
    chart_data = trend.set_index('DATE')[['COUNT']]
    st.line_chart(chart_data)
else:
    st.info("No data available")

st.divider()

# Table - basic dataframe only
st.subheader("Details")
st.dataframe(trend, use_container_width=True)
```

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `st.rerun()` AttributeError | st.rerun() doesn't exist in SiS | Remove all st.rerun() calls |
| `x is not a valid parameter` | Chart API different in SiS | Use `df.set_index()` pattern |
| `column_config not found` | API not available | Use basic st.dataframe() |
| `env_file not permitted` | Wrong snowflake.yml format | Remove env_file, list in artifacts |
| Data not changing with filter | Filter defined after queries | Move sidebar to top of file |
| Empty dataframes | Filter too restrictive | Check date range, lower HAVING thresholds |

---

## Checklist Before Deploying

- [ ] No `st.rerun()` or `st.experimental_rerun()` anywhere
- [ ] Using `get_active_session()` not `st.connection()`
- [ ] Charts use `set_index()` pattern, not x/y parameters
- [ ] No `st.column_config` usage
- [ ] No `type="primary"` on buttons
- [ ] Sidebar/filters defined BEFORE functions that use them
- [ ] `snowflake.yml` uses definition_version: 2 format
- [ ] `environment.yml` uses only `snowflake` channel
- [ ] Stage created in target database/schema
- [ ] All files listed in artifacts
