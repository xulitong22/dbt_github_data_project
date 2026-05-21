# GitHub Development Velocity Analytics

<p align="center">
  <img src="assets/dashboard_preview.png" width="80%" />
</p>

##  Project Overview
An end-to-end Analytics Engineering pipeline that monitors and visualizes repository health for the GitHub repository. Transforms raw GitHub API data into a clean, warehouse-ready Star Schema with automated daily refreshes.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Ingestion | Python + `pandas-gbq` |
| Data Warehouse | Google BigQuery |
| Transformation | dbt (data build tool) |
| Orchestration | GitHub Actions (CI + scheduled cron) |
| Visualization | Looker Studio |

---

## Architecture

The pipeline follows a **Medallion Architecture** with three layers:

```
GitHub API
    │
    ▼
🥉 Bronze (Raw)        — bigquery_loader.py → raw_github_data.*
    │
    ▼
🥈 Silver (Intermediate) — dbt models: cleaning, parsing, flagging
    │
    ▼
🥇 Gold (Marts)         — dbt models: fct_*, dim_* → Looker Studio
```

### Bronze — Ingestion
Raw JSON payloads from the GitHub `/issues` and `/pulls` endpoints are loaded into BigQuery via a Python script using `pandas-gbq`. The loader runs daily via a GitHub Actions cron job.

### Silver — Transformation
Heavy cleaning and enrichment in dbt:
- Regex parsing of PR descriptions to link Issues to Pull Requests
- Timestamp standardization for duration calculations
- Boolean flagging (`is_bug`, `is_community_contribution`)

### Gold — Marts
Optimized for reporting, following a Star Schema:

| Model | Type | Description |
|---|---|---|
| `fct_pull_requests` | Fact | One row per PR–Issue link, with merge and closure metrics |
| `fct_issues` | Fact | One row per issue, with resolution metrics |
| `fct_item_labels` | Bridge | Many-to-many relationship between items and labels |
| `dim_users` | Dimension | Unique GitHub users (humans and bots) |
| `dim_labels` | Dimension | Unique labels used in the repository |

<p align="center">
  <img src="assets/lineage_graph.png" width="80%" />
</p>

---

## Data Quality Tests

All Gold layer models are covered by dbt tests:

| Model | Tests |
|---|---|
| `dim_users` | `author_id`: unique, not_null |
| `dim_labels` | `label_key`: unique, not_null |
| `fct_pull_requests` | `pr_id`: not_null · `author_id`: referential integrity → `dim_users` |
| `fct_issues` | `issue_id`: unique, not_null · `author_id`: referential integrity → `dim_users` |
| `fct_item_labels` | `item_id`: not_null · `label_key`: referential integrity → `dim_labels` |

Tests run automatically on every pull request and push to `main` via the CI workflow. In production (`dbt build`), a model failing its tests will block all downstream models from running.

---

## CI/CD

Two GitHub Actions workflows are included:

### `ci.yml` — Pull Request Checks
Triggered on every PR and push to `main`:
1. Install dependencies (`dbt-bigquery`, `sqlfluff`)
2. Install dbt packages (`dbt deps`)
3. Lint SQL with SQLFluff
4. Run `dbt build --target dev` (models + tests)
5. Generate dbt docs (on merge to `main` only)

### `scheduled-pipeline.yml` — Daily Production Run
Runs every day at 02:00 UTC via cron:
1. Python ingestion script refreshes Bronze layer data in BigQuery
2. `dbt build --target prod` rebuilds Silver and Gold layers
3. All data quality tests run automatically

---

## Environments

Two dbt targets are configured in `profiles.yml`:

| Target | Dataset | Used by |
|---|---|---|
| `dev` | `dbt_github_analytics_dev` | Local development, CI checks |
| `prod` | `dbt_github_analytics` | Daily scheduled pipeline |

---

## Key Engineering Challenges

### Many-to-Many Label Relationships
A single PR or issue can have multiple labels. Joining labels directly to fact tables causes metric fan-out (e.g., a PR with 5 labels would inflate its "Hours to Merge" count by 5x in BI tools).

**Solution:** A bridge table (`fct_item_labels`) decouples labels from facts. In Looker Studio, Data Blending and `DISTINCT` logic ensure metrics like "Average Hours to Merge" are calculated once per item, regardless of how many labels it has.

### Dynamic Bug Identification
GitHub has no native "Bug" field — bug classification relies entirely on labels, which can be null or inconsistent.

**Solution:** A `COALESCE` + subquery pattern in dbt scans the label bridge table at the Silver layer. Any item with a label matching `%bug%` is flagged as `is_bug = true`, denormalized into `fct_issues` to enable simple boolean filtering in the dashboard without complex joins at query time.

---

## Key Metrics

- **Hours to Merge** — `TIMESTAMP_DIFF(merged_at, created_at, HOUR)`
- **Is Bug** — Boolean derived from label scanning, denormalized for performance
- **Community Contribution** — External vs. internal work identified via `author_association`

---

## Local Setup

### Prerequisites
- Python 3.11+
- A Google Cloud service account with BigQuery access
- A GitHub Personal Access Token (for higher API rate limits)

### Installation

```bash
# Clone the repo
git clone https://github.com/xulitong22/dbt_github_data_project.git
cd dbt_github_data_project

# Create and activate a virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your GCP project ID and service account credentials

source .env
```

### Running the Pipeline

```bash
# 1. Load raw data into BigQuery
python bigquery_loader.py

# 2. Install dbt packages
cd dbt_github
dbt deps

# 3. Run dbt (models + tests)
dbt build --target dev
```

### Required GitHub Secrets (for CI/CD)

| Secret | Description |
|---|---|
| `GCP_PROJECT_ID` | Your Google Cloud project ID |
| `BIGQUERY_DATASET` | Target BigQuery dataset name |
| `BIGQUERY_KEYFILE` | Full contents of your service account JSON |

