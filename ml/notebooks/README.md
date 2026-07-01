# Notebooks

Self-contained notebooks, each in its own folder with **the model artifacts it
generates** and a README. They tell the model story in order — baseline → semantic
upgrade → final multilingual model → real-world honeynet models. Each notebook
inlines its own training code, so it can be opened and re-run on its own.

| Folder | Notebook | What it is | Artifacts it produces | Served by |
|---|---|---|---|---|
| [`initial_demo/`](initial_demo/) | `initial_demo.ipynb` | First baseline: TF-IDF + LogReg/RF on the v1 English/Portuguese corpus | `scam_classifier.joblib`, `metrics.json`, `model_card.json` | [`../initial_serve/`](../initial_serve/) |
| [`embed_demo/`](embed_demo/) | `embed_demo.ipynb` | Semantic upgrade: e5-small embeddings + a soft-voting ensemble (test macro-F1 0.955) | `embed_models.joblib`, `embed_metrics.json`, `emb_e5small.npz` | [`../embed_serve/`](../embed_serve/) |
| [`final_model/`](final_model/) | `final_model.ipynb` | **Deployed** 4-class model: expanded en/pt/sw corpus; TF-IDF + LogReg wins (test macro-F1 0.946) | `embed_models_v2.joblib`, `embed_metrics_v2.json`, `emb_e5small_v2.npz`, **`scam_tfidf_v2.joblib`** | [`../final_serve/`](../final_serve/) |
| [`cmu_binary/`](cmu_binary/) | `cmu_binary.ipynb` | **Real-world binary detector** for the inbox scan: TF-IDF word+char + LogReg on the CMU-Africa Upanzi honeynet (en/rw/sw), recall-tuned | `cmu_scam_binary.joblib`, `metrics.json`, `model_card.json` | [`../cmu_inbox_serve/`](../cmu_inbox_serve/) |

## Running a notebook

```bash
cd ml/notebooks/<folder>
jupyter notebook <name>.ipynb        # or: jupyter nbconvert --to notebook --inplace --execute <name>.ipynb
```

Each notebook reads the corpus from `ml/data/labelled/` and writes its model
artifacts **into its own folder**. Embeddings are cached (`emb_e5small*.npz`), so
re-runs are fast and need no ~470 MB download.

The deployed model is `final_model/scam_tfidf_v2.joblib` (TF-IDF + Logistic
Regression, embedder-free), served by `../final_serve/` on a Hugging Face Space and
called by the mobile app.
