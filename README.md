# RethicsAI — AI-Powered Scam Detection & Cybercrime Reporting for Africa

**Author:** Wilsons Navid Wado Tiwa — BSc Software Engineering, African Leadership University
**Product:** RethicsAI mobile app (Flutter + Firebase + a custom Python ML scam classifier)
**Status:** Implementation & Testing milestone — deployed Android build available below.

RethicsAI turns the everyday question *“Is this message a scam?”* into an instant, explainable
verdict — then helps the user act on it: verify, block, and report to the right national authority.
It pairs a custom-trained scam classifier (not a wrapped LLM) with an education hub, an AI
assistant, and an authority-reporting directory covering 14 African countries.

**Why it matters — the reporting gap.** Cybercrime in Africa is chronically **under-reported**: INTERPOL
estimates that fewer than **20%** of incidents are ever formally logged, so the official statistics — and
the institutional response built on them — rest on a fraction of reality. At its core, RethicsAI is
**infrastructure that lowers the barrier to reporting**: it meets victims where the scam reaches them
(their phone, in their language), converts a confusing moment into a clear verdict, and routes a
structured report to the right authority in a single tap. Every report also enriches a regional scam
dataset the field currently lacks — so the platform helps close the reporting gap *and* the data gap at
once.

---

## 1. Deployed version — download & install (Android)

> **Direct APK download:**
> https://github.com/Wilsons-Navid/Capstone-Project/releases/download/v1.0.6/rethicsai-v1.0.6.apk
>
> **Release page:** https://github.com/Wilsons-Navid/Capstone-Project/releases/tag/v1.0.6

**Step-by-step install:**
1. On an Android phone, open the **direct APK link** above in a browser.
2. Tap **Download**; when it finishes, tap the file to open it.
3. Android may warn about **“Install from unknown sources”** — tap **Settings → Allow from this source** (normal for apps installed outside an app store).
4. If Google **Play Protect** shows a warning, tap **More details → Install anyway** (the build requests SMS-reading permissions, which Play Protect flags for sideloaded apps).
5. Open **RethicsAI**, create an account or sign in with Google, and you're in.

No desktop or developer tools are required to run the deployed app — just the APK.

---

## 2. Run / build from source (developers)

**Prerequisites:** [Flutter](https://docs.flutter.dev/get-started/install) 3.x, Android Studio or the Android SDK, a device/emulator.

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

The app ships with its Firebase configuration; no extra backend setup is needed to run it.

---

## 3. What the app does (core functionality)

| Feature | What it does |
|---|---|
| **Scanner** | Paste an SMS, email, URL, phone number or message → AI returns a **threat level + category + explanation**. |
| **Report to Authorities** | Country-aware directory (14 countries) of police / cyber-crime / financial-crime units — call, email, or report online with a pre-filled message. |
| **Incident Reporting** | Structured report with evidence upload, geolocation and priority. |
| **Case Tracking** | Status timeline for submitted cases. |
| **Education Hub** | Lessons (video + interactive) with gamification and certificates. |
| **Wilson AI Assistant** | Conversational cyber-safety Q&A (Claude Haiku). |
| **Notifications & Dashboard** | Real-time alerts; a personal security overview. |
| **Admin Console** | Manage authority contacts (add/edit/delete countries), moderate content, review cases. |
| **11 languages** | English, French, Swahili, Hausa, Yoruba, Igbo, Zulu, Xhosa, Afrikaans, Arabic, Duala. |

---

## 3.5 How it's built — two parts and their intersection

RethicsAI is **two engineered systems that meet at one screen.**

- **Part 1 — the mobile app** (`mobile/rethicsai/`): a Flutter / Material 3 client — the scanner UI,
  structured reporting, case tracking, education hub, Wilson assistant, admin console, the 14-country
  authority directory, and 11 languages — backed by Firebase (Auth, Firestore, Cloud Functions, FCM).
- **Part 2 — the ML system** (`ml/`): the research core — a hand-labelled four-class scam **corpus**, the
  training/evaluation **notebooks**, and the trained **classifier** (TF-IDF + multilingual e5 soft-voting
  ensemble) served behind a `/predict` API.
- **The intersection — the scanner.** This is where the two parts meet and where the project's thesis
  lives. A user pastes a message → the app's `ScamModelService` calls the model's `/predict` endpoint →
  the returned **category + confidence** is rendered in the verdict card. A **warm-up ping** fired on app
  launch keeps the hosted model responsive, so the live model verdict — not a keyword fallback — is what
  the user sees.

![RethicsAI architecture — the mobile app, the ML system, and the scanner that joins them](docs/assets/architecture.png)

### Try the model API directly

The scam classifier is hosted as a public Hugging Face Space — the same endpoint the app calls.

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

> The Space **sleeps when idle**, so the *first* request after a pause can take 30–90 seconds to wake the
> model (the app hides this with a warm-up ping). In the mobile app the URL is configurable via the
> `SCAM_MODEL_API` dart-define — e.g. `flutter run --dart-define=SCAM_MODEL_API=https://<your-space>.hf.space`.

---

## 4. Testing Results

> _Screenshots referenced below live in `docs/assets/` — add your captured images there._

### 4.1 Testing strategies

| Strategy | What it covers | How to run / evidence |
|---|---|---|
| **Automated unit tests** | Validation & sanitization logic (`SecurityUtils`), bundled authority-contacts data, theme tokens. | `cd mobile/rethicsai && flutter test` |
| **Automated widget tests** | Theme renders, `EarthColors` extension resolves, Material 3 enabled. | included in `flutter test` |
| **Manual / functional testing** | Core user flows: scan → verdict → report; dashboard; admin CRUD. | screenshots (§4.2) |

**Automated test run — all green:**

```text
$ flutter test
00:03 +36: All tests passed!
```

_(Screenshot slot: `docs/assets/test_run.png`)_

### 4.2 Functionality with different data values (the scanner)

The classifier returns one of four categories with a risk level. Capture a screenshot of each:

| Input (example) | Expected category | Expected verdict | Screenshot |
|---|---|---|---|
| “Congrats! You won ₦2,000,000 in the MTN promo. Send your BVN + ₦5,000 fee to claim.” | Advance-fee fraud | HIGH RISK | `docs/assets/scan_advance_fee.png` |
| “Your MoMo account will be blocked. Dial *123*PIN# now to verify.” | Mobile-money fraud | HIGH RISK | `docs/assets/scan_momo.png` |
| “Dear customer, your bank account is suspended. Click http://bit.ly/secure to reactivate.” | Phishing | HIGH RISK | `docs/assets/scan_phishing.png` |
| “Hi, are we still meeting at 3pm tomorrow?” | Not a scam | SAFE | `docs/assets/scan_safe.png` |

### 4.3 Performance on different hardware / software

Run the app on at least two configurations and record the result:

| Device / emulator | Android version | RAM | Result (launch, scan, report) | Screenshot |
|---|---|---|---|---|
| _e.g. Physical phone_ | _e.g. Android 14_ | _e.g. 8 GB_ | _smooth / acceptable_ | `docs/assets/perf_phone.png` |
| _e.g. Emulator (Pixel)_ | _e.g. Android 11_ | _e.g. 4 GB_ | _smooth / acceptable_ | `docs/assets/perf_emulator.png` |

---

## 5. Analysis — results vs. project objectives

### 5.1 What the proposal committed to vs. what was delivered

The proposal (Chapter 1) set three SMART objectives. The implementation **met or exceeded all three.**

| Proposal objective | Committed to | Delivered | Verdict |
|---|---|---|---|
| **Obj 1 — Corpus** | A labelled West African scam corpus of **≥ 500 incidents** across the typology. | **4,422** labelled messages across **4 classes** (advance-fee, mobile-money, phishing, not-a-scam), from Nazario, UCI-SMS, Mozambique & Mendeley smishing, regional news. | **Exceeded** (≈ 9× the target) |
| **Obj 2 — Platform** | Deploy a mobile platform integrating reporting + classification + risk assessment + education. | Flutter app **v1.0.6** with all four, plus assistant, admin console and 14-country authority reporting; installable APK. | **Exceeded** |
| **Obj 3 — Model comparison** | Compare **two classical baselines** (TF-IDF + logistic regression vs TF-IDF + random forest), per-category metrics. | Compared **six** models (the two baselines + e5-embedding LR/RF + soft-vote + stacking ensembles); deployed the soft-vote ensemble at **0.955** macro-F1. | **Exceeded scope** |
| Regional scope | Nigeria + Cameroon | Authority reporting for **14** countries | Exceeded |
| Language scope | English + French (Pidgin where possible) | App localised to **11** languages; corpus is English + Portuguese | Partly diverged |

**Honest deviations from the proposal:**
- Obj 3 was scoped as a *classical-only* two-baseline comparison. The delivered work went **beyond** it by adding multilingual e5 embeddings and ensembles. This strengthens the result, but the final report should frame the ensemble as an *extension* beyond the proposed classical baselines.
- The corpus language mix is **English + Portuguese** (from the Mozambique smishing set), not the English + French the proposal targeted; French / Pidgin coverage in the **model** remains thin, even though the **app** localises to 11 languages.

### 5.2 The ML analysis (figures from `ml/notebooks/`)

**Corpus & class imbalance** — phishing dominates; mobile-money and advance-fee are the minority classes (the root cause of the bias discussed below):

![Corpus class, source and language distribution](docs/assets/ml/ml_class_distribution.png)

**Model comparison** — of six models, the soft-voting ensemble wins at **macro-F1 0.955**, above the 0.943 TF-IDF + logistic-regression baseline:

![Macro-F1 by model on the test split](docs/assets/ml/ml_model_comparison.png)

**Confusion matrix (deployed ensemble)** — strong on the diagonal in-distribution; the visible leakage is advance-fee → phishing:

![Confusion matrix of the deployed soft-voting ensemble](docs/assets/ml/ml_confusion_matrix.png)

**Re-balancing ablation** — class-weighting, over-sampling and the combined strategy all converge to the same per-class recall; none beats the others on the hard advance-fee class, confirming that **data, not the algorithm, is the limit**:

![Per-class recall across re-balancing strategies](docs/assets/ml/ml_rebalance_ablation.png)

### 5.3 Where results fell short — and what the ML experiments showed

The 0.955 figure is *in-distribution*. The training corpus is **class-imbalanced** (phishing ≈ 2,401 ≫ not-a-scam ≈ 1,200 ≫
mobile-money ≈ 538 ≫ advance-fee ≈ 283), and the model inherits a **majority-class (phishing) bias**: on
out-of-distribution messages, genuine mobile-money and advance-fee scams — and occasionally even a
legitimate message — drift toward "phishing" at low confidence.

A controlled **re-balancing ablation** (a dedicated notebook testing four strategies — class-weighting,
over-sampling, under-sampling, and combined) found that the deployed class-weighting model was already
the best in-distribution, and that **all four strategies failed the same out-of-distribution cases.** That
is the key research finding: re-balancing the existing data cannot manufacture signal that isn't there —
the binding constraint is the **volume of authentic minority-class data**, not the algorithm.

A separate **serving-reliability** finding: the model is hosted on a managed Space that sleeps when idle,
so the first request after idle could time out and the app would silently fall back to weaker keyword
heuristics. This was fixed with a **warm-up ping** (fired on app launch and when the scanner opens) plus
longer timeouts — so the model verdict, not the fallback, is what users see.

---

## 6. Discussion — why the milestones matter

- **The deeper contribution is a reporting on-ramp.** Because fewer than 20% of African cybercrime
  incidents are ever formally reported, the binding societal problem isn't only *detecting* scams — it's
  the missing, low-friction path to *report* them. RethicsAI is infrastructure for that on-ramp: it turns
  reporting into something a non-technical victim can do in their language, in one tap, the moment it
  happens. Better reporting data is also what every downstream institutional response depends on.
- **Detection without action is half a solution.** The real impact of this milestone is not just a
  classifier that labels a message, but a product that closes the loop — turning a verdict into a
  one-tap report to a real authority in the user's country. That is the differentiator.
- **Owning the model matters.** Building a custom classifier (rather than calling a third-party LLM)
  means the intelligence is tuned to African scam vectors and languages, and every confirmed report
  can improve it — a data advantage competitors cannot copy by translating a UI.
- **A negative result with real value.** Proving that no re-balancing strategy fixes the
  out-of-distribution failures is itself a contribution: it redirects effort away from algorithmic
  tweaking and toward the thing that actually moves the needle — acquiring real, labelled, local scam
  data. Knowing *what won't work* saved the project from chasing a dead end.
- **Engineering reliability is part of the result.** A 0.955 model is worthless if the user sees a
  heuristic fallback because the service was cold. The warm-up fix is a reminder that for a deployed ML
  product, serving reliability matters as much as offline accuracy.
- **Trust is the product.** Accessibility and clarity decisions (verdicts shown by icon **and** colour
  **and** text, WCAG-AA contrast, 11 languages) are not cosmetic; for non-technical users they are the
  difference between guidance that is understood and guidance that is ignored.

---

## 7. Recommendations & Future Work

- **Confidence-aware verdicts:** surface model confidence and add an explicit “unsure — treat with
  caution” state to cut false positives and raise trust.
- **Collect authentic minority-class data** (mobile-money, advance-fee) — the single biggest lever on
  accuracy, as the re-balancing ablation showed. A data-access request to a regional smishing-research
  network (CMU-Africa's Upanzi) is already in progress to source real English mobile-money scam messages.
- **On-device inference:** a quantised model for offline, private screening in low-connectivity contexts.
- **Multi-modal detection:** images, link-reputation and voice-note analysis.
- **Consent-based escalation tiers:** from helping the user act (live today) to partnerships with operators and regulators.
- **Community guidance:** promote Rethics through telco and community-organisation channels where scam exposure is highest.

---

## 8. Repository map (related files)

```
Capstone-Project/
├── README.md                     ← this file (submission entry point)
├── mobile/rethicsai/             ← the RethicsAI Flutter app
│   ├── lib/                      ← app source (features/, core/, shared/)
│   ├── test/                     ← automated tests (flutter test → 36 passing)
│   └── design-system/MASTER.md   ← the design-system contract
├── ml/                           ← scam-classifier research (corpus, notebooks, serving)
├── docs/                         ← reports, assets/ (screenshots), templates
│   └── Rethics_Product_Brand_Report.docx
└── proposal/                     ← academic proposal workspace
```

---

## 9. Tech stack

Flutter (Dart) · Material 3 · Firebase (Auth, Firestore, Cloud Functions, FCM) ·
Python ML service (TF-IDF + e5 ensemble) · Claude Haiku (assistant) · 11 locales.

---

## 10. Demo video

**5-minute demo (core functionality):** _add link here_

> The video focuses on the core flows — scanning different messages, the verdict, reporting to
> authorities, the education hub and the assistant — rather than sign-up / sign-in.
