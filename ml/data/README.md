# ml/data/

This directory's `raw/`, `processed/`, and `external/` subfolders are gitignored. Code stays in version control; corpora do not.

## Suggested layout

- `raw/` — untouched source files. One folder per source. Each must contain a `SOURCE.md` describing provenance, license, date pulled, and contact.
- `processed/` — cleaned, normalised, schema-conformant CSV/parquet ready for training.
- `external/` — third-party datasets (separated to keep licensing visible).

## Required schema for processed datasets

| column | type | notes |
| --- | --- | --- |
| `text` | string | raw message body, after PII masking if redistributable |
| `label` | string | one of the six labels in `src/dataset.py::SCAM_LABELS` |
| `language` | string | ISO 639-1 (`en`, `fr`, `sw`, ...) or `pcm` for Pidgin English |
| `source` | string | short slug, e.g. `kaggle_phishing_2023`, `efcc_redacted_2024` |

`src/dataset.py::load_csv` enforces this.

## Candidate sources to try first

- Anti-Phishing Working Group (APWG) eCrime reports — phishing corpora
- UCI ML Repository — SMS Spam Collection (English, useful for transfer)
- Kaggle phishing URL collections
- EFCC public case summaries (Nigeria) — manual extraction + redaction
- ANTIC public advisories (Cameroon) — manual extraction
- WhatsApp / SMS scam screenshots collected via the pilot (later)
