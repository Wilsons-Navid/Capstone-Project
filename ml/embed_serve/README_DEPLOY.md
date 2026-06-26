# embed_serve — the ensemble scam-classifier API

Serves the soft-voting ensemble (TF-IDF + multilingual-e5-small, macro-F1 0.955),
produced by [`../notebooks/embed_demo/`](../notebooks/embed_demo/). Endpoints:
`GET /health`, `POST /predict` (`{"text": "..."}` → `{predicted_category, confidence,
scores}`), `POST /predict_batch`, interactive docs at `/docs`.

This service loads the e5 embedder, so the first request is slower (the weights are
pulled once). The lighter, embedder-free production model is [`../final_serve/`](../final_serve/).

> Loads `../notebooks/embed_demo/embed_models.joblib` (re-run that notebook to regenerate it).

## Run locally
```bash
cd ml
python -m uvicorn embed_serve.app:app --port 8000
# open http://127.0.0.1:8000/docs
```

## Deploy to Hugging Face Spaces
```bash
HF_TOKEN=hf_xxx python embed_serve/deploy_hf_space.py     # from ml/
```
Creates/updates a public Docker Space and uploads `embed_serve/` + the bundle (copied in
from the notebook folder). The Space serves on port **7860**; the first `/predict`
downloads the e5 weights (~470 MB) into the Space cache, then it stays warm.

## Notes
- `ALLOWED_ORIGINS` env var restricts CORS in production (defaults to `*`).
- On-device (TFLite) is intentionally not used — e5 → TFLite conversion is heavy; a hosted
  API keeps the app light and the model swappable.
