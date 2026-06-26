"""Lightweight FastAPI serving app for the v2 scam-message classifier.

Serves the project's best model on the expanded multilingual corpus:
TF-IDF + Logistic Regression (test macro-F1 0.946 over 9,623 messages in
English / Portuguese / Swahili). Pure scikit-learn — no torch, no sentence
embedder — so the container is tiny and there is **no cold-start model download**
(the failure mode the e5 ensemble had on a sleeping free Space).

Drop-in API compatible with the v1 ensemble service the mobile app already calls:
    POST /predict        {"text": "..."} -> {predicted_category, confidence, scores}
    POST /predict_batch  [{"text": "..."}, ...]
    GET  /health , GET / , GET /docs

Run locally (from ml/):
    python -m uvicorn final_serve.app:app --port 8000
"""

from __future__ import annotations

import os
from pathlib import Path

import joblib
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

HERE = Path(__file__).resolve().parent                  # ml/final_serve/
ML_ROOT = HERE.parent                                   # ml/
# The model lives with its notebook (notebooks/final_model/); a copy is bundled
# beside this app when deployed to a container. Use whichever exists.
_CANDIDATES = [
    HERE / "scam_tfidf_v2.joblib",
    ML_ROOT / "notebooks" / "final_model" / "scam_tfidf_v2.joblib",
]
MODEL_PATH = next((p for p in _CANDIDATES if p.exists()), _CANDIDATES[-1])

CLASS_ORDER = ["advance_fee_fraud", "mobile_money_fraud", "phishing", "not_a_scam"]

app = FastAPI(
    title="Scam Message Classifier — v2 (TF-IDF, multilingual)",
    description=(
        "Best model on the expanded African corpus: TF-IDF + Logistic Regression. "
        "Classifies a short message as advance_fee_fraud, mobile_money_fraud, "
        "phishing, or not_a_scam. Trained on English / Portuguese / Swahili "
        "(9,623 messages). Test macro-F1 0.946. No embedder -> instant cold start."
    ),
    version="2.0.0",
)

_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in _origins],
    allow_methods=["*"],
    allow_headers=["*"],
)

_bundle = None


def get_model():
    """Load the joblib once (cheap, ~1.5 MB, no network)."""
    global _bundle
    if _bundle is None:
        if not MODEL_PATH.exists():
            raise HTTPException(503, "Model missing. Run notebooks/final_model/final_model.ipynb "
                                     "(or scripts/13_export_tfidf_v2.py)")
        _bundle = joblib.load(MODEL_PATH)
    return _bundle


class Message(BaseModel):
    text: str = Field(..., min_length=1, examples=[
        "Iyo pesa itume kwenye namba hii ya Airtel 0689933027 jina PETER NYANGE."])


class Prediction(BaseModel):
    text: str
    predicted_category: str
    confidence: float
    scores: dict[str, float]


def _predict(texts: list[str]) -> list[Prediction]:
    bundle = get_model()
    pipe = bundle["pipeline"]
    classes = list(pipe.classes_)
    proba = pipe.predict_proba(texts)
    out: list[Prediction] = []
    for text, row in zip(texts, proba):
        scores = {c: float(row[classes.index(c)]) for c in CLASS_ORDER}
        label = max(scores, key=scores.get)
        out.append(Prediction(text=text, predicted_category=label,
                              confidence=round(scores[label], 4),
                              scores={c: round(s, 4) for c, s in scores.items()}))
    return out


@app.get("/", summary="Service info")
def root():
    b = get_model()
    return {
        "service": "scam-message-classifier",
        "model": b.get("model_name", "tfidf_logreg"),
        "version": "v2",
        "macro_f1": b.get("macro_f1", 0.946),
        "corpus": b.get("corpus", "demo_labeled_v2.jsonl"),
        "languages": ["en", "pt", "sw"],
        "classes": CLASS_ORDER,
        "status": "ok",
        "docs": "/docs",
    }


@app.get("/health", summary="Health check")
def health():
    return {"status": "healthy", "model_present": MODEL_PATH.exists()}


@app.post("/predict", response_model=Prediction, summary="Classify a single message")
def predict(msg: Message):
    return _predict([msg.text])[0]


@app.post("/predict_batch", summary="Classify many messages")
def predict_batch(messages: list[Message]):
    return _predict([m.text for m in messages])
