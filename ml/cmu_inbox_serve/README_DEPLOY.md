# cmu_inbox_serve — the binary inbox-scan API

Serves the **CMU honeynet binary detector** — TF-IDF (word + character n-grams) +
Logistic Regression, trained only on real scam text from the CMU-Africa Upanzi
smishing honeynet (English / Kinyarwanda / Swahili), produced by
[`../notebooks/cmu_binary/`](../notebooks/cmu_binary/).

Endpoints: `GET /health`, `POST /predict` (`{"text": "..."}` →
`{is_scam, scam_probability, verdict, threshold}`), `POST /predict_batch`, docs at `/docs`.

It applies the **recall-tuned threshold** saved in the model bundle (not a naive
0.5), so a flag means "worth a closer look" rather than a hard block. Pure
scikit-learn, so the container is tiny and there is **no cold-start download**.

> Loads `../notebooks/cmu_binary/cmu_scam_binary.joblib` (re-run that notebook to
> regenerate it).

## Run locally
```bash
cd ml
python -m uvicorn cmu_inbox_serve.app:app --port 8001
# open http://127.0.0.1:8001/docs
```

## Deploy to Hugging Face Spaces
```bash
HF_TOKEN=hf_xxx python cmu_inbox_serve/deploy_hf_space.py     # from ml/
```
Creates/updates a public Docker Space and uploads `cmu_inbox_serve/` + the model
(copied in from the notebook folder).

## Notes
- This is the **first stage** of a two-stage check: it decides *scam or not*; the
  four-class model (`../final_serve/`, and the v3 successor) decides *what kind*.
- `ALLOWED_ORIGINS` env var restricts CORS in production (defaults to `*`).
