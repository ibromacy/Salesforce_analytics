# 📊 SasS Revenue Analytics (Salesforce) — End-to-End Modern Data Platform
**CRM Sales Analytics | Airbyte · BigQuery · dbt Core · Airflow · Power BI**

---

## 📌 Overview

This project is a production-style analytics platform built on real Salesforce CRM data, covering accounts, opportunities, leads, contacts, sales activities, and pipeline performance. Every architectural decision was made deliberately, with cost, governance, and maintainability constraints in mind.

The platform answers a specific question: **how do you go from a live CRM system to governed, stakeholder-ready sales analytics** without duplicating transformation logic, without manual data movement, and without ungoverned access to raw data?

The answer is a layered architecture where each component owns a clearly defined responsibility:

- **Salesforce** — live CRM source system (accounts, opportunities, leads, contacts, tasks)
- **Airbyte Cloud** — managed CDC ingestion, schema detection, incremental sync
- **BigQuery** — cloud-native warehouse with separation of raw, staging, and mart layers
- **dbt Core** — Kimball dimensional modeling, SCD Type 2 snapshots, data quality enforcement
- **Apache Airflow** — orchestration with Airbyte trigger → dbt build → BI refresh *(planned)*
- **Power BI / Looker Studio** — audience-specific dashboards *(planned)*
- **Elementary** — dbt-native data observability *(planned)*
- **GitHub Actions** — automated CI running dbt build on every PR *(planned)*

---

## 🧠 Business Context

The platform was built around real commercial questions that a SaaS sales organisation would actually ask. The dimensional model was designed to support these questions directly.

| Business Question | Fact Table | Key Dimensions |
|---|---|---|
| What is the total pipeline value by stage? | fct_opportunities | dim_opportunity_stage, dim_date |
| Which accounts generate the most won revenue? | fct_opportunities | dim_account, dim_date |
| What is the win rate by lead source? | fct_opportunities | dim_user, dim_date |
| How long do deals take to close on average? | fct_opportunities | dim_account, dim_user |
| Which sales reps close the most revenue? | fct_opportunities | dim_user, dim_date |
| What is the lead conversion rate by channel? | fct_lead_conversion | dim_lead, dim_date |
| How many days does it take to convert a lead? | fct_lead_conversion | dim_lead, dim_user |
| Which reps have the highest activity volume? | fct_sales_activities | dim_user, dim_account |
| Is there a correlation between activity and deal outcomes? | fct_sales_activities + fct_opportunities | dim_user, dim_account |

Won revenue is tracked separately from lost and open pipeline throughout the model. Combining these into a single revenue metric is a common modeling mistake that makes executive dashboards misleading. Isolation was a deliberate grain decision.

---

## 🏗 Architecture & Key Design Decisions

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────────────────────────┐
│  Salesforce   │────▶│  Airbyte     │────▶│         BigQuery                     │
│  (CRM)        │     │  Cloud       │     │                                      │
│               │     │  CDC +       │     │  ┌────────────┐  ┌───────────────┐   │
│  • Accounts   │     │  Incremental │     │  │ raw_       │  │ staging       │   │
│  • Contacts   │     │  Sync        │     │  │ salesforce │─▶│ (views)       │   │
│  • Leads      │     │              │     │  │ (Bronze)   │  │ (Silver)      │   │
│  • Opps       │     │              │     │  └────────────┘  └──────┬────────┘   │
│  • Tasks      │     │              │     │                         │             │
│  • Users      │     │              │     │                  ┌──────▼────────┐   │
└──────────────┘     └──────────────┘     │                  │ marts         │   │
                                           │                  │ (tables)      │   │
                                           │                  │ (Gold)        │   │
                                           │                  └──────┬────────┘   │
                                           └──────────────────────────┼───────────┘
                                                                      │
                                                               ┌──────▼────────┐
                                                               │  Power BI /   │
                                                               │  Looker Studio│
                                                               └───────────────┘
```

### Why BigQuery (not Snowflake)

This project deliberately uses BigQuery to demonstrate platform versatility alongside a separate Snowflake-based project (Auto_project). BigQuery's serverless model eliminates warehouse sizing decisions — queries are billed per TB scanned, not per compute-second. For a CRM analytics use case with relatively small data volumes, this is more cost-effective than maintaining even an X-Small Snowflake warehouse. BigQuery's native integration with Google Cloud services (GCS, Looker Studio, Dataform) and its generous free tier (1TB query, 10GB storage per month) make it ideal for this scale of analytics.

### Why Airbyte for Ingestion (not custom Python)

The previous project (Auto_project) used Snowpipe + Streams + Tasks for ingestion and CDC — a powerful but infrastructure-heavy approach that required managing S3 event notifications, stream consumption, and task scheduling manually. For a CRM source like Salesforce, Airbyte is the better architectural choice because Salesforce's API is well-defined and Airbyte's connector handles authentication, pagination, rate limiting, schema detection, and incremental sync natively. Building this in custom Python would mean reimplementing what Airbyte already does reliably.

This is a deliberate trade-off: Airbyte abstracts away ingestion complexity at the cost of less granular control. For well-known SaaS sources, this trade-off is correct. For niche or internal APIs, custom Python would be the right choice.

### Why CDC Lives in Airbyte, Not dbt

In the Auto_project, CDC was handled by Snowflake Streams — a native change data capture mechanism that tracked row-level changes between consumption points. In this project, Airbyte handles CDC at the ingestion layer using Salesforce's `SystemModstamp` field to identify changed records. Each incremental sync pulls only new or modified records and deduplicates on the record ID before writing to BigQuery.

This means dbt staging models don't need incremental logic — they are materialised as views that clean and rename columns on top of already-deduplicated raw tables. This is architecturally cleaner than embedding deduplication logic in dbt, and keeps the staging layer focused on column selection and naming conventions rather than data engineering plumbing.

### Why Staging Models Are Views

Staging models filter deleted records, rename CamelCase Salesforce columns to snake_case, and select only analytically useful columns from the wide raw tables (Salesforce Account has 70+ columns; the staging model exposes ~30). Since these are lightweight transformations with no aggregation or joins, materialising them as views avoids unnecessary storage cost and ensures they always reflect the latest raw data without requiring a rebuild.

### Why SCD Type 2 on Accounts and Users

Account attributes (industry, type, customer priority, SLA tier) and user attributes (department, title, manager) change over time. Without SCD Type 2, a rep who moves from the EMEA team to the US team would have all historical deals retroactively attributed to the US team. With snapshots, each opportunity can be joined to the dimension record that was active at the time of the deal.

The snapshot strategy uses `timestamp` on `last_modified_at` — a reliable Salesforce system field that advances only when a genuine change occurs. This avoids noise rows that would result from using a query-execution timestamp.

---

## 🧱 Tech Stack

| Layer | Tool | Rationale |
|---|---|---|
| CRM Source | Salesforce (Developer Edition) | Real CRM data with accounts, opportunities, leads, contacts, tasks |
| Ingestion | Airbyte Cloud | Managed CDC, Salesforce connector with OAuth, incremental sync |
| Data Warehouse | BigQuery (Free Tier) | Serverless, per-query billing, native GCP integration |
| Transformation | dbt Core 2.0 | Kimball modeling, SCD Type 2 snapshots, testing, documentation |
| Orchestration | Apache Airflow *(planned)* | Airbyte sync trigger → dbt build → BI refresh |
| BI | Power BI / Looker Studio *(planned)* | Stakeholder-facing dashboards |
| Data Observability | Elementary *(planned)* | Anomaly detection, freshness monitoring, dbt test dashboard |
| CI | GitHub Actions *(planned)* | Automated dbt build + tests on every PR to main |
| Version Control | Git + GitHub | Feature branch workflow, full commit history |

---

## 🔄 Ingestion

### Airbyte Configuration

| Setting | Value | Rationale |
|---|---|---|
| Source | Salesforce (OAuth) | Secure token-based auth, no credentials in code |
| Destination | BigQuery (Service Account) | IAM-scoped access, JSON key stored securely |
| Sync Mode | Full Refresh → Incremental (migration planned) | Start simple, switch to incremental once stable |
| Schedule | Manual (development) → Scheduled (production) | Control costs during development |
| Landing Dataset | raw_salesforce | All raw tables land in a single dataset |

### Streams Synced

| Stream | Description | Record Count |
|---|---|---|
| Account | Companies and organisations | 13 |
| Contact | People linked to accounts | ~20 |
| Lead | Prospects not yet converted | ~10 |
| Opportunity | Sales deals with amounts and stages | 31 |
| OpportunityStage | Pipeline stage definitions | ~10 |
| Task | Activities (calls, emails, meetings) | ~50 |
| User | Sales reps and system users | ~5 |

---

## 🧪 dbt Transformation & Modeling

### Medallion Layers

| Layer | Owner | Content |
|---|---|---|
| Bronze | Airbyte | Raw Salesforce data — CamelCase columns, all fields, soft-deleted records included |
| Silver | dbt staging views | Cleaned, renamed, filtered — snake_case, useful columns only, deleted records excluded |
| Gold | dbt mart tables | Facts and dimensions — Kimball star schema, business logic, SCD Type 2 |

### Staging Models

| Model | Source | What It Does |
|---|---|---|
| stg_accounts | Account | Renames columns, filters IsDeleted, selects business-relevant fields |
| stg_contacts | Contact | Renames, filters, extracts mailing and other addresses |
| stg_leads | Lead | Renames, filters, includes conversion tracking fields |
| stg_opportunities | Opportunity | Renames, filters, includes financial and pipeline fields |
| stg_opportunity_stages | OpportunityStage | Renames, filters to active stages only |
| stg_tasks | Task | Renames, filters, includes call detail fields |
| stg_users | User | Renames, filters to active users only |

### Kimball Star Schema

#### Fact Tables

| Table | Grain | Description |
|---|---|---|
| fct_opportunities | 1 row per opportunity | Pipeline value, won/lost/open revenue, deal velocity, stage, forecast |
| fct_lead_conversion | 1 row per lead | Conversion status, days to convert, converted opportunity value |
| fct_sales_activities | 1 row per task | Activity type, duration, completion, priority |

#### Dimension Tables

| Table | SCD Strategy | Tracked Attributes |
|---|---|---|
| dim_account | Type 2 (timestamp on last_modified_at) | Industry, type, ownership, customer priority, SLA |
| dim_user | Type 2 (timestamp on last_modified_at) | Title, department, division, manager |
| dim_lead | No SCD — short lifecycle | Status, rating, source, conversion status |
| dim_opportunity_stage | No SCD — reference data | Stage label, sort order, probability, win/close flags |
| dim_date | No SCD — dates are immutable | Calendar and fiscal attributes |

### Revenue Isolation

Won, lost, and open pipeline revenue are tracked as separate measures in fct_opportunities:

- `won_revenue` — amount where deal is closed and won
- `lost_revenue` — amount where deal is closed and not won
- `open_pipeline_value` — amount where deal is still open

This prevents metric inflation and ensures executive dashboards show accurate pipeline and revenue figures. The same isolation principle was applied in the Auto_project for order revenue vs cancelled revenue.

### Data Quality

| Test Type | What It Catches |
|---|---|
| not_null | Missing values on primary keys and critical fields |
| unique | Duplicate rows violating grain definitions |
| accepted_values | Invalid deal_status values (must be Won, Lost, or Open) |
| relationships | Broken foreign keys between contacts/opportunities and accounts |

---

## 📊 Key Metrics & KPIs

### Pipeline Metrics (from fct_opportunities)
- Total Pipeline Value, Won Revenue, Lost Revenue
- Win Rate, Average Deal Size, Sales Cycle Length
- Pipeline by Stage, Revenue by Quarter, Forecast Accuracy
- Deals at Risk (overdue tasks, high days open)

### Lead Metrics (from fct_lead_conversion)
- Lead Conversion Rate, Time to Convert
- Conversion by Source, Conversion by Industry
- Lead Quality Score, Converted Deal Value

### Activity Metrics (from fct_sales_activities)
- Activities per Rep, Activities per Deal
- Average Call Duration, Task Completion Rate
- Activity Mix (calls vs emails vs meetings)

---

## 🔐 Security

| Decision | Rationale |
|---|---|
| Salesforce OAuth | Token-based authentication, no credentials stored in code |
| GCP Service Account | IAM-scoped BigQuery Admin access for Airbyte and dbt |
| JSON key in .gitignore | Service account key excluded from version control |
| Gold-only BI exposure *(planned)* | BI tools connect to mart tables only, never raw or staging |

---

## 💰 Cost Optimisation

| Decision | Cost Impact |
|---|---|
| Airbyte incremental sync | Only changed records pulled from Salesforce API per sync |
| BigQuery free tier | 1TB query + 10GB storage per month at no cost |
| Staging as views | No storage cost for Silver layer — computed on read |
| Manual sync schedule | No Airbyte credits burned on automatic syncs during development |
| Mart tables materialised | Queries against Gold hit pre-computed tables, not raw scans |

---

## 🗺 Production Roadmap

| Priority | Item | Status | Detail |
|---|---|---|---|
| 1 | Core data model | ✅ Done | Staging, snapshots, dimensions, facts — all passing |
| 2 | Airbyte ingestion | ✅ Done | Salesforce → BigQuery via Airbyte Cloud |
| 3 | CI with GitHub Actions | 🔲 Planned | dbt build on every PR, merge blocked on failure |
| 4 | Orchestration with Airflow | 🔲 Planned | Airbyte sync → dbt build → BI refresh → Slack alert |
| 5 | BI dashboards | 🔲 Planned | Power BI and/or Looker Studio on Gold mart tables |
| 6 | Data observability | 🔲 Planned | Elementary for anomaly detection, freshness, test dashboard |
| 7 | Switch Airbyte to incremental | 🔲 Planned | Move from Full Refresh to Incremental Append+Dedup |
| 8 | Documentation | 🔲 Planned | Data dictionary, lineage docs, ADRs |

---

## ⚠️ Known Limitations

| Limitation | Detail |
|---|---|
| Salesforce Developer Edition data | Sample CRM data with ~30 opportunities — sufficient for modeling but not for volume testing |
| No MRR/ARR metrics | Salesforce doesn't natively track recurring revenue — this would come from billing systems (Stripe, Zuora) in production |
| No churn analysis | Customer churn requires subscription data not present in standard Salesforce objects |
| Airbyte Cloud trial | 14-day trial with limited credits — production would use Airbyte self-hosted or a paid plan |

---

## 🏆 What This Project Demonstrates

- **Platform versatility** — BigQuery + Airbyte alongside a separate Snowflake + Snowpipe project
- **Managed ingestion** — Airbyte handling CDC, schema detection, and incremental sync for a SaaS source
- **Clean architectural boundaries** — Airbyte owns ingestion/CDC, dbt owns transformation/modeling
- **Kimball dimensional modeling** on real CRM data with grain discipline and metric isolation
- **SCD Type 2** via dbt snapshots with deliberate strategy selection per dimension
- **Revenue isolation** — won, lost, and open pipeline tracked as separate measures
- **Cost-conscious design** — views for staging, free tier usage, manual sync during development
- **Production-ready patterns** — the same modeling and testing approach used in enterprise CRM analytics

---

## ▶️ Run Locally

### Prerequisites
- Python 3.11+, dbt Core 2.0+, Git
- Google Cloud account with BigQuery enabled
- Salesforce Developer account
- Airbyte Cloud account (or self-hosted)

```bash
# 1. Clone the repo
git clone <repo_url>
cd salesforce_analytics

# 2. Install dbt BigQuery adapter
pip install dbt-bigquery

# 3. Configure profiles.yml (~/.dbt/profiles.yml)
# Add salesforce_analytics profile with BigQuery connection

# 4. Install packages
dbt deps

# 5. Run snapshots (creates SCD Type 2 history tables)
dbt snapshot

# 6. Build all models and run tests
dbt build
```

---

## 📁 Project Structure

```
salesforce_analytics/
├── models/
│   ├── staging/
│   │   ├── sources.yml          # Raw Salesforce table definitions
│   │   ├── schema.yml           # Staging model tests
│   │   ├── stg_accounts.sql
│   │   ├── stg_contacts.sql
│   │   ├── stg_leads.sql
│   │   ├── stg_opportunities.sql
│   │   ├── stg_opportunity_stages.sql
│   │   ├── stg_tasks.sql
│   │   └── stg_users.sql
│   └── marts/
│       ├── schema.yml           # Mart model tests
│       ├── dim_date.sql
│       ├── dim_account.sql
│       ├── dim_user.sql
│       ├── dim_lead.sql
│       ├── dim_opportunity_stage.sql
│       ├── fct_opportunities.sql
│       ├── fct_lead_conversion.sql
│       └── fct_sales_activities.sql
├── snapshots/
│   ├── accounts_snapshot.sql
│   └── users_snapshot.sql
├── dbt_project.yml
├── packages.yml
└── README.md
```
