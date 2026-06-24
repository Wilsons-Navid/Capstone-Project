"""Relabel the two new African SMS datasets into the project's 4-class taxonomy.

Inputs (raw, binary-labelled):
  * ExAIS_SMS  — African-English (Nigeria), labels SPAM / HAM, headerless per-user CSVs.
  * BongoScam  — Tanzanian Swahili, labels scam / trust, columns Category,Sms.

Output: ml/data/labelled/african_relabeled.jsonl, one record per message matching
the demo_labeled schema {id, text, language, category, source}.

Mapping methodology (documented for the dissertation — auditable, conservative):

  legitimate  -> not_a_scam
     ExAIS HAM, BongoScam trust.

  ExAIS SPAM  -> heuristic suggester (src.auto_label.suggest, English/French lexicon).
     Only assigns a *scam* category when an actual fraud pattern fires
     (prize/fee, bank-impersonation, click-to-verify, PIN request, ...). ExAIS
     "spam" is mostly benign telco promotional bulk SMS; per the taxonomy
     (NOT_A_SCAM := "legitimate communication, benign spam, ...") those correctly
     fall through to not_a_scam. This is deliberately conservative: we do not
     invent a fraud sub-type the text does not support.

  BongoScam scam -> Swahili/African lexicon below, because the English suggester
     does not fire on Swahili. Ordered rules:
       1. advance-fee markers (prize / Freemason-occult-wealth / fake job) -> advance_fee_fraud
       2. mobile-money markers (send money to this Airtel/Tigo/Vodacom/M-Pesa number) -> mobile_money_fraud
       3. phishing markers (verify/click/account) -> phishing
       4. fallback -> mobile_money_fraud  (the dominant Tanzanian SMS-fraud type;
          every record here is an author-verified scam, so the residual is a
          confirmed scam awaiting a finer sub-type, not a benign message).

These remain source/heuristic provenance labels — the same standing as the rest
of demo_labeled.jsonl — and feed the same human kappa-audit (Objective 3) before
any final claim.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from src.auto_label import suggest                      # noqa: E402
from src.schema import stable_id                        # noqa: E402
from src.taxonomy import ScamCategory                   # noqa: E402

RAW = ROOT / "data" / "raw"
OUT = ROOT / "data" / "labelled" / "african_relabeled.jsonl"

# Confidence floor below which an ExAIS "spam" suggestion is treated as benign
# (promotional spam) and mapped to not_a_scam rather than a guessed scam type.
EXAIS_SCAM_CONF = 0.55

# The model has 4 in-scope classes. The suggester can return the wider 6-class
# taxonomy, so out-of-scope hits are folded to their nearest in-scope class
# (identity-theft is credential/ID harvesting -> phishing; romance and
# synthetic-media both end in a money request -> advance-fee) rather than
# discarded, preserving the fraud signal.
IN_SCOPE_REMAP = {
    ScamCategory.IDENTITY_THEFT: ScamCategory.PHISHING,
    ScamCategory.ROMANCE_SCAM: ScamCategory.ADVANCE_FEE_FRAUD,
    ScamCategory.SYNTHETIC_MEDIA_FRAUD: ScamCategory.PHISHING,
}

# --- Swahili / African mobile-money sub-typing lexicon -----------------------
SW_ADVANCE_FEE = (
    "umeshinda", "imeshinda", "umepata", "zawadi", "tuzo", "hongera", "bahati",
    "umechaguliwa", "freemason", "friimason", "free'mason", "free mason", "666",
    "utajiri", "miliki mali", "mtaji", "mkopo", "ndoto", "congratulations",
    "your cv", "cv has passed", "salary", "bonus", "promotion", "kafala",
    "tajiri", "matajiri", "utimize", "biashara vipaji",
)
SW_MOBILE_MONEY = (
    "pesa", "hela", " ela", "iyo ela", "tuma", "itume", "nitumie", "utanitumia",
    "namba hii", "kwenye namba", "kwemye namba", "m-pesa", "mpesa", "tigo pesa",
    "tigopesa", "airtel money", "halopesa", "tigo", "vodacom", "voda ", "airtel",
    "wakala", "salio", "muamala", "nitakurefund", "refund", "unitumie", "unixaidie",
)
SW_PHISHING = (
    "bonyeza", "thibitisha", "akaunti yako", "password", "link", "namba ya siri",
)


def _hit(text_lc: str, bag: tuple[str, ...]) -> bool:
    return any(k in text_lc for k in bag)


def swahili_category(text: str) -> ScamCategory:
    """Sub-type an author-verified Swahili scam message."""
    t = text.lower()
    if _hit(t, SW_ADVANCE_FEE):
        return ScamCategory.ADVANCE_FEE_FRAUD
    if _hit(t, SW_MOBILE_MONEY):
        return ScamCategory.MOBILE_MONEY_FRAUD
    if _hit(t, SW_PHISHING):
        return ScamCategory.PHISHING
    return ScamCategory.MOBILE_MONEY_FRAUD  # documented fallback


# --- parsers -----------------------------------------------------------------
def parse_exais() -> list[dict]:
    """Headerless per-user CSVs. Each row: ..,LABEL,TEXT,.. where LABEL is the
    first field equal to SPAM/HAM (case-insensitive) and TEXT is everything after
    it (text may itself contain commas, hence the join)."""
    rows: list[dict] = []
    seen: set[str] = set()
    src_dir = RAW / "exais" / "ExAIS_SMS Spam Dataset"
    for csv_path in sorted(src_dir.glob("*.csv")):
        with csv_path.open(encoding="utf-8", errors="replace") as fh:
            for fields in csv.reader(fh):
                label_idx = next((i for i, f in enumerate(fields)
                                  if f.strip().upper() in {"SPAM", "HAM"}), None)
                if label_idx is None:
                    continue
                label = fields[label_idx].strip().upper()
                text = ",".join(fields[label_idx + 1:]).strip().strip(",").strip()
                if len(text) < 6:           # drop empty / junk ("Info", "CANCLE")
                    continue
                key = text.lower()
                if key in seen:
                    continue
                seen.add(key)
                if label == "HAM":
                    cat = ScamCategory.NOT_A_SCAM
                else:                        # SPAM -> heuristic, benign by default
                    sug, conf, _ = suggest(text)
                    sug = IN_SCOPE_REMAP.get(sug, sug)
                    cat = sug if (sug != ScamCategory.NOT_A_SCAM
                                  and conf >= EXAIS_SCAM_CONF) else ScamCategory.NOT_A_SCAM
                rows.append({"id": stable_id(text), "text": text, "language": "en",
                             "category": cat.value, "source": "exais_sms"})
    return rows


def parse_swahili() -> list[dict]:
    rows: list[dict] = []
    seen: set[str] = set()
    path = RAW / "swahili_bongo" / "bongo_scam.csv"
    with path.open(encoding="utf-8", errors="replace") as fh:
        for row in csv.DictReader(fh):
            text = (row.get("Sms") or "").strip()
            cat_raw = (row.get("Category") or "").strip().lower()
            if len(text) < 6:
                continue
            key = text.lower()
            if key in seen:
                continue
            seen.add(key)
            if cat_raw == "trust":
                cat = ScamCategory.NOT_A_SCAM
            elif cat_raw == "scam":
                cat = swahili_category(text)
            else:
                continue
            rows.append({"id": stable_id(text), "text": text, "language": "sw",
                         "category": cat.value, "source": "swahili_bongo"})
    return rows


def main() -> None:
    import json
    from collections import Counter

    exais = parse_exais()
    swahili = parse_swahili()
    allrows = exais + swahili

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8") as fh:
        for r in allrows:
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")

    print(f"ExAIS:   {len(exais):>5} records  {Counter(r['category'] for r in exais)}")
    print(f"Swahili: {len(swahili):>5} records  {Counter(r['category'] for r in swahili)}")
    print(f"TOTAL:   {len(allrows):>5} -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
