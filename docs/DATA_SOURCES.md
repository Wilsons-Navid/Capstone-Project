# Dataset Sources — Rethicsec Scam-Detection Model

This document lists every raw dataset used to train the project's scam-detection
classifier (classes: `advance_fee_fraud`, `mobile_money_fraud`, `phishing`,
`not_a_scam`), with citable source links. Provenance tags shown below are stored
verbatim in each record's `source_url` field in `ml/data/raw/`.

## Datasets used in training

### 1. UCI SMS Spam Collection v.1
English SMS messages (5,574) labelled ham/spam. Provided English smishing and
legitimate-SMS examples.
- Dataset page: https://archive.ics.uci.edu/dataset/228/sms+spam+collection
- Direct download: https://archive.ics.uci.edu/ml/machine-learning-databases/00228/smsspamcollection.zip
- Citation: Almeida, T.A., Gómez Hidalgo, J.M., Yamakami, A. (2011). *Contributions to the Study of SMS Spam Filtering: New Collection and Results.* ACM DOCENG'11.

### 2. Nazario Phishing Corpus
Phishing emails (`.mbox` archives). Provided the phishing class.
- Project page: https://monkey.org/~jose/phishing/
- Landing/wiki: https://monkey.org/~jose/wiki/doku.php?id=PhishingCorpus
- Note: distribution is gated behind a manual download form.

### 3. SMS Phishing Dataset (Dataset_5971) — Mendeley Data
Smishing/phishing SMS with URL/email/phone indicator flags.
- Mendeley Data: https://data.mendeley.com/datasets/f45bkkt8pr
- DOI: 10.17632/f45bkkt8pr
- Authors: Mishra, Sandhya; Soni, Devpriya.
- Provenance tag: `mendeley:f45bkkt8pr`

### 4. MOZ-Smishing (Mozambique mobile-money SMS)
Portuguese M-Pesa mobile-money SMS. Provided the mobile-money-fraud class and
African/regional coverage.
- Hugging Face: https://huggingface.co/datasets/MOZNLP/MOZ-Smishing
- Provenance tag: `hf:MOZNLP/MOZ-Smishing`

### 5. Premium Times regional news stream (supplementary)
West African scam/fraud news context, harvested via the public WordPress REST
API (`/wp-json/wp/v2/posts?search=<query>`). Provided regional advance-fee /
scam context.
- Site: https://www.premiumtimesng.com

## Datasets being added to the corpus

These real, African scam/SMS datasets are being incorporated to strengthen
African-language and African-English coverage. Both require relabelling from
their native binary labels into the project's four-class taxonomy
(advance_fee_fraud / mobile_money_fraud / phishing / not_a_scam), and their
Kaggle licence must be confirmed before redistribution.

### 6. Swahili SMS Detection Dataset (BongoScam)
1,508 real Tanzanian Swahili SMS labelled scam / trust. Adds Swahili (East
African) mobile-money smishing coverage to a currently Portuguese-only
mobile-money class.
- Kaggle: https://www.kaggle.com/datasets/henrydioniz/swahili-sms-detection-dataset
- Repo: https://github.com/Henryle-hd/BongoScamDetection
- Native labels: `scam` / `trust`
- Supporting literature: arXiv:2502.16947 (Using Machine Learning to Detect Fraudulent SMSs in Swahili); *Uncovering SMS Spam in Swahili Text Using Deep Learning Approaches*.
- **Status: adopted for the corpus; licence verification + relabel pending.**

### 7. ExAIS_SMS Spam Dataset
5,240 real African-English SMS (2,350 spam / 2,890 ham) collected from 20
consenting members of the Federal University of Agriculture, Abeokuta, Nigeria
(sensitive details masked). African-English context is directly relevant to the
English-language smishing gap.
- Kaggle: https://www.kaggle.com/datasets/ysfbil/exais-sms-dataset
- Original repo: https://github.com/AbayomiAlli/SMS-Spam-Dataset
- Native labels: `Spam` / `Ham`
- Citation: Onashoga, A.S., Abayomi-Alli, O.O., Sodiya, A.S., Ojo, D.A. (2015). *An Adaptive and Collaborative Server-Side SMS Spam Filtering Scheme Using Artificial Immune System.* Information Security Journal: A Global Perspective, 24(4-6), 133-145.
- **Status: candidate; licence verification + relabel pending.**

## Future / requested dataset (not yet in training)

### CMU-Africa Upanzi smishing-honeynet — English mobile-money smishing
Real English-language mobile-money smishing SMS, intended to close the
cross-lingual MoMo gap (the `mobile_money_fraud` class is currently
Lusophone-only and misclassifies English MoMo messages as phishing). The dataset
is gated and not publicly downloadable.

- Source paper: Lamptey, Gueye, Seidu, Luhanga, Sowon. *(Smishing honeynet study.)*
  COMPASS '24. DOI: 10.1145/3674829.3675080
- Honeynet coverage: Rwanda, Botswana, Ghana, Kenya, Uganda.
- **Data-access request status: SENT 2026-06-22, awaiting reply.**
  Request directed to Edith Luhanga (CMU-Africa), cc Karen Sowon.
- Request letter: `docs/outreach/CMU_Upanzi_data_request.md`

## Datasets evaluated and rejected (out of scope)
Assessed but out of scope for a text classifier — they contain transaction
records, not scam-message text, so the model cannot train on them. Listed for
transparency / due diligence.
- **PaySim** (Kaggle, `ealaxi/paysim1`): ~6.36M synthetic mobile-money transaction records (amounts, balances, transfer types, isFraud) seeded from real African logs; CC BY-SA 4.0. No message text. Relevant only if scope extended to a transaction-level fraud model.
- **mobile-money-fraud-detection** (github.com/antann07): synthetic mobile-money transaction records / engineered behavioural features (SIM-swap, device/location, velocity). No message text.

## Sources attempted but NOT used
The following regional government advisory sources were probed but yielded **no**
training data (blocked), and are not counted among the sources used:
- ngCERT (`cert.gov.ng`) — Cloudflare anti-bot, HTTP 403
- ANTIC (`antic.cm`) — host unreachable (connect timeout)
- EFCC (`efccnigeria.org`) — empty shell / 404
