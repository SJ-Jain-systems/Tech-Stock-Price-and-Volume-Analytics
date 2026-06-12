-- Prepare aligned daily-return panels and summary statistics for Bayesian
-- portfolio modeling.  The selected universe matches the project configuration:
-- AAPL, AMZN, FB, GOOG, MSFT, NFLX, and NVDA.

CREATE OR REPLACE VIEW aligned_daily_returns AS
WITH selected_symbols(symbol) AS (
    VALUES
        ('AAPL'),
        ('AMZN'),
        ('FB'),
        ('GOOG'),
        ('MSFT'),
        ('NFLX'),
        ('NVDA')
), valid_selected_returns AS (
    SELECT
        r.symbol,
        r.date,
        r.log_return
    FROM daily_returns AS r
    INNER JOIN selected_symbols AS s
        ON r.symbol = s.symbol
    WHERE r.log_return IS NOT NULL
), symbol_coverage AS (
    SELECT
        symbol,
        MIN(date) AS first_return_date,
        MAX(date) AS last_return_date
    FROM valid_selected_returns
    GROUP BY symbol
), candidate_dates AS (
    SELECT DISTINCT date
    FROM valid_selected_returns
), expected_available_symbols AS (
    SELECT
        d.date,
        COUNT(*) AS expected_symbol_count
    FROM candidate_dates AS d
    INNER JOIN symbol_coverage AS c
        ON d.date BETWEEN c.first_return_date AND c.last_return_date
    GROUP BY d.date
), actual_available_symbols AS (
    SELECT
        date,
        COUNT(DISTINCT symbol) AS actual_symbol_count
    FROM valid_selected_returns
    GROUP BY date
), aligned_dates AS (
    SELECT e.date
    FROM expected_available_symbols AS e
    INNER JOIN actual_available_symbols AS a
        ON e.date = a.date
    WHERE e.expected_symbol_count = a.actual_symbol_count
)
SELECT
    r.symbol,
    r.date,
    r.log_return
FROM valid_selected_returns AS r
INNER JOIN aligned_dates AS d
    ON r.date = d.date
ORDER BY r.date, r.symbol;

CREATE OR REPLACE VIEW restricted_aligned_daily_returns AS
WITH selected_symbols(symbol) AS (
    VALUES
        ('AAPL'),
        ('AMZN'),
        ('FB'),
        ('GOOG'),
        ('MSFT'),
        ('NFLX'),
        ('NVDA')
), restricted_bounds AS (
    SELECT
        MAX(first_return_date) AS start_date,
        MIN(last_return_date) AS end_date,
        COUNT(*) AS symbol_count
    FROM (
        SELECT
            r.symbol,
            MIN(r.date) AS first_return_date,
            MAX(r.date) AS last_return_date
        FROM daily_returns AS r
        INNER JOIN selected_symbols AS s
            ON r.symbol = s.symbol
        WHERE r.log_return IS NOT NULL
        GROUP BY r.symbol
    ) AS coverage
)
SELECT
    r.symbol,
    r.date,
    r.log_return
FROM aligned_daily_returns AS r
CROSS JOIN restricted_bounds AS b
WHERE r.date BETWEEN b.start_date AND b.end_date
  AND b.symbol_count = 7
ORDER BY r.date, r.symbol;

CREATE OR REPLACE VIEW portfolio_returns_wide AS
SELECT
    date,
    MAX(CASE WHEN symbol = 'AAPL' THEN log_return END) AS AAPL,
    MAX(CASE WHEN symbol = 'AMZN' THEN log_return END) AS AMZN,
    MAX(CASE WHEN symbol = 'FB' THEN log_return END) AS FB,
    MAX(CASE WHEN symbol = 'GOOG' THEN log_return END) AS GOOG,
    MAX(CASE WHEN symbol = 'MSFT' THEN log_return END) AS MSFT,
    MAX(CASE WHEN symbol = 'NFLX' THEN log_return END) AS NFLX,
    MAX(CASE WHEN symbol = 'NVDA' THEN log_return END) AS NVDA
FROM restricted_aligned_daily_returns
GROUP BY date
HAVING COUNT(DISTINCT symbol) = 7
ORDER BY date;

CREATE OR REPLACE VIEW portfolio_summary_inputs AS
SELECT
    symbol,
    AVG(log_return) AS mean_daily_return,
    STDDEV_SAMP(log_return) AS daily_volatility,
    AVG(log_return) * 252 AS annualized_return,
    STDDEV_SAMP(log_return) * SQRT(252) AS annualized_volatility,
    COUNT(*) AS trading_days
FROM restricted_aligned_daily_returns
GROUP BY symbol
ORDER BY symbol;

CREATE OR REPLACE VIEW return_correlation_matrix_long AS
WITH symbol_pairs AS (
    SELECT
        s1.symbol AS symbol_1,
        s2.symbol AS symbol_2
    FROM portfolio_summary_inputs AS s1
    CROSS JOIN portfolio_summary_inputs AS s2
), paired_returns AS (
    SELECT
        p.symbol_1,
        p.symbol_2,
        r1.log_return AS return_1,
        r2.log_return AS return_2
    FROM symbol_pairs AS p
    INNER JOIN restricted_aligned_daily_returns AS r1
        ON p.symbol_1 = r1.symbol
    INNER JOIN restricted_aligned_daily_returns AS r2
        ON p.symbol_2 = r2.symbol
       AND r1.date = r2.date
)
SELECT
    symbol_1,
    symbol_2,
    CORR(return_1, return_2) AS correlation
FROM paired_returns
GROUP BY symbol_1, symbol_2
ORDER BY symbol_1, symbol_2;
