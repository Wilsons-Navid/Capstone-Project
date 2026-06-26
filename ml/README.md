# `ml/` — scam-message classifier (corpus + models)

The machine-learning track of the project: it builds a multilingual corpus and trains the classifier that powers the app's scanner. The model scores a short message as **advance_fee_fraud**, **mobile_money_fraud**, **phishing**, or **not_a_scam**.

**Deployed model:** TF-IDF + Logistic Regression on the v2 corpus (9,623 messages, English / Portuguese / Swahili), held-out **macro-F1 0.946** (mobile-money fraud F1 0.983; per-language accuracy en 0.95 / pt 1.00 / sw 0.98). It is embedder-free, served from `final_serve/` on a Hugging Face Space, and called by the mobile app.

```bash
pip install -r requirements.txt
cd notebooks/final_model && jupyter nbconvert --to notebook --inplace --execute final_model.ipynb
```

Canonical write-up: **`notebooks/final_model/final_model.ipynb`**. Each notebook is
self-contained and lives with the artifacts it produces — see [`notebooks/`](notebooks/).

## How the model is built

The project classifier scores a short message as **advance_fee_fraud**, **mobile_money_fraud**, **phishing**, or **not_a_scam** (the four data-backed classes; romance / identity-theft / synthetic-media are future work). It is built and compared in three rungs:

1. **Lexical baseline** — TF-IDF → Logistic Regression / Random Forest (`notebooks/initial_demo/`).
2. **Semantic upgrade** — multilingual **e5-small** sentence embeddings → Logistic Regression / Random Forest, plus a soft-voting/stacking ensemble (`notebooks/embed_demo/`).
3. **Final model** — the same ladder on the expanded en/pt/sw corpus; the lightweight TF-IDF + LogReg model wins and is deployed (`notebooks/final_model/`).

**Result (held-out test, macro-F1):**
- **v1 corpus (4,422 msgs, en/pt):** TF-IDF baseline **0.943** → **soft-voting ensemble 0.955** (best on this corpus) — `notebooks/embed_demo/`.
- **v2 corpus (9,623 msgs, en/pt/sw — adds the ExAIS + BongoScam African SMS sets):** **TF-IDF + LogReg 0.946** is the best single model; soft-vote 0.941, embeddings-only 0.899. Mobile-money fraud becomes the strongest class (F1 0.983) and per-language accuracy is en 0.95 / pt 1.00 / sw 0.98. See `notebooks/final_model/`; the deployed API is `final_serve/` (embedder-free, instant cold start).

On both corpora the multilingual embeddings do *not* beat the lexical baseline — scam messages reuse give-away keywords TF-IDF already catches — but they contribute complementary cross-lingual signal. See the finding in the notebook.

The delivered model is the v2 run (`notebooks/final_model/final_model.ipynb`, served by `final_serve/`). The earlier rungs are kept as the documented baseline: `notebooks/embed_demo/` (v1 ensemble) and `notebooks/initial_demo/` (first preliminary run). Each notebook is self-contained and saves its artifacts beside it; the three serve dirs (`initial_serve/`, `embed_serve/`, `final_serve/`) each load the matching notebook's model.

## Corpus scope

- Public stream: Nazario / UCI SMS Spam / Mendeley smishing / MOZ-Smishing (Portuguese M-Pesa).
- Regional stream: West African news (ngCERT / ANTIC / EFCC probed but blocked).
- **African SMS additions (v2):** ExAIS African-English SMS (Nigeria) + BongoScam Tanzanian Swahili, relabelled to the 4-class taxonomy by `scripts/11_relabel_african.py` and merged by `scripts/12_build_corpus_v2.py` → `data/labelled/demo_labeled_v2.jsonl`. Full source links in `../docs/DATA_SOURCES.md`.
- No live pilot; no LLM comparison (both retained as future work).

## Binding deadlines (from proposal §1.3.1)

| Objective | Deliverable | Deadline |
|---|---|---|
| **1** | Labelled corpus ≥500 items, Cohen's κ ≥ 0.7 on 100-item audit | **12 Jun 2026** |
| **2** | Working Android build (separate track in `mobile/`) | 26 Jun 2026 |
| **3** | LR vs RF comparison table with per-category metrics | 10 Jul 2026 |

## The six-category taxonomy (locked)

Defined in `src/taxonomy.py`:

1. `advance_fee_fraud`
2. `mobile_money_fraud`
3. `phishing`
4. `romance_scam`
5. `identity_theft`
6. `synthetic_media_fraud`
7. `not_a_scam` (residual, for training-time false positives)

## Layout

```
ml/
├── README.md                          ← this file
├── requirements.txt                   ← Python deps (pydantic, pandas, scikit-learn, requests)
├── notebooks/                         ← three self-contained notebooks, each with its models
│   ├── README.md                      ← overview table of the three
│   ├── initial_demo/                  ← initial_demo.ipynb + scam_classifier.joblib, metrics.json, model_card.json
│   ├── embed_demo/                    ← embed_demo.ipynb + embed_models.joblib, embed_metrics.json, emb_e5small.npz
│   └── final_model/                   ← final_model.ipynb + embed_models_v2.joblib, …_v2.json, …_v2.npz, scam_tfidf_v2.joblib (DEPLOYED)
├── initial_serve/                     ← FastAPI API for the initial_demo model
├── embed_serve/                       ← FastAPI API for the embed_demo ensemble (loads e5)
├── final_serve/                       ← FastAPI API for the deployed model (on Hugging Face)
├── src/
│   ├── __init__.py
│   ├── taxonomy.py                    ← six-category enum + descriptions
│   ├── schema.py                      ← Pydantic LabelledItem model + JSONL I/O
│   ├── loaders.py                     ← UCI SMS Spam, Nazario, Kaggle CSV loaders
│   ├── scrapers.py                    ← regional advisory scrapers (ngCERT / ANTIC / EFCC / news)
│   ├── auto_label.py                  ← heuristic category suggester (labelling bootstrap)
│   └── labelling.py                   ← audit sampling + Cohen's κ
├── scripts/                           ← 01..13 data pipeline (download → … → relabel → export deployed model)
└── data/
    ├── raw/                           ← downloaded datasets (zips gitignored, extracts tracked)
    ├── labelled/                      ← JSONL corpora + labelling intermediates
    └── audits/                        ← second-rater audit samples for κ
```

> Model training code is **inlined in the notebooks** (each owns its pipeline); there is
> no shared `demo_model`/`embed_model` module. `src/` holds the corpus + labelling library.

## Regional stream reachability (probed 2026-06-01)

Only one of the four regional sources is currently scrapable:

| Source | Status | Notes |
|---|---|---|
| Premium Times (news, EN) | **works** | WordPress REST API `/wp-json/wp/v2/posts?search=…`; 393 unique scam-relevant paragraphs harvested |
| ngCERT (`cert.gov.ng`) | blocked | Cloudflare anti-bot, HTTP 403 |
| ANTIC (`antic.cm`, FR) | blocked | host unreachable (connect timeout) |
| EFCC (`efccnigeria.org`) | blocked | empty shell / news path 404 |

The blocked sources are kept as honest, non-crashing probes in `src/scrapers.py`
that log why they yielded nothing — the unavailability of official advisories is
itself a data-collection limitation to report. French/Pidgin coverage remains a
gap the public + Premium-Times streams do not fill.

## End-to-end pipeline

```bash
# 1. Fetch public datasets (UCI SMS Spam auto-fetches; Nazario + Kaggle are manual)
python ml/scripts/01_download_public.py

# 1b. Harvest the regional stream (Premium Times; gov sites are blocked, logged)
python ml/scripts/07_scrape_regional.py

# 2. Normalise + quality phase (schema validate, deduplicate, length-filter, write JSONL)
#    Folds in both the public datasets and data/raw/regional/regional_news.jsonl
python ml/scripts/02_normalise.py

# 3a. (optional bootstrap) batch AUTO-suggest pass to make the human pass confirm-or-correct
python ml/scripts/03c_batch_autolabel.py

# 3. Label rater-1 pass — interactive, resume-safe. 03b is the AI-assisted variant.
python ml/scripts/03b_assisted_label.py    # (or 03_label_helper.py for pure-manual)

# 4. Once ≥500 items are labelled, generate a stratified 100-item audit sample for rater 2
python ml/scripts/04_create_audit_sample.py

# 5. After rater 2 labels the audit sample, compute Cohen's κ
python ml/scripts/05_compute_kappa.py

# 6. If κ ≥ 0.7, lock the corpus and produce the stratified 70/15/15 split
python ml/scripts/06_split.py
```

## Schema (one record per JSONL line)

| Field | Type | Notes |
|---|---|---|
| `id` | str | Stable 12-char SHA1 hash of `text` |
| `text` | str | Free-text incident description |
| `language` | str | ISO 639-1; `pcm` for Nigerian Pidgin |
| `source_stream` | enum | `public` / `regional` |
| `source_url` | str (optional) | Provenance link |
| `original_label` | str (optional) | Source dataset's own label |
| `category` | enum | One of the seven taxonomy labels |
| `label_source` | enum | `rater1` / `rater2` / `adjudicated` / `auto` |
| `labelled_at` | datetime (UTC) | When the label was applied |

## Quality phase rules (per proposal §3.4.2)

Applied in `02_normalise.py` before any training:

1. **Schema validation** — Pydantic rejects records missing required fields or with unknown language tags.
2. **Deduplication** — exact-text by `id` (SHA1 of text).
3. **Near-duplicate detection** — character 5-gram fingerprint with Jaccard ≥ 0.85 → collapse to first occurrence.
4. **Length filtering** — drop records with `len(text) < 20` or `len(text) > 2000`.

## Audit + κ workflow

- `04_create_audit_sample.py` writes `data/audits/audit_sample_blinded.jsonl` — items with category stripped, ready for rater 2.
- Rater 2 saves their labels as `data/audits/rater2.jsonl`.
- `05_compute_kappa.py` reads both rater files, computes κ on the shared item-id intersection, prints the value.
- The proposal threshold is **κ ≥ 0.7**.
