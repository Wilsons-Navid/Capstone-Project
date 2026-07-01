# cmu_v3_serve — the honeynet-enriched four-class API

Serves **v3** — the v2 four-class model retrained after folding the CMU-Africa
Upanzi honeynet capture into the corpus, produced by
[`../notebooks/cmu_corpus_v3/`](../notebooks/cmu_corpus_v3/). Same recipe as v2
(TF-IDF + Logistic Regression), more realistic mobile-money and African-language
data. In the controlled comparison, macro-F1 rose from **0.881** (v2 data only) to
**0.932** on the shared test set, driven by the mobile-money class.

Endpoints: `GET /health`, `POST /predict` (`{"text": "..."}` →
`{predicted_category, confidence, scores}`), `POST /predict_batch`, docs at `/docs`.
Embedder-free, so there is no cold-start model download. Drop-in compatible with
the v2 API the app already calls.

> Loads `../notebooks/cmu_corpus_v3/scam_tfidf_v3.joblib` (re-run that notebook to
> regenerate it).

## Run locally
```bash
cd ml
python -m uvicorn cmu_v3_serve.app:app --port 8002
# open http://127.0.0.1:8002/docs
```

## Deploy to Hugging Face Spaces
```bash
HF_TOKEN=hf_xxx python cmu_v3_serve/deploy_hf_space.py     # from ml/
```
Creates/updates a public Docker Space and uploads `cmu_v3_serve/` + the model.

## Notes
- This is the **second stage** of the two-stage check: the binary
  [`../cmu_inbox_serve/`](../cmu_inbox_serve/) decides *scam or not*; this endpoint
  decides *what kind*.
- To promote v3 to production, point the app's `scamModelApiBaseUrl`
  (`mobile/rethicsai/lib/core/config/api_config.dart`) at this Space's URL.
- `ALLOWED_ORIGINS` env var restricts CORS in production (defaults to `*`).
