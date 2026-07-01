"""FastAPI service for the v3 four-class scam classifier.

v3 is the v2 model retrained on the corpus after the CMU-Africa honeynet capture
was folded in. Same recipe (TF-IDF + Logistic Regression), more and more realistic
mobile-money data, so the mobile-money class and the African-language slices read
better. Pure scikit-learn, so there is no cold-start model download.

Drop-in API compatible with the v2 service the mobile app already calls:
    POST /predict        {"text": "..."} -> {predicted_category, confidence, scores}
    POST /predict_batch  [{"text": "..."}, ...]
    GET  /health , GET / , GET /docs

Run locally (from ml/):
    python -m uvicorn cmu_v3_serve.app:app --port 8002
"""

from __future__ import annotations

import os
from pathlib import Path

import joblib
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

HERE = Path(__file__).resolve().parent                  # ml/cmu_v3_serve/
ML_ROOT = HERE.parent                                   # ml/
_CANDIDATES = [
    HERE / "scam_tfidf_v3.joblib",
    ML_ROOT / "notebooks" / "cmu_corpus_v3" / "scam_tfidf_v3.joblib",
]
MODEL_PATH = next((p for p in _CANDIDATES if p.exists()), _CANDIDATES[-1])

CLASS_ORDER = ["advance_fee_fraud", "mobile_money_fraud", "phishing", "not_a_scam"]

app = FastAPI(
    title="Scam Message Classifier — v3 (TF-IDF, honeynet-enriched)",
    description=(
        "Four-class classifier retrained on the corpus after adding the CMU-Africa "
        "Upanzi honeynet capture. Classes: advance_fee_fraud, mobile_money_fraud, "
        "phishing, not_a_scam. Languages: English, Portuguese, Swahili, Kinyarwanda. "
        "No embedder -> instant cold start."
    ),
    version="3.0.0",
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
    global _bundle
    if _bundle is None:
        if not MODEL_PATH.exists():
            raise HTTPException(503, "Model missing. Run "
                                     "notebooks/cmu_corpus_v3/cmu_corpus_v3.ipynb")
        _bundle = joblib.load(MODEL_PATH)
    return _bundle


class Message(BaseModel):
    text: str = Field(..., min_length=1, examples=[
        "Niba byagushobokera nkakugora, ohereza amafranga kuri iyi nimero ya mobile money."])


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
        "version": "v3",
        "macro_f1": b.get("macro_f1"),
        "corpus": b.get("corpus", "demo_labeled_v3.jsonl"),
        "languages": ["en", "pt", "sw", "rw"],
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
