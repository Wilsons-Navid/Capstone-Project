"""Draw the ml/ pipeline diagram: corpus -> notebooks -> models -> serve -> app.

Recreates docs/assets/ml/ml_pipeline.png in code so it can be regenerated. Shows
all five models. The two honeynet models are marked as the ones the app runs today:
the four-class v3 backs the manual scan, and the binary model backs the SMS feature.

Run:  python scripts/make_ml_pipeline_diagram.py
"""

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

OUT = Path(__file__).resolve().parent.parent / "docs" / "assets" / "ml" / "ml_pipeline.png"

# Earth palette, consistent with the app and the other README diagrams
GOLD   = "#C8851A"
CREAM  = "#EFE7D6"
GREEN  = "#2E7D34"
BROWN  = "#2B1D14"
BROWN2 = "#4A3627"
MUTED  = "#7A6E62"
WHITE  = "#FFFFFF"
DARKTX = "#2B1D14"

plt.rcParams["font.family"] = "DejaVu Sans"

fig, ax = plt.subplots(figsize=(18, 10.5))
ax.set_xlim(0, 18)
ax.set_ylim(0, 12)
ax.axis("off")


def box(cx, cy, w, h, fc, text, tc, sub=None, sc=None, fs=15, sub_fs=11):
    ax.add_patch(FancyBboxPatch(
        (cx - w / 2, cy - h / 2), w, h,
        boxstyle="round,pad=0.02,rounding_size=0.14",
        facecolor=fc, edgecolor="none"))
    if sub:
        ax.text(cx, cy + 0.20, text, ha="center", va="center", color=tc,
                fontsize=fs, fontweight="bold")
        ax.text(cx, cy - 0.30, sub, ha="center", va="center", color=sc,
                fontsize=sub_fs, fontweight="bold")
    else:
        ax.text(cx, cy, text, ha="center", va="center", color=tc,
                fontsize=fs, fontweight="bold")


def harrow(x0, x1, y, color=BROWN, lw=2.4):
    ax.annotate("", xy=(x1, y), xytext=(x0, y),
                arrowprops=dict(arrowstyle="-|>", color=color, lw=lw,
                                shrinkA=0, shrinkB=0, mutation_scale=18))


def curve(x0, y0, x1, y1, color=BROWN):
    ax.add_patch(FancyArrowPatch(
        (x0, y0), (x1, y1), arrowstyle="-|>", color=color, lw=2.2,
        mutation_scale=16, connectionstyle=f"arc3,rad={(y0 - y1) * 0.06:.3f}"))


# --- column geometry -------------------------------------------------------
NB, ART, SRV, API, CLI = 5.0, 8.6, 11.9, 14.4, 16.6
NB_W, ART_W, SRV_W, API_W, CLI_W = 2.5, 3.2, 2.6, 1.5, 2.2
H = 1.3
rows = [9.6, 7.8, 6.0, 4.2, 2.4]

# --- title + column headers ------------------------------------------------
ax.text(9.0, 11.5, "How the pieces fit together: from corpus to the deployed app",
        ha="center", va="center", fontsize=23, fontweight="bold", color=DARKTX)
for x, label in [(NB, "notebooks/"), (ART, "model artifact"), (SRV, "serve apps"),
                 (API, "API"), (CLI, "client")]:
    ax.text(x, 10.7, label, ha="center", va="center", fontsize=13,
            style="italic", color=MUTED)

# --- data + pipeline box (spans the rows) ----------------------------------
dx, dtop, dbot = 1.9, 9.9, 2.1
ax.add_patch(FancyBboxPatch((dx - 1.55, dbot), 3.1, dtop - dbot,
             boxstyle="round,pad=0.02,rounding_size=0.14", facecolor=BROWN, edgecolor="none"))
ax.text(dx, 9.35, "Data and pipeline", ha="center", va="center",
        color=GOLD, fontsize=15, fontweight="bold")
box(dx, 8.35, 2.5, 0.95, BROWN2, "data/", WHITE, "the labelled corpus", "#D9CDBE", fs=14, sub_fs=10)
box(dx, 7.10, 2.5, 0.95, BROWN2, "scripts/ 01..15", WHITE, "build the corpus (+ CMU)", "#D9CDBE", fs=13.5, sub_fs=10)
ax.text(dx, 5.75, "download · normalise · label", ha="center", va="center", color="#B7A996", fontsize=10)
ax.text(dx, 5.35, "audit + kappa · split · relabel", ha="center", va="center", color="#B7A996", fontsize=10)
ax.text(dx, 4.95, "export · ingest CMU honeynet", ha="center", va="center", color="#B7A996", fontsize=10)
ax.text(dx, 4.20, "CMU capture: kept local", ha="center", va="center", color=GOLD, fontsize=10, fontweight="bold")

# arrows from the data box to each notebook
for y in rows:
    curve(dx + 1.55, 6.0, NB - NB_W / 2 - 0.05, y)

# --- the five rows ---------------------------------------------------------
# notebook, artifact, artifact-subtitle, sub-colour, serve, client, client-role
R = [
    ("initial_demo",   "scam_classifier.joblib",  None,                     None,   "initial_serve/",   None,         None),
    ("embed_demo",     "embed_models.joblib",     None,                     None,   "embed_serve/",     None,         None),
    ("final_model",    "scam_tfidf_v2.joblib",    "previous (superseded)",  MUTED,  "final_serve/",     None,         None),
    ("cmu_corpus_v3",  "scam_tfidf_v3.joblib",    "the scan model (live)",  GREEN,  "cmu_v3_serve/",    "mobile app", "manual scan"),
    ("cmu_binary",     "cmu_scam_binary.joblib",  "the SMS model (live)",   GREEN,  "cmu_inbox_serve/", "mobile app", "SMS inbox"),
]

for (nb, art, sub, sc, srv, cli, role), y in zip(R, rows):
    box(NB, y, NB_W, H, GOLD, nb, WHITE, fs=14.5)
    box(ART, y, ART_W, H, CREAM, art, DARKTX, sub, sc, fs=13.5, sub_fs=10.5)
    box(SRV, y, SRV_W, H, GREEN, srv, WHITE, fs=14)
    box(API, y, API_W, H, BROWN, "/predict", WHITE, fs=13)
    harrow(NB + NB_W / 2, ART - ART_W / 2, y)
    harrow(ART + ART_W / 2, SRV - SRV_W / 2, y)
    harrow(SRV + SRV_W / 2, API - API_W / 2, y)
    if cli:
        box(CLI, y, CLI_W, H, GOLD, cli, WHITE, role, "#F0E4C8", fs=14, sub_fs=10.5)
        harrow(API + API_W / 2, CLI - CLI_W / 2, y, color=GREEN, lw=2.8)

# --- caption ---------------------------------------------------------------
ax.text(9.0, 0.9,
        "Each notebook trains and saves its own model into its own folder, and the matching serve app loads exactly that model.",
        ha="center", va="center", fontsize=13, style="italic", color=MUTED)

OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=130, bbox_inches="tight", facecolor="white", pad_inches=0.3)
print("wrote", OUT, f"({OUT.stat().st_size/1e3:.0f} KB)")
