# RethicsAI — 5-Minute Demo Video Script (shot list)

**Goal:** demonstrate the *core* functionality under the rubric — different testing strategies,
different data values, and performance — in ~5 minutes. **Skip sign-up/sign-in** (the rubric says so).

---

## Before you hit record (2-minute prep)

- [ ] **Warm up the model first:** open the Scanner once and run any scan, wait ~30–60s. The ML Space
      sleeps when idle; warming it up means your demo scans show the **AI model verdict**, not the heuristic fallback.
- [ ] Have the **4 example messages** ready to paste (copy them from §2 below into a notes app on the phone).
- [ ] Sign in **before** recording so you can open straight onto the dashboard.
- [ ] Screen-record at portrait, clean status bar; speak slowly and clearly.
- [ ] Have a second device or emulator ready for the 20-second performance shot (or record it separately).

---

## The script (≈5:00 total)

| Time | On screen | Say this (narration) |
|---|---|---|
| **0:00–0:20** *(Hook)* | App icon / splash, then dashboard. | “This is RethicsAI — a scam-defence app for Africa. Across the continent, mobile-money, advance-fee and phishing scams cost everyday users real money. RethicsAI answers one question instantly: *is this message a scam?* — and helps you act on it.” |
| **0:20–0:35** *(Orientation)* | Dashboard: stats, feature grid. | “When I open the app I land on my dashboard — reports filed, cases resolved, threats blocked — and quick access to every tool.” |
| **0:35–2:05** *(CORE: Scanner — different data values)* | Tap **Scanner**. Paste each of the 4 messages, scan, and let the verdict appear. | “The heart of the app is the scanner. Let me test it with **different kinds of messages.**” Then for each: paste → “Here's an **advance-fee** scam… the AI flags it **HIGH RISK** and tells me *why*.” Repeat for **mobile-money**, **phishing**, and finally the **safe** message: “And a normal message comes back **SAFE** — so it doesn't cry wolf.” |
| **2:05–2:50** *(CORE: Report to authorities)* | On a scam result, scroll to **Report to authorities**. Open the **country dropdown** (show the full list). Tap **Call / Email / Report online**. | “A verdict isn't enough — RethicsAI helps me **act**. It shows the real cyber-crime and police units for my country — and I can switch country here; all 14 are covered. One tap calls them, emails a report, or opens the official portal, pre-filled.” |
| **2:50–3:20** *(Education hub)* | Open **Education**, show a lesson + gamification/progress. | “To stop the *next* scam, the education hub has short lessons, with progress and certificates — prevention, not just detection.” |
| **3:20–3:50** *(Wilson AI assistant)* | Open **Wilson**, ask: *“How do I know if a MoMo message is fake?”* Show the answer. | “And Wilson, the built-in assistant, answers cyber-safety questions in plain language, any time.” |
| **3:50–4:20** *(Admin — country management)* | Open **Admin → Emergency Contacts**. Tap **+**, choose **Add new country**, fill a couple of fields, save. | “For administrators, the whole authority directory is editable in-app — I can **add a brand-new country**, update it, or delete it, with no app update.” |
| **4:20–4:40** *(Testing strategies + hardware)* | Cut to a terminal showing `flutter test` → **All 36 passed**. Then a quick clip of the app running on a **second device/emulator**. | “On the engineering side: the app has an automated test suite — unit and widget tests — that passes green, and it runs smoothly across different Android devices.” |
| **4:40–5:00** *(Close: analysis + recommendation)* | Back to dashboard / app logo. | “So all three project objectives are met: a labelled scam corpus, a working detection-and-reporting platform, and a custom classifier at **0.955 macro-F1**. The next step is collecting more local scam data to push accuracy further. RethicsAI — know the scam, stop the scam.” |

---

## The 4 scanner inputs (copy these to the phone)

1. **Advance-fee:** `Congratulations! You have won 2,000,000 in the MTN promo. Send your BVN and a 5,000 activation fee to claim your prize now.`
2. **Mobile-money:** `Your MoMo account will be blocked today. Dial *123*PIN# now to verify your wallet and avoid suspension.`
3. **Phishing:** `Dear customer, your bank account has been suspended. Click http://bit.ly/secure-restore to reactivate immediately.`
4. **Safe:** `Hi, are we still meeting at 3pm tomorrow at the office?`

---

## Rubric mapping (so nothing is missed)

| Rubric item | Covered by |
|---|---|
| Different **testing strategies** | 4:20 shot — `flutter test` (unit + widget) + manual functional walkthrough |
| Different **data values** | 0:35–2:05 — four different scanner inputs → four verdicts |
| **Performance on different hardware/software** | 4:20 shot — app on a second device/emulator (also fill the README matrix) |
| **Analysis** vs objectives | 4:40 close — Obj 1/2/3 recap |
| **Recommendation / future work** | 4:40 close — “collect more local scam data” |

> Keep total length **at or under 5:00.** If you run long, trim the Education and Wilson shots to ~15s each.
