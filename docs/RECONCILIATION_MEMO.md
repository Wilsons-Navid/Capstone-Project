# Phase 0 Reconciliation Memo — Capstone Scope vs. Built Reality

**Author:** Wilsons Navid Wado Tiwa
**Date:** 2026-05-05
**For:** Capstone supervisor — first meeting
**Decision required by:** end of Sprint 1 (Day 7)
**Length:** read in ~10 min
**Capstone window:** **2 months**, target completion ~2026-07-05 (8 weeks / 56 days)

---

## 1. Purpose

The Pre-Capstone proposal (`docs/coursework/Major-assesment/`) and the working app at `mobile/rethicsai/` diverge in three load-bearing ways. Two new threads you raised — **deepfakes** and the **CMU Africa Upanzi Network** work on mobile money scams — are not yet incorporated anywhere. This memo:

1. States the gap honestly.
2. Proposes a single reframing that resolves all three divergences and absorbs both new threads.
3. Asks for sign-off on five specific decisions before Phase 1 begins.

I am asking for sign-off so I can stop asking the same scoping questions every week and spend the next eight weeks on ML research, not on rewriting plans.

---

## 2. What the proposal locked in

| Element | Proposal commitment |
| --- | --- |
| Pilot scope | Lagos, Nigeria + Douala, Cameroon (50–100 users) |
| Languages | English, French, Pidgin English (3) |
| Scam categories | 5: advance-fee fraud, mobile money fraud, phishing, romance scams, identity theft |
| ML approach | Custom Scikit-learn / TensorFlow classifier trained on West African data |
| ML target | ≥85% classification accuracy |
| Risk-assessment SLA | ≤30 seconds via Firebase Cloud Function |
| Educational content | ≥20 articles in EN / FR / PCM |
| Sample size | 50–100 users; 10–15 semi-structured interviews; SUS questionnaire |

## 3. What the app actually is, today

| Element | Built reality |
| --- | --- |
| Name | Rethicssec (folder still says rethicsai), v1.0.2+3 |
| Positioning | "Cybersecurity Platform for Africa" — pan-African |
| Languages | 11 — en, sw, fr, ar, ha, yo, ig, zu, xh, af, sawa (Duala) |
| Features built | auth, dashboard, ai_assistant, incidents, cases, education, scanner, emergency, notifications, settings, admin |
| AI/ML layer | **Vertex AI Gemini 1.5 Flash** + **OpenAI GPT-4o-mini** via Firebase Cloud Functions |
| Custom-trained model | None |
| Measured accuracy | None |
| Fixed scam taxonomy in code | None — open-ended LLM threat analysis |
| Production state | Privacy Policy finalised, Play Store assets ready |

## 4. The gaps, scored by risk

| # | Gap | Severity | Why it matters for the defense |
| --- | --- | --- | --- |
| **G1** | Custom ML model promised but absent | **Critical** | Without it, "AI-powered" in the title is delivered entirely by third-party APIs. No evaluation, no accuracy claim, no contribution to the West African ML literature. |
| **G2** | Pilot scope (Lagos+Douala) vs. app positioning (pan-African) | High | Pilot data will only validate two cities; broader claims will be unsupported by evidence. |
| **G3** | 3 languages promised, 11 in app | Medium | More features than I can rigorously evaluate; risk of shallow multilingual claims. |

---

## 5. New threads raised by the supervisor

### 5.1 Deepfakes

You raised this as a current threat vector. Two facts to hold:

- **Operationally:** AI-generated voice (vishing 2.0), video (romance/sextortion), and image (fake KYC docs) attacks are now in the wild against African mobile money users. Voice cloning targeting M-Pesa / MTN MoMo confirmations has been reported across East Africa.
- **For this capstone:** detecting deepfakes is a different ML problem from classifying scam *text*. It would require audio/video models (e.g., Wav2Vec2 for voice spoofing detection, or a CNN/transformer for face-swap detection). That's a separate research thread, not a tweak.

**Recommended posture:** treat deepfakes as a **modular extension**, not a pivot. Concretely:

1. Add a 6th category — `synthetic_media_fraud` — to the taxonomy in `ml/src/dataset.py`. Even text-only classifiers can pick up the giveaway language ("listen to this voice note from your son"). This is cheap.
2. Add one focused chapter in the dissertation on the deepfake threat landscape in Africa, citing recent voice-cloning incidents, and frame deepfake-modality detection (audio/image) as **Phase 5 / future work**.
3. Optionally, prototype a single deepfake-aware *user feature* in the app: a "this audio looks AI-generated" warning using an off-the-shelf detector (e.g., Resemble Detect API or a Hugging Face audio anti-spoofing model). One feature, one screen — not a third research thread.

This costs ~1 week of extra work, gives the dissertation a 2026-current angle, and keeps the project shippable.

### 5.2 CMU Africa Upanzi Network — mobile money scam research

This is the **single highest-leverage thread** in this entire memo. The Upanzi Network at CMU-Africa (Kigali) has been running exactly the kind of research my project assumes. Specifically:

- **Lamptey, Gueye, Luhanga, Seidu, Sowon (2024)** — *"A honeynet infrastructure to battle SMS scammers"* — built an inexpensive honeynet that actively collects smishing messages from scammers. Their dataset spans **Rwanda, Botswana, Ghana, Kenya, and Uganda**. ([CMU-Africa news, Oct 2024](https://www.africa.engineering.cmu.edu/news/2024/10/10-smishing.html))
- **Sowon et al. (2024)** — *"The Role of User-Agent Interactions on Mobile Money Practices in Kenya and Tanzania"*, presented at **IEEE Symposium on Security & Privacy (S&P) 2024**. 72 interviews with MoMo users. ([CyLab](https://www.cylab.cmu.edu/news/2024/07/10-navigating-digital-financial-inclusion-in-africa.html))
- **Mitigating Mobile Money Services Frauds in Rwanda (2022)** — CMU-Africa authors. ([ResearchGate](https://www.researchgate.net/publication/364959459_Mitigating_Mobile_Money_Services_frauds_in_Rwanda))
- **Security Gaps in the Mobile Money System in Rwanda: Challenges, Risks and Mitigation (2024, Springer)** — found that the dominant attack types are SMishing, identity theft, phishing, and authentication attacks. ([Springer](https://link.springer.com/chapter/10.1007/978-3-031-62277-9_42))

**Implications for this capstone:**

1. The Upanzi honeynet is, in effect, a working solution to my **single biggest risk — labelled scam data**. Their dataset is exactly the input my classifier needs.
2. I should **email Assane Gueye and Karen Sowon** in week 1 of Phase 1 with a one-paragraph collaboration request: introduce the project, explain the comparative ML study, ask whether the honeynet dataset is shareable for academic use (with proper attribution). Worst case: no reply. Best case: I get real-world West/East African smishing data and a reference.
3. The Sowon S&P 2024 paper supersedes parts of my literature review (Chapter Two of the dissertation will need to cite it — currently my closest precedent is Chieloka & Ugwu 2021, which is much weaker).
4. The Rwanda findings (SMishing + identity theft + phishing + authentication attacks) corroborate four of my five categories. This *strengthens* the proposal's choice of categories with peer-reviewed evidence I can cite.

**Recommended posture:** treat CMU-Africa as a **reference institution** for this project. Cite their work in the lit review, attempt the data collaboration, and explicitly position my contribution as "victim-facing application + comparative ML evaluation, complementing the Upanzi Network's scam-collection infrastructure."

---

## 6. Proposed reframing — one sentence

> **From:** "Build a custom ML classifier for West African scam detection."
> **To:** "Compare API-based LLMs against classical ML baselines for multilingual scam classification across the five categories in West Africa, deploy the chosen approach in a pilot mobile app in Lagos and Douala, and treat deepfake-modality detection as a modular extension."

This single reframing resolves all three gaps (G1–G3) **and** absorbs both new threads:

| Element | How the reframing handles it |
| --- | --- |
| G1 — missing custom ML | Classical baselines are the contribution; LLMs become the comparison arm, not the deliverable |
| G2 — scope creep | Pilot stays Lagos+Douala; pan-African app is acknowledged as deployment infrastructure but not the unit of evaluation |
| G3 — 11 langs vs 3 | Evaluation focuses on EN/FR/PCM; other 8 languages remain in the app as production features but are out of scope for accuracy claims (with a note in the dissertation explaining why) |
| Deepfakes | Added as 6th category for text-only detection of "voice note" / "video call" lures; full audio/visual detection deferred to future work |
| CMU Africa | Upanzi work cited in lit review; honeynet dataset pursued in Phase 1 week 1; project positioned as complementary, not competing |

## 7. Five decisions I need from you

| # | Decision | My recommendation | Tick |
| --- | --- | --- | --- |
| **D1** | Adopt the LLM-vs-classical comparative reframing as the core ML contribution? | Yes | ☐ |
| **D2** | Lock pilot scope at **Lagos + Douala only**, with all broader app coverage labelled "deployment infrastructure" in the dissertation? | Yes | ☐ |
| **D3** | Add `synthetic_media_fraud` as a 6th text-only category and defer audio/visual deepfake detection to Future Work? | Yes | ☐ |
| **D4** | Approve outreach to CMU-Africa Upanzi Network (Gueye, Sowon, Lamptey) for academic data-sharing collaboration? | Yes | ☐ |
| **D5** | Update the 5 SMART objectives in Chapter One (`docs/Unit_One_Draft - Copy.docx`) to match the reframing — specifically replacing Objective 2 ("≥85% accuracy with custom classifier") with a comparative-evaluation objective? | Yes | ☐ |

If any answer is *no*, the rest of the year's plan changes materially. We should resolve this in the first meeting.

---

## 8. Compressed 2-month sprint plan (post-reframing)

The original proposal assumed 6 months. We have 2. The app is already built, so most of that compresses cleanly. The pilot is the main scope cut.

| Sprint | Days | Focus | Exit gate |
| --- | --- | --- | --- |
| **S1 — Foundation** | 1–7 | This memo, supervisor sign-off, CMU outreach email sent, codebase recovery (6-month dormancy), ML venv, public datasets pulled (APWG / UCI SMS Spam / Kaggle phishing), PII masking, first labelled set (~500 examples) | TF-IDF + LR baseline running end-to-end; D1–D5 signed off |
| **S2 — ML core** | 8–14 | Random Forest baseline; LLM zero-shot eval for both Gemini 1.5 Flash and GPT-4o-mini; per-language confusion matrices on EN / FR / PCM; error analysis; dataset card + model cards | 3-approach comparison table on held-out test set in `ml/reports/` |
| **S3 — App + pilot prep** | 15–21 | Lock 6-category taxonomy in `analyzeSuspiciousContent`; log every classification (model, prompt, latency, output) to Firestore; deepfake-aware UI warning; consent forms, interview guide, recruitment plan, IRB submission if needed | Scanner emits structured incidents tagged with category + confidence + model; pilot kit ready |
| **S4 — Pilot launch** | 22–35 | Pilot in **one city only, 15–25 users** (down from 50–100 across 2 cities); SUS + Firebase analytics flowing; 5–8 mid-pilot semi-structured interviews | Pilot wraps with usable data |
| **S5 — Analysis + writing** | 36–49 | SUS scoring, thematic analysis (Braun & Clarke), on-pilot ML accuracy via expert relabelling; draft dissertation chapters 4 (Results) and 5 (Discussion) in parallel | All analysis done; chapters 4–5 drafted |
| **S6 — Submit + defend** | 50–56 | Polish, demo video, defense rehearsal | Submitted, defended |

### What this compression cuts vs. the original 6-month proposal

| Cut | Original | Compressed |
| --- | --- | --- |
| Pilot users | 50–100 | 15–25 |
| Pilot cities | 2 (Lagos + Douala) | 1 (whichever I can physically access) |
| Pilot duration | 8–10 weeks | 2 weeks |
| ML baselines | 4 (TF-IDF×3 + transformer) | 2 (TF-IDF + LR; TF-IDF + RF) |
| Transformer fine-tuning | Yes (XLM-R / AfroXLMR) | **Cut** — too expensive in time |
| CMU-Africa data dependency | Plan assumed this | Send the email; assume **no reply in time** |
| Interviews | 10–15 | 5–8 |

### Implication for D2 (pilot scope decision)

D2 in §7 originally said "Lock pilot to Lagos + Douala only." With the 2-month constraint, **D2 needs to be revised: pilot in ONE city only**. I will confirm which city in Sprint 1 based on what's physically accessible. The other city is documented as future work.

---

## 9. What this memo does NOT propose to change

- The mixed-methods research design in Unit 4 (still appropriate)
- The annotated bibliography (will be extended, not redone — adding ~5 CMU-Africa citations and ~3 deepfake citations)
- The Pre-Capstone proposal's literature review themes (still hold)
- The Flutter + Firebase tech stack (correct choice)
- The Pre-Capstone proposal as a whole — it remains the foundation document; this memo is an addendum

---

## 10. Key references introduced by this memo

- Lamptey, B. O., Gueye, A., Luhanga, E., Seidu, M., & Sowon, K. (2024). *A honeynet infrastructure to battle SMS scammers.* CMU-Africa Upanzi Network. https://www.africa.engineering.cmu.edu/news/2024/10/10-smishing.html
- Sowon, K., et al. (2024). *The Role of User-Agent Interactions on Mobile Money Practices in Kenya and Tanzania.* IEEE Symposium on Security & Privacy (S&P 2024). https://www.cylab.cmu.edu/news/2024/07/10-navigating-digital-financial-inclusion-in-africa.html
- *Mitigating Mobile Money Services Frauds in Rwanda* (2022). CMU-Africa. https://www.researchgate.net/publication/364959459_Mitigating_Mobile_Money_Services_frauds_in_Rwanda
- *Security Gaps in the Mobile Money System in Rwanda: Challenges, Risks and Mitigation* (2024). Springer. https://link.springer.com/chapter/10.1007/978-3-031-62277-9_42
- CyLab-Africa initiative — joint CMU CyLab + CMU-Africa. https://africa.engineering.cmu.edu/research/cybersecurity/cylab/index.html
- Upanzi Network at CMU-Africa. https://www.africa.engineering.cmu.edu/research/upanzi/index.html
