# RethicsAI: AI-powered scam detection and cybercrime reporting for Africa

**Author:** Wilsons Navid Wado Tiwa, BSc Software Engineering, African Leadership University
**Product:** RethicsAI mobile app (Flutter + Firebase + a custom Python ML scam classifier)
**Status:** Implementation and Testing milestone. The deployed Android build is linked below.

RethicsAI answers a simple question for everyday users: is this message a scam? It gives a clear verdict
in seconds and then helps the user act on it, including reporting the scam to the right national authority.
The app uses a custom-trained scam classifier rather than a general-purpose LLM, together with an
education hub, an AI assistant, and an authority-reporting directory that covers 14 African countries.

**Why it matters: the reporting gap.** Cybercrime in Africa is badly under-reported. INTERPOL estimates
that fewer than 20% of incidents are ever formally logged, so the official statistics, and the
institutional response built on them, cover only a fraction of what actually happens. RethicsAI is built
to lower the barrier to reporting. It reaches victims where the scam reaches them, on their phone and in
their language, converts a confusing message into a clear verdict, and routes a structured report to the
right authority in one tap. Each report also adds to a regional scam dataset the field currently lacks, so
the platform works on the reporting gap and the data gap at the same time.

---

## 1. Deployed version: download and install (Android)

> **Direct APK download:**
> https://github.com/Wilsons-Navid/Capstone-Project/releases/download/v1.0.6/rethicsai-v1.0.6.apk
>
> **Release page:** https://github.com/Wilsons-Navid/Capstone-Project/releases/tag/v1.0.6
>
> **Model API (Hugging Face):** https://wadotuh-scam-classifier-api.hf.space (usage in §4)

**Step-by-step install:**
1. On an Android phone, open the direct APK link above in a browser.
2. Tap Download; when it finishes, tap the file to open it.
3. Android may warn about "Install from unknown sources". Tap Settings, then Allow from this source. This is normal for apps installed outside an app store.
4. If Google Play Protect shows a warning, tap More details, then Install anyway. The build requests SMS-reading permissions, which Play Protect flags for sideloaded apps.
5. Open RethicsAI, create an account or sign in with Google, and you are in.

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

| Feature | What it does |
|---|---|
| Scanner | Paste an SMS, email, URL, phone number or message; the AI returns a threat level, a category, and an explanation. |
| Report to authorities | Country-aware directory (14 countries) of police, cyber-crime, and financial-crime units. Call, email, or report online with a pre-filled message. |
| Incident reporting | Structured report with evidence upload, geolocation, and priority. |
| Case tracking | Status timeline for submitted cases. |
| Education hub | Lessons (video and interactive) with gamification and certificates. |
| Wilson AI assistant | Conversational cyber-safety questions and answers (Claude Haiku). |
| Notifications and dashboard | Real-time alerts and a personal security overview. |
| Admin console | Manage authority contacts (add, edit, delete countries), moderate content, review cases. |
| 11 languages | English, French, Swahili, Hausa, Yoruba, Igbo, Zulu, Xhosa, Afrikaans, Arabic, Duala. |

### 3.1 App screenshots

<p align="center">
  <img src="docs/assets/screenshots/dashboard.png" width="200" alt="Dashboard">
  <img src="docs/assets/screenshots/scanner.png" width="200" alt="Threat scanner">
  <img src="docs/assets/screenshots/scanner_input.png" width="200" alt="Scanner input">
</p>
<p align="center"><em>Dashboard, the threat scanner, and the scan input.</em></p>

<p align="center">
  <img src="docs/assets/screenshots/advance_fee_actions.png" width="200" alt="Report-to-authorities actions">
  <img src="docs/assets/screenshots/mobile_money_2.png" width="200" alt="A mobile-money scan">
  <img src="docs/assets/screenshots/security_features.png" width="200" alt="Security features">
</p>
<p align="center"><em>Report-to-authorities actions, a mobile-money scan, and the security features.</em></p>

<p align="center">
  <img src="docs/assets/screenshots/education.png" width="200" alt="Education hub">
  <img src="docs/assets/screenshots/ai_assistant.png" width="200" alt="Wilson AI assistant">
  <img src="docs/assets/screenshots/admin.png" width="200" alt="Admin dashboard">
</p>
<p align="center"><em>The education hub, the Wilson AI assistant, and the admin dashboard.</em></p>

<p align="center">
  <img src="docs/assets/screenshots/report_incident.png" width="200" alt="Report an incident">
  <img src="docs/assets/screenshots/incident_report_2.png" width="200" alt="Incident report form">
</p>
<p align="center"><em>Incident reporting.</em></p>

---

## 4. How it's built: two parts and their intersection

RethicsAI has two engineered parts that meet at one screen.

- **Part 1, the mobile app** (`mobile/rethicsai/`): a Flutter and Material 3 client. It holds the scanner
  UI, structured reporting, case tracking, the education hub, the Wilson assistant, the admin console, the
  14-country authority directory, and 11 languages, backed by Firebase (Auth, Firestore, Cloud Functions,
  FCM).
- **Part 2, the ML system** (`ml/`): the research core. It contains a hand-labelled four-class scam
  corpus, the training and evaluation notebooks, and the trained classifier (a TF-IDF and multilingual e5
  soft-voting ensemble) served behind a `/predict` API.
- **The intersection, the scanner.** This is where the two parts meet. A user pastes a message, the app's
  `ScamModelService` calls the model's `/predict` endpoint, and the returned category and confidence are
  shown in the verdict card. A warm-up ping on app launch keeps the hosted model responsive, so the user
  sees the live model verdict instead of a keyword fallback.

![RethicsAI architecture: the mobile app, the ML system, and the scanner that joins them](docs/assets/architecture.png)

### Try the model API directly

The scam classifier is hosted as a public Hugging Face Space, the same endpoint the app calls.

- **Model API base URL:** https://wadotuh-scam-classifier-api.hf.space
- **Endpoint:** `POST /predict`
- **Request body:** `{ "text": "<message to classify>" }`

**Example (curl):**

```bash
curl -X POST https://wadotuh-scam-classifier-api.hf.space/predict \
  -H "Content-Type: application/json" \
  -d '{"text":"Congratulations! You won 2000000 in the MTN promo. Send your BVN and a 5000 activation fee to claim now."}'
```

**Example response:**

```json
{
  "predicted_category": "advance_fee_fraud",
  "confidence": 0.6993,
  "scores": {
    "advance_fee_fraud": 0.6993,
    "mobile_money_fraud": 0.015,
    "phishing": 0.1862,
    "not_a_scam": 0.0995
  }
}
```

> The Space sleeps when idle, so the first request after a pause can take 30 to 90 seconds to wake the
> model (the app hides this with a warm-up ping). In the mobile app the URL is set with the
> `SCAM_MODEL_API` dart-define, for example
> `flutter run --dart-define=SCAM_MODEL_API=https://<your-space>.hf.space`.

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
  <img src="docs/assets/scan_advance_fee.png" width="210" alt="Advance-fee fraud verdict, high risk, 96%">
  <img src="docs/assets/scan_momo.png" width="210" alt="Mobile-money fraud verdict, high risk, 85%">
  <img src="docs/assets/scan_phishing.png" width="210" alt="Phishing verdict, high risk, 97%">
  <img src="docs/assets/scan_safe.png" width="210" alt="Not a scam verdict, safe, 97%">
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

<p align="center"><img src="docs/assets/perf_phone.png" width="240" alt="RethicsAI running on an Infinix Note 50 Pro"></p>

---

## 6. Analysis: results vs. project objectives

### 6.1 What the proposal committed to vs. what was delivered

The proposal (Chapter 1) set three SMART objectives. The implementation met or exceeded all three.

| Proposal objective | Committed to | Delivered | Verdict |
|---|---|---|---|
| Obj 1, Corpus | A labelled West African scam corpus of at least 500 incidents across the typology. | 4,422 labelled messages across 4 classes (advance-fee, mobile-money, phishing, not-a-scam), from Nazario, UCI-SMS, Mozambique and Mendeley smishing, and regional news. | Exceeded (about 9 times the target) |
| Obj 2, Platform | Deploy a mobile platform integrating reporting, classification, risk assessment, and education. | Flutter app v1.0.6 with all four, plus the assistant, admin console, and 14-country authority reporting; installable APK. | Exceeded |
| Obj 3, Model comparison | Compare two classical baselines (TF-IDF with logistic regression vs TF-IDF with random forest), per-category metrics. | Compared six models (the two baselines, e5-embedding LR and RF, soft-vote, and stacking ensembles); deployed the soft-vote ensemble at 0.955 macro-F1. | Exceeded scope |
| Regional scope | Nigeria and Cameroon | Authority reporting for 14 countries | Exceeded |
| Language scope | English and French (Pidgin where possible) | App localised to 11 languages; corpus is English and Portuguese | Partly diverged |

Honest deviations from the proposal:

- Obj 3 was scoped as a classical-only, two-baseline comparison. The delivered work went beyond it by adding multilingual e5 embeddings and ensembles. This strengthens the result, but the final report should frame the ensemble as an extension beyond the proposed classical baselines.
- The corpus language mix is English and Portuguese (from the Mozambique smishing set), not the English and French the proposal targeted. French and Pidgin coverage in the model remains thin, even though the app localises to 11 languages.
- Corpus provenance: the corpus is labelled by scam typology, but most rows come from public English and Portuguese smishing and phishing datasets (UCI SMS, Nazario, and the Mozambican M-Pesa set), used as a proxy for the target distribution. A corpus collected specifically from West African sources is future work, so the "West African corpus" framing should be read as typology-aligned rather than fully region-native.

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

> Note: each record has `id`, `text`, `language`, `category`, and `source`. The `mobile_money_fraud` class
> is sourced almost entirely from Mozambican M-Pesa smishing, so it is in Portuguese (for example,
> "A Minha Conta Tem Problema, Transfere Neste Número 857857934 ... Aparece Nome Da Monica Rui" means
> "my account has a problem, transfer to this number, in the name of Monica Rui"). That is why the corpus
> is English and Portuguese, and why French and Pidgin coverage in the model is still thin (see §6.1).

Corpus and class imbalance. Phishing dominates; mobile-money and advance-fee are the minority classes, which is the root cause of the bias discussed below:

![Corpus class, source and language distribution](docs/assets/ml/ml_class_distribution.png)

Model comparison. Of six models, the soft-voting ensemble wins at macro-F1 0.955, above the 0.943 TF-IDF with logistic-regression baseline:

![Macro-F1 by model on the test split](docs/assets/ml/ml_model_comparison.png)

Confusion matrix (deployed ensemble). It is strong on the diagonal in-distribution; the visible leakage is advance-fee predicted as phishing:

![Confusion matrix of the deployed soft-voting ensemble](docs/assets/ml/ml_confusion_matrix.png)

Re-balancing ablation. Class-weighting, over-sampling, and the combined strategy all converge to the same per-class recall, and none beats the others on the hard advance-fee class. This confirms that data, not the algorithm, is the limit:

![Per-class recall across re-balancing strategies](docs/assets/ml/ml_rebalance_ablation.png)

### 6.3 Where results fell short, and what the ML experiments showed

The 0.955 figure is in-distribution. The training corpus is class-imbalanced (phishing about 2,401, then
not-a-scam about 1,200, then mobile-money about 538, then advance-fee about 283), and the model inherits a
majority-class bias toward phishing. On out-of-distribution messages, genuine mobile-money and advance-fee
scams, and occasionally even a legitimate message, drift toward phishing at low confidence.

A controlled re-balancing ablation (a notebook testing four strategies: class-weighting, over-sampling,
under-sampling, and combined) found that the deployed class-weighting model was already the best
in-distribution, and that all four strategies failed the same out-of-distribution cases. That is the key
finding: re-balancing the existing data cannot create signal that is not there. The binding constraint is
the volume of authentic minority-class data, not the algorithm.

A separate finding concerns serving reliability. The model is hosted on a managed Space that sleeps when
idle, so the first request after idle could time out and the app would fall back to weaker keyword
heuristics. A warm-up ping (fired on app launch and when the scanner opens) plus longer timeouts fixed
this, so users see the model verdict rather than the fallback.

---

## 7. Discussion: why the milestones matter

- Because fewer than 20% of African cybercrime incidents are ever formally reported, the harder problem is
  not only detecting scams but giving people a low-friction way to report them. RethicsAI provides that
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
- Collect authentic minority-class data (mobile-money and advance-fee). This is the single biggest lever on accuracy, as the re-balancing ablation showed. A data-access request to a regional smishing-research network (CMU-Africa's Upanzi) is already in progress to source real English mobile-money scam messages.
- On-device inference: a quantised model for offline, private screening on low-connectivity networks.
- Multi-modal detection: images, link reputation, and voice notes.
- Consent-based escalation tiers: from helping the user act today to partnerships with operators and regulators.
- Community outreach: promote the app through telco and community-organisation channels where scam exposure is highest.

---

## 9. Repository map (related files)

```
Capstone-Project/
├── README.md                     ← this file (submission entry point)
├── mobile/rethicsai/             ← the RethicsAI Flutter app
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
(TF-IDF + e5 ensemble), Claude Haiku for the assistant, and 11 locales.

---

## 11. Demo video

**5-minute demo (core functionality):** _add link here_

> The video focuses on the core flows (scanning different messages, the verdict, reporting to authorities,
> the education hub, and the assistant) rather than sign-up or sign-in.
