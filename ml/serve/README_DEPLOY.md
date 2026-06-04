# Deploying the scam-classifier ensemble API

Serves the soft-voting ensemble (TF-IDF + multilingual-e5-small, macro-F1 0.955) as a
REST API the mobile app's threat scanner calls. Endpoints: `GET /health`,
`POST /predict` (`{"text": "..."}` → `{predicted_category, confidence, scores}`),
`POST /predict_batch`, interactive docs at `/docs`.

> Requires `models/embed_models.joblib` to exist — generate it with
> `python src/embed_model.py` (it is gitignored; commit it via LFS only on the deploy target).

## Run locally
```bash
cd ml
python -m uvicorn serve.app:app --port 8000
# open http://127.0.0.1:8000/docs
```

## Option A — Hugging Face Spaces (recommended, free, 16 GB RAM)
1. Create a new **Space** → SDK **Docker**.
2. Push these into the Space repo (build context = repo root, so keep the same layout):
   `serve/` (incl. `Dockerfile`, `requirements.txt`, `app.py`), `src/`, and
   `models/embed_models.joblib` (track the joblib with **git-lfs**).
3. The Space builds the Dockerfile and serves on port **7860** automatically.
4. First request downloads the e5 weights (~470 MB) into the Space cache, then it's warm.
5. API base URL: `https://<user>-<space>.hf.space` → point the app's `scamModelApiBaseUrl` at it.

Spaces sleep when idle and wake on the next request (a few seconds cold start).

## Option B — Google Cloud Run (same GCP project as Firebase)
```bash
cd ml
gcloud run deploy scam-api \
  --source . \                      # uses serve/Dockerfile if at root; else --function/--image
  --memory 2Gi --cpu 1 --port 7860 \
  --allow-unauthenticated --region <region>
```
- Set `--memory 2Gi` (torch + e5 need it). Scales to zero (no idle cost; free monthly quota covers light demo traffic).
- For no cold-start during a live demo, add `--min-instances 1` (small cost).

## Notes
- `ALLOWED_ORIGINS` env var restricts CORS in production (defaults to `*`).
- On-device (TFLite) is intentionally **not** used here — e5 → TFLite conversion is heavy; a hosted API keeps the app light and the model swappable.
