-- Generate rolling volatility, moving-average, liquidity, and momentum features
-- from daily adjusted-close returns.  Windowed calculations are partitioned by
-- symbol and ordered by date, while early rows are retained with NULL values
-- until a complete lookback window is available.
CREATE OR REPLACE TABLE rolling_features AS
WITH windowed_features AS (
    SELECT
        symbol,
        date,
        adj_close,
        volume,
        simple_return,
        log_return,
        dollar_volume,

        -- Momentum features
        (adj_close / LAG(adj_close, 21) OVER symbol_by_date) - 1 AS return_21d,
        (adj_close / LAG(adj_close, 63) OVER symbol_by_date) - 1 AS return_63d,
        (adj_close / LAG(adj_close, 126) OVER symbol_by_date) - 1 AS return_126d,
        (adj_close / LAG(adj_close, 252) OVER symbol_by_date) - 1 AS return_252d,

        -- Rolling return statistics
        COUNT(simple_return) OVER window_21d AS return_count_21d,
        AVG(simple_return) OVER window_21d AS raw_rolling_mean_21d,
        STDDEV_SAMP(simple_return) OVER window_21d AS raw_rolling_vol_21d,
        COUNT(simple_return) OVER window_63d AS return_count_63d,
        STDDEV_SAMP(simple_return) OVER window_63d AS raw_rolling_vol_63d,
        COUNT(simple_return) OVER window_126d AS return_count_126d,
        STDDEV_SAMP(simple_return) OVER window_126d AS raw_rolling_vol_126d,
        COUNT(simple_return) OVER window_252d AS return_count_252d,
        STDDEV_SAMP(simple_return) OVER window_252d AS raw_rolling_vol_252d,

        -- Moving averages
        COUNT(adj_close) OVER window_20d AS price_count_20d,
        AVG(adj_close) OVER window_20d AS raw_ma_20,
        COUNT(adj_close) OVER window_50d AS price_count_50d,
        AVG(adj_close) OVER window_50d AS raw_ma_50,
        COUNT(adj_close) OVER window_200d AS price_count_200d,
        AVG(adj_close) OVER window_200d AS raw_ma_200,

        -- Liquidity features
        COUNT(volume) OVER window_21d AS volume_count_21d,
        AVG(volume) OVER window_21d AS raw_avg_volume_21d,
        COUNT(volume) OVER window_63d AS volume_count_63d,
        AVG(volume) OVER window_63d AS raw_avg_volume_63d,
        STDDEV_SAMP(volume) OVER window_63d AS raw_volume_stddev_63d,
        COUNT(dollar_volume) OVER window_21d AS dollar_volume_count_21d,
        AVG(dollar_volume) OVER window_21d AS raw_avg_dollar_volume_21d
    FROM daily_returns
    WINDOW
        symbol_by_date AS (
            PARTITION BY symbol
            ORDER BY date
        ),
        window_20d AS (
            PARTITION BY symbol
            ORDER BY date
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ),
        window_21d AS (
            PARTITION BY symbol
            ORDER BY date
            ROWS BETWEEN 20 PRECEDING AND CURRENT ROW
        ),
        window_50d AS (
            PARTITION BY symbol
            ORDER BY date
            ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
        ),
        window_63d AS (
            PARTITION BY symbol
            ORDER BY date
            ROWS BETWEEN 62 PRECEDING AND CURRENT ROW
        ),
        window_126d AS (
            PARTITION BY symbol
            ORDER BY date
            ROWS BETWEEN 125 PRECEDING AND CURRENT ROW
        ),
        window_200d AS (
            PARTITION BY symbol
            ORDER BY date
            ROWS BETWEEN 199 PRECEDING AND CURRENT ROW
        ),
        window_252d AS (
            PARTITION BY symbol
            ORDER BY date
            ROWS BETWEEN 251 PRECEDING AND CURRENT ROW
        )
), complete_windows AS (
    SELECT
        symbol,
        date,
        adj_close,
        volume,
        simple_return,
        log_return,
        dollar_volume,
        return_21d,
        return_63d,
        return_126d,
        return_252d,
        CASE WHEN return_count_21d = 21 THEN raw_rolling_mean_21d END AS rolling_mean_21d,
        CASE WHEN return_count_21d = 21 THEN raw_rolling_vol_21d END AS rolling_vol_21d,
        CASE WHEN return_count_63d = 63 THEN raw_rolling_vol_63d END AS rolling_vol_63d,
        CASE WHEN return_count_126d = 126 THEN raw_rolling_vol_126d END AS rolling_vol_126d,
        CASE WHEN return_count_252d = 252 THEN raw_rolling_vol_252d END AS rolling_vol_252d,
        CASE WHEN price_count_20d = 20 THEN raw_ma_20 END AS ma_20,
        CASE WHEN price_count_50d = 50 THEN raw_ma_50 END AS ma_50,
        CASE WHEN price_count_200d = 200 THEN raw_ma_200 END AS ma_200,
        CASE WHEN volume_count_21d = 21 THEN raw_avg_volume_21d END AS avg_volume_21d,
        CASE WHEN volume_count_63d = 63 THEN raw_avg_volume_63d END AS avg_volume_63d,
        CASE WHEN dollar_volume_count_21d = 21 THEN raw_avg_dollar_volume_21d END AS avg_dollar_volume_21d,
        CASE
            WHEN volume_count_63d = 63 AND raw_volume_stddev_63d > 0
                THEN (volume - raw_avg_volume_63d) / raw_volume_stddev_63d
        END AS volume_zscore_63d
    FROM windowed_features
)
SELECT
    symbol,
    date,
    adj_close,
    volume,
    simple_return,
    log_return,
    dollar_volume,
    return_21d,
    return_63d,
    return_126d,
    return_252d,
    rolling_mean_21d,
    rolling_vol_21d,
    rolling_vol_63d,
    rolling_vol_126d,
    rolling_vol_252d,
    rolling_vol_21d * SQRT(252) AS rolling_ann_vol_21d,
    rolling_vol_63d * SQRT(252) AS rolling_ann_vol_63d,
    rolling_vol_126d * SQRT(252) AS rolling_ann_vol_126d,
    rolling_vol_252d * SQRT(252) AS rolling_ann_vol_252d,
    ma_20,
    ma_50,
    ma_200,
    CASE WHEN ma_20 IS NOT NULL THEN adj_close > ma_20 END AS above_ma_20,
    CASE WHEN ma_50 IS NOT NULL THEN adj_close > ma_50 END AS above_ma_50,
    CASE WHEN ma_200 IS NOT NULL THEN adj_close > ma_200 END AS above_ma_200,
    avg_volume_21d,
    avg_volume_63d,
    avg_dollar_volume_21d,
    volume_zscore_63d
FROM complete_windows
ORDER BY symbol, date;
