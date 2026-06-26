<h1 align="center"><code>ml/</code>: the scam-message classifier</h1>

<p align="center"><strong>The research core of Rethicsec: corpus, modelling experiments, and the deployed classifier</strong></p>

<p align="center">
  <a href="https://wadotuh-scam-classifier-api-final.hf.space"><img alt="Final model API" src="https://img.shields.io/badge/Final%20API-live-2E7D34?style=for-the-badge&logo=huggingface&logoColor=white"></a>
  <img alt="Model macro-F1 0.946" src="https://img.shields.io/badge/Model-macro--F1%200.946-C8851A?style=for-the-badge">
  <img alt="Corpus languages" src="https://img.shields.io/badge/Corpus-EN%20%7C%20PT%20%7C%20SW-5C4536?style=for-the-badge">
  <img alt="Corpus size" src="https://img.shields.io/badge/Messages-9%2C623-3E2B20?style=for-the-badge">
  <img alt="Framework scikit-learn" src="https://img.shields.io/badge/Framework-scikit--learn-A66E12?style=for-the-badge&logo=scikitlearn&logoColor=white">
</p>

This directory holds the research core of Rethicsec: the corpus, the modelling
experiments, and the trained classifier that the mobile app's scanner calls. Given a
short message, the classifier answers one question, namely whether the message is a scam
and of what kind. It assigns one of four labels: `advance_fee_fraud`,
`mobile_money_fraud`, `phishing`, or `not_a_scam`.

The sections below explain what was built, how the three models compare on real numbers,
and why one of them was chosen for deployment.

## Table of contents

1. [Live model APIs](#live-model-apis)
2. [Why there are three models](#why-there-are-three-models)
3. [Results: every model across the three experiments](#results-every-model-across-the-three-experiments)
4. [Why the final model was chosen](#why-the-final-model-was-chosen)
5. [How the pieces fit together](#how-the-pieces-fit-together)
6. [Repository map](#repository-map)
7. [The corpus](#the-corpus)
8. [Reproducing the work](#reproducing-the-work)
9. [Data format and quality checks](#data-format-and-quality-checks)
10. [Taxonomy and deliverables](#taxonomy-and-deliverables)

## Live model APIs

All three models are deployed, each behind its own public endpoint. Send a `POST` request
to `/predict` with a JSON body of `{"text": "..."}`. Interactive documentation is at
`/docs` on each Space.

| Model | Live API | Summary |
|---|---|---|
| Final (deployed; the app uses this) | https://wadotuh-scam-classifier-api-final.hf.space | TF-IDF with Logistic Regression on the en/pt/sw corpus. Test macro-F1 0.946. No embedder, so it starts instantly. |
| Embedding ensemble | https://wadotuh-scam-classifier-api-embed.hf.space | TF-IDF plus e5-small embeddings in a soft-voting ensemble. Test macro-F1 0.955 on the smaller corpus. |
| Initial baseline | https://wadotuh-scam-classifier-api-initial.hf.space | TF-IDF with Logistic Regression, the first baseline. |

A quick test against the deployed model, using a Swahili mobile-money lure:

```bash
curl -X POST https://wadotuh-scam-classifier-api-final.hf.space/predict \
  -H "Content-Type: application/json" \
  -d '{"text":"Iyo pesa itume kwenye namba hii ya Airtel 0689933027 jina PETER NYANGE."}'
# returns: {"predicted_category":"mobile_money_fraud","confidence":0.9966, ...}
```

## Why there are three models

The project did not train a single model in isolation. It ran three experiments in
sequence, kept all of them, and deployed the one the evidence supported. Each experiment
asks a specific question, and each builds on the answer to the previous one. Keeping all
three makes the reasoning auditable: a reader can open any notebook, follow the full
experiment, re-run it on its own, and call its live API to compare the models directly.

| Stage | Notebook | The question it answers |
|---|---|---|
| 1 | [`notebooks/initial_demo/`](notebooks/initial_demo/) | Can a simple, inexpensive model classify these messages at all? It establishes a classical TF-IDF with Logistic Regression baseline on the first English and Portuguese corpus. This baseline is the control: a more complex model has to beat it to justify its cost. |
| 2 | [`notebooks/embed_demo/`](notebooks/embed_demo/) | Does modelling meaning, rather than keywords, improve results? It adds multilingual sentence embeddings (e5-small) and combines them with the lexical model in soft-voting and stacking ensembles. Its headline macro-F1 looked strong, but a per-class read exposed the real setback: the model kept misclassifying `mobile_money_fraud` and `advance_fee_fraud`, the two classes that mattered most and had the fewest training examples. That weakness is what motivated stage 3. |
| 3 | [`notebooks/final_model/`](notebooks/final_model/) | Can more data fix the two weak classes, and which model should ship? Because the embedding model failed on mobile-money and advance-fee messages, real African SMS was gathered (Nigerian ExAIS and Tanzanian BongoScam) to give those classes far more examples. The notebook repeats the full comparison on the expanded English, Portuguese, and Swahili corpus, then selects the model for deployment. After the data was added, the plain TF-IDF with Logistic Regression model came out on top, so it is the one that ships. |

## Results: every model across the three experiments

Each notebook reports its models on a held-out test split (70/15/15, stratified, fixed
seed). The tables below give the full ladder, not only the winner, so the comparison is
transparent. Accuracy is overall correctness; macro-F1 averages the per-class F1 scores and
so weighs the rare scam classes as heavily as the common ones, which is why it is the
headline metric.

**Stage 1 baseline (4,422 messages, English and Portuguese), from `initial_demo`:**

| Model | Accuracy | Macro-F1 |
|---|---|---|
| TF-IDF + Logistic Regression | 0.958 | 0.943 |
| TF-IDF + Random Forest | 0.950 | 0.928 |

The baseline only fits the two lexical models. It is the control that stage 2 has to beat,
so the embedding work begins from these numbers.

**Stage 2, corpus v1 (the same 4,422 messages), from `embed_demo`:**

| Model | Accuracy | Macro-F1 |
|---|---|---|
| TF-IDF + Logistic Regression | 0.958 | 0.943 |
| TF-IDF + Random Forest | 0.950 | 0.928 |
| e5 embeddings + Logistic Regression | 0.953 | 0.926 |
| e5 embeddings + Random Forest | 0.952 | 0.910 |
| Soft-voting ensemble | **0.971** | **0.955** (best) |
| Stacking ensemble | 0.952 | 0.925 |

**Stage 3, corpus v2 (9,623 messages, English, Portuguese, and Swahili), from `final_model`:**

| Model | Accuracy | Macro-F1 |
|---|---|---|
| TF-IDF + Logistic Regression | **0.965** | **0.946** (best, deployed) |
| TF-IDF + Random Forest | 0.936 | 0.913 |
| e5 embeddings + Logistic Regression | 0.929 | 0.899 |
| e5 embeddings + Random Forest | 0.918 | 0.884 |
| Soft-voting ensemble | 0.959 | 0.941 |
| Stacking ensemble | 0.958 | 0.937 |

This is where the stage 2 setback gets resolved. On the smaller corpus the embedding
ensemble had struggled to tell mobile-money and advance-fee messages apart, the two classes
with the fewest examples. Once the African SMS was added, mobile-money fraud went from a
weak class to the strongest one, reaching a per-class F1 of 0.983. Per-language test
accuracy was 0.95 for English, 1.00 for Portuguese, and 0.98 for Swahili, which answers the
coverage question the African data was added to test. The fix was more data for the weak
classes, not a more complex model.

## Why the final model was chosen

The deployed model is TF-IDF with Logistic Regression, the v2 result in the table above.
The path to it runs through the stage 2 setback. The embedding ensemble was the most
complex model and won on the smaller v1 corpus, but a per-class look showed it could not
reliably classify `mobile_money_fraud` or `advance_fee_fraud`, which are the classes the
app exists to catch. The response was to gather real African SMS for those classes and
retrain everything on the larger corpus. On that corpus the plain lexical model, not the
ensemble, came out best, so it is the one that ships. Three reasons support the choice.

First, accuracy. On the expanded corpus it has the highest macro-F1 (0.946) and the
highest accuracy (0.965) of any model tried, single or ensemble, and it carries the
previously weak mobile-money class to a per-class F1 of 0.983. The soft-voting ensemble,
which won on the smaller v1 corpus, fell behind it once the corpus grew.

Second, cost. The lexical model is a small scikit-learn pipeline of about 1.5 MB. It needs
no sentence-embedding network, so the service starts immediately and uses little memory.
The embedding ensemble requires a 470 MB e5 download and more memory at serve time, and on
v2 it scored lower, so its extra complexity buys nothing here.

Third, an honest reading of the embeddings. On both corpora the embedding models did not
beat the lexical baseline. Scam messages reuse give-away phrasing, for example "you have
won", "verify your account", and the Swahili "tuma pesa", which is exactly the signal that
TF-IDF captures well. The reason the lexical model pulls further ahead on v2 is that the
added African SMS is keyword-rich, so a larger and more lexical corpus favours the lexical
model. The embeddings still have value as cross-lingual cover for paraphrase and wording
the model has not seen, but they do not win on this in-distribution test. Reporting that
plainly is a more defensible claim than presenting a single headline figure.

In short, the lexical model is both the most accurate on the deployment corpus and the
cheapest to run, so it is the one served to the app. The other two remain available as the
documented baseline and the semantic comparison.

## How the pieces fit together

![From the corpus, through the scripts and the three notebooks, to the serve apps, the predict API, and the mobile app](../docs/assets/ml/ml_pipeline.png)

Each notebook contains its own training code; there is no shared `demo_model` or
`embed_model` module to import. A notebook writes its artifacts into its own folder, and
the matching `*_serve/` service loads exactly that model. A given model therefore lives,
trains, ships, and serves from one place.

## Repository map

| Path | Contents |
|---|---|
| [`notebooks/`](notebooks/) | The three experiments. Each folder holds one notebook, the models it produced, and a short README. Begin at [`notebooks/README.md`](notebooks/README.md). |
| `initial_serve/`, `embed_serve/`, `final_serve/` | One FastAPI service per model (the app, a Dockerfile, and a Hugging Face deploy script). Each loads the matching notebook's model. |
| `scripts/` | The numbered data pipeline, `01_` through `13_`: acquire, clean, label, audit, split, relabel the African data, and export the deployed model. |
| `src/` | The corpus and labelling library: `taxonomy.py`, `schema.py` (a Pydantic record plus JSONL input and output), `loaders.py`, `scrapers.py`, `auto_label.py`, and `labelling.py` (audit sampling and Cohen's kappa). |
| `data/` | `raw/` for downloaded datasets, `labelled/` for the JSONL corpora, and `audits/` for the second-rater samples used to compute kappa. |

## The corpus

The corpus holds 9,623 messages across English, Portuguese, and Swahili, labelled into the
four classes. It was assembled from three streams.

The first is public datasets: the Nazario phishing collection, UCI SMS Spam, Mendeley
smishing, and MOZ-Smishing (Portuguese M-Pesa messages). The second is a regional news
stream of West African scam reporting, harvested from Premium Times through its WordPress
API. The third, added for v2, is real African SMS: ExAIS (African-English, from Nigeria)
and BongoScam (Swahili, from Tanzania). The African sets carry binary native labels, which
`scripts/11_relabel_african.py` maps into the four-class taxonomy before
`scripts/12_build_corpus_v2.py` merges them in. Source links and licences are listed in
[`../docs/DATA_SOURCES.md`](../docs/DATA_SOURCES.md).

The labels are source-provenance and heuristic labels. A human inter-rater study, measured
with Cohen's kappa, is the final standard of label quality (Objective 3). A first-hand
victim-collected corpus, the three reserved scam classes, and a comparison against a large
language model are out of scope and recorded as future work.

The official advisory sites were tested as sources but could not be scraped, as of
1 June 2026:

| Source | Status | Note |
|---|---|---|
| Premium Times (English news) | works | WordPress REST API; 393 unique scam-relevant paragraphs harvested |
| ngCERT (`cert.gov.ng`) | blocked | Cloudflare anti-bot (HTTP 403) |
| ANTIC (`antic.cm`, French) | blocked | host unreachable |
| EFCC (`efccnigeria.org`) | blocked | empty page or HTTP 404 |

The blocked sources stay in `src/scrapers.py` as honest probes that log why they returned
nothing. The lack of reachable official advisories is itself a data-collection limitation
worth recording, and French and Pidgin coverage remains a gap.

## Reproducing the work

To train a model, run its notebook. Each one trains and saves its own artifacts, and the
cached embeddings mean the embedding notebooks do not re-download the e5 weights:

```bash
pip install -r requirements.txt
cd notebooks/final_model
jupyter nbconvert --to notebook --inplace --execute final_model.ipynb
```

To rebuild the corpus from raw sources, run the numbered pipeline:

```bash
python scripts/01_download_public.py     # fetch public datasets into data/raw/
python scripts/07_scrape_regional.py     # harvest the regional stream (blocked gov sites are logged)
python scripts/02_normalise.py           # raw to JSONL, with the quality checks below
python scripts/03c_batch_autolabel.py    # optional auto-suggest pass, so the human pass is confirm-or-correct
python scripts/03b_assisted_label.py     # rater-1 labelling, resume-safe (03_label_helper.py is fully manual)
python scripts/04_create_audit_sample.py # a blinded 100-item sample for rater 2
python scripts/05_compute_kappa.py       # Cohen's kappa on the shared items (threshold 0.7)
python scripts/06_split.py               # lock the corpus and produce the 70/15/15 split
python scripts/11_relabel_african.py     # map ExAIS and BongoScam into the four classes
python scripts/12_build_corpus_v2.py     # merge into data/labelled/demo_labeled_v2.jsonl
python scripts/13_export_tfidf_v2.py     # export the deployed model, scam_tfidf_v2.joblib
```

## Data format and quality checks

Each corpus file is JSON Lines, one record per line:

| Field | Notes |
|---|---|
| `id` | a stable 12-character SHA1 hash of `text` |
| `text` | the message |
| `language` | ISO 639-1 (`pcm` for Nigerian Pidgin) |
| `category` | one of the taxonomy labels |
| `label_source` | `rater1`, `rater2`, `adjudicated`, or `auto` |
| `source_stream`, `source_url`, `original_label`, `labelled_at` | provenance fields |

`scripts/02_normalise.py` runs four checks before any training, following proposal section
3.4.2. It validates each record against the Pydantic schema, removes exact duplicates by
`id`, collapses near-duplicates (character 5-gram fingerprints with Jaccard similarity at
or above 0.85), and drops messages shorter than 20 or longer than 2000 characters.

## Taxonomy and deliverables

The taxonomy lives in `src/taxonomy.py`. Four classes are in scope because they are backed
by data: `advance_fee_fraud`, `mobile_money_fraud`, `phishing`, and `not_a_scam`. Three
more (`romance_scam`, `identity_theft`, and `synthetic_media_fraud`) are defined but held
for future work.

The objectives and their deadlines, from proposal section 1.3.1:

| Objective | Deliverable | Deadline |
|---|---|---|
| 1 | A labelled corpus of at least 500 items, with Cohen's kappa of 0.7 or higher on a 100-item audit | 12 June 2026 |
| 2 | A working Android build (in [`../mobile/`](../mobile/)) | 26 June 2026 |
| 3 | A model comparison with per-category metrics | 10 July 2026 |
