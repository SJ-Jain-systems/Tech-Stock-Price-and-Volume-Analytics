-- Derive drawdown, downside-risk, and tail-risk metrics for each technology stock.
-- Metrics are built from clean adjusted-close prices and daily return features.

CREATE OR REPLACE TABLE drawdowns AS
SELECT
    symbol,
    date,
    adj_close,
    MAX(adj_close) OVER (
        PARTITION BY symbol
        ORDER BY date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_peak,
    (adj_close / MAX(adj_close) OVER (
        PARTITION BY symbol
        ORDER BY date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )) - 1 AS drawdown
FROM clean_prices
ORDER BY symbol, date;

CREATE OR REPLACE VIEW stock_level_risk_summary AS
WITH return_summary AS (
    SELECT
        symbol,
        MIN(date) AS start_date,
        MAX(date) AS end_date,
        COUNT(*) AS trading_days,
        AVG(log_return) * 252 AS annualized_return,
        STDDEV_SAMP(log_return) * SQRT(252) AS annualized_volatility,
        MIN(simple_return) AS worst_daily_return,
        MAX(simple_return) AS best_daily_return,
        AVG(CASE WHEN simple_return <= -0.02 THEN 1.0 ELSE 0.0 END) AS bad_day_rate_2pct,
        AVG(CASE WHEN simple_return <= -0.05 THEN 1.0 ELSE 0.0 END) AS bad_day_rate_5pct,
        AVG(volume) AS avg_daily_volume,
        AVG(dollar_volume) AS avg_dollar_volume
    FROM daily_returns
    GROUP BY symbol
), drawdown_summary AS (
    SELECT
        symbol,
        MIN(drawdown) AS max_drawdown
    FROM drawdowns
    GROUP BY symbol
)
SELECT
    r.symbol,
    r.start_date,
    r.end_date,
    r.trading_days,
    r.annualized_return,
    r.annualized_volatility,
    CASE
        WHEN r.annualized_volatility > 0
            THEN r.annualized_return / r.annualized_volatility
    END AS sharpe_like_ratio,
    d.max_drawdown,
    r.worst_daily_return,
    r.best_daily_return,
    r.bad_day_rate_2pct,
    r.bad_day_rate_5pct,
    r.avg_daily_volume,
    r.avg_dollar_volume
FROM return_summary AS r
LEFT JOIN drawdown_summary AS d
    ON r.symbol = d.symbol
ORDER BY r.symbol;

CREATE OR REPLACE VIEW annual_stock_metrics AS
WITH annual_return_summary AS (
    SELECT
        symbol,
        EXTRACT(YEAR FROM date)::INTEGER AS year,
        COUNT(*) AS trading_days,
        AVG(log_return) * 252 AS annualized_return,
        STDDEV_SAMP(log_return) * SQRT(252) AS annualized_volatility,
        MIN(simple_return) AS worst_daily_return,
        AVG(CASE WHEN simple_return <= -0.02 THEN 1.0 ELSE 0.0 END) AS bad_day_rate_2pct,
        AVG(CASE WHEN simple_return <= -0.05 THEN 1.0 ELSE 0.0 END) AS bad_day_rate_5pct
    FROM daily_returns
    GROUP BY symbol, year
), annual_drawdown_summary AS (
    SELECT
        symbol,
        EXTRACT(YEAR FROM date)::INTEGER AS year,
        MIN(drawdown) AS max_drawdown_in_year
    FROM drawdowns
    GROUP BY symbol, year
)
SELECT
    r.symbol,
    r.year,
    r.trading_days,
    r.annualized_return,
    r.annualized_volatility,
    CASE
        WHEN r.annualized_volatility > 0
            THEN r.annualized_return / r.annualized_volatility
    END AS sharpe_like_ratio,
    d.max_drawdown_in_year,
    r.worst_daily_return,
    r.bad_day_rate_2pct,
    r.bad_day_rate_5pct
FROM annual_return_summary AS r
LEFT JOIN annual_drawdown_summary AS d
    ON r.symbol = d.symbol
   AND r.year = d.year
ORDER BY r.symbol, r.year;
