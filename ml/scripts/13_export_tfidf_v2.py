"""Export the standalone v2 serving model (TF-IDF + Logistic Regression).

Pulls the fitted tfidf_logreg pipeline out of the v2 ensemble bundle and saves it
as a small self-contained joblib for the lightweight `serve_v2` API. This is the
best model on the expanded corpus (test macro-F1 0.946) and needs no embedder.

Run (from ml/):  python scripts/13_export_tfidf_v2.py
"""

from __future__ import annotations

from pathlib import Path

import joblib

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "models" / "embed_models_v2.joblib"
OUT = ROOT / "models" / "scam_tfidf_v2.joblib"


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"missing {SRC} — run notebooks/build_main_notebook_v2.py first")
    b = joblib.load(SRC)
    bundle = {
        "pipeline": b["tfidf_logreg"],
        "class_order": b["class_order"],
        "model_name": "tfidf_logreg",
        "macro_f1": 0.946,
        "corpus": "demo_labeled_v2.jsonl",
    }
    joblib.dump(bundle, OUT)
    print(f"saved {OUT.relative_to(ROOT)} ({OUT.stat().st_size/1e6:.2f} MB)")


if __name__ == "__main__":
    main()
