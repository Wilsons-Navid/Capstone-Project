"""Renders the RethicsAI mobile + ML + intersection architecture as a styled PNG."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
import os

BROWN = "#2D1B14"
AMBER = "#CC8800"
GREEN = "#2E7D32"
SAND = "#F3EDE6"
INK = "#22201E"

fig, ax = plt.subplots(figsize=(12, 5.2))
ax.set_xlim(0, 12); ax.set_ylim(0, 5.2); ax.axis("off")
fig.patch.set_facecolor("white")

boxes = [
    dict(x=0.6, color=BROWN, title="MOBILE APP", lines=["Scanner UI", "Verdict card"], tag="Part 1  ·  Flutter client"),
    dict(x=4.7, color=AMBER, title="ScamModelService", lines=["warm-up ping", "+ POST call"], tag="Intersection  ·  the scanner"),
    dict(x=8.8, color=GREEN, title="ML ENSEMBLE API", lines=["TF-IDF + e5", "macro-F1 0.955"], tag="Part 2  ·  hosted model"),
]
BW, BH, BY = 2.6, 1.7, 2.5

for b in boxes:
    ax.add_patch(FancyBboxPatch((b["x"], BY), BW, BH,
                                boxstyle="round,pad=0.02,rounding_size=0.18",
                                linewidth=0, facecolor=b["color"]))
    cx = b["x"] + BW / 2
    ax.text(cx, BY + BH - 0.42, b["title"], ha="center", va="center",
            color="white", fontsize=13, fontweight="bold")
    for i, ln in enumerate(b["lines"]):
        ax.text(cx, BY + BH - 0.92 - i * 0.42, ln, ha="center", va="center",
                color="white", fontsize=10.5, alpha=0.95)
    # tag pill under box
    ax.text(cx, BY - 0.55, b["tag"], ha="center", va="center",
            color=INK, fontsize=10, fontweight="bold")


def arrow(x1, x2, y, label, color, up=True):
    ax.add_patch(FancyArrowPatch((x1, y), (x2, y),
                                 arrowstyle="-|>", mutation_scale=20,
                                 linewidth=2.2, color=color))
    ax.text((x1 + x2) / 2, y + (0.52 if up else -0.62), label, ha="center",
            va="center", fontsize=10, color=color, fontweight="bold")


# Forward flow (top), return flow (bottom)
b1r, b2l, b2r, b3l = 0.6 + BW, 4.7, 4.7 + BW, 8.8
arrow(b1r + 0.05, b2l - 0.05, BY + BH - 0.35, "paste message", BROWN, up=True)
arrow(b2r + 0.05, b3l - 0.05, BY + BH - 0.35, "POST /predict", GREEN, up=True)
arrow(b3l - 0.05, b2r + 0.05, BY + 0.35, "prediction", GREEN, up=False)
arrow(b2l - 0.05, b1r + 0.05, BY + 0.35, "category + confidence", BROWN, up=False)

ax.text(6, 4.85, "RethicsAI — two parts and their intersection",
        ha="center", va="center", fontsize=15, fontweight="bold", color=BROWN)
ax.text(6, 0.55,
        "A pasted message flows from the app to the hosted ensemble and the category + confidence return to the verdict card.",
        ha="center", va="center", fontsize=9.5, color="#5A554F", style="italic")

out = os.path.join(os.path.dirname(__file__), "assets", "architecture.png")
plt.savefig(out, dpi=160, bbox_inches="tight", facecolor="white")
print("Saved:", out)
