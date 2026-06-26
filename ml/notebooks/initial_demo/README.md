# initial_demo — first baseline

The **initial/preliminary** scam-message classifier: a classical TF-IDF + Logistic
Regression / Random Forest pipeline on the v1 corpus (English / Portuguese,
4,422 labelled messages). This is the starting point the later notebooks improve on.

## Contents
- `initial_demo.ipynb` — EDA, model architecture, metrics, live inference. Self-contained
  (all training code is inlined; no project imports).
- `scam_classifier.joblib` — the best fitted pipeline (the artifact this notebook owns).
- `metrics.json` — dev/test metrics for both pipelines.
- `model_card.json` — summary card (best model, class list, split sizes, headline scores).

## Result
Best model **TF-IDF + Logistic Regression**, held-out test macro-F1 ≈ **0.94**.

## Run
```bash
cd ml/notebooks/initial_demo
jupyter nbconvert --to notebook --inplace --execute initial_demo.ipynb
```
Reads `../../data/labelled/demo_labeled.jsonl`; writes the three artifacts above into
this folder.

## Served by
[`../../initial_serve/`](../../initial_serve/) — `POST /predict` over FastAPI.
