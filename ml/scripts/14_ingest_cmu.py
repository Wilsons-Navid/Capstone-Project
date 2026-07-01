"""Turn the CMU-Africa Upanzi honeynet dump into a clean binary corpus.

The honeynet exported its capture table straight out of MySQL, so the CSV we get
is raw: seven unlabelled columns, Windows-1252 encoding, messages with embedded
newlines, and a good amount of junk that never came from a real phone. This
script does the unglamorous work of turning that dump into something a model can
learn from, and writes the result to `ml/data/labelled/cmu_binary.jsonl`.

Column layout of the dump (there is no header row):

    0  id             row id from the honeynet database
    1  message        the captured text  <- what we train on
    2  label          1 = scam, 0 = legitimate / receipt  <- the target
    3  timestamp      when it was captured (2023-2026)
    4  cat_a          small-int category id (scam-type taxonomy)
    5  cat_b          small-int category id
    6  message_clean  a PII-scrubbed copy the honeynet produced (we ignore it)

What "cleaning" means here, and why:

  * The honeynet portal is a public endpoint, so bots hammer it with SQL
    injection, XSS and template-injection probes. Those land in the table as
    "messages" but they are attacks on the server, not smishing, so we drop them.
  * A handful of rows are the operators testing the portal ("CORS error",
    "mobile submission failed"). Not phone messages either -> dropped.
  * PII was replaced with placeholder tokens (A1, A2, XY, ZWXY...). Left alone,
    a model would happily decide that the token "A1" predicts fraud. We collapse
    every placeholder to a single neutral <ent> marker so it carries no signal.
  * Receipts repeat verbatim thousands of times. We keep one copy of each
    (message, label) pair so the split can't leak a training row into the test set.

Run from the `ml/` directory:

    python scripts/14_ingest_cmu.py

Nothing here is notebook-specific; both the binary notebook and the corpus-v3
builder import `load_clean_cmu()` so the cleaning rules live in exactly one place.
"""

from __future__ import annotations

import csv
import json
import re
from pathlib import Path

ML_ROOT = Path(__file__).resolve().parent.parent            # ml/
RAW = ML_ROOT / "data" / "raw" / "cmu_honeynet" / "momo-data.csv"
OUT = ML_ROOT / "data" / "labelled" / "cmu_binary.jsonl"

MYSQL_NULL = "\\N"

# --- junk detectors --------------------------------------------------------
# Bot probes against the honeynet web portal (not phone messages). Besides the
# usual SQL/JS payloads this covers the XSS scanner traffic that hits any public
# endpoint: the bxss.me beacon domain, edge-side-include probes, and the throwaway
# .zzz test domains that carry no message at all.
_INJECTION = re.compile(
    r"(SELECT\s|UNION\s|response\.write|\$\{|<script|OR\s+\d+=\(|sleep\(|"
    r"WAITFOR|BENCHMARK\(|pg_sleep|information_schema|0x[0-9a-f]{4}|"
    r"bxss\.me|<esi|esi:include|xss\.html|\.zzz[/?])",
    re.I,
)
# Operators poking the portal.
_SYSTEM = re.compile(
    r"CORS|mobile submission|portal isn't|502 error|testing local|"
    r"server experiencing some challenge",
    re.I,
)
# Short random tokens like "nOIKaN7z" that scanners submit as usernames.
_GIBBERISH = re.compile(r"^[A-Za-z0-9+/=]{6,12}$")

# Placeholder tokens the honeynet used to redact names, phone numbers, amounts.
_PLACEHOLDER = re.compile(r"\b(?:A\d{1,2}|XY|ZWXY|B\d?)\b")


def _is_junk(text: str) -> bool:
    t = text.strip()
    if not t:
        return True
    if _INJECTION.search(t):
        return True
    if _SYSTEM.search(t):
        return True
    if _GIBBERISH.match(t):
        return True
    return False


def _neutralise(text: str) -> str:
    """Collapse redaction placeholders + long numbers to neutral markers, tidy space."""
    text = _PLACEHOLDER.sub("<ent>", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def load_clean_cmu() -> list[dict]:
    """Return a list of {text, label, timestamp} dicts, cleaned and de-duplicated.

    `label` is 1 for scam, 0 for legitimate. This is the single entry point both
    notebooks call.
    """
    rows: list[list[str]] = []
    with open(RAW, "r", encoding="cp1252", newline="") as fh:
        for r in csv.reader(fh):
            if len(r) == 7:                     # skip lines the dump mangled
                rows.append(r)

    seen: set[tuple[str, str]] = set()
    out: list[dict] = []
    for _id, message, label, ts, _a, _b, _clean in rows:
        if label not in ("0", "1"):
            continue
        if message in ("", MYSQL_NULL) or _is_junk(message):
            continue
        text = _neutralise(message)
        if len(text) < 3:                       # nothing left after tidying
            continue
        key = (text.lower(), label)
        if key in seen:                         # drop exact duplicates
            continue
        seen.add(key)
        out.append({
            "text": text,
            "label": int(label),
            "timestamp": ts if ts != MYSQL_NULL else None,
        })
    return out


def main() -> None:
    records = load_clean_cmu()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        for rec in records:
            fh.write(json.dumps(rec, ensure_ascii=False) + "\n")

    n = len(records)
    scam = sum(r["label"] for r in records)
    print(f"wrote {n} unique clean messages -> {OUT.relative_to(ML_ROOT)}")
    print(f"  scam (1):       {scam}")
    print(f"  legitimate (0): {n - scam}")


if __name__ == "__main__":
    main()
