# 📊 SaaS Revenue Analytics (Salesforce) — End-to-End Modern Data Platform
**CRM Sales Analytics | Airbyte · BigQuery · dbt Core · MetricFlow · GitHub Actions**

---

## 📌 Overview

This project is a production-style analytics platform built on real Salesforce CRM data, covering accounts, opportunities, leads, contacts, campaigns, products, sales activities, and pipeline performance. Every architectural decision was made deliberately, with cost, governance, and maintainability constraints in mind.

The platform answers a specific question: **how do you go from a live CRM system to governed, stakeholder-ready sales analytics** without duplicating transformation logic, without manual data movement, and without ungoverned access to raw data?

The answer is a layered architecture where each component owns a clearly defined responsibility:

- **Salesforce** — live CRM source system (accounts, opportunities, leads, contacts, campaigns, tasks)
- **Airbyte Cloud** — managed CDC ingestion, schema detection, incremental sync
- **BigQuery** — cloud-native warehouse with dataset separation (raw, staging, marts by department, snapshots)
- **dbt Core (Fusion 2.0)** — Kimball dimensional modeling, SCD Type 2 snapshots, data quality enforcement
- **MetricFlow** — semantic layer defining governed metric definitions as code
- **GitHub Actions** — automated CI running dbt build on every PR, merge blocked on failure
- **Apache Airflow** — orchestration with Airbyte trigger → dbt build → BI refresh *(planned)*
- **Looker Studio** — audience-specific dashboards for Sales, Marketing, and Customer teams *(planned)*
- **Elementary** — dbt-native data observability *(planned)*

---

## 🧠 Business Context

The platform serves **three SaaS departments** with dedicated fact models and KPIs for each:

### Sales
| Business Question | Fact Table | Key Dimensions |
|---|---|---|
| What is the total pipeline value by stage? | fct_opportunities | dim_opportunity_stage, dim_date |
| Which accounts generate the most won revenue? | fct_opportunities | dim_account, dim_date |
| What is the win rate by lead source? | fct_opportunities | dim_user, dim_date |
| Which sales reps close the most revenue? | fct_sales_performance | dim_user, dim_date |
| Which products sell the most? | fct_product_performance | dim_account, dim_date |

### Marketing
| Business Question | Fact Table | Key Dimensions |
|---|---|---|
| What is the lead conversion rate by channel? | fct_lead_conversion | dim_lead, dim_date |
| Which campaigns generate the highest ROI? | fct_campaign_performance | dim_campaign, dim_date |
| What is the cost per won deal by campaign? | fct_campaign_performance | dim_campaign |
| Which lead sources produce the best quality leads? | fct_marketing_performance | dim_date |

### Customer Success
| Business Question | Fact Table | Key Dimensions |
|---|---|---|
| Which accounts are at risk of churning? | fct_account_health | dim_account |
| What is the total revenue at risk? | fct_account_health | dim_account |
| Where are the upsell opportunities? | fct_account_health | dim_account |

Won revenue is tracked separately from lost and open pipeline throughout the model. Combining these into a single revenue metric is a common modeling mistake that makes executive dashboards misleading. Isolation was a deliberate grain decision.

---

## 🏗 Architecture & Key Design Decisions

### Why BigQuery (not Snowflake)
This project deliberately uses BigQuery to demonstrate platform versatility alongside a separate Snowflake-based project (Auto_project). BigQuery's serverless model eliminates warehouse sizing decisions — queries are billed per TB scanned, not per compute-second. For a CRM analytics use case with relatively small data volumes, this is more cost-effective than maintaining even an X-Small Snowflake warehouse.

### Why Airbyte for Ingestion (not custom Python)
The previous project (Auto_project) used Snowpipe + Streams + Tasks for ingestion and CDC. For a CRM source like Salesforce, Airbyte is the better architectural choice because Salesforce's API is well-defined and Airbyte's connector handles authentication, pagination, rate limiting, schema detection, and incremental sync natively.

### Why CDC Lives in Airbyte, Not dbt
Airbyte handles CDC at the ingestion layer using Salesforce's SystemModstamp field. This means dbt staging models don't need incremental logic — they are materialised as views that clean and rename columns on top of already-deduplicated raw tables.

### Why Dataset Separation by Department
BigQuery datasets are separated by function and department. A generate_schema_name macro ensures dbt writes to the exact dataset specified. This enables granular access control — marketing sees only marts_marketing, customer success sees only marts_customer.

### Why MetricFlow for Semantic Layer
Metric definitions (win rate, conversion rate, campaign ROI) are defined as code in MetricFlow rather than in BI tools. This creates a single source of truth for how every metric is calculated.

### Why SCD Type 2 on Accounts and Users
Account and user attributes change over time. Snapshots use timestamp on last_modified_at — a reliable Salesforce system field that advances only when a genuine change occurs.

---

## 🧱 Tech Stack

| Layer | Tool | Rationale |
|---|---|---|
| CRM Source | Salesforce (Developer Edition) | Real CRM data |
| Ingestion | Airbyte Cloud | Managed CDC, OAuth, incremental sync |
| Data Warehouse | BigQuery (Free Tier) | Serverless, per-query billing |
| Transformation | dbt Core (Fusion 2.0) | Kimball modeling, SCD Type 2, testing |
| Semantic Layer | MetricFlow | Governed metric definitions as code |
| CI | GitHub Actions (dbt Fusion) | Automated dbt build on every PR |
| Orchestration | Apache Airflow *(planned)* | Airbyte → dbt → BI refresh |
| BI | Looker Studio *(planned)* | Stakeholder dashboards |
| Observability | Elementary *(planned)* | Anomaly detection, freshness monitoring |
| Version Control | Git + GitHub | Branch protection, feature branch workflow |

---

## 🔄 Ingestion

### Streams Synced

| Stream | Description | Record Count |
|---|---|---|
| Account | Companies and organisations | 13 |
| Contact | People linked to accounts | ~20 |
| Lead | Prospects not yet converted | ~22 |
| Opportunity | Sales deals with amounts and stages | 31 |
| OpportunityStage | Pipeline stage definitions | ~10 |
| OpportunityLineItem | Products within each deal | ~10 |
| Campaign | Marketing campaigns | 4 |
| CampaignMember | Leads/contacts assigned to campaigns | ~15 |
| Task | Activities (calls, emails, meetings) | ~50 |
| User | Sales reps and system users | ~5 |

---

## 🧪 dbt Transformation & Modeling

### Medallion Layers

| Layer | Owner | BigQuery Dataset |
|---|---|---|
| Bronze | Airbyte | raw_salesforce |
| Silver | dbt staging views | staging_salesforce |
| Gold — Sales | dbt mart tables | marts_sales |
| Gold — Marketing | dbt mart tables | marts_marketing |
| Gold — Customer | dbt mart tables | marts_customer |
| Gold — Dimensions | dbt mart tables | marts_dimensions |
| History | dbt snapshots | snapshots_salesforce |

### Fact Tables — Sales (marts_sales)

| Table | Grain | Description |
|---|---|---|
| fct_opportunities | 1 row per opportunity | Pipeline value, won/lost/open revenue, deal velocity |
| fct_sales_activities | 1 row per task | Activity type, duration, completion, priority |
| fct_sales_performance | 1 row per sales rep | Aggregated win rate, revenue, activity correlation |
| fct_product_performance | 1 row per line item | Product-level revenue, quantity, discount analysis |

### Fact Tables — Marketing (marts_marketing)

| Table | Grain | Description |
|---|---|---|
| fct_lead_conversion | 1 row per lead | Conversion status, days to convert, converted value |
| fct_campaign_performance | 1 row per campaign | Campaign ROI, member reach, response rate |
| fct_marketing_performance | 1 row per lead source | Conversion rate, quality score, revenue by channel |

### Fact Tables — Customer (marts_customer)

| Table | Grain | Description |
|---|---|---|
| fct_account_health | 1 row per account | Health score, churn signals, upsell status, lifetime revenue |

### Dimension Tables (marts_dimensions)

| Table | SCD Strategy | Tracked Attributes |
|---|---|---|
| dim_account | Type 2 | Industry, type, ownership, customer priority, SLA |
| dim_user | Type 2 | Title, department, division, manager |
| dim_lead | No SCD | Status, rating, source, conversion status |
| dim_opportunity_stage | No SCD | Stage label, sort order, probability |
| dim_campaign | No SCD | Campaign type, status, budget, duration |
| dim_date | No SCD | Calendar and fiscal attributes |
| metricflow_time_spine | View | Daily date spine for MetricFlow |

### Key Design Decisions

**fct_product_performance** reads from staging directly, not fct_opportunities — same fan trap prevention as the Auto_project.

**fct_account_health** derives health_status (Healthy/At Risk/Churning) from engagement signals — a proxy metric documented honestly as requiring billing data for true churn.

**Revenue isolation** — won, lost, and open pipeline tracked as separate measures throughout.

---

## 📐 MetricFlow Semantic Layer

### Sales Metrics
| Metric | Type | Definition |
|---|---|---|
| total_revenue | simple | Sum of won_revenue |
| win_rate | derived | won_deal_count / closed_deal_count |
| average_deal_size | simple | Average of amount |
| average_sales_cycle | simple | Average of days_to_close |

### Marketing Metrics
| Metric | Type | Definition |
|---|---|---|
| lead_conversion_rate | derived | converted_leads / total_leads |
| campaign_roi | derived | (won_revenue - spend) / spend |
| cost_per_member | derived | spend / total_members |

### Customer Metrics
| Metric | Type | Definition |
|---|---|---|
| total_lifetime_revenue | simple | Sum of lifetime_revenue |
| average_account_revenue | simple | Average lifetime_revenue |

### Activity Metrics
| Metric | Type | Definition |
|---|---|---|
| activity_completion_rate | derived | completed / total activities |
| average_call_duration | simple | Average call_duration_minutes |

---

## 🔁 CI — GitHub Actions

- Installs **dbt Fusion 2.0** — same version as local, eliminating version mismatch
- Writes profiles.yml at runtime using **GitHub Secrets**
- Builds to isolated **ci_salesforce** dataset
- **Branch protection** blocks merge on failure

---

## 🔐 Security

| Decision | Rationale |
|---|---|
| Salesforce OAuth | Token-based auth, no credentials in code |
| GCP Service Account | IAM-scoped access |
| JSON key in .gitignore | Key excluded from version control |
| GitHub Secrets | CI credentials injected at runtime |
| Dataset separation | BI connects to marts only |

---

## 💰 Cost Optimisation

| Decision | Cost Impact |
|---|---|
| Airbyte incremental sync | Only changed records per sync |
| BigQuery free tier | 1TB query + 10GB storage free |
| Staging as views | No storage cost for Silver layer |
| Manual sync schedule | No credits burned during development |
| CI on dbt Fusion | Faster builds, less GitHub Actions minutes |

---

## 🗺 Production Roadmap

| Priority | Item | Status | Detail |
|---|---|---|---|
| 1 | Core data model | ✅ Done | 10 staging, 8 facts, 7 dimensions, 2 snapshots |
| 2 | Airbyte ingestion | ✅ Done | Salesforce → BigQuery (10 streams) |
| 3 | Department separation | ✅ Done | Separate datasets for sales, marketing, customer |
| 4 | CI with GitHub Actions | ✅ Done | dbt Fusion, branch protection, CI dataset isolation |
| 5 | MetricFlow semantic layer | ✅ Done | 20+ governed metrics across all departments |
| 6 | BI dashboards | 🔲 Planned | Looker Studio on Gold mart tables |
| 7 | Orchestration | 🔲 Planned | Airflow: Airbyte sync → dbt build → BI refresh |
| 8 | Data observability | 🔲 Planned | Elementary for anomaly detection and freshness |
| 9 | Incremental sync | 🔲 Planned | Switch Airbyte to Incremental Append+Dedup |

---

## ⚠️ Known Limitations

| Limitation | Detail |
|---|---|
| Salesforce Developer data | ~30 opportunities — sufficient for modeling, not volume testing |
| No MRR/ARR metrics | Requires billing system (Stripe/Zuora) integration |
| Proxy churn metric | Based on engagement signals, not subscription churn |
| Airbyte Cloud trial | 14-day trial — production would use self-hosted |

---

## 🏆 What This Project Demonstrates

- **Platform versatility** — BigQuery + Airbyte alongside a separate Snowflake + Snowpipe project
- **Three-department coverage** — Sales, Marketing, and Customer analytics from a single CRM source
- **Managed ingestion** — Airbyte handling CDC and incremental sync for a SaaS source
- **Clean architectural boundaries** — Airbyte owns CDC, dbt owns transformation, MetricFlow owns metrics
- **Kimball dimensional modeling** with grain discipline and metric isolation
- **SCD Type 2** via dbt snapshots with deliberate strategy selection
- **Semantic layer** — MetricFlow defining governed metrics as code
- **Automated CI** — dbt Fusion on GitHub Actions with branch protection
- **Dataset governance** — department-level separation for access control
- **Production-ready patterns** — enterprise CRM analytics approach

---

## ▶️ Run Locally

```bash
# 1. Clone the repo
git clone <repo_url>
cd salesforce_analytics

# 2. Install dbt Fusion
curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh | sh -s -- --update

# 3. Configure profiles.yml and install packages
dbt deps

# 4. Run snapshots then build
dbt snapshot
dbt build
```

---

## 📁 Project Structure

```
salesforce_analytics/
├── .github/workflows/ci.yml
├── macros/generate_schema_name.sql
├── models/
│   ├── staging/
│   │   ├── sources.yml, schema.yml
│   │   ├── stg_accounts.sql, stg_contacts.sql, stg_leads.sql
│   │   ├── stg_opportunities.sql, stg_opportunity_stages.sql
│   │   ├── stg_opportunity_line_items.sql
│   │   ├── stg_campaigns.sql, stg_campaign_members.sql
│   │   ├── stg_tasks.sql, stg_users.sql
│   ├── marts/
│   │   ├── sales/ (fct_opportunities, fct_sales_activities, fct_sales_performance, fct_product_performance)
│   │   ├── marketing/ (fct_lead_conversion, fct_campaign_performance, fct_marketing_performance)
│   │   ├── customer/ (fct_account_health)
│   │   └── dimensions/ (dim_account, dim_user, dim_lead, dim_campaign, dim_date, dim_opportunity_stage, metricflow_time_spine)
│   └── metrics.yml
├── snapshots/ (accounts_snapshot, users_snapshot)
├── dbt_project.yml, packages.yml
└── README.md
```
