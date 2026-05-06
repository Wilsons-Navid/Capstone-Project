"""Classical ML baselines for scam classification."""
from __future__ import annotations

from sklearn.ensemble import GradientBoostingClassifier, RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline


def make_tfidf_lr(C: float = 1.0) -> Pipeline:
    return Pipeline([
        ("tfidf", TfidfVectorizer(ngram_range=(1, 2), min_df=2, max_features=50_000)),
        ("clf", LogisticRegression(C=C, max_iter=1000, class_weight="balanced")),
    ])


def make_tfidf_rf(n_estimators: int = 300) -> Pipeline:
    return Pipeline([
        ("tfidf", TfidfVectorizer(ngram_range=(1, 2), min_df=2, max_features=50_000)),
        ("clf", RandomForestClassifier(
            n_estimators=n_estimators, n_jobs=-1, class_weight="balanced", random_state=42,
        )),
    ])


def make_tfidf_gb(n_estimators: int = 300) -> Pipeline:
    return Pipeline([
        ("tfidf", TfidfVectorizer(ngram_range=(1, 2), min_df=2, max_features=50_000)),
        ("clf", GradientBoostingClassifier(n_estimators=n_estimators, random_state=42)),
    ])


BASELINES = {
    "tfidf_lr": make_tfidf_lr,
    "tfidf_rf": make_tfidf_rf,
    "tfidf_gb": make_tfidf_gb,
}
