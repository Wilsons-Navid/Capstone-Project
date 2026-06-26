# `ml/` — the scam-message classifier

This is the research core of Rethicsec: the corpus, the experiments, and the trained
model that powers the app's scanner. Given a short message, it answers one question —
**is this a scam, and what kind?** — with one of four labels: `advance_fee_fraud`,
`mobile_money_fraud`, `phishing`, or `not_a_scam`.

## 🔌 Live model APIs

Each model is deployed as its own public API. `POST /predict` with `{"text": "..."}`;
interactive docs at `/docs`.

| Model | Live API | One-line |
|---|---|---|
| 🟢 **Final** *(deployed — the app calls this)* | **https://wadotuh-scam-classifier-api-final.hf.space** | TF-IDF + Logistic Regression, en/pt/sw, **macro-F1 0.946**, embedder-free |
| 🔵 Embedding ensemble | https://wadotuh-scam-classifier-api-embed.hf.space | TF-IDF + e5 soft-voting ensemble, **macro-F1 0.955** (v1 corpus) |
| ⚪ Initial baseline | https://wadotuh-scam-classifier-api-initial.hf.space | TF-IDF + Logistic Regression, the first baseline |

```bash
curl -X POST https://wadotuh-scam-classifier-api-final.hf.space/predict \
  -H "Content-Type: application/json" \
  -d '{"text":"Iyo pesa itume kwenye namba hii ya Airtel 0689933027 jina PETER NYANGE."}'
# → {"predicted_category":"mobile_money_fraud","confidence":0.9966, ...}
```

---

## Why three models? (the short story)

We did not train one model and call it a day. We ran **three deliberate experiments**,
kept all three, and deployed the one that earned it. Each answers a question, and each
builds on the last:

| # | Notebook | The question it answers | The takeaway |
|---|---|---|---|
| 1 | **`initial_demo`** | *Can a simple, cheap model even do this?* | A classical **TF-IDF + Logistic Regression** baseline on the first English/Portuguese corpus. It's the control — nothing fancier is worth it unless it beats this. |
| 2 | **`embed_demo`** | *Does understanding meaning, not just keywords, help?* | Adds multilingual **sentence embeddings (e5-small)** and ensembles them with the lexical model. Tests semantics vs. keywords. |
| 3 | **`final_model`** | *Does it hold up across real African languages — and what do we ship?* | Re-runs the whole comparison on the **expanded en/pt/sw corpus** (real Nigerian + Tanzanian SMS) and picks the deployed model. |

**The honest finding (and why it's interesting):** on *both* corpora the fancy
embeddings do **not** beat the simple lexical baseline. Scam messages reuse give-away
phrases (*"you have won"*, *tuma pesa*, *verify your account*) that TF-IDF already
catches. So the model we ship is the **cheapest** one — TF-IDF + Logistic Regression —
which is also the easiest to serve (no 470 MB embedder, instant cold start). The
embeddings still earn their place as cross-lingual insurance for paraphrase and unseen
wording; they just don't win the leaderboard. Reporting that honestly is a stronger
claim than any single headline number.

> **Why keep all three (and three APIs)?** So the reasoning is transparent and
> reproducible. Anyone can open one notebook, read the whole experiment, re-run it in
> isolation, and hit its live API to compare models side by side. Science, not a black box.

---

## How it fits together

```
  data/  ──(scripts/ 01..13: download → normalise → label → audit/κ → split → relabel → export)──┐
                                                                                                  ▼
  notebooks/        each notebook is self-contained: it trains AND saves its own model
    ├── initial_demo/  ──►  scam_classifier.joblib      ──►  initial_serve/ ─┐
    ├── embed_demo/    ──►  embed_models.joblib          ──►  embed_serve/   ─┤  POST /predict
    └── final_model/   ──►  scam_tfidf_v2.joblib  (ship) ──►  final_serve/   ─┘        │
                                                                                       ▼
                                                                          📱 mobile app scanner
```

A notebook owns its training code (inlined — there is no shared `demo_model`/`embed_model`
module), saves its artifacts **into its own folder**, and has a matching `*_serve/` API
that loads exactly that model. Change a model → it lives, trains, ships, and serves from
one place.

---

## Repository map

| Path | What's inside |
|---|---|
| [`notebooks/`](notebooks/) | The three experiments, each in its own folder with its notebook + the models it produced + a README. Start at [`notebooks/README.md`](notebooks/README.md). |
| `initial_serve/` · `embed_serve/` · `final_serve/` | One FastAPI service per model (app, Dockerfile, HF deploy script). Each loads the matching notebook's model. |
| `scripts/` | The numbered data pipeline, `01_…` → `13_…` (acquire → clean → label → audit → split → relabel African data → export the deployed model). |
| `src/` | The corpus + labelling **library**: `taxonomy.py`, `schema.py` (Pydantic + JSONL I/O), `loaders.py`, `scrapers.py`, `auto_label.py`, `labelling.py` (audit sampling + Cohen's κ). |
| `data/` | `raw/` downloaded datasets · `labelled/` the JSONL corpora · `audits/` second-rater samples for κ. |

---

## Results at a glance

Held-out **test** macro-F1 (70/15/15 stratified split, seed 42):

| Corpus | Best single model | Best ensemble | Notebook |
|---|---|---|---|
| **v1** — 4,422 msgs, en/pt | TF-IDF + LogReg **0.943** | soft-voting **0.955** ✅ best | `embed_demo` |
| **v2** — 9,623 msgs, en/pt/sw | **TF-IDF + LogReg 0.946** ✅ deployed | soft-voting 0.941 | `final_model` |

On v2, mobile-money fraud becomes the **strongest** class (F1 0.983) once Swahili joins
Portuguese in it, and per-language test accuracy is **English ≈ 0.95 · Portuguese ≈ 1.0 ·
Swahili ≈ 0.98** — the coverage question the African data was added to answer.

---

## The corpus

A four-class corpus of **9,623 messages across English, Portuguese, and Swahili**, built
from three streams:

- **Public datasets:** Nazario phishing · UCI SMS Spam · Mendeley smishing · MOZ-Smishing (Portuguese M-Pesa).
- **Regional news stream:** West African scam-relevant reporting (Premium Times via its WordPress API; the official advisory sites ngCERT / ANTIC / EFCC were probed but are blocked — see below).
- **Real African SMS (v2):** **ExAIS** (African-English, Nigeria) + **BongoScam** (Swahili, Tanzania), relabelled into the 4-class taxonomy by `scripts/11_relabel_african.py` and merged by `scripts/12_build_corpus_v2.py`.

Full source links and licences are in [`../docs/DATA_SOURCES.md`](../docs/DATA_SOURCES.md).
Labels are source/heuristic provenance labels; a human inter-rater **κ-verified** audit is
the final word (Objective 3). *Out of scope (future work): a first-hand victim-collected
corpus, romance / identity-theft / synthetic-media classes, and an LLM comparison.*

### Regional source reachability (probed 2026-06-01)

| Source | Status | Note |
|---|---|---|
| Premium Times (EN news) | **works** | WordPress REST API; 393 unique scam-relevant paragraphs harvested |
| ngCERT (`cert.gov.ng`) | blocked | Cloudflare anti-bot (HTTP 403) |
| ANTIC (`antic.cm`, FR) | blocked | host unreachable |
| EFCC (`efccnigeria.org`) | blocked | empty shell / 404 |

The blocked sources are kept as honest, non-crashing probes in `src/scrapers.py` — the
unavailability of official advisories is itself a data-collection limitation worth
reporting. French/Pidgin coverage remains a gap.

---

## Reproduce it

**Run a model** (each notebook trains and saves its own artifacts; the e5 cache means no
re-download):

```bash
pip install -r requirements.txt
cd notebooks/final_model
jupyter nbconvert --to notebook --inplace --execute final_model.ipynb
```

**Rebuild the corpus from scratch** (the numbered pipeline):

```bash
python scripts/01_download_public.py     # fetch public datasets into data/raw/
python scripts/07_scrape_regional.py     # harvest the regional stream (gov sites are logged as blocked)
python scripts/02_normalise.py           # raw → JSONL + quality phase (validate, dedup, length-filter)
python scripts/03c_batch_autolabel.py    # (optional) AUTO-suggest pass so the human pass is confirm-or-correct
python scripts/03b_assisted_label.py     # rater-1 labelling (resume-safe; 03_label_helper.py = pure manual)
python scripts/04_create_audit_sample.py # blinded 100-item sample for rater 2
python scripts/05_compute_kappa.py       # Cohen's κ on the shared items (threshold κ ≥ 0.7)
python scripts/06_split.py               # lock corpus → stratified 70/15/15 split
python scripts/11_relabel_african.py     # relabel ExAIS + BongoScam → 4-class
python scripts/12_build_corpus_v2.py     # merge → data/labelled/demo_labeled_v2.jsonl
python scripts/13_export_tfidf_v2.py     # export the deployed model (scam_tfidf_v2.joblib)
```

### Data record (one JSON object per line)

| Field | Notes |
|---|---|
| `id` | stable 12-char SHA1 of `text` |
| `text` | the message |
| `language` | ISO 639-1 (`pcm` = Nigerian Pidgin) |
| `category` | one of the taxonomy labels |
| `label_source` | `rater1` / `rater2` / `adjudicated` / `auto` |
| `source_stream`, `source_url`, `original_label`, `labelled_at` | provenance |

### Quality phase (`02_normalise.py`, per proposal §3.4.2)

Pydantic schema validation → exact-dedup by `id` → near-dup collapse (char 5-gram
Jaccard ≥ 0.85) → length filter (drop `< 20` or `> 2000` chars).

---

## Taxonomy & deliverables

**Taxonomy** (`src/taxonomy.py`): the four data-backed classes in scope are
`advance_fee_fraud`, `mobile_money_fraud`, `phishing`, `not_a_scam`. Three more
(`romance_scam`, `identity_theft`, `synthetic_media_fraud`) are defined but reserved for
future work.

**Objectives & deadlines** (proposal §1.3.1):

| Obj | Deliverable | Deadline |
|---|---|---|
| 1 | Labelled corpus ≥ 500 items, Cohen's κ ≥ 0.7 on a 100-item audit | 12 Jun 2026 |
| 2 | Working Android build (in [`../mobile/`](../mobile/)) | 26 Jun 2026 |
| 3 | Model comparison with per-category metrics | 10 Jul 2026 |
