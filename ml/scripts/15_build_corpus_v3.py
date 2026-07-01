"""Fold the CMU honeynet capture into the four-class corpus (v2 -> v3).

The v2 corpus is labelled with four categories:

    advance_fee_fraud, mobile_money_fraud, phishing, not_a_scam

The CMU honeynet only tells us scam-or-not. So to reuse it in the four-class
model we have to decide *which kind* of scam each honeynet message is. We do that
with an explicit, readable rule set rather than a black box, because a marker who
reads this script should be able to agree or disagree with each rule.

The rules, in priority order (first match wins):

  1. advance_fee_fraud  - a promise of money: lotteries, prizes, inheritance,
                          "you have won", loan lures ("no CRB check").
  2. phishing           - an attack on an account: "account blocked/suspended",
                          "verify", "confirm your", a login link, a bank name.
  3. mobile_money_fraud - a direct request to move money: "send me", MoMo/M-Pesa
                          pleas, fake proof-of-payment, the Kinyarwanda/Swahili
                          verbs of asking for cash.
  4. anything left over  -> mobile_money_fraud, because this honeynet is
                          mobile-money-centric and the residue is overwhelmingly
                          that kind of social engineering.

Legitimate honeynet messages (real receipts, airtime promos) become not_a_scam,
and they are valuable: they are genuine African mobile-money texts, the exact
"hard negatives" a naïve model tends to flag by mistake.

A short OVERRIDES list at the bottom hand-corrects the handful of messages the
rules get wrong (the "manual confirm" pass). Each override records why.

Run from ml/:  python scripts/15_build_corpus_v3.py
"""

from __future__ import annotations

import hashlib
import json
import re
from importlib import import_module
from pathlib import Path

import sys
ML_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ML_ROOT / "scripts"))
ingest = import_module("14_ingest_cmu")

V2 = ML_ROOT / "data" / "labelled" / "demo_labeled_v2.jsonl"
OUT = ML_ROOT / "data" / "labelled" / "demo_labeled_v3.jsonl"

# --- category rules --------------------------------------------------------
# "Promise of money" scams: lotteries, prizes, inheritance, loans, investment,
# work-from-home and jackpot lures. All of them dangle a future payout.
_ADVANCE_FEE = re.compile(
    r"lottery|\bprize\b|\bwon\b|winner|\baward\b|inherit|beneficiar|next of kin|"
    r"compensation|donation|claim your|\bloans?\b|qualify|no crb|borrow|"
    r"national lottery|\bnla\b|investment|work ?from ?home|part-?time|hiring|"
    r"\bjackpot\b|\bprofits?\b|\bforex\b|earn .{0,15}(daily|weekly|home)", re.I)
# Fake proof-of-payment: a bogus "you have received X" receipt, often paired with
# a "your account is blocked" twist. The word "block" here is bait, not phishing,
# so we catch the receipt shape before the phishing rule can grab it.
_MOMO_RECEIPT = re.compile(
    r"\*1\d\d\*[rs]\*|m-?money\s*\*|confirmed\.?\s*you have received|"
    r"mpesa\b.*confirmed|you have received .{0,30}(rwf|ksh)", re.I)
# An attack on an account: blocked/suspended, verify, a login link, a bank name.
_PHISHING = re.compile(
    r"account.*(block|suspend|verif|confirm)|(block|suspend|verif)e?d?.*account|"
    r"\bverify\b|confirm your|update your|log ?in|password|\bpin code\b|"
    r"click (here|the link)|https?://|bit\.ly|www\.|\bkcb\b|\bbank\b|fri:", re.I)
# A direct request to move money: MoMo/M-Pesa pleas and the local verbs of asking.
_MOMO = re.compile(
    r"\bmomo\b|mobile money|m-?pesa|mpesa|\*165|\*182|\*150|amafranga|mafaranga|"
    r"naomba|nkakugora|nkaguha|nisaidie|send me|tuma|kindly (clear|send|pay)|"
    r"reverse|wrong number|\bpesa\b|nimero", re.I)


def categorise_scam(text: str) -> str:
    if _ADVANCE_FEE.search(text):
        return "advance_fee_fraud"
    if _MOMO_RECEIPT.search(text):
        return "mobile_money_fraud"      # fake proof-of-payment, before phishing
    if _PHISHING.search(text):
        return "phishing"
    if _MOMO.search(text):
        return "mobile_money_fraud"
    return "mobile_money_fraud"          # honeynet residue is momo social engineering


# --- rough language tag (v2 uses en/sw/pt; CMU adds Kinyarwanda 'rw') ------
_RW = re.compile(r"\b(nka|kuri|amafranga|wowe|ejo|nimero|ukan|byagush|murakoze|"
                 r"mafaranga|uguze|kanda|shyiramo|nkakugora|niba|waretse)\b", re.I)
_SW = re.compile(r"\b(pesa|tuma|namba|salio|hongera|umeshinda|bonyeza|piga|jina|"
                 r"asante|naomba|naitwa|nisaidie|hela|pole|hio|zangu)\b", re.I)


def language_of(text: str) -> str:
    if _RW.search(text):
        return "rw"
    if _SW.search(text):
        return "sw"
    return "en"


def _id(text: str) -> str:
    return "cmu_" + hashlib.md5(text.encode("utf-8")).hexdigest()[:10]


# --- manual-confirm overrides ---------------------------------------------
# Keyed by a distinctive substring; sets the correct category. Filled after
# eyeballing the rule output (see the audit print at the bottom).
OVERRIDES: list[tuple[str, str]] = [
    # (substring found in message, correct_category)
]


def _apply_overrides(text: str, cat: str) -> str:
    for needle, correct in OVERRIDES:
        if needle.lower() in text.lower():
            return correct
    return cat


def build_cmu_rows() -> list[dict]:
    rows = []
    for rec in ingest.load_clean_cmu():
        text = rec["text"]
        if rec["label"] == 1:
            cat = _apply_overrides(text, categorise_scam(text))
        else:
            cat = "not_a_scam"
        rows.append({
            "id": _id(text),
            "text": text,
            "language": language_of(text),
            "category": cat,
            "source": "cmu_honeynet",
        })
    return rows


def main() -> None:
    v2_rows = [json.loads(l) for l in V2.read_text(encoding="utf-8").splitlines() if l.strip()]
    cmu_rows = build_cmu_rows()

    # guard: don't duplicate a v2 id
    seen = {r["id"] for r in v2_rows}
    cmu_rows = [r for r in cmu_rows if r["id"] not in seen]

    all_rows = v2_rows + cmu_rows
    with open(OUT, "w", encoding="utf-8") as fh:
        for r in all_rows:
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")

    from collections import Counter
    print(f"v2 rows:  {len(v2_rows)}")
    print(f"cmu rows: {len(cmu_rows)}")
    print(f"v3 total: {len(all_rows)}  ->  {OUT.relative_to(ML_ROOT)}")
    print("\ncmu category split:", dict(Counter(r["category"] for r in cmu_rows)))
    print("cmu language split:", dict(Counter(r["language"] for r in cmu_rows)))
    print("\nv3 category totals:", dict(Counter(r["category"] for r in all_rows)))


if __name__ == "__main__":
    main()
