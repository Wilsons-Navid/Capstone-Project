"""FastAPI serving app for the INITIAL demo classifier (TF-IDF + Logistic Regression).

Serves the first baseline model produced by the initial_demo notebook
(`notebooks/initial_demo/scam_classifier.joblib`), trained on the v1 English /
Portuguese corpus. Pure scikit-learn — no embedder, tiny and instant.

Self-contained: the saved artifact is a plain scikit-learn Pipeline, so this app
loads it directly with no project dependency.

Run locally (from ml/):
    python -m uvicorn initial_serve.app:app --reload --port 8000
    # then open http://127.0.0.1:8000/docs

Classes: advance_fee_fraud | mobile_money_fraud | phishing | not_a_scam
"""

from __future__ import annotations

import os
from pathlib import Path

import joblib
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

HERE = Path(__file__).resolve().parent                  # ml/initial_serve/
ML_ROOT = HERE.parent                                   # ml/
_CANDIDATES = [
    HERE / "scam_classifier.joblib",
    ML_ROOT / "notebooks" / "initial_demo" / "scam_classifier.joblib",
]
MODEL_PATH = next((p for p in _CANDIDATES if p.exists()), _CANDIDATES[-1])

CLASS_ORDER = ["advance_fee_fraud", "mobile_money_fraud", "phishing", "not_a_scam"]

app = FastAPI(
    title="Scam Message Classifier — Initial demo (TF-IDF)",
    description=(
        "The initial baseline: a TF-IDF + Logistic Regression pipeline on the v1 "
        "English / Portuguese corpus. Classifies a short message as "
        "advance_fee_fraud, mobile_money_fraud, phishing, or not_a_scam."
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

_pipe = None


def get_model():
    """Load the fitted Pipeline once (cheap, no network)."""
    global _pipe
    if _pipe is None:
        if not MODEL_PATH.exists():
            raise HTTPException(503, "Model missing. Run notebooks/initial_demo/initial_demo.ipynb")
        _pipe = joblib.load(MODEL_PATH)
    return _pipe


class Message(BaseModel):
    text: str = Field(..., min_length=1, examples=[
        "URGENT! Your number won a 2000 prize. Call 09061790121 to claim."])


class Prediction(BaseModel):
    text: str
    predicted_category: str
    confidence: float
    scores: dict[str, float]


def _predict(texts: list[str]) -> list[Prediction]:
    pipe = get_model()
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
    return {
        "service": "scam-message-classifier",
        "model": "initial demo (tfidf_logreg)",
        "version": "initial",
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
