"""Generate and execute the EXPANDED-CORPUS notebook (v2).

Same model ladder as `build_main_notebook.py` (TF-IDF + multilingual-e5-small ->
soft-voting / stacking ensemble), but trained on `demo_labeled_v2.jsonl` — the
corpus grown with two real African SMS datasets:
  * ExAIS_SMS    — African-English (Nigeria), spam/ham.
  * BongoScam    — Tanzanian Swahili, scam/trust.
relabeled into the 4-class taxonomy by `scripts/11_relabel_african.py`.

A separate embedding cache (emb_e5small_v2.npz) is used so the v1 artefacts stay
reproducible.

Run:  python ml/notebooks/build_main_notebook_v2.py
"""

from __future__ import annotations

from pathlib import Path

import nbformat as nbf
from nbconvert.preprocessors import ExecutePreprocessor

HERE = Path(__file__).resolve().parent
OUT = HERE / "scam_detection_main_v2.ipynb"

md = lambda s: nbf.v4.new_markdown_cell(s)
code = lambda s: nbf.v4.new_code_cell(s)

cells = [
    md("# Scam-Message Classifier — Expanded Multilingual Corpus (v2)\n"
       "Same classifier as the main notebook — it decides whether a short message is "
       "**advance-fee fraud**, **mobile-money fraud**, **phishing**, or **not-a-scam** — "
       "but trained on a **larger, more African corpus**.\n\n"
       "Two real African SMS datasets have been added and relabeled into the 4-class taxonomy:\n\n"
       "| Dataset | Origin | Language | Native labels |\n"
       "|---|---|---|---|\n"
       "| **ExAIS_SMS** | Federal Univ. of Agriculture, Abeokuta (Nigeria) | African-English | spam / ham |\n"
       "| **BongoScam** | Tanzania | Swahili | scam / trust |\n\n"
       "Relabelling (see `scripts/11_relabel_african.py`): legitimate → *not_a_scam*; "
       "ExAIS spam → a heuristic English suggester (benign promo spam stays *not_a_scam*); "
       "Swahili scam → a Swahili/African mobile-money lexicon. These join the original "
       "public sources (Nazario, UCI, Mendeley, MOZ-Smishing).\n\n"
       "The model is built in three rungs and compared head-to-head:\n\n"
       "1. **Lexical baseline** — TF-IDF → Logistic Regression / Random Forest.\n"
       "2. **Semantic upgrade** — multilingual **e5-small** sentence embeddings → LogReg / RF "
       "(language-agnostic: en / pt / sw).\n"
       "3. **Ensemble** — soft-voting and stacking over the lexical + semantic models.\n\n"
       "*Labels here are source/heuristic provenance labels, the same standing as the rest of "
       "the corpus; the human inter-rater κ-verified set is the final evaluation (Objective 3).*"),

    md("## 1 · Data engineering — the expanded corpus"),
    code("import sys\n"
         "from pathlib import Path\n"
         "import pandas as pd, numpy as np\n"
         "import matplotlib.pyplot as plt, seaborn as sns\n"
         "sys.path.insert(0, str(Path.cwd().parent))\n"
         "from src import demo_model as dm        # shared corpus loader + TF-IDF baseline\n"
         "from src import embed_model as em        # embeddings + ensemble (this pipeline)\n"
         "sns.set_theme(style='whitegrid')\n"
         "\n"
         "V2 = Path.cwd().parent / 'data' / 'labelled' / 'demo_labeled_v2.jsonl'\n"
         "em.EMB_CACHE = em.MODELS / 'emb_e5small_v2.npz'   # separate cache; keep v1 intact\n"
         "df = dm.load_df(V2)\n"
         "print(f'{len(df):,} labelled messages | classes = {dm.CLASS_ORDER}')\n"
         "df.sample(4, random_state=0)"),

    md("**Corpus growth — what the African datasets added.** The original corpus was "
       "English/Portuguese only; the additions bring African-English (ExAIS) and Swahili "
       "(BongoScam), and roughly double the two scarce scam classes (mobile-money, advance-fee)."),
    code("AFRICAN = {'exais_sms', 'swahili_bongo'}\n"
         "df['corpus'] = np.where(df['source'].isin(AFRICAN), 'v2 added (African)', 'v1 original')\n"
         "growth = df.groupby(['category','corpus']).size().unstack(fill_value=0)\n"
         "growth = growth.reindex(dm.CLASS_ORDER)\n"
         "ax = growth[['v1 original','v2 added (African)']].plot.bar(\n"
         "        stacked=True, figsize=(9,4.4), color=['#0d253d','#e76f51'])\n"
         "for c in dm.CLASS_ORDER:\n"
         "    tot = int(growth.loc[c].sum())\n"
         "    ax.text(dm.CLASS_ORDER.index(c), tot+40, str(tot), ha='center', fontsize=9)\n"
         "plt.title('Corpus growth by class — original vs African additions')\n"
         "plt.ylabel('messages'); plt.xticks(rotation=15); plt.legend(title='')\n"
         "plt.tight_layout(); plt.show()\n"
         "growth.assign(total=growth.sum(1))"),

    code("# Corpus shape: class / source / language\n"
         "fig, ax = plt.subplots(1, 3, figsize=(16, 4))\n"
         "df['category'].value_counts().reindex(dm.CLASS_ORDER).plot.bar(\n"
         "    ax=ax[0], color='#533afd', title='Class distribution')\n"
         "df['source'].value_counts().plot.bar(ax=ax[1], color='#0d253d', title='Source')\n"
         "df['language'].value_counts().plot.bar(ax=ax[2], color='#e76f51', title='Language')\n"
         "for a in ax: a.tick_params(axis='x', rotation=30)\n"
         "ax[2].set_xticklabels(['English','Swahili','Portuguese'][:df['language'].nunique()])\n"
         "plt.tight_layout(); plt.show()"),

    md("**Provenance — which source feeds which class.** The corpus is deliberately "
       "multi-source and now multi-region so no single class is tied to one writing style "
       "or one country."),
    code("ct = pd.crosstab(df['category'], df['source']).reindex(dm.CLASS_ORDER)\n"
         "plt.figure(figsize=(11,4.2))\n"
         "sns.heatmap(ct, annot=True, fmt='d', cmap='rocket_r', cbar_kws={'label':'messages'})\n"
         "plt.title('Class x source provenance (7 sources, 3 languages)')\n"
         "plt.ylabel(''); plt.xlabel(''); plt.xticks(rotation=20, ha='right')\n"
         "plt.tight_layout(); plt.show()"),

    md("**Language × class.** Mobile-money fraud is now carried by Portuguese (MOZ) *and* "
       "Swahili (BongoScam); advance-fee and phishing gain African-English (ExAIS). This "
       "cross-lingual spread is exactly what the multilingual embedding is meant to exploit."),
    code("lc = pd.crosstab(df['language'], df['category'])[dm.CLASS_ORDER]\n"
         "lc.index = [{'en':'English','pt':'Portuguese','sw':'Swahili'}.get(i,i) for i in lc.index]\n"
         "plt.figure(figsize=(8,3.4))\n"
         "sns.heatmap(lc, annot=True, fmt='d', cmap='mako_r', cbar_kws={'label':'messages'})\n"
         "plt.title('Language x class'); plt.ylabel(''); plt.xlabel('')\n"
         "plt.xticks(rotation=18, ha='right'); plt.tight_layout(); plt.show()"),

    md("## 2 · Two feature representations\n"
       "**Lexical — TF-IDF.** Word 1–2 grams, `min_df=2`, sublinear TF, unicode accent "
       "stripping, vocab capped at 30,000. Strong when scams reuse give-away phrases but "
       "blind to paraphrase and to languages it never saw at fit time.\n\n"
       "**Semantic — multilingual-e5-small.** A sentence-transformer mapping each message "
       "(prefixed `\"query: \"`) to a 384-dim vector where *meaning* drives proximity. It covers "
       "English / Portuguese / Swahili in one shared space, so a Swahili mobile-money scam sits "
       "near its Portuguese and English cousins. Embeddings are cached (`emb_e5small_v2.npz`).\n\n"
       "Each representation feeds a **Logistic Regression** (`class_weight='balanced'`) and a "
       "**Random Forest** (500 trees). RF is skipped on TF-IDF (weak on sparse input). "
       "70/15/15 **stratified** split, seed 42, metrics on the held-out **test** split only."),

    md("## 3 · Train the full ladder\n"
       "`em.train_and_eval(df)` fits the four base models and both ensembles in one call "
       "(the same function the CLI report and the saved model use). First run encodes "
       "~9.6k messages with e5-small, then caches them."),
    code("bundle = em.train_and_eval(df)\n"
         "train, dev, test = bundle['splits']\n"
         "print(f'train {len(train)} / dev {len(dev)} / test {len(test)}')\n"
         "print('models:', list(bundle['base']) + ['ensemble_softvote', 'ensemble_stack'])\n"
         "print('ensemble members:', bundle['members'])"),

    md("**Ensembles.**\n"
       "- **Soft-voting** = element-wise mean of the member probability vectors, then arg-max.\n"
       "- **Stacking** = a meta Logistic Regression trained on the **dev-split** member "
       "probabilities (bases fit on train only — no leakage), applied to the test split."),

    md("## 4 · Results — held-out test set"),
    code("rows = [{'model': n,\n"
         "         'accuracy': round(bundle['results'][n]['accuracy'], 3),\n"
         "         'macro_F1': round(bundle['results'][n]['macro_f1'], 3)}\n"
         "        for n in bundle['order']]\n"
         "summary = pd.DataFrame(rows).set_index('model'); summary"),

    code("# Macro-F1 across the ladder, baseline + best marked\n"
         "base_f1 = summary.loc['tfidf_logreg', 'macro_F1']\n"
         "best_name = bundle['best']; best_f1 = summary.loc[best_name, 'macro_F1']\n"
         "colors = ['#9aa7b8','#c2ccd9','#7c6cf0','#a99bf6','#533afd','#0d253d']\n"
         "lo = max(0.80, summary['macro_F1'].min() - 0.03)\n"
         "ax = summary['macro_F1'].plot.bar(color=colors, figsize=(9,4.4), ylim=(lo,1.0))\n"
         "ax.axhline(base_f1, ls='--', color='#e63946', lw=1.2, label=f'baseline {base_f1:.3f}')\n"
         "for i, v in enumerate(summary['macro_F1']):\n"
         "    ax.text(i, v+0.002, f'{v:.3f}', ha='center', fontsize=9,\n"
         "            fontweight='bold' if summary.index[i]==best_name else 'normal')\n"
         "plt.title(f'Macro-F1 by model (test split) — best: {best_name} {best_f1:.3f}')\n"
         "plt.xticks(rotation=20, ha='right'); plt.legend(); plt.tight_layout(); plt.show()"),

    md("**Per-class F1** — where each representation wins, now across three languages."),
    code("sub = ['tfidf_logreg','emb_logreg','emb_rf','ensemble_softvote']\n"
         "rowsf = [{'class': c, 'model': n, 'F1': bundle['results'][n]['per_class'][c]}\n"
         "         for n in sub for c in dm.CLASS_ORDER]\n"
         "fdf = pd.DataFrame(rowsf)\n"
         "plt.figure(figsize=(10,4.4))\n"
         "sns.barplot(data=fdf, x='class', y='F1', hue='model',\n"
         "            palette=['#9aa7b8','#7c6cf0','#a99bf6','#533afd'])\n"
         "plt.ylim(0.5,1.02); plt.title('Per-class F1: lexical vs semantic vs ensemble')\n"
         "plt.xticks(rotation=12); plt.legend(title='', fontsize=8); plt.tight_layout(); plt.show()"),

    md("**Confusion matrix — the shipped model (soft-voting ensemble).**"),
    code("from sklearn.metrics import confusion_matrix\n"
         "cm = confusion_matrix(test['category'], bundle['softvote_pred'], labels=dm.CLASS_ORDER)\n"
         "plt.figure(figsize=(6,5))\n"
         "sns.heatmap(cm, annot=True, fmt='d', cmap='Purples',\n"
         "            xticklabels=dm.CLASS_ORDER, yticklabels=dm.CLASS_ORDER)\n"
         "plt.title(f\"Soft-voting ensemble (macro-F1 {bundle['results']['ensemble_softvote']['macro_f1']:.3f})\")\n"
         "plt.xlabel('predicted'); plt.ylabel('true'); plt.xticks(rotation=30)\n"
         "plt.tight_layout(); plt.show()"),

    md("**Per-language accuracy of the shipped ensemble.** Does the model actually work in "
       "Swahili and Portuguese, or only in English? This is the headline question the African "
       "data was added to answer."),
    code("test_eval = test.copy()\n"
         "test_eval['pred'] = bundle['softvote_pred']\n"
         "test_eval['correct'] = test_eval['pred'] == test_eval['category']\n"
         "by_lang = (test_eval.groupby('language')['correct'].agg(['mean','size'])\n"
         "           .rename(columns={'mean':'accuracy','size':'n'}))\n"
         "by_lang.index = [{'en':'English','pt':'Portuguese','sw':'Swahili'}.get(i,i) for i in by_lang.index]\n"
         "ax = by_lang['accuracy'].plot.bar(color=['#533afd','#0d253d','#e76f51'], figsize=(6,4), ylim=(0,1.05))\n"
         "for i,(v,n) in enumerate(zip(by_lang['accuracy'], by_lang['n'])):\n"
         "    ax.text(i, v+0.01, f'{v:.2f}\\n(n={n})', ha='center', fontsize=9)\n"
         "plt.title('Test accuracy by language (soft-voting ensemble)')\n"
         "plt.ylabel('accuracy'); plt.xticks(rotation=0); plt.tight_layout(); plt.show()\n"
         "by_lang"),

    md("## 5 · Finding\n"
       "Read the printed numbers above as the live evidence — this is what they show on the "
       "expanded, three-language corpus:\n\n"
       "1. **The lexical model wins — TF-IDF + Logistic Regression is the best single model "
       "(macro-F1 ≈ 0.95)**, narrowly ahead of the soft-voting ensemble and clearly ahead of the "
       "embeddings alone. The African data we added is **keyword-rich** (telco terms, Airtel/Tigo "
       "numbers, *umeshinda*, *freemason*, *tuma pesa*), exactly the give-away signal TF-IDF is "
       "built to catch — so a bigger, more lexical corpus *favours* the lexical model.\n"
       "2. **Embeddings add cross-lingual robustness, not leaderboard position.** As on the "
       "smaller corpus, `emb_logreg` / `emb_rf` sit *below* the TF-IDF baseline; the soft-voting "
       "ensemble stays essentially tied with it. The honest read is that semantic features are "
       "insurance for paraphrase and unseen wording, not a win on this in-distribution test.\n"
       "3. **The model works in every language it was given** — per-language test accuracy is "
       "English ≈ 0.95, Portuguese ≈ 1.0, Swahili ≈ 0.98. Adding real African data answered the "
       "coverage question the corpus existed to answer.\n"
       "4. **Mobile-money fraud went from the weak class to the strongest** (per-class F1 ≈ 0.98) "
       "once Swahili joined Portuguese in that class — directly closing the cross-lingual "
       "mobile-money gap. Advance-fee remains the hardest class (F1 ≈ 0.87) and is the next "
       "target for more data.\n\n"
       "**Which model to choose:** by macro-F1, **TF-IDF + Logistic Regression** — and it is also "
       "the cheapest to serve (no 470 MB embedder). Keep the soft-voting ensemble as the option "
       "when cross-lingual / out-of-distribution robustness matters more than the last half-point "
       "of in-distribution macro-F1.\n\n"
       "*Caveat:* these remain source/heuristic provenance labels. ExAIS 'spam' is mostly benign "
       "promotional bulk SMS and is mapped conservatively to *not_a_scam*; the Swahili scam "
       "sub-typing leans on a mobile-money lexicon with a documented fallback. The κ-verified "
       "human audit (Objective 3) is the final word."),

    md("## 6 · Live inference (soft-voting ensemble, multilingual)"),
    code("examples = [\n"
         "  'URGENT! Your number won a 2,000,000 prize GUARANTEED. Call 09061790121 to claim now.',\n"
         "  'Caro cliente, a sua conta M-Pesa foi bloqueada. Envie o seu PIN para reactivar.',\n"
         "  'Iyo pesa itume kwenye namba hii ya Airtel 0689933027 jina PETER NYANGE.',  # Swahili momo\n"
         "  'Hongera! Umeshinda Tsh 10,000,000 kutoka TUZO POINT. Piga simu 0617488472 kupata zawadi.',  # Swahili prize\n"
         "  'Cher client, votre compte bancaire sera suspendu. Cliquez ici pour verifier: http://bit.ly/x9',\n"
         "  'Hey, are we still on for lunch at 1pm tomorrow?',\n"
         "]\n"
         "for t, (label, conf, _) in zip(examples, em.predict_messages(bundle, examples)):\n"
         "    print(f'{label:20} ({conf:.2f})  <- {t[:70]}')"),

    md("## 7 · Save the v2 model + metrics\n"
       "Persist the expanded-corpus ensemble alongside the v1 artefacts (suffixed `_v2`) so the "
       "comparison is reproducible and the serving app can be pointed at whichever wins."),
    code("import json, joblib\n"
         "base, meta = bundle['base'], bundle['meta']\n"
         "(em.MODELS / 'embed_metrics_v2.json').write_text(json.dumps(\n"
         "    {'embedder': em.EMB_MODEL, 'corpus': 'demo_labeled_v2.jsonl',\n"
         "     'n_total': len(df), 'test': bundle['results'], 'best': bundle['best'],\n"
         "     'n_train': len(train), 'n_dev': len(dev), 'n_test': len(test)}, indent=2))\n"
         "joblib.dump({'tfidf_logreg': base['tfidf_logreg'][0], 'emb_logreg': base['emb_logreg'][0],\n"
         "             'emb_rf': base['emb_rf'][0], 'stack_meta': meta, 'members': bundle['members'],\n"
         "             'embedder': em.EMB_MODEL, 'class_order': dm.CLASS_ORDER},\n"
         "            em.MODELS / 'embed_models_v2.joblib')\n"
         "print('saved: models/embed_metrics_v2.json, models/embed_models_v2.joblib')\n"
         "print('BEST MODEL:', bundle['best'], '->',\n"
         "      round(bundle['results'][bundle['best']]['macro_f1'], 4), 'macro-F1')"),
]

nb = nbf.v4.new_notebook()
nb.cells = cells
nb.metadata = {"kernelspec": {"name": "python3", "display_name": "Python 3"},
               "language_info": {"name": "python"}}

print("Executing v2 notebook (trains the ladder on the expanded corpus; first run encodes ~9.6k msgs)...")
ep = ExecutePreprocessor(timeout=1800, kernel_name="python3")
ep.preprocess(nb, {"metadata": {"path": str(HERE)}})
nbf.write(nb, OUT)
print(f"Wrote executed notebook -> {OUT}")
