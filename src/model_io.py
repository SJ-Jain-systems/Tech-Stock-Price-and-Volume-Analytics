"""Input/output helpers for Bayesian model artifacts.

This module centralizes persistence for ArviZ posterior samples and summary
CSV tables so notebooks can save model outputs using consistent project paths.
"""

from __future__ import annotations

from pathlib import Path

import arviz as az
import pandas as pd

from src.config import MODELS_DIR, ROOT_DIR

POSTERIOR_SAMPLES_DIR: Path = MODELS_DIR / "posterior_samples"
TABLES_DIR: Path = ROOT_DIR / "reports" / "tables"


def ensure_model_dirs() -> None:
    """Create directories used for persisted model outputs if needed."""
    POSTERIOR_SAMPLES_DIR.mkdir(parents=True, exist_ok=True)
    TABLES_DIR.mkdir(parents=True, exist_ok=True)


def save_inference_data(idata: az.InferenceData, path: str | Path) -> Path:
    """Save an ArviZ ``InferenceData`` object to a NetCDF file.

    Parameters
    ----------
    idata:
        Fitted posterior samples and related ArviZ groups.
    path:
        Destination NetCDF path.

    Returns
    -------
    pathlib.Path
        The resolved destination path for convenient notebook display.
    """
    output_path = Path(path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    idata.to_netcdf(output_path)
    return output_path


def load_inference_data(path: str | Path) -> az.InferenceData:
    """Load a NetCDF file into an ArviZ ``InferenceData`` object."""
    return az.from_netcdf(Path(path))


def save_summary_table(df: pd.DataFrame, path: str | Path) -> Path:
    """Save a posterior summary table as a CSV file without the DataFrame index."""
    output_path = Path(path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_path, index=False)
    return output_path
