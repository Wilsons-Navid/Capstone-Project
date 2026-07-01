# cmu_corpus_v3 — four-class model, honeynet-enriched

Answers one question with a controlled experiment: **does adding the CMU-Africa
Upanzi honeynet capture to the training data make the four-class model better,
without breaking anything else?**

The honeynet scams are mapped into the four categories by
[`../../scripts/15_build_corpus_v3.py`](../../scripts/15_build_corpus_v3.py) (an
explicit rule set plus a manual-confirm pass), the legitimate honeynet messages
become `not_a_scam`, and the result is merged with the v2 corpus into
`demo_labeled_v3.jsonl`.

The notebook then splits v3 once and trains two models on the same split — one on
the v2 rows only, one on v2 + honeynet — and scores both on the same held-out test
set. Only the training data differs, so the gap is the honeynet's effect.

| Item | Value |
|---|---|
| Task | 4-class: advance_fee_fraud / mobile_money_fraud / phishing / not_a_scam |
| Corpus | `demo_labeled_v3.jsonl` (~10,722 messages; ~1,099 from the honeynet) |
| Recipe | **identical to v2**: TF-IDF (1–2), LogReg, class-weighted, C=4.0 |
| macro-F1 (shared test) | v2-only **0.881** → v3 **0.932** |
| TF-IDF vs e5 embeddings | TF-IDF **0.932** > e5 **0.874** > ensemble 0.929 — lexical wins, so the shipped model stays embedder-free |
| Languages | en, pt, sw, **rw** (Kinyarwanda, new) |
| Served by | [`../../cmu_v3_serve/`](../../cmu_v3_serve/) |

## Build / re-run
```bash
cd ml/notebooks/cmu_corpus_v3
python build_cmu_corpus_v3.py
jupyter nbconvert --to notebook --inplace --execute cmu_corpus_v3.ipynb
```
Writes `scam_tfidf_v3.joblib` and `metrics_v3.json` into this folder. The shipped
model is refit on the whole v3 corpus; the quoted numbers are the held-out
experiment numbers.

## Relationship to the other models
This is the **category** stage of a two-stage check. The binary
[`../cmu_binary/`](../cmu_binary/) model decides *scam or not* for the inbox scan;
this one decides *what kind* once a flag is raised. It supersedes
[`../final_model/`](../final_model/) (v2) as the four-class endpoint.
