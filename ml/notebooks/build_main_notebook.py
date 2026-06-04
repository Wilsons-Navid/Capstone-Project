"""Generate and execute the MAIN project notebook.

Produces `ml/notebooks/scam_detection_main.ipynb` — the canonical model notebook
for the project: lexical (TF-IDF) + semantic (multilingual-e5-small) base models
combined into a soft-voting / stacking ensemble. Built from the same
`src/embed_model.train_and_eval()` used for training + serving, so the notebook,
the saved metrics and the served model all agree.

(`model_demo.ipynb` is the earlier preliminary/demo notebook — kept for the record.)

Run:  python ml/notebooks/build_main_notebook.py
"""

from __future__ import annotations

from pathlib import Path

import nbformat as nbf
from nbconvert.preprocessors import ExecutePreprocessor

HERE = Path(__file__).resolve().parent
OUT = HERE / "scam_detection_main.ipynb"

md = lambda s: nbf.v4.new_markdown_cell(s)
code = lambda s: nbf.v4.new_code_cell(s)

cells = [
    md("# Scam-Message Classifier — Main Model\n"
       "The project's classifier: it decides whether a short message is "
       "**advance-fee fraud**, **mobile-money fraud**, **phishing**, or **not-a-scam**.\n\n"
       "The model is built in two stages and compared head-to-head:\n\n"
       "1. **Lexical baseline** — TF-IDF features → Logistic Regression / Random Forest "
       "(*keyword* signal).\n"
       "2. **Semantic upgrade** — multilingual **e5-small** sentence embeddings → "
       "Logistic Regression / Random Forest (*meaning & context* signal, language-agnostic).\n"
       "3. **Ensemble** — soft-voting and stacking over the lexical + semantic models.\n\n"
       "*This is the main pipeline. An earlier `model_demo.ipynb` was a preliminary test; "
       "everything here supersedes it and is the artifact the dissertation reports.*"),

    md("## 1 · Data engineering"),
    code("import sys\n"
         "from pathlib import Path\n"
         "import pandas as pd, numpy as np\n"
         "import matplotlib.pyplot as plt, seaborn as sns\n"
         "sys.path.insert(0, str(Path.cwd().parent))\n"
         "from src import demo_model as dm        # shared corpus loader + TF-IDF baseline\n"
         "from src import embed_model as em        # embeddings + ensemble (this pipeline)\n"
         "sns.set_theme(style='whitegrid')\n"
         "df = dm.load_df()\n"
         "print(f'{len(df):,} labelled messages | classes = {dm.CLASS_ORDER}')\n"
         "df.head(4)"),

    code("# Corpus shape: class / source / language\n"
         "fig, ax = plt.subplots(1, 3, figsize=(15, 4))\n"
         "df['category'].value_counts().plot.bar(ax=ax[0], color='#533afd', title='Class distribution')\n"
         "df['source'].value_counts().plot.bar(ax=ax[1], color='#0d253d', title='Source')\n"
         "df['language'].value_counts().plot.bar(ax=ax[2], color='#e76f51', title='Language')\n"
         "for a in ax: a.tick_params(axis='x', rotation=30)\n"
         "plt.tight_layout(); plt.show()"),

    md("**Provenance — which source feeds which class.** The corpus is deliberately "
       "multi-source so no single class is tied to one writing style."),
    code("ct = pd.crosstab(df['category'], df['source'])\n"
         "plt.figure(figsize=(9,4.2))\n"
         "sns.heatmap(ct, annot=True, fmt='d', cmap='rocket_r', cbar_kws={'label':'messages'})\n"
         "plt.title('Class x source provenance'); plt.ylabel(''); plt.xlabel('')\n"
         "plt.xticks(rotation=20, ha='right'); plt.tight_layout(); plt.show()"),

    md("## 2 · Two feature representations\n"
       "**Lexical — TF-IDF.** Word 1–2 grams, `min_df=2`, sublinear TF, unicode accent "
       "stripping, vocab capped at 30,000. Strong when scams reuse give-away phrases "
       "(*\"verify your account\"*, *\"you have won\"*) but blind to paraphrase and unseen wording.\n\n"
       "**Semantic — multilingual-e5-small.** A sentence-transformer that maps each message "
       "(prefixed `\"query: \"`) to a 384-dim vector where *meaning* — not exact words — drives "
       "proximity. Covers English / Portuguese / French and other languages (incl. Swahili), so "
       "it generalises across the languages the corpus mixes. Embeddings are cached "
       "(`models/emb_e5small.npz`) so re-runs are fast.\n\n"
       "Each representation feeds a **Logistic Regression** (L2 cross-entropy, `class_weight='balanced'`) "
       "and a **Random Forest** (500 bagged CART trees). Random Forest is skipped on TF-IDF "
       "(weak on high-dim sparse input). Training protocol: 70/15/15 **stratified** split, seed 42, "
       "metrics on the held-out **test** split only."),

    md("## 3 · Train the full ladder\n"
       "`em.train_and_eval()` fits the four base models and both ensembles in one call "
       "(the same function the CLI report and the saved model use)."),
    code("bundle = em.train_and_eval(df)\n"
         "train, dev, test = bundle['splits']\n"
         "print(f'train {len(train)} / dev {len(dev)} / test {len(test)}')\n"
         "print('models:', list(bundle['base']) + ['ensemble_softvote', 'ensemble_stack'])\n"
         "print('ensemble members:', bundle['members'])"),

    md("**Ensembles.**\n"
       "- **Soft-voting** = element-wise mean of the member probability vectors, then arg-max.\n"
       "- **Stacking** = a meta Logistic Regression trained on the **dev-split** member "
       "probabilities (bases are fit on train only, so there is no leakage), applied to the "
       "test-split member probabilities."),

    md("## 4 · Results — held-out test set"),
    code("rows = [{'model': n,\n"
         "         'accuracy': round(bundle['results'][n]['accuracy'], 3),\n"
         "         'macro_F1': round(bundle['results'][n]['macro_f1'], 3)}\n"
         "        for n in bundle['order']]\n"
         "summary = pd.DataFrame(rows).set_index('model'); summary"),

    code("# Macro-F1 across the ladder, baseline marked\n"
         "base_f1 = summary.loc['tfidf_logreg', 'macro_F1']\n"
         "colors = ['#9aa7b8','#c2ccd9','#7c6cf0','#a99bf6','#533afd','#0d253d']\n"
         "ax = summary['macro_F1'].plot.bar(color=colors, figsize=(9,4.2), ylim=(0.85,0.99))\n"
         "ax.axhline(base_f1, ls='--', color='#e63946', lw=1.2, label=f'baseline {base_f1:.3f}')\n"
         "for i, v in enumerate(summary['macro_F1']):\n"
         "    ax.text(i, v+0.002, f'{v:.3f}', ha='center', fontsize=9)\n"
         "plt.title('Macro-F1 by model (test split)'); plt.xticks(rotation=20, ha='right')\n"
         "plt.legend(); plt.tight_layout(); plt.show()"),

    md("**Per-class F1** — where each representation wins. Embeddings lift mobile-money and "
       "not-a-scam; TF-IDF holds advance-fee; the soft-vote ensemble takes the best of both."),
    code("sub = ['tfidf_logreg','emb_logreg','emb_rf','ensemble_softvote']\n"
         "rowsf = [{'class': c, 'model': n, 'F1': bundle['results'][n]['per_class'][c]}\n"
         "         for n in sub for c in dm.CLASS_ORDER]\n"
         "fdf = pd.DataFrame(rowsf)\n"
         "plt.figure(figsize=(10,4.4))\n"
         "sns.barplot(data=fdf, x='class', y='F1', hue='model',\n"
         "            palette=['#9aa7b8','#7c6cf0','#a99bf6','#533afd'])\n"
         "plt.ylim(0.6,1.02); plt.title('Per-class F1: lexical vs semantic vs ensemble')\n"
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

    md("## 5 · Finding\n"
       "1. **Semantic embeddings alone do not beat the lexical baseline on this corpus.** "
       "`emb_logreg` / `emb_rf` land *below* `tfidf_logreg` — scam messages here reuse strong "
       "give-away keywords that TF-IDF already catches, and embeddings actually hurt the "
       "smallest class (advance-fee).\n"
       "2. **But the representations are complementary** — embeddings are stronger exactly "
       "where wording varies (mobile-money, benign).\n"
       "3. **The soft-voting ensemble is the best model**, beating the baseline and lifting "
       "every class. It is what we ship.\n"
       "4. **Stacking under-performs soft-voting** — the meta-learner over-fits the small dev "
       "split; plain averaging generalises better.\n\n"
       "*Caveat:* these are still source-provenance labels; the human inter-rater-verified "
       "corpus is the final evaluation. The honest, ensemble-based result is a stronger claim "
       "than any single headline number."),

    md("## 6 · Live inference (soft-voting ensemble, multilingual)"),
    code("examples = [\n"
         "  'URGENT! Your number won a 2,000,000 prize GUARANTEED. Call 09061790121 to claim now.',\n"
         "  'Caro cliente, a sua conta M-Pesa foi bloqueada. Envie o seu PIN para reactivar.',\n"
         "  'Cher client, votre compte bancaire sera suspendu. Cliquez ici pour verifier: http://bit.ly/x9',\n"
         "  'Hey, are we still on for lunch at 1pm tomorrow?',\n"
         "]\n"
         "for t, (label, conf, _) in zip(examples, em.predict_messages(bundle, examples)):\n"
         "    print(f'{label:20} ({conf:.2f})  <- {t[:66]}')"),

    md("## 7 · Deployment & next steps\n"
       "The trained ensemble + embedder reference are saved to "
       "`ml/models/embed_models.joblib`, metrics to `ml/models/embed_metrics.json`, served "
       "via **FastAPI**:\n\n"
       "```bash\n"
       "python -m uvicorn ml.serve.app:app --reload --port 8000\n"
       "# open http://127.0.0.1:8000/docs  ->  POST /predict\n"
       "```\n\n"
       "Roadmap from here: on-device inference in the mobile app (SMS access), an admin "
       "dashboard that recycles user-reported scams back into the corpus, and growing the "
       "human-verified labels to firm up the numbers above."),
]

nb = nbf.v4.new_notebook()
nb.cells = cells
nb.metadata = {"kernelspec": {"name": "python3", "display_name": "Python 3"},
               "language_info": {"name": "python"}}

print("Executing main notebook (trains the ladder inline; embeddings cached)...")
ep = ExecutePreprocessor(timeout=900, kernel_name="python3")
ep.preprocess(nb, {"metadata": {"path": str(HERE)}})
nbf.write(nb, OUT)
print(f"Wrote executed notebook -> {OUT}")
