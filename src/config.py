"""Project configuration constants for paths, symbols, and default modeling settings."""

from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data"
RAW_DATA_DIR = DATA_DIR / "raw"
PROCESSED_DATA_DIR = DATA_DIR / "processed"
DATABASE_DIR = DATA_DIR / "database"
MODELS_DIR = PROJECT_ROOT / "models"
FIGURES_DIR = PROJECT_ROOT / "reports" / "figures"

TECH_SYMBOLS = ("AAPL", "AMZN", "FB", "GOOG", "MSFT", "NFLX", "NVDA")
RAW_CSV_NAME = "tech_stocks.csv"
