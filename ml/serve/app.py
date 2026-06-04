"""FastAPI serving app for the MAIN scam-message classifier.

Serves the soft-voting ensemble (TF-IDF Logistic Regression + multilingual-e5-small
embeddings -> Logistic Regression / Random Forest), the project's best model
(test macro-F1 0.955). Loads the self-contained ensemble saved by
`src/embed_model.py` (`models/embed_models.joblib`) plus the e5 embedder, and
exposes a prediction endpoint with interactive Swagger docs at /docs.

Run locally:
    python -m uvicorn serve.app:app --reload --port 8000   # from ml/
    # then open http://127.0.0.1:8000/docs

Classes: advance_fee_fraud | mobile_money_fraud | phishing | not_a_scam
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

ROOT = Path(__file__).resolve().parent.parent          # ml/
sys.path.insert(0, str(ROOT / "src"))
import embed_model as em                                # noqa: E402

MODEL_PATH = ROOT / "models" / "embed_models.joblib"

app = FastAPI(
    title="Scam Message Classifier — Ensemble (main model)",
    description=(
        "Soft-voting ensemble over a lexical TF-IDF model and multilingual "
        "e5-small sentence-embedding models. Classifies a short message as "
        "advance_fee_fraud, mobile_money_fraud, phishing, or not_a_scam. "
        "Multilingual (English / Portuguese / French + more). Test macro-F1 0.955."
    ),
    version="1.0.0",
)

# CORS — allow the mobile app / web front-ends to call this API.
_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in _origins],
    allow_methods=["*"],
    allow_headers=["*"],
)

_models = None


def get_models():
    """Lazy-load the ensemble + embedder once (first request warms it)."""
    global _models
    if _models is None:
        if not MODEL_PATH.exists():
            raise HTTPException(503, "Model not trained. Run: python src/embed_model.py")
        _models = em.load_ensemble(MODEL_PATH)
        em.predict_loaded(["warmup"], _models)          # pull the e5 weights now
    return _models


class Message(BaseModel):
    text: str = Field(..., min_length=1, examples=[
        "Caro cliente, a sua conta M-Pesa foi bloqueada. Envie o seu PIN para reactivar."])


class Prediction(BaseModel):
    text: str
    predicted_category: str
    confidence: float
    scores: dict[str, float]


def _predict_one(text: str) -> Prediction:
    label, conf, scores = em.predict_loaded([text], get_models())[0]
    return Prediction(text=text, predicted_category=label,
                      confidence=round(conf, 4),
                      scores={c: round(p, 4) for c, p in scores.items()})


@app.get("/", summary="Service info")
def root():
    return {
        "service": "scam-message-classifier",
        "model": "soft-voting ensemble (tfidf_logreg + e5_logreg + e5_rf)",
        "macro_f1": 0.955,
        "classes": em.CLASS_ORDER,
        "status": "ok",
        "docs": "/docs",
    }


@app.get("/health", summary="Health check")
def health():
    return {"status": "healthy", "model_present": MODEL_PATH.exists()}


@app.post("/predict", response_model=Prediction, summary="Classify a single message")
def predict(msg: Message):
    return _predict_one(msg.text)


@app.post("/predict_batch", summary="Classify many messages")
def predict_batch(messages: list[Message]):
    models = get_models()
    results = em.predict_loaded([m.text for m in messages], models)
    return [{"text": m.text, "predicted_category": label, "confidence": round(conf, 4),
             "scores": {c: round(p, 4) for c, p in scores.items()}}
            for m, (label, conf, scores) in zip(messages, results)]
