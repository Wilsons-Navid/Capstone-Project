# final_serve — the deployed scam-classifier API

Serves the **deployed** model — TF-IDF + Logistic Regression on the v2 corpus
(macro-F1 0.946, en/pt/sw), produced by [`../notebooks/final_model/`](../notebooks/final_model/).
Endpoints: `GET /health`, `POST /predict` (`{"text": "..."}` →
`{predicted_category, confidence, scores}`), `POST /predict_batch`, docs at `/docs`.

It is **embedder-free** (pure scikit-learn), so the container is tiny and there is
**no cold-start model download**.

> Loads `../notebooks/final_model/scam_tfidf_v2.joblib` (re-run that notebook, or
> `python scripts/13_export_tfidf_v2.py`, to regenerate it).

## Run locally
```bash
cd ml
python -m uvicorn final_serve.app:app --port 8000
# open http://127.0.0.1:8000/docs
```

## Deploy to Hugging Face Spaces (current production)
```bash
HF_TOKEN=hf_xxx python final_serve/deploy_hf_space_v2.py     # from ml/
```
Creates/updates a public Docker Space and uploads `final_serve/` + the model (copied in
from the notebook folder). Live API: `https://wilsons579-scam-classifier-api-v2.hf.space`
— the app's `scamModelApiBaseUrl` (`mobile/rethicsai/lib/core/config/api_config.dart`)
points here.

## Notes
- `ALLOWED_ORIGINS` env var restricts CORS in production (defaults to `*`).
- On-device (TFLite) is intentionally not used — a hosted API keeps the app light and the
  model swappable without shipping a new APK.
