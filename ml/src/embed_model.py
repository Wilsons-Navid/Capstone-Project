"""Objective 3 — semantic upgrade + ensemble, built ON the TF-IDF demo.

Adds multilingual sentence embeddings (intfloat/multilingual-e5-small — en/fr/pt + Swahili)
feeding LogisticRegression / RandomForest, plus a soft-voting and a stacking ensemble over
the TF-IDF and embedding base models. Reuses demo_model's corpus, 70/15/15 split, CLASS_ORDER
and SEED so every number is directly comparable to the approved baseline.

Run:  python src/embed_model.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import joblib
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, f1_score

# Import the approved baseline pipeline so the comparison shares everything.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from demo_model import (CLASS_ORDER, MODELS, SEED, build_pipelines, load_df,  # noqa: E402
                        split)

EMB_MODEL = "intfloat/multilingual-e5-small"  # small/fast multilingual (en/fr/pt + Swahili).
EMB_PREFIX = "query: "                          # e5 models expect this prefix on each text.
# NOTE: LaBSE (sentence-transformers/LaBSE) gives wider African-language coverage but is ~1.9GB
# and heavier on CPU — swap EMB_MODEL back to it (drop EMB_PREFIX) once real African-language data exists.
EMB_CACHE = MODELS / "emb_e5small.npz"


# ----------------------------------------------------------------------------- embeddings
def embed_corpus(df) -> dict[str, np.ndarray]:
    """Return {id: vector}. Cached to disk so reruns are instant."""
    ids = df["id"].tolist()
    if EMB_CACHE.exists():
        d = np.load(EMB_CACHE, allow_pickle=True)
        cache = {str(i): v for i, v in zip(d["ids"], d["emb"])}
        if all(i in cache for i in ids):
            print(f"[embed] loaded {len(cache)} cached {EMB_MODEL} vectors")
            return cache

    from sentence_transformers import SentenceTransformer
    print(f"[embed] encoding {len(ids)} messages with {EMB_MODEL} (first run downloads ~470MB)...")
    model = SentenceTransformer(EMB_MODEL)
    vecs = model.encode([EMB_PREFIX + t for t in df["text"].tolist()], batch_size=64,
                        show_progress_bar=True, normalize_embeddings=True)
    MODELS.mkdir(parents=True, exist_ok=True)
    np.savez(EMB_CACHE, ids=np.array(ids, dtype=object), emb=np.asarray(vecs, dtype=np.float32))
    return {i: v for i, v in zip(ids, vecs)}


def emb_matrix(df, id2vec) -> np.ndarray:
    return np.vstack([id2vec[i] for i in df["id"].tolist()])


# ----------------------------------------------------------------------------- helpers
def proba_aligned(model, X) -> np.ndarray:
    """predict_proba with columns reordered to CLASS_ORDER."""
    p = model.predict_proba(X)
    classes = list(model.classes_)
    return p[:, [classes.index(c) for c in CLASS_ORDER]]


def metrics(y_true, y_pred) -> dict:
    f = f1_score(y_true, y_pred, labels=CLASS_ORDER, average=None, zero_division=0)
    return {
        "accuracy": float(accuracy_score(y_true, y_pred)),
        "macro_f1": float(f1_score(y_true, y_pred, labels=CLASS_ORDER, average="macro",
                                   zero_division=0)),
        "per_class": {c: float(f[i]) for i, c in enumerate(CLASS_ORDER)},
    }


def main() -> None:
    df = load_df()
    train, dev, test = split(df)
    id2vec = embed_corpus(df)
    Xtr_e, Xdv_e, Xte_e = (emb_matrix(d, id2vec) for d in (train, dev, test))
    ytr, ydv, yte = train["category"], dev["category"], test["category"]

    # --- base models -------------------------------------------------------
    base = {}                                # name -> (fitted_model, feature_kind)
    pipes = build_pipelines()                # tfidf_logreg, tfidf_rf  (the demo baseline)
    for name, pipe in pipes.items():
        pipe.fit(train["text"], ytr)
        base[name] = (pipe, "text")

    emb_lr = LogisticRegression(max_iter=4000, class_weight="balanced", C=8.0)
    emb_lr.fit(Xtr_e, ytr)
    base["emb_logreg"] = (emb_lr, "emb")

    emb_rf = RandomForestClassifier(n_estimators=500, class_weight="balanced",
                                    n_jobs=-1, random_state=SEED)
    emb_rf.fit(Xtr_e, ytr)
    base["emb_rf"] = (emb_rf, "emb")

    def X_for(kind, txt_df, emb):
        return txt_df["text"] if kind == "text" else emb

    # --- ensembles over {tfidf_logreg, labse_logreg, labse_rf} -------------
    members = ["tfidf_logreg", "emb_logreg", "emb_rf"]

    def stack_proba(split_df, emb):
        return [proba_aligned(base[m][0], X_for(base[m][1], split_df, emb)) for m in members]

    # soft voting = mean of member probabilities
    sv_test = np.mean(stack_proba(test, Xte_e), axis=0)
    softvote_pred = [CLASS_ORDER[i] for i in sv_test.argmax(1)]

    # stacking = meta-LogReg trained on DEV member-probabilities (no leakage: bases fit on train)
    meta = LogisticRegression(max_iter=4000, class_weight="balanced")
    meta.fit(np.hstack(stack_proba(dev, Xdv_e)), ydv)
    stack_pred = meta.predict(np.hstack(stack_proba(test, Xte_e)))

    # --- collect results ---------------------------------------------------
    results = {}
    for name, (model, kind) in base.items():
        results[name] = metrics(yte, model.predict(X_for(kind, test, Xte_e)))
    results["ensemble_softvote"] = metrics(yte, softvote_pred)
    results["ensemble_stack"] = metrics(yte, list(stack_pred))

    # --- report ------------------------------------------------------------
    order = ["tfidf_logreg", "tfidf_rf", "emb_logreg", "emb_rf",
             "ensemble_softvote", "ensemble_stack"]
    print(f"\nsplit: train {len(train)} / dev {len(dev)} / test {len(test)}   classes={CLASS_ORDER}\n")
    head = f"{'model':<20} {'acc':>6} {'macroF1':>8}   " + "  ".join(f"{c[:10]:>10}" for c in CLASS_ORDER)
    print(head); print("-" * len(head))
    for name in order:
        r = results[name]
        pc = "  ".join(f"{r['per_class'][c]:>10.3f}" for c in CLASS_ORDER)
        tag = "  <- baseline" if name == "tfidf_logreg" else ""
        print(f"{name:<20} {r['accuracy']:>6.3f} {r['macro_f1']:>8.3f}   {pc}{tag}")

    best = max(results, key=lambda n: results[n]["macro_f1"])
    print(f"\nbest by macro-F1: {best} ({results[best]['macro_f1']:.3f})")

    MODELS.mkdir(parents=True, exist_ok=True)
    (MODELS / "embed_metrics.json").write_text(json.dumps(
        {"embedder": EMB_MODEL, "test": results, "best": best,
         "n_train": len(train), "n_dev": len(dev), "n_test": len(test)}, indent=2))
    joblib.dump({"emb_logreg": emb_lr, "emb_rf": emb_rf, "stack_meta": meta,
                 "members": members, "embedder": EMB_MODEL},
                MODELS / "embed_models.joblib")
    print(f"\nsaved: models/embed_metrics.json, models/embed_models.joblib, {EMB_CACHE.name}")


if __name__ == "__main__":
    main()
