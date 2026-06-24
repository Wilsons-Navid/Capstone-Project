"""Merge the relabeled African datasets into the corpus -> demo_labeled_v2.jsonl.

Keeps the original demo_labeled.jsonl untouched (so v1 results stay reproducible)
and writes a v2 superset that the v2 notebook trains on. Dedup is by lowercased
text across ALL sources, so an African record that happens to duplicate an
existing one is dropped (original kept).
"""

from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LAB = ROOT / "data" / "labelled"
BASE = LAB / "demo_labeled.jsonl"
EXTRA = LAB / "african_relabeled.jsonl"
OUT = LAB / "demo_labeled_v2.jsonl"


def read(path: Path) -> list[dict]:
    return [json.loads(l) for l in path.read_text(encoding="utf-8").splitlines() if l.strip()]


def main() -> None:
    base = read(BASE)
    extra = read(EXTRA)

    seen: set[str] = {r["text"].strip().lower() for r in base}
    merged = list(base)
    added = 0
    for r in extra:
        key = r["text"].strip().lower()
        if key in seen:
            continue
        seen.add(key)
        merged.append(r)
        added += 1

    with OUT.open("w", encoding="utf-8") as fh:
        for r in merged:
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")

    print(f"base {len(base)} + extra {len(extra)} (dedup {len(extra)-added} dropped) "
          f"-> {len(merged)} rows")
    print("category:", dict(Counter(r["category"] for r in merged)))
    print("source:  ", dict(Counter(r["source"] for r in merged)))
    print("language:", dict(Counter(r["language"] for r in merged)))
    print(f"written -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
