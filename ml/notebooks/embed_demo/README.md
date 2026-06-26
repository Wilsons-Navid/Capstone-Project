# embed_demo — semantic upgrade + ensemble

Builds on the baseline by adding **multilingual sentence embeddings**
(`intfloat/multilingual-e5-small`) and combining them with the lexical TF-IDF model
in a **soft-voting ensemble**. Same v1 corpus (English / Portuguese, 4,422 messages).

## Contents
- `embed_demo.ipynb` — two feature representations, the full model ladder, ensembles,
  per-class analysis, live inference. Self-contained (training code inlined).
- `embed_models.joblib` — the saved soft-voting ensemble bundle (TF-IDF LogReg +
  e5 LogReg + e5 RF + stacking meta + embedder reference).
- `embed_metrics.json` — test metrics for every model in the ladder.
- `emb_e5small.npz` — cached e5 embeddings so re-runs skip re-encoding.

## Result
The **soft-voting ensemble** is best, test macro-F1 ≈ **0.955** — it beats the lexical
baseline and lifts every class. Embeddings alone do *not* beat TF-IDF here, but they
contribute complementary cross-lingual signal.

## Run
```bash
cd ml/notebooks/embed_demo
jupyter nbconvert --to notebook --inplace --execute embed_demo.ipynb
```
Reads `../../data/labelled/demo_labeled.jsonl`; writes the artifacts above into this
folder. First-ever run downloads the e5 weights (~470 MB); afterwards the `.npz` cache
makes it instant.

## Served by
[`../../embed_serve/`](../../embed_serve/) — loads this bundle + the e5 embedder.
