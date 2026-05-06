# Capstone — AI-Powered Cybercrime Reporting & Scam Detection in West Africa

**Author:** Wilsons Navid Wado Tiwa — BSc Software Engineering, African Leadership University
**Term:** Final-year capstone, **2-month execution window** (target completion ~2026-07-05)
**Global Challenge:** Millennium Project Challenge 12 — transnational organised crime
**Today:** 2026-05-05 — Sprint 1 begins

---

## Single source of truth — current status

| | |
| --- | --- |
| **App** | Rethicssec v1.0.2+3 (Flutter + Firebase), already published — code at `mobile/rethicsai/` (consolidated into the workspace 2026-05-05; original backup at `C:\Users\LENOVO\Desktop\rethicsai\` is read-only) |
| **ML model** | **Not built.** Production app uses Vertex AI Gemini 1.5 Flash + OpenAI GPT-4o-mini via Cloud Functions; no custom-trained classifier exists |
| **Pilot** | Not started. Lagos + Douala per the proposal |
| **Dissertation** | Not started. All 4 unit assignments + Pre-Capstone Major Assessment proposal complete (`docs/`) |
| **Sprint** | S1 — Foundation (reconciliation + codebase recovery + first ML baseline) |

---

## Workspace map

```
Capstone-Project/
├── README.md                ← this file (status board)
├── .gitignore
├── docs/                    ← all planning deliverables (Units 1–4, Pre-Capstone proposal)
├── mobile/                  ← Rethicssec Flutter app (consolidated 2026-05-05)
│   ├── PRIVACY_POLICY.md / .docx
│   ├── PLAYSTORE_DESCRIPTIONS.md
│   ├── create_privacy_policy_docx.py
│   └── rethicsai/           ← the Flutter project itself (lib/, android/, ios/, functions/, ...)
├── ml/                      ← machine learning research workspace (the missing piece)
│   ├── README.md            ← research framing + sprint deliverables
│   ├── requirements.txt
│   ├── data/                ← raw + processed corpora (gitignored)
│   ├── notebooks/           ← exploration, baselines, ad-hoc eval
│   ├── src/                 ← importable training / preprocessing / eval code
│   │   ├── dataset.py
│   │   ├── preprocessing.py
│   │   ├── baselines.py
│   │   ├── llm_baselines.py
│   │   └── eval.py
│   ├── models/              ← saved checkpoints (gitignored)
│   └── reports/             ← model cards, error analysis
├── meetings/                ← weekly supervisor meeting notes
│   └── _template.md
├── pilot/                   ← consent forms, interview guides, analysis
└── dissertation/            ← final report (chapters, generators)
```

---

## Where the app lives

The Flutter app is now in-tree at `mobile/rethicsai/`. The Cloud Functions backend lives inside it at `mobile/rethicsai/functions/` (no separate `backend/` folder anymore — the pointer was removed when the code was consolidated).

The original location at `C:\Users\LENOVO\Desktop\rethicsai\` is **kept untouched as a read-only backup**. From 2026-05-05 forward, all editing, building, and committing happens against the workspace copy. Do not edit the backup; it exists only as a safety net.

Build artifacts (`build/`, `.dart_tool/`, `node_modules/`) were excluded during the copy and will regenerate on first `flutter pub get` / `npm install`. The `.git/`, `.firebase/`, and IDE configs travelled with the project so deploys and Android Studio reopen cleanly.

---

## The reconciliation that has to happen first

The Pre-Capstone proposal (`docs/coursework/Major-assesment/`) and the built app diverge in three load-bearing ways:

| | Proposal | Built app |
| --- | --- | --- |
| Pilot scope | Lagos + Douala only | Pan-African positioning |
| Languages | en, fr, pcm (3) | 11 African languages |
| ML approach | Custom Scikit-learn / TensorFlow classifier, ≥85% accuracy on 5 categories | Vertex Gemini Flash + GPT-4o-mini, no measured accuracy, no fixed taxonomy |

Phase 0 is about deciding which of these to amend (the proposal) and which to add (the missing custom-ML evaluation). The recommended framing — **"LLM-based vs. classical ML scam detection for low-resource West African languages"** — keeps the existing app *and* delivers the ML rigor your supervisor asked for, by treating the deployed LLMs as one arm of a comparative study.

See `ml/README.md` for the research question and Phase 1 deliverables.

---

## Sprint plan (2-month overview)

The original proposal assumed a 6-month plan. The app is already built, so most of that compresses cleanly. Pilot scope is the main cut.

| Sprint | Days | Focus | Exit gate |
| --- | --- | --- | --- |
| **S1 — Foundation** | 1–7 | Reconciliation memo + supervisor sign-off; codebase recovery (6-month dormancy); ML venv; pull public datasets; PII masking; ~500-example labelled set | TF-IDF + LR baseline running end-to-end |
| **S2 — ML core** | 8–14 | Add RF baseline; LLM zero-shot eval (Gemini + GPT-4o-mini); per-language confusion matrices; dataset + model cards | 3-approach comparison on held-out test set |
| **S3 — App + pilot prep** | 15–21 | Lock 6-category taxonomy in `analyzeSuspiciousContent`; classification logging to Firestore; deepfake-aware UI warning; consent forms, interview guide, recruitment, IRB | App emits structured incidents; pilot kit ready |
| **S4 — Pilot launch** | 22–35 | Pilot in **one city, 15–25 users**; SUS + Firebase analytics; 5–8 mid-pilot interviews | Pilot wraps with usable data |
| **S5 — Analysis + writing** | 36–49 | SUS scoring, thematic analysis, on-pilot ML accuracy; dissertation chapters in parallel | Analysis done; chapters 4–5 drafted |
| **S6 — Submit + defend** | 50–56 | Polish, demo video, defense rehearsal | Submitted, defended |

**Cuts from the original year-long plan:** pilot 50–100 users → 15–25; 2 cities → 1; ML baselines 4 → 2 (no transformer fine-tuning); CMU-Africa data assumed unavailable in time (still send the email).

---

## Weekly supervisor meeting cadence

Use `meetings/_template.md`. One file per meeting, named `YYYY-MM-DD.md`. Every meeting covers four sections:

1. Last week — committed vs delivered (with evidence: commit links, plots, screenshots)
2. Blockers
3. Reading & learning the supervisor assigned (what you took away, follow-up questions)
4. This week — commitments

---

## Key documents

Coursework (Units 1–4 + Pre-Capstone Major Assessment) all live under `docs/coursework/`:

| File | What it is |
| --- | --- |
| `docs/coursework/Unit_One_Draft - Copy.docx` | Chapter One — intro, problem, objectives (5 SMART), research questions (5), scope, significance |
| `docs/coursework/WilsonsNavidWadoTiwa-Unit Two Assignment.docx` | Refined Unit 2 draft |
| `docs/coursework/unit3/WilsonsNavidWadoTiwa_Unit_Three Assignment.docx` | Annotated bibliography (22 sources) |
| `docs/coursework/unit4/WilsonsNavidWadoTiwa_Unit Four Assignment.docx` | Methodology — mixed-methods, SUS, semi-structured interviews, thematic analysis |
| `docs/coursework/Major-assesment/WilsonsNavidWadoTiwa_Pre-Capstone_Research_Proposal_v2.docx` | Full Pre-Capstone proposal w/ literature review, system design, all 6 UML diagrams |
| `docs/coursework/Major-assesment/diagrams/` | Agile model, system architecture, ERD, class, use case, mixed-methods diagrams |

Active project documents in `docs/` root: `RECONCILIATION_MEMO.md`, `WilsonsNavidWadoTiwa_Reconciliation_Memo.docx`, `onboarding/Capstone_Onboarding_Report.docx`, plus auxiliary files (`Mission-Capstone.docx`, `Project Draft.docx`, `Rubric.docx`).

---

## Formatting standard (locked across all academic deliverables)

APA 7 · Times New Roman 12pt body · Arial 14pt headings, 12pt subheadings · double-spaced · 1-inch margins · file naming `WilsonsNavidWadoTiwa_<Unit/Section>`
