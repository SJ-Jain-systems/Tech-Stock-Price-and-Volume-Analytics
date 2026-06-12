-- Compute adjusted-close daily returns, calendar-month returns, and annual
-- returns by symbol for downstream feature engineering and risk modeling.
CREATE OR REPLACE TABLE daily_returns AS
WITH lagged_prices AS (
    SELECT
        symbol,
        date,
        adj_close,
        volume,
        LAG(adj_close) OVER (
            PARTITION BY symbol
            ORDER BY date
        ) AS previous_adj_close
    FROM clean_prices
)
SELECT
    symbol,
    date,
    adj_close,
    volume,
    (adj_close / previous_adj_close) - 1 AS simple_return,
    LN(adj_close / previous_adj_close) AS log_return,
    adj_close * volume AS dollar_volume
FROM lagged_prices
WHERE previous_adj_close IS NOT NULL
ORDER BY symbol, date;

CREATE OR REPLACE VIEW monthly_returns AS
WITH monthly_prices AS (
    SELECT
        symbol,
        EXTRACT(YEAR FROM date)::INTEGER AS year,
        EXTRACT(MONTH FROM date)::INTEGER AS month,
        MIN(date) AS month_start_date,
        MAX(date) AS month_end_date,
        ARG_MIN(adj_close, date) AS first_price,
        ARG_MAX(adj_close, date) AS last_price,
        SUM(volume) AS monthly_volume
    FROM clean_prices
    GROUP BY symbol, year, month
)
SELECT
    symbol,
    year,
    month,
    month_start_date,
    month_end_date,
    (last_price / first_price) - 1 AS monthly_return,
    LN(last_price / first_price) AS monthly_log_return,
    monthly_volume
FROM monthly_prices
ORDER BY symbol, year, month;

CREATE OR REPLACE VIEW annual_returns AS
WITH annual_prices AS (
    SELECT
        symbol,
        EXTRACT(YEAR FROM date)::INTEGER AS year,
        ARG_MIN(adj_close, date) AS first_price,
        ARG_MAX(adj_close, date) AS last_price,
        SUM(volume) AS annual_volume
    FROM clean_prices
    GROUP BY symbol, year
)
SELECT
    symbol,
    year,
    first_price,
    last_price,
    (last_price / first_price) - 1 AS annual_return,
    LN(last_price / first_price) AS annual_log_return,
    annual_volume
FROM annual_prices
ORDER BY symbol, year;
