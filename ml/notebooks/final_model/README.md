# final_model — the deployed model

The **final** classifier, trained on the **expanded multilingual corpus** (9,623
messages in English / Portuguese / Swahili) after adding two real African SMS datasets
(ExAIS, BongoScam — see `../../scripts/11_relabel_african.py`). This is the model that
ships in the app.

## Contents
- `final_model.ipynb` — corpus growth analysis, the full model ladder across three
  languages, per-language accuracy, live inference, and the export of the deployed model.
  Self-contained (training code inlined).
- `embed_models_v2.joblib` — the full ensemble bundle on the v2 corpus.
- `embed_metrics_v2.json` — test metrics for every model in the ladder.
- `emb_e5small_v2.npz` — cached e5 embeddings for the v2 corpus.
- **`scam_tfidf_v2.joblib`** — the lightweight standalone **TF-IDF + Logistic Regression**
  model. This is the **deployed** model (embedder-free, ~1.5 MB, instant cold start).

## Result
**TF-IDF + Logistic Regression is the best single model, test macro-F1 ≈ 0.946.**
Mobile-money fraud becomes the strongest class (F1 ≈ 0.98); per-language test accuracy is
English ≈ 0.95, Portuguese ≈ 1.0, Swahili ≈ 0.98. Embeddings add cross-lingual robustness
but do not beat the lexical model on this in-distribution test, so the cheaper TF-IDF model
is the one shipped.

## Run
```bash
cd ml/notebooks/final_model
jupyter nbconvert --to notebook --inplace --execute final_model.ipynb
```
Reads `../../data/labelled/demo_labeled_v2.jsonl`; writes the four artifacts above into
this folder. (`../../scripts/13_export_tfidf_v2.py` can also regenerate
`scam_tfidf_v2.joblib` from `embed_models_v2.joblib`.)

## Served by
[`../../final_serve/`](../../final_serve/) — deployed to a Hugging Face Space and called by
the mobile app (`mobile/rethicsai/lib/core/config/api_config.dart`).
