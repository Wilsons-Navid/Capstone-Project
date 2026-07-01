"""FastAPI service for the CMU honeynet binary scam detector.

This is the first-pass filter behind the app's inbox scan. It answers one
question about a single SMS — scam or not — and it answers it fast, because the
model is a small scikit-learn pipeline with no embedder to download. The richer
four-class model says what *kind* of scam it is; this one just raises the flag.

The bundle carries its own decision threshold (tuned for high scam recall in the
notebook), so the service does not fall back to a naive 0.5 cut-off.

    POST /predict        {"text": "..."} -> {is_scam, scam_probability, verdict, threshold}
    POST /predict_batch  [{"text": "..."}, ...]
    GET  /health , GET / , GET /docs

Run locally (from ml/):
    python -m uvicorn cmu_inbox_serve.app:app --port 8001
"""

from __future__ import annotations

import os
from pathlib import Path

import joblib
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

HERE = Path(__file__).resolve().parent                  # ml/cmu_inbox_serve/
ML_ROOT = HERE.parent                                   # ml/
# The model lives with its notebook; the deploy script copies a bundle in beside
# this app before upload. Locally we fall back to the notebook folder.
_CANDIDATES = [
    HERE / "cmu_scam_binary.joblib",
    ML_ROOT / "notebooks" / "cmu_binary" / "cmu_scam_binary.joblib",
]
MODEL_PATH = next((p for p in _CANDIDATES if p.exists()), _CANDIDATES[-1])

app = FastAPI(
    title="CMU Honeynet Scam Detector — binary inbox scan",
    description=(
        "First-pass SMS scan: is this message a scam or not? Trained only on "
        "real scam text captured by the CMU-Africa Upanzi smishing honeynet "
        "(English / Kinyarwanda / Swahili). Applies a recall-tuned threshold, "
        "so a flag means 'worth a closer look', not a hard block."
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

_bundle = None


def get_bundle():
    """Load the joblib once (small, no network)."""
    global _bundle
    if _bundle is None:
        if not MODEL_PATH.exists():
            raise HTTPException(503, "Model missing. Run "
                                     "notebooks/cmu_binary/cmu_binary.ipynb to build it.")
        _bundle = joblib.load(MODEL_PATH)
    return _bundle


class Message(BaseModel):
    text: str = Field(..., min_length=1, examples=[
        "Your account (FRI:23889079/MM) has been blocked. Contact bank within 24hrs."])


class Prediction(BaseModel):
    text: str
    is_scam: bool
    scam_probability: float
    threshold: float
    verdict: str


def _predict(texts: list[str]) -> list[Prediction]:
    bundle = get_bundle()
    pipe = bundle["pipeline"]
    thr = float(bundle.get("threshold", 0.5))
    # class order in the pipeline: index of label 1 ("scam")
    classes = list(pipe.classes_)
    scam_idx = classes.index(1) if 1 in classes else classes.index("scam")
    proba = pipe.predict_proba(texts)[:, scam_idx]
    out: list[Prediction] = []
    for text, p in zip(texts, proba):
        p = float(p)
        is_scam = p >= thr
        out.append(Prediction(
            text=text,
            is_scam=is_scam,
            scam_probability=round(p, 4),
            threshold=round(thr, 4),
            verdict="likely scam" if is_scam else "looks legitimate",
        ))
    return out


@app.get("/", summary="Service info")
def root():
    b = get_bundle()
    return {
        "service": "cmu-honeynet-binary-scam-detector",
        "model": b.get("model_name", "tfidf_word+char_logreg"),
        "task": "binary scam vs legit",
        "threshold": b.get("threshold", 0.5),
        "test_scam_f1": b.get("test_scam_f1"),
        "test_pr_auc": b.get("test_pr_auc"),
        "corpus": b.get("corpus", "cmu_binary.jsonl"),
        "languages": ["en", "rw", "sw"],
        "status": "ok",
        "docs": "/docs",
    }


@app.get("/health", summary="Health check")
def health():
    return {"status": "healthy", "model_present": MODEL_PATH.exists()}


@app.post("/predict", response_model=Prediction, summary="Scan a single message")
def predict(msg: Message):
    return _predict([msg.text])[0]


@app.post("/predict_batch", summary="Scan many messages")
def predict_batch(messages: list[Message]):
    return _predict([m.text for m in messages])
