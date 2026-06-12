# bayesian-tech-equity-risk-lab

A professional financial data science project for studying large-cap technology equity risk with SQL feature engineering, Bayesian modeling, and portfolio analytics.

## Project Overview

`bayesian-tech-equity-risk-lab` is designed to analyze historical OHLCV data for major technology stocks and build a reproducible research workflow from raw market data through Bayesian risk modeling and portfolio decision support.

The project uses a CSV named `tech_stocks.csv` with the following fields:

- `Unnamed: 0`
- `symbol`
- `date`
- `open`
- `high`
- `low`
- `close`
- `close_adjusted`
- `volume`
- `split_coefficient`

Expected symbols:

- `AAPL`
- `AMZN`
- `FB`
- `GOOG`
- `MSFT`
- `NFLX`
- `NVDA`

## Goals

This repository will eventually provide an end-to-end workflow to:

1. Load and validate raw equity OHLCV data.
2. Store clean price history in a local analytical database.
3. Engineer daily returns, rolling volatility, drawdown, and portfolio inputs with SQL.
4. Explore financial behavior across large-cap technology stocks.
5. Estimate Bayesian return and volatility models with PyMC.
6. Quantify uncertainty in downside risk and regime behavior.
7. Build Bayesian portfolio optimization inputs.
8. Produce a final Quarto-compatible analytical report and dashboard.

## Repository Structure

```text
bayesian-tech-equity-risk-lab/
├── data/
│   ├── raw/                 # Optional local raw data staging; generated/local files not tracked by git
│   ├── processed/           # Cleaned intermediate datasets; not tracked by git
│   └── database/            # Local DuckDB databases; not tracked by git
├── tech_stocks.csv          # Tracked source OHLCV dataset for this project
├── models/
│   └── posterior_samples/   # Saved posterior draws and model artifacts; not tracked by git
├── notebooks/
│   ├── 01_data_quality_and_sql_loading.ipynb
│   ├── 02_financial_eda.ipynb
│   ├── 03_sql_feature_engineering.ipynb
│   ├── 04_bayesian_return_model.ipynb
│   ├── 05_bayesian_volatility_and_downside_risk.ipynb
│   ├── 06_bayesian_regime_model.ipynb
│   ├── 07_bayesian_portfolio_optimization.ipynb
│   └── 08_final_summary_dashboard.ipynb
├── reports/
│   ├── figures/             # Generated charts and dashboard assets; not tracked by git
│   └── final_report.qmd     # Quarto-compatible final report skeleton
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_clean_prices.sql
│   ├── 03_daily_returns.sql
│   ├── 04_rolling_features.sql
│   ├── 05_risk_metrics.sql
│   └── 06_portfolio_inputs.sql
├── src/
│   ├── __init__.py
│   ├── config.py
│   ├── data_loader.py
│   ├── sql_utils.py
│   ├── feature_engineering.py
│   ├── risk_metrics.py
│   ├── bayesian_models.py
│   ├── portfolio.py
│   └── visualization.py
├── .gitignore
├── README.md
└── requirements.txt
```

## Planned Workflow

### 1. Data Quality and SQL Loading

The first notebook will inspect `tech_stocks.csv`, validate schema assumptions, check missing values and duplicate rows, and load clean records into DuckDB.

### 2. Financial EDA

Exploratory analysis will compare price behavior, liquidity, adjusted-close histories, daily returns, volatility, correlation, drawdowns, and extreme-return events across tickers.

### 3. SQL Feature Engineering

The SQL scripts will define reproducible transformations for cleaned prices, daily returns, rolling features, risk metrics, and portfolio model inputs.

### 4. Bayesian Return Modeling

Bayesian models will estimate expected returns with uncertainty intervals rather than relying only on point estimates.

### 5. Bayesian Volatility and Downside Risk

Volatility, downside deviation, Value-at-Risk-style summaries, and tail-risk quantities will be modeled probabilistically.

### 6. Bayesian Regime Modeling

Regime models will explore whether return and volatility patterns differ across latent market states.

### 7. Bayesian Portfolio Optimization

Posterior return, risk, and covariance estimates will be translated into portfolio inputs that preserve uncertainty.

### 8. Final Summary Dashboard

The final notebook and Quarto report will summarize data quality, core findings, model diagnostics, risk estimates, and portfolio implications.

## Environment Setup

Create and activate a virtual environment, then install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Data Placement

The primary project dataset is tracked in the repository as:

```text
tech_stocks.csv
```

Optional local data staging files under `data/raw/`, processed outputs, local databases, generated figures, and model artifacts are intentionally excluded from version control.

## Current Status

This repository currently contains the project scaffold only. Full data loading, feature engineering, modeling, visualization, and reporting implementations will be added in later development phases.
