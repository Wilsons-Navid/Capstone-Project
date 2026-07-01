# cmu_binary — real-world binary scam detector

Trains the **first-pass inbox scanner**: given one SMS, is it a scam or not?

Unlike the other notebooks in this project, this one learns from a single,
real-world source — the **CMU-Africa Upanzi smishing honeynet** — so every scam it
sees was captured from an actual fraudster, in the languages people are actually
targeted in (English, Kinyarwanda, Swahili). The honeynet dump is cleaned by
[`../../scripts/14_ingest_cmu.py`](../../scripts/14_ingest_cmu.py) before it reaches
the notebook.

| Item | Value |
|---|---|
| Task | Binary: scam vs legit |
| Data | CMU Upanzi honeynet, cleaned & de-duplicated (~1,099 messages, ~165 scam) |
| Features | TF-IDF word (1–2) **+** character (3–5) n-grams |
| Model | Logistic Regression, class-weighted, recall-tuned threshold |
| Test scam-F1 | see `metrics.json` (~0.87) |
| Test PR-AUC / ROC-AUC | ~0.93 / ~0.99 |
| Served by | [`../../cmu_inbox_serve/`](../../cmu_inbox_serve/) |

## Build / re-run
```bash
cd ml/notebooks/cmu_binary
python build_cmu_binary.py                               # regenerate the .ipynb from source
jupyter nbconvert --to notebook --inplace --execute cmu_binary.ipynb
```
The notebook is generated from `build_cmu_binary.py` so the prose and code live in
plain text under version control. Running it writes three artifacts into this
folder: `cmu_scam_binary.joblib` (the model + its threshold), `metrics.json` and
`model_card.json`.

## Why binary, and why separate
This model decides *whether* to worry. The four-class model
([`../final_model/`](../final_model/) and its v3 successor
[`../cmu_corpus_v3/`](../cmu_corpus_v3/)) decides *what kind* of scam it is. The
inbox scan runs this one first because it is fast and trained on real captures;
the category model runs second for detail.
