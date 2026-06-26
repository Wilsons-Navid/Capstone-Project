# Scam-Message Classifier — Initial Product Demonstration

A classical machine-learning model that classifies a short message (SMS / email / chat)
into one of four classes:

| Class | Example |
|---|---|
| `phishing` | "Verify your bank account or it will be suspended: http://bit.ly/x9" |
| `mobile_money_fraud` | "A sua conta M-Pesa foi bloqueada. Envie o seu PIN para reactivar." |
| `advance_fee_fraud` | "You won a £2000 prize GUARANTEED. Call to claim." |
| `not_a_scam` | "Hey, are we still meeting for lunch at 1pm?" |

It is served as a REST API with interactive Swagger UI.

> **Status — initial model.** Trained on **source-provenance labels** (Nazario phishing
> corpus, MOZ-Smishing, Mendeley smishing, UCI SMS). The final dissertation evaluation
> will use a human inter-rater-verified (Cohen's κ) corpus; that labelling is in progress.
> Three further categories (romance / identity-theft / synthetic-media) are scoped as
> future work — no public message datasets exist for them.

## Repository & live demo

- GitHub: https://github.com/Wilsons-Navid/report-Demo
- Live web app: https://frontend-inky-xi-23.vercel.app
- Live API (Swagger): https://scam-classifier-api.onrender.com/docs
- Demo code lives under `ml/`.

## Performance (held-out test set, n = 664)

| Model | Accuracy | Macro-F1 |
|---|---|---|
| **TF-IDF + Logistic Regression** | **0.958** | **0.943** |
| TF-IDF + Random Forest (500 trees) | 0.950 | 0.928 |

Per-class F1 (Logistic Regression): mobile-money **0.99**, phishing **0.96**,
not-a-scam **0.96**, advance-fee **0.86**. Full report + confusion matrices are in the
notebook.

## Project layout

```
ml/
├── data/
│   ├── raw/            UCI, Nazario, Mendeley smishing, MOZ-Smishing (downloaders in scripts/)
│   └── labelled/       demo_labeled.jsonl (4,422 labelled messages)
├── src/                corpus + labelling library (loaders, schema, taxonomy, auto_label, scrapers, labelling)
├── scripts/            01..13 data pipeline (download → normalise → label → build → relabel → export)
├── notebooks/
│   ├── initial_demo/   initial_demo.ipynb  ← this demo's notebook (EDA, architecture, metrics, inference) + its model
│   ├── embed_demo/     embed_demo.ipynb    ← semantic upgrade + ensemble + its model
│   └── final_model/    final_model.ipynb   ← deployed model + its artifacts
└── final_serve/        app.py — FastAPI app for the deployed model (initial_serve/ and embed_serve/ mirror it)
```

## Setup

```bash
# from the repo root
python -m venv .venv && .venv\Scripts\activate      # Windows
pip install -r ml/requirements.txt
```

## Reproduce the model

```bash
# 1. assemble the labelled demo dataset (from the downloaded sources)
python ml/scripts/10_build_demo_dataset.py

# 2. train + save the model by running the notebook (it owns its code and artifacts)
cd ml/notebooks/initial_demo
jupyter nbconvert --to notebook --inplace --execute initial_demo.ipynb
```

The notebook `ml/notebooks/initial_demo/initial_demo.ipynb` already contains executed
outputs (class distributions, length plots, metrics tables, confusion matrices, live
inference) and saves `scam_classifier.joblib` + `metrics.json` beside itself.

## Run the deployment MVP (Swagger UI)

```bash
cd ml
python -m uvicorn initial_serve.app:app --reload --port 8000
```

Open **http://127.0.0.1:8000/docs** → `POST /predict`:

```json
{ "text": "URGENT! Your number won a 2000 prize, call 09061790121 to claim." }
```

Response:

```json
{ "predicted_category": "advance_fee_fraud", "confidence": 0.99,
  "scores": { "advance_fee_fraud": 0.99, "phishing": 0.00, "mobile_money_fraud": 0.00, "not_a_scam": 0.01 } }
```

Endpoints: `GET /health`, `POST /predict`, `POST /predict_batch`, Swagger at `/docs`.

## Designs / screenshots

_Add screenshots before submitting:_
- `docs/screens/notebook_metrics.png` — the metrics + confusion-matrix cells
- `docs/screens/swagger_predict.png` — the Swagger `/predict` request + response

## Deployment plan

- **Now (MVP):** FastAPI + Uvicorn, model loaded from `scam_classifier.joblib`; Swagger UI for interactive testing.
- **Next:** containerise (Dockerfile) and deploy to a free-tier host (Render / Railway / Fly.io); the `/predict` API is consumed by the mobile front-end.
- **Model lifecycle:** retrain on the κ-verified corpus once labelling completes; version the model artifact and metrics.

## Video demo

`<add 5–10 min video link here>` — walk through: the notebook (data → architecture → metrics),
then the live Swagger `/predict` on a few example messages across the classes.
