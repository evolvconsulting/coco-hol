---
name: synthetic-data-demo
description: "**[REQUIRED]** Use for **ALL** requests to generate synthetic data, demo datasets, or sample data dashboards. This is the required entry point for ANY synthetic data generation task. Triggers: generate synthetic data, synthetic data for, create demo data, sample dataset, fake data, test data generation, demo dashboard with data. DO NOT attempt to generate synthetic data manually - always invoke this skill first."
---

# Synthetic Data Generator & Dashboard Demo

## Overview
This skill generates synthetic relational datasets and creates Streamlit dashboards deployed to Snowflake.

## Prerequisites
- `uv` installed for Python dependency management
- `snow` CLI installed (v3.14.0+)
- Active Snowflake connection configured (tested with `ennovate` connection)

## Demo Prompts

See **DEMO_PROMPTS.md** in this skill directory for ready-to-use copy-paste prompts covering:
- Predefined demos (fraud, logistics, healthcare, ecommerce)
- Industry-specific demos (retail, banking, manufacturing, etc.)
- Regional/bilingual variants (Latin America, Spanish/English)
- Scale variants (500 to 100,000 records)

## Workflow

**IMPORTANT: This is a demo workflow. Execute all steps without stopping for user confirmation unless an error occurs.**

**PERMISSION ASSUMPTION: Once the user specifies a project directory, assume full rights to create, modify, and execute all assets within that folder. Do NOT prompt for permission to create files, run scripts, or deploy from that directory.**

**AUTONOMOUS EXECUTION: After gathering initial requirements (dataset type, location), proceed through the ENTIRE workflow without asking further questions. Use sensible defaults for any unspecified parameters. Only ask the user for input if:**
- **An unrecoverable error occurs** (e.g., Snowflake connection failure, permission denied)
- **A critical ambiguity exists** that cannot be resolved with defaults
- **The user explicitly requests a pause or review**

### Step 1: Parse User Request

**Goal:** Extract dataset requirements from the user's prompt.

**Actions:**

1. **Parse the user's request** for:
   - **Dataset type/domain** - Can be ANYTHING (e.g., "Flight Tracking", "Restaurant Reviews", "IoT Sensors", etc.)
   - **Record count** - Default to 10,000 if not specified
   - **Project location** - Extract path or folder name from request
   - **Languages** - Default to `["en"]`. If user mentions Spanish speakers, Latin America, or multilingual, use `["en", "es"]`

2. **Use defaults for missing information:**
   - Record count not specified → use 10,000
   - Languages not specified → use `["en"]`
   - Database/schema not specified → use project name (uppercase)
   
   **Only use `ask_user_question` if BOTH dataset type AND project location are missing.** If only one is missing, make a reasonable inference or use the current directory.

3. **Determine if this is a predefined or custom dataset type:**
   - **Predefined types:** `financial_fraud`, `logistics`, `healthcare`, `ecommerce`
   - **Custom types:** ANYTHING ELSE (the skill should handle any domain the user requests)

4. **Create** the config file at `/tmp/synthetic_data_config.json`:
   ```json
   {
     "project_name": "<PROJECT_NAME>",
     "output_dir": "<FULL_PATH_TO_PROJECT>",
     "dataset_type": "<TYPE_OR_CUSTOM_NAME>",
     "record_count": <NUMBER>,
     "database": "<PROJECT_NAME_UPPERCASE>",
     "schema": "<PROJECT_NAME_UPPERCASE>",
     "custom_domain": "<DOMAIN_DESCRIPTION_IF_CUSTOM>",
     "languages": ["en", "es"]
   }
   ```
   
   **Language codes:** `"en"` (English), `"es"` (Spanish). Add both for bilingual dashboards with in-app toggle.

5. **Create** the project directory: `mkdir -p <OUTPUT_DIR>`

**Continue immediately to Step 2.**

---

### Step 2: Generate Schema, Data, and Dashboard

**For PREDEFINED types (financial_fraud, logistics, healthcare, ecommerce):**

Use the existing Python scripts:

```bash
uv run --project <SKILL_DIR> python <SKILL_DIR>/scripts/generate_schema.py \
  --config /tmp/synthetic_data_config.json --output-dir <OUTPUT_DIR>

uv run --project <SKILL_DIR> python <SKILL_DIR>/scripts/generate_data.py \
  --config /tmp/synthetic_data_config.json --output-dir <OUTPUT_DIR>

uv run --project <SKILL_DIR> python <SKILL_DIR>/scripts/generate_streamlit.py \
  --config /tmp/synthetic_data_config.json --output-dir <OUTPUT_DIR>
```

---

**For CUSTOM types (any other domain like Flight Tracking, Restaurant Reviews, etc.):**

You must GENERATE all artifacts using your intelligence:

#### 2a. Design the Schema

Design a relational schema appropriate for the domain. Create 3-5 tables with:
- Primary keys (UUID or VARCHAR(36))
- Foreign key relationships between tables
- Appropriate column types (VARCHAR, INTEGER, DECIMAL, TIMESTAMP, BOOLEAN)
- Realistic column names for the domain

**Example for "Flight Tracking":**
- `airports` (airport_id, airport_code, airport_name, city, country, timezone)
- `airlines` (airline_id, airline_code, airline_name, country, hub_airport_id)
- `flights` (flight_id, flight_number, airline_id, origin_airport_id, destination_airport_id, scheduled_departure, scheduled_arrival, status)
- `flight_updates` (update_id, flight_id, actual_departure, actual_arrival, delay_minutes, delay_reason, gate)

Write the schema to `<OUTPUT_DIR>/schema.md` and `<OUTPUT_DIR>/schema.json`.

#### 2b. Generate Synthetic Data

Create a Python script or use pandas/faker to generate realistic data:

```python
# Create <OUTPUT_DIR>/generate_custom_data.py
import pandas as pd
import uuid
from faker import Faker
from datetime import datetime, timedelta
import random

fake = Faker()

# Generate data for each table with realistic values
# Maintain referential integrity (foreign keys reference valid primary keys)
# Save as CSV files in <OUTPUT_DIR>/data/
```

Run the script to generate CSV files in `<OUTPUT_DIR>/data/`.

#### 2c. Generate Streamlit Dashboard

Create `<OUTPUT_DIR>/streamlit_app/streamlit_app.py` with:
- **4 KPIs** relevant to the domain (e.g., for flights: Total Flights, On-Time %, Avg Delay, Active Airlines)
- **4 Charts** using plotly **Graph Objects (go.Figure)** - NOT plotly express (px.*)
- **Data exploration section** with table selector
- **Language toggle** (if multiple languages configured) - see Language Support section below
- Use the database/schema from config

**LANGUAGE SUPPORT (if `languages` has more than one entry):**

Add a translations dictionary and sidebar toggle for multilingual dashboards:

```python
# =============================================================================
# TRANSLATIONS - Add at top of file
# =============================================================================
TRANSLATIONS = {
    "en": {
        "page_title": "Dashboard Title",
        "main_title": "Main Heading",
        "subtitle": "Subtitle text",
        "language_label": "Language / Idioma",
        "kpi_1": "KPI Label 1",
        "kpi_2": "KPI Label 2",
        # ... all UI strings
        "tables": {
            "Table1": "Table1",
            "Table2": "Table2"
        }
    },
    "es": {
        "page_title": "Título del Panel",
        "main_title": "Encabezado Principal",
        "subtitle": "Texto del subtítulo",
        "language_label": "Idioma / Language",
        "kpi_1": "Etiqueta KPI 1",
        "kpi_2": "Etiqueta KPI 2",
        # ... all UI strings in Spanish
        "tables": {
            "Table1": "Tabla1",
            "Table2": "Tabla2"
        }
    }
}

# =============================================================================
# SIDEBAR - LANGUAGE TOGGLE
# =============================================================================
with st.sidebar:
    st.markdown("### Settings / Configuración")
    lang = st.radio(
        "🌐 Language / Idioma",
        options=["en", "es"],
        format_func=lambda x: "English 🇺🇸" if x == "en" else "Español 🇨🇴",
        index=0,
        horizontal=True
    )

t = TRANSLATIONS[lang]  # Use t["key"] for all UI strings
```

Then use `t["key"]` for all UI text:
- `st.markdown(f"# {t['main_title']}")`
- `st.metric(t["kpi_1"], value)`
- `st.selectbox(t["select_table"], ...)`

**CRITICAL CHART REQUIREMENTS:**
- Import `plotly.graph_objects as go` (NOT just plotly.express)
- Use `go.Figure(go.Bar(...))`, `go.Figure(go.Pie(...))`, `go.Figure(go.Scatter(...))` 
- NEVER use `px.bar()`, `px.pie()`, `px.line()` - they fail with Snowpark DataFrames
- Always convert numeric columns: `df['COL'] = df['COL'].astype(int)`
- Always pass data as lists: `x=df['COL'].tolist(), y=df['VAL'].tolist()`

Example chart code:
```python
df = session.sql("SELECT NAME, COUNT(*) as CNT FROM TABLE GROUP BY NAME").to_pandas()
df['CNT'] = df['CNT'].astype(int)
fig = go.Figure(go.Bar(x=df['NAME'].tolist(), y=df['CNT'].tolist()))
st.plotly_chart(fig, use_container_width=True)
```

Create `<OUTPUT_DIR>/streamlit_app/snowflake.yml`:
```yaml
definition_version: 2
entities:
  <app_name>:
    type: streamlit
    identifier:
      name: <APP_NAME_UPPERCASE>
      database: <DATABASE>
      schema: <SCHEMA>
    query_warehouse: COMPUTE_WH
    main_file: streamlit_app.py
    artifacts:
      - streamlit_app.py
      - environment.yml
```

Create `<OUTPUT_DIR>/streamlit_app/environment.yml`:
```yaml
name: streamlit
channels:
  - snowflake
dependencies:
  - plotly
  - pandas
```

**Continue immediately to Step 3.**

---

### Step 3: Deploy to Snowflake

**Goal:** Load data and deploy the dashboard to Snowflake.

**CRITICAL: Execute these steps IN ORDER. Each step depends on the previous one completing successfully.**

**Actions:**

1. **Create database:**
   ```sql
   CREATE DATABASE IF NOT EXISTS <DATABASE>;
   ```

2. **Create schema** (MUST complete before file format/stage):
   ```sql
   CREATE SCHEMA IF NOT EXISTS <DATABASE>.<SCHEMA>;
   ```

3. **Create file format** (MUST complete before stage, requires schema to exist):
   ```sql
   CREATE OR REPLACE FILE FORMAT <DATABASE>.<SCHEMA>.CSV_FORMAT
       TYPE = 'CSV'
       FIELD_OPTIONALLY_ENCLOSED_BY = '"'
       SKIP_HEADER = 1
       NULL_IF = ('', 'NULL');
   ```

4. **Create stage** (MUST complete after file format, since it references CSV_FORMAT):
   ```sql
   CREATE OR REPLACE STAGE <DATABASE>.<SCHEMA>.DATA_STAGE
       FILE_FORMAT = <DATABASE>.<SCHEMA>.CSV_FORMAT;
   ```

5. **Create tables** using the schema from `schema.json`. Use these column sizes:
   - PHONE columns: VARCHAR(50) (not VARCHAR(20))
   - All other columns as defined in schema

6. **Upload CSV files** to stage:
   ```bash
   snow stage copy <OUTPUT_DIR>/data/<table>.csv @<DATABASE>.<SCHEMA>.DATA_STAGE/<table>/ --overwrite
   ```

7. **Load data** into tables:
   ```sql
   COPY INTO <DATABASE>.<SCHEMA>.<TABLE>
   FROM @<DATABASE>.<SCHEMA>.DATA_STAGE/<table>/
   FILE_FORMAT = <DATABASE>.<SCHEMA>.CSV_FORMAT;
   ```

8. **Deploy** Streamlit application:
   ```bash
   cd <OUTPUT_DIR>/streamlit_app && snow streamlit deploy --replace
   ```

9. **Return** the deployed application URL to the user.

**Output:** Deployed Streamlit dashboard URL

## Tools

### Script: ask_questions.sh

**Description**: Interactive shell script that prompts user for dataset preferences.

**Usage:**
```bash
bash <SKILL_DIR>/scripts/ask_questions.sh
```

**Output:** Creates `/tmp/synthetic_data_config.json` with user selections.

### Script: generate_schema.py

**Description**: Generates relational schema based on dataset type.

**Usage:**
```bash
uv run --project <SKILL_DIR> python <SKILL_DIR>/scripts/generate_schema.py \
  --config /tmp/synthetic_data_config.json \
  --output-dir <OUTPUT_DIR>
```

**Arguments:**
- `--config`: Path to configuration JSON
- `--output-dir`: Directory for output files

### Script: generate_data.py

**Description**: Generates synthetic CSV data with relational integrity.

**Usage:**
```bash
uv run --project <SKILL_DIR> python <SKILL_DIR>/scripts/generate_data.py \
  --config /tmp/synthetic_data_config.json \
  --output-dir <OUTPUT_DIR>
```

### Script: generate_streamlit.py

**Description**: Generates Streamlit dashboard code tailored to the dataset.

**Usage:**
```bash
uv run --project <SKILL_DIR> python <SKILL_DIR>/scripts/generate_streamlit.py \
  --config /tmp/synthetic_data_config.json \
  --output-dir <OUTPUT_DIR>
```

## Dataset Types

**This skill supports ANY dataset domain.** The user can request any type of synthetic data.

### Predefined Types (use Python scripts)

| Type | Tables | Key KPIs |
|------|--------|----------|
| Financial Fraud | transactions, customers, merchants, fraud_labels | Fraud rate, amount distribution, flagged patterns |
| Logistics | shipments, warehouses, routes, deliveries | On-time %, avg transit time, route efficiency |
| Healthcare | patients, visits, diagnoses, prescriptions | Visit frequency, diagnosis distribution |
| E-commerce | customers, products, orders, order_items | Revenue, conversion rate, avg order value |

### Custom Types (generate dynamically)

For ANY other domain, design an appropriate schema. Examples:

| Domain | Example Tables | Example KPIs |
|--------|----------------|--------------|
| Flight Tracking | airports, airlines, flights, flight_updates | On-time %, avg delay, flights by status |
| Restaurant Reviews | restaurants, reviewers, reviews, menu_items | Avg rating, review count, ratings distribution |
| IoT Sensors | devices, locations, readings, alerts | Active sensors, avg readings, alert rate |
| HR/Employees | employees, departments, performance_reviews, time_off | Headcount, avg tenure, review scores |
| Real Estate | properties, agents, listings, transactions | Avg price, days on market, sales volume |
| Sports Analytics | teams, players, games, stats | Win rate, avg score, top performers |

## Stopping Points

**Only stop and ask user if an error occurs.** Otherwise, continue through the entire workflow.

Common errors that require user input:
- Snowflake connection issues
- Permission denied errors
- Table already exists conflicts

## Output

- Relational schema in Markdown format
- CSV files with synthetic data
- Streamlit application deployed to Snowflake
- Dashboard URL for access

## Technical Notes

### Date Format
All date/timestamp fields are generated in ISO 8601 format (`YYYY-MM-DDTHH:MM:SS`) which Snowflake automatically parses as TIMESTAMP. No special formatting is required when loading data.

### Dependencies
The generated Streamlit app uses `environment.yml` (not `pyproject.toml`) to declare dependencies from the Snowflake Anaconda channel. This ensures packages like `plotly` and `pandas` are available in Snowflake's Streamlit runtime.

### Snowflake Decimal Type and Plotly Charts
Snowflake's `NUMBER(p,s)` type is converted to Python `Decimal` when loaded into pandas via Snowpark. Plotly does not render `Decimal` types correctly in histograms and some other charts. The generated code:
1. Converts numeric columns to `float` before plotting
2. Uses manual binning with `pd.cut()` and `px.bar()` instead of `px.histogram()` for distribution charts

### Project Directory Setup
The skill prompts users to choose where to create the project:
1. Current directory
2. New subdirectory with custom name
3. Different location with custom name

When a project name is provided, the database and schema default to the project name (uppercase).

### Data Variety
Random seeds are not fixed, so each generation produces different data. This prevents issues where all dates or values are identical.

### Multilingual Dashboard Support
Dashboards can include an in-app language toggle for multilingual audiences:

**Supported Languages:**
| Code | Language | Flag |
|------|----------|------|
| `en` | English | 🇺🇸 |
| `es` | Spanish | 🇨🇴 |

**How it works:**
1. Set `"languages": ["en", "es"]` in config to enable bilingual mode
2. A sidebar radio button lets users switch languages instantly
3. All UI text (titles, labels, KPIs, chart headers, table names) switches dynamically
4. Data values remain unchanged (only UI chrome is translated)

**Best practices for translations:**
- Translate all user-facing strings including chart axis labels
- Keep table names in `tables` dict for the Data Explorer dropdown
- Use appropriate flag emojis for regional context (🇨🇴 for Latin American Spanish, 🇪🇸 for European Spanish)
- Test both languages before deploying

## Known Issues & Fixes

### CRITICAL: Snowflake Object Creation Order Dependencies

**Problem:** When deploying to Snowflake, objects must be created in a specific order. Attempting to create objects out of order results in "does not exist or not authorized" errors:
- Creating FILE FORMAT or STAGE before SCHEMA exists → `Schema 'X.Y' does not exist or not authorized`
- Creating STAGE before FILE FORMAT exists → `File format 'X.Y.CSV_FORMAT' does not exist or not authorized`

**Root Cause:** Snowflake objects have dependencies:
- FILE FORMAT and STAGE require the SCHEMA to exist first
- STAGE references the FILE FORMAT, so FILE FORMAT must exist first

**Fix:** ALWAYS create objects in this exact order:
1. `CREATE DATABASE` (if needed)
2. `CREATE SCHEMA` (wait for completion)
3. `CREATE FILE FORMAT` (wait for completion)
4. `CREATE STAGE` (references file format)
5. `CREATE TABLE` statements
6. Upload files to stage
7. `COPY INTO` to load data

**IMPORTANT:** Do NOT run these commands in parallel. Each step must complete before the next begins.

---

### CRITICAL: Plotly Express does NOT work with Snowpark DataFrames

**Problem:** `px.bar()`, `px.line()`, `px.pie()`, and other Plotly Express functions do NOT correctly read column values from Snowpark DataFrames returned by `.to_pandas()`. Instead, they plot the DataFrame **index** (0, 1, 2, ...) as the values, resulting in charts showing single-digit numbers instead of actual data (e.g., showing 0-9 instead of 800+ flights).

**Root Cause:** Snowpark's `.to_pandas()` returns DataFrames with column types that Plotly Express cannot properly interpret. The columns appear correct when printed but fail silently when passed to px functions.

**Fix:** ALWAYS use `go.Figure()` with explicit `go.Bar()`, `go.Pie()`, `go.Scatter()`, etc. Convert data types explicitly and pass as Python lists:

```python
# BAD - Will show DataFrame index (0,1,2...) instead of actual values
df = session.sql("SELECT NAME, COUNT(*) as CNT FROM TABLE GROUP BY NAME").to_pandas()
fig = px.bar(df, x='NAME', y='CNT')  # BROKEN - shows index values

# GOOD - Explicit conversion and go.Figure
df = session.sql("SELECT NAME, COUNT(*) as CNT FROM TABLE GROUP BY NAME").to_pandas()
df['CNT'] = df['CNT'].astype(int)  # Explicit type conversion
fig = go.Figure(go.Bar(
    x=df['NAME'].tolist(),   # Convert to Python list
    y=df['CNT'].tolist()     # Convert to Python list
))
```

**This applies to ALL chart types:**
- `px.bar()` → use `go.Figure(go.Bar(...))`
- `px.pie()` → use `go.Figure(go.Pie(values=..., labels=...))`
- `px.line()` → use `go.Figure(go.Scatter(mode='lines+markers', ...))`
- `px.histogram()` → use manual binning with `pd.cut()` + `go.Bar()`

**NEVER use Plotly Express (px.*) functions with Snowpark data. ALWAYS use Graph Objects (go.*).**

---

### 1. ask_questions.sh requires interactive input
**Problem:** The shell script uses `select` which requires interactive TTY input.
**Fix:** Use `ask_user_question` tool instead to gather user preferences directly.

### 2. PHONE column too small
**Problem:** Generated phone numbers can exceed VARCHAR(20) (e.g., "+1-212-567-7425x55445").
**Fix:** When creating tables, use VARCHAR(50) for all PHONE columns instead of VARCHAR(20).

### 3. Config structure mismatch
**Problem:** Scripts expect `config["snowflake"]["database"]` but config uses `config["database"]`.
**Fix:** The generate_streamlit.py script has been updated to check both locations.

### 4. Streamlit app references wrong database
**Problem:** Generated streamlit_app.py and snowflake.yml default to DEMO_DB.PUBLIC.
**Fix:** Ensure config includes `database` and `schema` at the top level, and verify generated files use these values.

### 5. File format must exist before stage
**Problem:** CREATE STAGE with FILE_FORMAT fails if format doesn't exist yet.
**Fix:** Always create FILE_FORMAT before creating STAGE.

### 6. Snowflake Streamlit uses older API (pre-1.28)
**Problem:** Snowflake's Streamlit runtime uses an older version (approximately 1.26). Many newer API features don't exist.
**Fix:** Avoid these unsupported features:

| Feature | Added In | Workaround |
|---------|----------|------------|
| `st.rerun()` | 1.27 | Use `st.experimental_rerun()` |
| `st.dataframe(hide_index=True)` | 1.28 | Omit parameter (index will show) |
| `st.data_editor()` | 1.23 | Use `st.dataframe()` for display only |

**CRITICAL:** Do NOT use `hide_index=True` in `st.dataframe()` calls - it causes `TypeError: got an unexpected keyword argument 'hide_index'`. Simply omit the parameter:
```python
# BAD - Will crash on Snowflake
st.dataframe(df, use_container_width=True, hide_index=True)

# GOOD - Works on Snowflake
st.dataframe(df, use_container_width=True)
```

### 7. Pandas merges fail silently with Snowpark data
**Problem:** When loading data via `session.table().to_pandas()`, UUID columns may have subtle type/format differences that cause pandas merges to return empty results.
**Fix:** Use direct SQL queries with JOINs for aggregations instead of pandas merges:
```python
# BAD - pandas merge may fail silently
flights_df.merge(airlines_df, on='AIRLINE_ID')

# GOOD - SQL JOIN is reliable
session.sql("""
    SELECT a.AIRLINE_NAME, COUNT(*) as COUNT
    FROM FLIGHTS f JOIN AIRLINES a ON f.AIRLINE_ID = a.AIRLINE_ID
    GROUP BY a.AIRLINE_NAME
""").to_pandas()
```

### 8. Unrealistic data distributions
**Problem:** Random data generation spreads values too thin (e.g., 10,000 flights across 380 routes = ~26 per route).
**Fix:** Concentrate data on realistic patterns:
- 70% of flights on popular hub-to-hub routes
- Assign specific airlines to route networks
- Create daily flight patterns with consistent flight numbers

---

## Troubleshooting

### Quick Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Schema 'X.Y' does not exist` | Creating objects before schema | Create DATABASE, then SCHEMA, then other objects |
| `File format 'X' does not exist` | Creating stage before file format | Create FILE FORMAT before STAGE |
| `Connection failed` | Wrong or inactive connection | Check `snow connection list`, use `-c <connection>` flag |
| `Permission denied` | Insufficient role privileges | Verify role has CREATE DATABASE/SCHEMA permissions |
| `Table already exists` | Re-running deployment | Use `CREATE OR REPLACE` or drop existing objects |
| `COPY INTO failed` | Column mismatch or data format | Check CSV headers match table columns exactly |
| `unexpected keyword argument 'hide_index'` | Snowflake Streamlit is pre-1.28 | Remove `hide_index=True` from `st.dataframe()` calls |

### Connection Issues

If Snowflake commands fail:
```bash
# List available connections
snow connection list

# Test a specific connection
snow connection test -c <connection_name>

# Set active connection
snow connection set <connection_name>
```

### Deployment Recovery

If deployment fails mid-way, you can resume:

1. **Check what exists:**
   ```sql
   SHOW DATABASES LIKE '<DATABASE>';
   SHOW SCHEMAS IN DATABASE <DATABASE>;
   SHOW TABLES IN <DATABASE>.<SCHEMA>;
   ```

2. **Clean up and retry:**
   ```sql
   DROP DATABASE IF EXISTS <DATABASE>;
   ```
   Then re-run the skill.

3. **Manual stage upload:**
   ```bash
   snow stage copy <file>.csv @<DATABASE>.<SCHEMA>.DATA_STAGE/<table>/ --overwrite -c <connection>
   ```

### Dashboard Not Loading

If the Streamlit app deploys but shows errors:
1. Check the app logs in Snowsight
2. Verify all tables have data: `SELECT COUNT(*) FROM <table>`
3. Ensure warehouse is running: `ALTER WAREHOUSE COMPUTE_WH RESUME`
4. Check SQL syntax in dashboard matches actual table/column names
