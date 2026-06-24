# Rethicsec: AI-powered scam detection and cybercrime reporting for Africa

**Author:** Wilsons Navid Wado Tiwa, BSc Software Engineering, African Leadership University
**Product:** Rethicsec mobile app (Flutter + Firebase + a custom Python ML scam classifier)
**Status:** Implementation and Testing milestone. The deployed Android build is linked below.

Rethicsec answers a simple question for everyday users: is this message a scam? It gives a clear verdict
in seconds and then helps the user act on it, including reporting the scam to the right national authority.
The app uses a custom-trained, multilingual scam classifier rather than a general-purpose LLM, together
with an education hub, an AI assistant, and an authority-reporting directory that covers 14 African
countries. The classifier is trained on real African scam messages in **English, Portuguese, and Swahili**
and recognises four scam types (advance-fee fraud, mobile-money fraud, phishing, and not-a-scam).

**Why it matters: the reporting gap.** Cybercrime in Africa is badly under-reported. INTERPOL estimates
that fewer than 20% of incidents are ever formally logged, so the official statistics, and the
institutional response built on them, cover only a fraction of what actually happens. Rethicsec is built
to lower the barrier to reporting. It reaches victims where the scam reaches them, on their phone and in
their language, converts a confusing message into a clear verdict, and routes a structured report to the
right authority in one tap. Each report also adds to a regional scam dataset the field currently lacks, so
the platform works on the reporting gap and the data gap at the same time.

---

## 1. Deployed version: download and install (Android)

> **Direct APK download:**
> https://github.com/Wilsons-Navid/Capstone-Project/releases/download/v1.0.8/rethicsec-v1.0.8.apk
>
> **Release page:** https://github.com/Wilsons-Navid/Capstone-Project/releases/tag/v1.0.8
>
> **Model API (Hugging Face):** https://wilsons579-scam-classifier-api-v2.hf.space (usage in §4)

**Step-by-step install:**
1. On an Android phone, open the direct APK link above in a browser.
2. Tap Download; when it finishes, tap the file to open it.
3. Android may warn about "Install from unknown sources". Tap Settings, then Allow from this source. This is normal for apps installed outside an app store.
4. If Google Play Protect shows a warning, tap More details, then Install anyway. The build requests SMS-reading permissions, which Play Protect flags for sideloaded apps.
5. Open Rethicsec, create an account or sign in with Google, and you are in.

No desktop or developer tools are needed to run the deployed app. The APK is enough.

---

## 2. Run or build from source (developers)

**Prerequisites:** [Flutter](https://docs.flutter.dev/get-started/install) 3.x, Android Studio or the Android SDK, and a device or emulator.

```bash
# 1. Clone
git clone https://github.com/Wilsons-Navid/Capstone-Project.git
cd Capstone-Project/mobile/rethicsai

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device / emulator
flutter run

# 4. (optional) Build your own release APK
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

The app ships with its Firebase configuration, so no extra backend setup is needed to run it.

---

## 3. What the app does (core functionality)

| Feature (name in the app) | What it does |
|---|---|
| Threat Scanner | Paste an SMS, email, URL, phone number or message; the AI returns a threat level, a category, and an explanation. |
| SMS Protection | Scan your inbox or live-classify incoming SMS with the model (Android only). |
| Report to authorities | Country-aware directory (14 countries) of police, cyber-crime, and financial-crime units. Call, email, or report online with a pre-filled message. |
| Report Incident | Structured report with evidence upload, geolocation, and priority. |
| Track Cases | Status timeline for submitted cases. |
| Learn & Protect | Lessons (video and interactive) with gamification and certificates. |
| Wilson AI | Conversational cyber-safety questions and answers (Claude Haiku). |
| Need Immediate Help? | Emergency-contacts directory for quick access during an active fraud. |
| Dashboard and Notifications | Personal security overview and a real-time alerts inbox. |
| Admin Panel | Manage authority contacts (add, edit, delete countries), moderate content, review cases. |
| Language | 11 locales: English, French, Swahili, Hausa, Yoruba, Igbo, Zulu, Xhosa, Afrikaans, Arabic, Duala. |

### 3.1 App screenshots

<p align="center">
  <img src="docs/assets/screenshots/dashboard.png" height="380" alt="Dashboard">
  <img src="docs/assets/screenshots/scanner.png" height="380" alt="Threat scanner">
  <img src="docs/assets/screenshots/scanner_input.png" height="380" alt="Scanner input">
</p>
<p align="center"><em>Dashboard, the threat scanner, and the scan input.</em></p>

<p align="center">
  <img src="docs/assets/screenshots/advance_fee_actions.png" height="380" alt="Report-to-authorities actions">
  <img src="docs/assets/screenshots/mobile_money_2.png" height="380" alt="A mobile-money scan">
  <img src="docs/assets/screenshots/security_features.png" height="380" alt="Security features">
</p>
<p align="center"><em>Report-to-authorities actions, a mobile-money scan, and the security features.</em></p>

<p align="center">
  <img src="docs/assets/screenshots/education.png" height="380" alt="Education hub">
  <img src="docs/assets/screenshots/ai_assistant.png" height="380" alt="Wilson AI assistant">
  <img src="docs/assets/screenshots/admin.png" height="380" alt="Admin dashboard">
</p>
<p align="center"><em>The education hub, the Wilson AI assistant, and the admin dashboard.</em></p>

<p align="center">
  <img src="docs/assets/screenshots/report_incident.png" height="380" alt="Report an incident">
  <img src="docs/assets/screenshots/incident_report_2.png" height="380" alt="Incident report form">
</p>
<p align="center"><em>Incident reporting.</em></p>

---

## 4. How it's built: two parts and their intersection

Rethicsec has two engineered parts that meet at one screen.

- **Part 1, the mobile app** (`mobile/rethicsai/`): a Flutter and Material 3 client. It holds the scanner
  UI, structured reporting, case tracking, the education hub, the Wilson assistant, the admin console, the
  14-country authority directory, and 11 languages, backed by Firebase (Auth, Firestore, Cloud Functions,
  FCM).
- **Part 2, the ML system** (`ml/`): the research core. It contains a four-class scam corpus of **9,623
  messages across English, Portuguese, and Swahili**, the training and evaluation notebooks, and the
  trained classifier served behind a `/predict` API. Several models are compared (TF-IDF and multilingual
  e5 base models plus soft-voting and stacking ensembles); the deployed model is the best of them on the
  expanded corpus, **TF-IDF + Logistic Regression (test macro-F1 0.946)**. Because it is pure
  scikit-learn with no embedder to download, the service cold-starts instantly.
- **The intersection, the scanner.** This is where the two parts meet. A user pastes a message, the app's
  `ScamModelService` calls the model's `/predict` endpoint, and the returned category and confidence are
  shown in the verdict card. A warm-up ping on app launch keeps the hosted model responsive, so the user
  sees the live model verdict instead of a keyword fallback.

![Rethicsec architecture: the mobile app, the ML system, and the scanner that joins them](docs/assets/architecture.png)

### Try the model API directly

The scam classifier is hosted as a public Hugging Face Space, the same endpoint the app calls.

- **Model API base URL:** https://wilsons579-scam-classifier-api-v2.hf.space
- **Endpoint:** `POST /predict`
- **Request body:** `{ "text": "<message to classify>" }`

**Example (curl) — a Swahili mobile-money lure:**

```bash
curl -X POST https://wilsons579-scam-classifier-api-v2.hf.space/predict \
  -H "Content-Type: application/json" \
  -d '{"text":"Iyo pesa itume kwenye namba hii ya Airtel 0689933027 jina PETER NYANGE."}'
```

**Example response:**

```json
{
  "predicted_category": "mobile_money_fraud",
  "confidence": 0.9966,
  "scores": {
    "advance_fee_fraud": 0.0012,
    "mobile_money_fraud": 0.9966,
    "phishing": 0.0009,
    "not_a_scam": 0.0013
  }
}
```

> The v2 model is pure scikit-learn (no embedder to download), so a warm request answers in about a
> second and there is no 470 MB cold-start download. The Space still sleeps when idle, so only the first
> request after a pause waits a few seconds for the container to wake (the app hides this with a warm-up
> ping). In the mobile app the URL is set with the `SCAM_MODEL_API` dart-define, for example
> `flutter run --dart-define=SCAM_MODEL_API=https://<your-space>.hf.space`. The previous e5 soft-voting
> ensemble (macro-F1 0.955 on the smaller corpus) remains available at
> `https://wadotuh-scam-classifier-api.hf.space`.

---

## 5. Testing results

> Screenshots referenced below live in `docs/assets/`. Add your captured images there.

### 5.1 Testing strategies

| Strategy | What it covers | How to run / evidence |
|---|---|---|
| Automated unit tests | Validation and sanitization logic (`SecurityUtils`), bundled authority-contacts data, theme tokens. | `cd mobile/rethicsai && flutter test` |
| Automated widget tests | Theme renders, `EarthColors` extension resolves, Material 3 enabled. | included in `flutter test` |
| Manual / functional testing | Core user flows: scan, verdict, report; dashboard; admin CRUD. | screenshots (§5.2) |

Automated test run (all green):

```text
$ flutter test
00:03 +36: All tests passed!
```

![flutter test output showing all 36 tests passing](docs/assets/test_run.png)

### 5.2 Functionality with different data values (the scanner)

The scanner was tested with one real message per class (taken from the corpus). Each returned the correct
category and risk level from the AI model, with the model's confidence shown on screen:

| Input (corpus message) | Model category | Verdict | Confidence |
|---|---|---|---|
| "URGENT! ...you have won a £900 prize GUARANTEED. Call 09061701939. Claim code S89. Valid 12hrs only" | Advance-fee fraud | HIGH RISK | 96% |
| "...FAIZAL ALBERTO BERNADO" (Mozambican M-Pesa lure, Portuguese) | Mobile-money fraud | HIGH RISK | 85% |
| "TKO NOTICE: Compromised Accounts - eBay Registration Suspension" | Phishing | HIGH RISK | 97% |
| "Okey dokey, i'll be over in a bit just sorting some stuff out." | Not a scam | SAFE | 97% |

<p align="center">
  <img src="docs/assets/scan_advance_fee.png" height="380" alt="Advance-fee fraud verdict, high risk, 96%">
  <img src="docs/assets/scan_momo.png" height="380" alt="Mobile-money fraud verdict, high risk, 85%">
  <img src="docs/assets/scan_phishing.png" height="380" alt="Phishing verdict, high risk, 97%">
  <img src="docs/assets/scan_safe.png" height="380" alt="Not a scam verdict, safe, 97%">
</p>

The verdicts use the deployed model (the cards read "AI Model Verdict" with a confidence bar), and each
verdict is shown by icon, colour, and text together (red for scam, green for safe).

### 5.3 Performance on different hardware / software

The app was run on a physical Infinix Note 50 Pro (model X6855). All core flows (launch, navigation, scan,
and report) ran smoothly on the device.

| Device / emulator | Android version | RAM | Result (launch, scan, report) | Screenshot |
|---|---|---|---|---|
| Infinix Note 50 Pro (X6855), physical | Android 15 | 8 GB | Smooth; all core flows worked | `docs/assets/perf_phone.png` |
| _Second config (a different phone or an emulator)_ | _e.g. Android 11_ | _e.g. 4 GB_ | _add result_ | `docs/assets/perf_emulator.png` |

<p align="center"><img src="docs/assets/perf_phone.png" height="420" alt="Rethicsec running on an Infinix Note 50 Pro"></p>

---

## 6. Analysis: results vs. project objectives

### 6.1 What the proposal committed to vs. what was delivered

The proposal (Chapter 1) set three SMART objectives. The implementation met or exceeded all three.

| Proposal objective | Committed to | Delivered | Verdict |
|---|---|---|---|
| Obj 1, Corpus | A labelled West African scam corpus of at least 500 incidents across the typology. | 9,623 labelled messages across 4 classes (advance-fee, mobile-money, phishing, not-a-scam) and 3 languages (English, Portuguese, Swahili), from Nazario, UCI-SMS, Mozambique and Mendeley smishing, regional news, the **ExAIS African-English SMS set (Nigeria)**, and the **BongoScam Tanzanian Swahili set**. | Exceeded (about 19 times the target) |
| Obj 2, Platform | Deploy a mobile platform integrating reporting, classification, risk assessment, and education. | Flutter app with all four, plus the assistant, admin console, and 14-country authority reporting; installable APK. | Exceeded |
| Obj 3, Model comparison | Compare two classical baselines (TF-IDF with logistic regression vs TF-IDF with random forest), per-category metrics. | Compared six models (the two baselines, e5-embedding LR and RF, soft-vote, and stacking ensembles) on the expanded corpus; deployed the best, **TF-IDF + logistic regression at macro-F1 0.946**, with per-language and per-class breakdowns. | Exceeded scope |
| Regional scope | Nigeria and Cameroon | Authority reporting for 14 countries | Exceeded |
| Language scope | English and French (Pidgin where possible) | App localised to 11 languages; corpus is English, Portuguese, and Swahili | Partly diverged |

Honest deviations from the proposal:

- Obj 3 was scoped as a classical-only, two-baseline comparison. The delivered work went beyond it by adding multilingual e5 embeddings and ensembles. Interestingly, on the larger, keyword-rich African corpus the classical TF-IDF + logistic-regression model is again the strongest single model (macro-F1 0.946), narrowly ahead of the ensemble; the embeddings act as cross-lingual insurance rather than a leaderboard win. The final report should frame the embeddings/ensembles as an extension beyond, and a fair comparison against, the proposed classical baselines.
- The corpus language mix is English, Portuguese, and Swahili, not the English and French the proposal targeted. Two real African sources were added since the first milestone — the ExAIS African-English SMS set (Nigeria) and the BongoScam Tanzanian Swahili set — which materially improved African coverage. French and Pidgin coverage in the model remains thin, even though the app localises to 11 languages.
- Corpus provenance: the corpus is labelled by scam typology. It now combines public English/Portuguese smishing and phishing datasets (UCI SMS, Nazario, the Mozambican M-Pesa set, Mendeley) with two real African SMS datasets (ExAIS, BongoScam). The African additions are relabelled from their native binary labels into the four-class typology by a documented, auditable rule set (`ml/scripts/11_relabel_african.py`), and these remain heuristic/provenance labels pending the inter-rater κ audit. A corpus collected first-hand from West African victims is still future work, so the "West African corpus" framing should be read as typology-aligned and now partly region-native rather than fully field-collected. Full source links are in `docs/DATA_SOURCES.md`.

### 6.2 The ML analysis (figures from `ml/notebooks/`)

Example messages from the corpus, two per class. These are verbatim records from
`ml/data/labelled/demo_labeled.jsonl` (the JSON Lines training file), in their stored dictionary form,
with the original spelling and encoding preserved:

```json
{"id": "13766c415bc9", "text": "FREE entry into our £250 weekly competition just text the word WIN to 80086 NOW. 18 T&C www.txttowin.co.uk", "language": "en", "category": "advance_fee_fraud", "source": "uci_sms"}
{"id": "cfba88227a34", "text": "As a valued customer, I am pleased to advise you that following recent draw of your Mobile No. you are awarded with a Rs.2,00,000 Bonus Prize, call 6200992462", "language": "en", "category": "advance_fee_fraud", "source": "mendeley_smishing"}
{"id": "22b1f0f110b5", "text": "boa tarda, o valor pod-me mandar neste nr: 857217192, na conta M-Pesa vem em nome de FAIZAL ALBERTO BERNADO.", "language": "pt", "category": "mobile_money_fraud", "source": "moz_smishing"}
{"id": "938101622afe", "text": "A Minha Conta Tem Problema, Transfere Neste Número 857857934 Porfavor Aparece Nome Da Monica Rui.", "language": "pt", "category": "mobile_money_fraud", "source": "moz_smishing"}
{"id": "90369829fb76", "text": "Notification Of your eBay Internet Account Security", "language": "en", "category": "phishing", "source": "nazario_email"}
{"id": "b314f26279d8", "text": "Verify Your Details With SouthTrust Bank [Sun, 22 May 2005 13:21:14 +0200]", "language": "en", "category": "phishing", "source": "nazario_email"}
{"id": "afb1a063028b", "text": "Wif my family booking tour package.", "language": "en", "category": "not_a_scam", "source": "uci_sms"}
{"id": "e08140acbb70", "text": "How abt making some of the pics bigger?", "language": "en", "category": "not_a_scam", "source": "uci_sms"}
```

> Note: each record has `id`, `text`, `language`, `category`, and `source`. These examples are from the
> original v1 corpus. In the current v2 corpus the `mobile_money_fraud` class is no longer
> Portuguese-only: it is now carried by Mozambican M-Pesa smishing (Portuguese) **and** Tanzanian Swahili
> mobile-money lures from the BongoScam set (for example, "Iyo pesa itume kwenye namba hii ya Airtel
> 0689933027" means "send that money to this Airtel number"). The corpus is therefore English,
> Portuguese, and Swahili; French and Pidgin coverage in the model is still thin (see §6.1).

The figures below are from the **v1 corpus (4,422 messages)**, the milestone-1 analysis. The
**v2 corpus (9,623 messages)** results that follow are reproduced live in
`ml/notebooks/scam_detection_main_v2.ipynb`.

Corpus and class imbalance (v1). Phishing dominates; mobile-money and advance-fee are the minority classes, which is the root cause of the bias discussed below:

![Corpus class, source and language distribution](docs/assets/ml/ml_class_distribution.png)

Model comparison (v1). Of six models, the soft-voting ensemble wins at macro-F1 0.955, above the 0.943 TF-IDF with logistic-regression baseline:

![Macro-F1 by model on the test split](docs/assets/ml/ml_model_comparison.png)

Confusion matrix (v1 deployed ensemble). It is strong on the diagonal in-distribution; the visible leakage is advance-fee predicted as phishing:

![Confusion matrix of the deployed soft-voting ensemble](docs/assets/ml/ml_confusion_matrix.png)

Re-balancing ablation (v1). Class-weighting, over-sampling, and the combined strategy all converge to the same per-class recall, and none beats the others on the hard advance-fee class. This confirms that data, not the algorithm, is the limit:

![Per-class recall across re-balancing strategies](docs/assets/ml/ml_rebalance_ablation.png)

**v2 results — after adding the African data.** Retraining the same model ladder on the expanded
9,623-message corpus (English, Portuguese, Swahili) gives:

| Model | Accuracy | Macro-F1 |
|---|---|---|
| **TF-IDF + Logistic Regression (deployed)** | **0.965** | **0.946** |
| Soft-voting ensemble | 0.959 | 0.941 |
| Stacking ensemble | 0.958 | 0.937 |
| TF-IDF + Random Forest | 0.936 | 0.913 |
| e5 embeddings + Logistic Regression | 0.929 | 0.899 |
| e5 embeddings + Random Forest | 0.918 | 0.884 |

- **Mobile-money fraud went from the weakest class to the strongest** (per-class F1 0.983), because the
  Swahili BongoScam data joined the Portuguese M-Pesa data in that class. This directly addresses the
  cross-lingual mobile-money gap reported at milestone 1. Advance-fee remains the hardest class (F1 0.874).
- **The model works in every language it was given:** per-language test accuracy is English 0.95,
  Portuguese 1.00, Swahili 0.98.
- The keyword-rich African data favours the lexical model, so TF-IDF + logistic regression is again the
  best single model; the multilingual embeddings add cross-lingual robustness but do not top the board.

### 6.3 Where results fell short, and what the ML experiments showed

At milestone 1, the 0.955 figure was in-distribution and the v1 corpus was class-imbalanced (phishing
about 2,401, then not-a-scam about 1,200, then mobile-money about 538, then advance-fee about 283). The
v1 model inherited a majority-class bias toward phishing, and genuine mobile-money and advance-fee scams
(and occasionally even legitimate messages) drifted toward phishing at low confidence. A controlled
re-balancing ablation (testing class-weighting, over-sampling, under-sampling, and combined) showed that
re-balancing the existing data could not create signal that was not there: the binding constraint was the
**volume of authentic minority-class data, not the algorithm**.

That diagnosis drove the v2 work. Acting on it, two real African SMS datasets were sourced and added — the
ExAIS African-English set and the Tanzanian Swahili BongoScam set — which roughly doubled the two scarce
classes (mobile-money 538 → 1,166, advance-fee 283 → 597) and added a third language. The payoff is direct:
**mobile-money fraud became the strongest class (F1 0.983)** and the model now reads Swahili and Portuguese,
not just English. The minority-data constraint the ablation identified has been substantially eased, though
advance-fee remains the hardest class and English mobile-money data is still comparatively thin (a
data-access request to CMU-Africa's Upanzi network is in progress to source real English mobile-money
messages).

A separate finding concerns serving reliability. The v1 model was an e5 ensemble that had to download a
470 MB embedder on first request; on a Space that sleeps when idle this could time out and the app would
fall back to weaker keyword heuristics. The v2 model removes the cause entirely: it is pure scikit-learn
(about 1.5 MB, no embedder), so it cold-starts instantly and answers a warm request in about a second. The
warm-up ping on app launch is retained to mask the container wake from idle, so users reliably see the
model verdict rather than the fallback.

---

## 7. Discussion: why the milestones matter

- Because fewer than 20% of African cybercrime incidents are ever formally reported, the harder problem is
  not only detecting scams but giving people a low-friction way to report them. Rethicsec provides that
  path: a non-technical victim can report a scam in their own language, in one tap, the moment it happens.
  That reporting data is also what downstream institutional responses depend on.
- Detection on its own is only half the job. This milestone matters because it closes the loop: a verdict
  becomes a one-tap report to a real authority in the user's country.
- Building a custom classifier instead of calling a third-party LLM means the model is tuned to African
  scam patterns and languages, and every confirmed report can improve it. That data advantage is hard for
  competitors to copy by translating a user interface.
- Proving that no re-balancing strategy fixes the out-of-distribution failures is a useful result in
  itself. It points effort away from algorithm tweaks and toward acquiring real, labelled, local scam
  data. Knowing what does not work kept the project from chasing a dead end.
- A 0.955 model is useless if the user sees a keyword fallback because the service was cold. The warm-up
  fix is a reminder that for a deployed model, serving reliability matters as much as offline accuracy.
- Accessibility and clarity are not cosmetic. Showing each verdict as an icon, a colour, and a text label,
  meeting WCAG AA contrast, and supporting 11 languages all decide whether a non-technical user actually
  understands the guidance.

---

## 8. Recommendations and future work

- Confidence-aware verdicts: show the model's confidence and add an explicit "unsure, treat with caution" state to cut false positives and build trust.
- Collect authentic minority-class data (mobile-money and advance-fee). This was the single biggest lever on accuracy, as the re-balancing ablation showed, and v2 acted on it by adding the ExAIS and BongoScam African SMS sets — mobile-money is now the strongest class. The remaining gaps are advance-fee volume and English (rather than Swahili/Portuguese) mobile-money data; a data-access request to a regional smishing-research network (CMU-Africa's Upanzi) is in progress to source the latter.
- On-device inference: a quantised model for offline, private screening on low-connectivity networks.
- Multi-modal detection: images, link reputation, and voice notes.
- Consent-based escalation tiers: from helping the user act today to partnerships with operators and regulators.
- Community outreach: promote the app through telco and community-organisation channels where scam exposure is highest.

---

## 9. Repository map (related files)

```
Capstone-Project/
├── README.md                     ← this file (submission entry point)
├── mobile/rethicsai/             ← the Rethicsec Flutter app
│   ├── lib/                      ← app source (features/, core/, shared/)
│   ├── test/                     ← automated tests (flutter test, 36 passing)
│   └── design-system/MASTER.md   ← the design-system contract
├── ml/                           ← scam-classifier research (corpus, notebooks, serving)
├── docs/                         ← reports, assets/ (screenshots), templates
│   └── Rethics_Product_Brand_Report.docx
└── proposal/                     ← academic proposal workspace
```

---

## 10. Tech stack

Flutter (Dart), Material 3, Firebase (Auth, Firestore, Cloud Functions, FCM), a Python ML service
(scikit-learn TF-IDF + logistic-regression classifier, with a multilingual e5 ensemble compared against
it), FastAPI on a Hugging Face Docker Space, Claude Haiku for the assistant, and 11 locales.

---

## 11. Demo video

**5-minute demo (core functionality):** _add link here_

> The video focuses on the core flows (scanning different messages, the verdict, reporting to authorities,
> the education hub, and the assistant) rather than sign-up or sign-in.
