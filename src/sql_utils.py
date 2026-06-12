"""SQL utility functions for DuckDB-backed analytics workflows.

The helpers in this module are intentionally small and notebook-friendly: they
open local DuckDB connections, execute versioned SQL scripts, initialize the raw
price table from the validated CSV loader, and return query results as pandas
DataFrames.
"""

from __future__ import annotations

from pathlib import Path

import duckdb
from duckdb import DuckDBPyConnection
from pandas import DataFrame

from src.config import DUCKDB_PATH, RAW_CSV_PATH, SQL_DIR
from src.data_loader import load_raw_stock_data

PIPELINE_SQL_FILES: tuple[str, ...] = (
    "02_clean_prices.sql",
    "03_daily_returns.sql",
    "04_rolling_features.sql",
    "05_risk_metrics.sql",
    "06_portfolio_inputs.sql",
)


def get_connection(db_path: str | Path = DUCKDB_PATH) -> DuckDBPyConnection:
    """Return a DuckDB connection for the requested database path.

    Parameters
    ----------
    db_path:
        Path to the DuckDB database file. Use ``":memory:"`` for an in-memory
        database. Parent directories are created for file-backed databases.

    Returns
    -------
    duckdb.DuckDBPyConnection
        Open DuckDB connection ready for SQL execution.
    """

    if str(db_path) == ":memory:":
        return duckdb.connect(database=":memory:")

    database_path = Path(db_path)
    database_path.parent.mkdir(parents=True, exist_ok=True)
    return duckdb.connect(database=str(database_path))


def execute_sql_file(
    connection: DuckDBPyConnection, sql_file_path: str | Path
) -> None:
    """Read a SQL file from disk and execute it against a DuckDB connection.

    Parameters
    ----------
    connection:
        Open DuckDB connection that should execute the SQL script.
    sql_file_path:
        Path to a SQL file. The file may contain one statement, multiple
        semicolon-delimited statements, comments, or only comments.

    Raises
    ------
    FileNotFoundError
        If ``sql_file_path`` does not exist.
    """

    script_path = Path(sql_file_path)
    if not script_path.exists():
        raise FileNotFoundError(f"SQL file not found at: {script_path}")

    sql = script_path.read_text(encoding="utf-8")
    if _contains_executable_sql(sql):
        connection.execute(sql)


def initialize_database(
    raw_csv_path: str | Path = RAW_CSV_PATH,
    db_path: str | Path = DUCKDB_PATH,
) -> DuckDBPyConnection:
    """Create a DuckDB database and load the validated raw stock prices.

    This function is the standard notebook entry point for bootstrapping the SQL
    layer. It loads and validates the source CSV with
    :func:`src.data_loader.load_raw_stock_data`, creates or replaces the
    ``raw_prices`` table, executes ``sql/02_clean_prices.sql``, and returns the
    open connection for additional queries.

    Parameters
    ----------
    raw_csv_path:
        CSV file containing raw OHLCV stock prices.
    db_path:
        DuckDB database file to create or update. Use ``":memory:"`` for a
        transient in-memory database.

    Returns
    -------
    duckdb.DuckDBPyConnection
        Open connection containing ``raw_prices`` and cleaned SQL artifacts.
    """

    connection = get_connection(db_path)
    raw_prices = load_raw_stock_data(raw_csv_path)

    connection.register("raw_prices_df", raw_prices)
    try:
        connection.execute(
            """
            CREATE OR REPLACE TABLE raw_prices AS
            SELECT
                symbol,
                CAST(date AS DATE) AS date,
                open,
                high,
                low,
                close,
                close_adjusted,
                CAST(volume AS BIGINT) AS volume,
                split_coefficient
            FROM raw_prices_df
            """
        )
    finally:
        connection.unregister("raw_prices_df")

    execute_sql_file(connection, SQL_DIR / "02_clean_prices.sql")
    return connection


def run_sql_pipeline(connection: DuckDBPyConnection) -> None:
    """Execute the project SQL feature-engineering pipeline in order.

    Parameters
    ----------
    connection:
        Open DuckDB connection with a populated ``raw_prices`` table.
    """

    for sql_file_name in PIPELINE_SQL_FILES:
        execute_sql_file(connection, SQL_DIR / sql_file_name)


def query_to_df(connection: DuckDBPyConnection, query: str) -> DataFrame:
    """Run a SQL query and return the result as a pandas DataFrame.

    Parameters
    ----------
    connection:
        Open DuckDB connection to query.
    query:
        SQL query text to execute.

    Returns
    -------
    pandas.DataFrame
        Query result materialized as a pandas DataFrame.
    """

    return connection.execute(query).df()


def _contains_executable_sql(sql: str) -> bool:
    """Return ``True`` when SQL text contains more than comments/whitespace."""

    for line in sql.splitlines():
        stripped_line = line.strip()
        if stripped_line and not stripped_line.startswith("--"):
            return True
    return False
