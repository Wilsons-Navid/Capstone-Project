"""Evaluation utilities for scam classifiers."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence

import numpy as np
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    precision_recall_fscore_support,
)


@dataclass
class EvalResult:
    accuracy: float
    macro_f1: float
    per_class: dict
    confusion: np.ndarray
    report: str


def evaluate(y_true: Sequence, y_pred: Sequence, labels: Sequence[str]) -> EvalResult:
    acc = accuracy_score(y_true, y_pred)
    p, r, f, support = precision_recall_fscore_support(
        y_true, y_pred, labels=labels, zero_division=0
    )
    per_class = {
        label: {
            "precision": float(p[i]),
            "recall": float(r[i]),
            "f1": float(f[i]),
            "support": int(support[i]),
        }
        for i, label in enumerate(labels)
    }
    macro_f1 = float(np.mean(f))
    cm = confusion_matrix(y_true, y_pred, labels=labels)
    report = classification_report(y_true, y_pred, labels=labels, zero_division=0)
    return EvalResult(acc, macro_f1, per_class, cm, report)


def evaluate_per_language(
    y_true: Sequence,
    y_pred: Sequence,
    languages: Sequence[str],
    labels: Sequence[str],
) -> dict[str, EvalResult]:
    """Stratified evaluation by language column."""
    arr_lang = np.asarray(languages)
    arr_true = np.asarray(y_true)
    arr_pred = np.asarray(y_pred)
    return {
        str(lang): evaluate(arr_true[arr_lang == lang], arr_pred[arr_lang == lang], labels)
        for lang in np.unique(arr_lang)
    }
