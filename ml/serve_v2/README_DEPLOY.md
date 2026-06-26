# Deploying the v2 scam-classifier API

Serves the deployed model — TF-IDF + Logistic Regression on the v2 corpus
(macro-F1 0.946, en/pt/sw) — as a REST API the mobile app's scanner calls.
Endpoints: `GET /health`, `POST /predict` (`{"text": "..."}` →
`{predicted_category, confidence, scores}`), `POST /predict_batch`, docs at `/docs`.

Unlike the v1 ensemble, this model is **embedder-free** (pure scikit-learn), so the
container is tiny and there is **no cold-start model download**.

> Requires `models/scam_tfidf_v2.joblib`. Generate it with
> `python scripts/13_export_tfidf_v2.py` (it extracts the TF-IDF + LogReg pipeline
> from `models/embed_models_v2.joblib`).

## Run locally
```bash
cd ml
python -m uvicorn serve_v2.app:app --port 8000
# open http://127.0.0.1:8000/docs
```

## Deploy to Hugging Face Spaces (current production)
```bash
HF_TOKEN=hf_xxx python serve_v2/deploy_hf_space_v2.py     # from ml/
```
This creates/updates a public Docker Space and uploads `serve_v2/` + `src/` +
`models/scam_tfidf_v2.joblib`. The Space builds the Dockerfile and serves on port
**7860**. Live API: `https://wilsons579-scam-classifier-api-v2.hf.space` — point the
app's `scamModelApiBaseUrl` (`mobile/rethicsai/lib/core/config/api_config.dart`) at it.

## Notes
- `ALLOWED_ORIGINS` env var restricts CORS in production (defaults to `*`).
- On-device (TFLite) is intentionally not used — a hosted API keeps the app light
  and the model swappable without shipping a new APK.
