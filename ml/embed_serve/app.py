"""FastAPI serving app for the embedding-ensemble scam-message classifier.

Serves the soft-voting ensemble (TF-IDF Logistic Regression + multilingual-e5-small
embeddings -> Logistic Regression / Random Forest), test macro-F1 0.955 on the v1
corpus. Loads the self-contained ensemble bundle produced by the embed_demo
notebook (`notebooks/embed_demo/embed_models.joblib`) plus the e5 embedder, and
exposes a prediction endpoint with interactive Swagger docs at /docs.

Self-contained: the serving logic is inlined here (the notebooks own the training
code), so this app has no dependency on the rest of the project.

Run locally (from ml/):
    python -m uvicorn embed_serve.app:app --reload --port 8000
    # then open http://127.0.0.1:8000/docs

Classes: advance_fee_fraud | mobile_money_fraud | phishing | not_a_scam
"""

from __future__ import annotations

import os
from pathlib import Path

import joblib
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

HERE = Path(__file__).resolve().parent                  # ml/embed_serve/
ML_ROOT = HERE.parent                                   # ml/
_CANDIDATES = [
    HERE / "embed_models.joblib",
    ML_ROOT / "notebooks" / "embed_demo" / "embed_models.joblib",
]
MODEL_PATH = next((p for p in _CANDIDATES if p.exists()), _CANDIDATES[-1])

CLASS_ORDER = ["advance_fee_fraud", "mobile_money_fraud", "phishing", "not_a_scam"]
EMB_PREFIX = "query: "

app = FastAPI(
    title="Scam Message Classifier — Ensemble (embed_demo)",
    description=(
        "Soft-voting ensemble over a lexical TF-IDF model and multilingual "
        "e5-small sentence-embedding models. Classifies a short message as "
        "advance_fee_fraud, mobile_money_fraud, phishing, or not_a_scam. "
        "Multilingual (English / Portuguese / French + more). Test macro-F1 0.955."
    ),
    version="1.0.0",
)

_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in _origins],
    allow_methods=["*"],
    allow_headers=["*"],
)

_models = None
_embedder = None


def get_models():
    """Lazy-load the ensemble bundle once (first request warms the embedder)."""
    global _models, _embedder
    if _models is None:
        if not MODEL_PATH.exists():
            raise HTTPException(503, "Model missing. Run notebooks/embed_demo/embed_demo.ipynb")
        _models = joblib.load(MODEL_PATH)
        from sentence_transformers import SentenceTransformer
        _embedder = SentenceTransformer(_models["embedder"])
    return _models


def _predict(texts: list[str]):
    models = get_models()
    order = models.get("class_order", CLASS_ORDER)
    emb = _embedder.encode([EMB_PREFIX + t for t in texts], normalize_embeddings=True)
    probs = []
    for m in models["members"]:
        X = texts if m.startswith("tfidf") else emb
        p = models[m].predict_proba(X)
        classes = list(models[m].classes_)
        probs.append(p[:, [classes.index(c) for c in order]])
    avg = np.mean(probs, axis=0)
    out = []
    for row in avg:
        ranked = sorted(zip(order, row), key=lambda x: -x[1])
        out.append((ranked[0][0], float(ranked[0][1]),
                    {c: float(p) for c, p in zip(order, row)}))
    return out


class Message(BaseModel):
    text: str = Field(..., min_length=1, examples=[
        "Caro cliente, a sua conta M-Pesa foi bloqueada. Envie o seu PIN para reactivar."])


class Prediction(BaseModel):
    text: str
    predicted_category: str
    confidence: float
    scores: dict[str, float]


@app.get("/", summary="Service info")
def root():
    return {
        "service": "scam-message-classifier",
        "model": "soft-voting ensemble (tfidf_logreg + e5_logreg + e5_rf)",
        "macro_f1": 0.955,
        "classes": CLASS_ORDER,
        "status": "ok",
        "docs": "/docs",
    }


@app.get("/health", summary="Health check")
def health():
    return {"status": "healthy", "model_present": MODEL_PATH.exists()}


@app.post("/predict", response_model=Prediction, summary="Classify a single message")
def predict(msg: Message):
    label, conf, scores = _predict([msg.text])[0]
    return Prediction(text=msg.text, predicted_category=label, confidence=round(conf, 4),
                      scores={c: round(s, 4) for c, s in scores.items()})


@app.post("/predict_batch", summary="Classify many messages")
def predict_batch(messages: list[Message]):
    results = _predict([m.text for m in messages])
    return [{"text": m.text, "predicted_category": label, "confidence": round(conf, 4),
             "scores": {c: round(s, 4) for c, s in scores.items()}}
            for m, (label, conf, scores) in zip(messages, results)]
