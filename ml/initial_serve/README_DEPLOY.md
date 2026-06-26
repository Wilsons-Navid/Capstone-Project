# initial_serve — the initial-demo classifier API

Serves the initial baseline — TF-IDF + Logistic Regression on the v1 corpus — produced by
[`../notebooks/initial_demo/`](../notebooks/initial_demo/). Endpoints: `GET /health`,
`POST /predict` (`{"text": "..."}` → `{predicted_category, confidence, scores}`),
`POST /predict_batch`, docs at `/docs`.

Pure scikit-learn (no embedder), so the container is tiny and cold-starts instantly.

> Loads `../notebooks/initial_demo/scam_classifier.joblib` (re-run that notebook to regenerate it).

## Run locally
```bash
cd ml
python -m uvicorn initial_serve.app:app --port 8000
# open http://127.0.0.1:8000/docs
```

## Deploy to Hugging Face Spaces
```bash
HF_TOKEN=hf_xxx python initial_serve/deploy_hf_space.py     # from ml/
```
Creates/updates a public Docker Space and uploads `initial_serve/` + the model (copied in
from the notebook folder). The Space serves on port **7860**; first `/predict` is instant.

## Notes
- `ALLOWED_ORIGINS` env var restricts CORS in production (defaults to `*`).
- This is the earliest baseline; the deployed production model is [`../final_serve/`](../final_serve/).
