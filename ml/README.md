# ml/

Machine learning research for the capstone. Frames the production app's LLM-based scam detection (see `../backend/`) as one arm of a comparative study, and adds the classical-ML evaluation that the Pre-Capstone proposal originally promised.

## Research question (working)

> How do classical ML baselines compare to API-based LLMs on multilingual scam classification across the five categories prioritised in the proposal, and how should the cost / latency / accuracy trade-off shape the deployed system?

## Five scam categories (locked)

1. `advance_fee_fraud`
2. `mobile_money_fraud`
3. `phishing`
4. `romance_scam`
5. `identity_theft`

Plus `none` for the LLM evaluation, since not every incoming message is fraudulent.

## Layout

```
ml/
├── data/         # raw + processed datasets (gitignored)
├── notebooks/    # exploration, EDA, ad-hoc evaluation
├── src/          # importable training / preprocessing / eval code
│   ├── dataset.py
│   ├── preprocessing.py
│   ├── baselines.py
│   ├── llm_baselines.py
│   └── eval.py
├── models/       # saved checkpoints (gitignored)
└── reports/      # model cards, error analysis writeups
    └── MODEL_CARD_TEMPLATE.md
```

## Setup

```
cd ml
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Phase 1 deliverables (8 weeks)

- [ ] Dataset card (`reports/dataset_card.md`) — sources, size, label distribution, language distribution, annotation protocol, biases
- [ ] Three classical baselines trained + evaluated with stratified 5-fold CV (TF-IDF + LR / RF / GB)
- [ ] One transformer baseline (multilingual: XLM-R or AfroXLMR) fine-tuned on the same split
- [ ] LLM zero-shot + few-shot evaluation on the held-out test set (Gemini 1.5 Flash + GPT-4o-mini)
- [ ] Per-language and per-class confusion matrices in `reports/`
- [ ] Latency + cost measurements for the LLM arm
- [ ] Decision memo: which approach goes into the production app

## Suggested order of work

1. **Week 1** — Dataset acquisition plan; pull whatever public corpora exist (APWG, UCI, Kaggle phishing collections); document gaps.
2. **Week 2** — PII masking pipeline; build labelled seed set (~500 examples / category if possible) by manual annotation + weak supervision.
3. **Week 3** — TF-IDF + LR end-to-end with stratified 5-fold CV; baseline metrics committed to `reports/`.
4. **Week 4** — Add RF + GB; per-language stratification; first dataset card draft.
5. **Week 5** — Transformer baseline (XLM-R fine-tuning).
6. **Week 6** — LLM zero-shot eval (both Gemini + OpenAI); record latency and cost per call.
7. **Week 7** — LLM few-shot eval; error analysis (qualitative examples of disagreements between best classical model and LLMs).
8. **Week 8** — Decision memo + ML methods chapter draft.
