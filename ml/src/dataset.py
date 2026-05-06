"""Dataset loaders and stratified splitters for West African scam corpora."""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import pandas as pd

DATA_ROOT = Path(__file__).resolve().parents[1] / "data"

REQUIRED_COLUMNS = ("text", "label", "language", "source")

SCAM_LABELS = (
    "advance_fee_fraud",
    "mobile_money_fraud",
    "phishing",
    "romance_scam",
    "identity_theft",
    "none",
)


@dataclass
class Split:
    train: pd.DataFrame
    val: pd.DataFrame
    test: pd.DataFrame


def load_csv(path: str | Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    missing = set(REQUIRED_COLUMNS) - set(df.columns)
    if missing:
        raise ValueError(f"missing columns in {path}: {sorted(missing)}")
    bad = set(df["label"].unique()) - set(SCAM_LABELS)
    if bad:
        raise ValueError(f"unknown labels in {path}: {sorted(bad)}")
    return df


def stratified_split(
    df: pd.DataFrame,
    train_frac: float = 0.7,
    val_frac: float = 0.15,
    seed: int = 42,
) -> Split:
    from sklearn.model_selection import train_test_split

    train, temp = train_test_split(
        df, train_size=train_frac, stratify=df["label"], random_state=seed
    )
    rel_val = val_frac / (1 - train_frac)
    val, test = train_test_split(
        temp, train_size=rel_val, stratify=temp["label"], random_state=seed
    )
    return Split(
        train=train.reset_index(drop=True),
        val=val.reset_index(drop=True),
        test=test.reset_index(drop=True),
    )
