# RethicsAI — Design System (MASTER)

> Single source of truth for UI work. Both `flutter-ai-ui-skill` and `ui-ux-pro-max`
> follow this file. Page-specific deviations live in `design-system/pages/<page>.md`
> and override this file for that page only.

**Product:** cybercrime reporting + scam scanner, Africa-first mobile (Flutter, Material 3).
**Personality:** trustworthy, warm, professional, calm-under-crisis — **not** playful, not
corporate-cold. Brand identity is the **African earth-tone palette** (decided; keep it).

---

## 1. Color tokens (source: `lib/core/themes/app_theme.dart`)

Brand colors are intentionally constant across light/dark (they are the brand). Surfaces
and text adapt via `ColorScheme` in `darkTheme`. **Never** put a raw `Color(0xFF…)` in a
widget — reference a token (`AppTheme.*`, the `EarthColors` ThemeExtension, or
`Theme.of(context).colorScheme.*`).

| Role | Token | Hex | Use for |
|------|-------|-----|---------|
| Primary | `primaryColor` | `#2D1B14` | Primary actions, app-bar text, brand |
| Secondary (amber) | `secondaryColor` | `#CC8800` | **Accents/fills/icons only** (see contrast rule) |
| Amber text | `amberText` *(new)* | `#7A5C00` | Amber-colored **text** on light surfaces (AA-safe) |
| Accent | `accentColor` | `#9CAF88` | Acacia green tertiary |
| Error | `errorColor` | `#CD5C5C` | Errors, destructive |
| Success | `successColor` | `#388E3C` | Safe/verified verdicts |
| Warning | `warningColor` | `#D4A574` | Caution verdicts |
| Info | `infoColor` | `#1976D2` | Scanner / informational |

### Contrast rule (CRITICAL — WCAG AA)
- `secondaryColor` `#CC8800` on white = **2.96:1 → FAILS** 4.5:1 for text.
  `secondaryDark` `#B8860B` = 3.26:1 → only OK for **large text / UI glyphs (3:1)**.
- ✅ Amber for **fills, borders, icons, chips** (≥3:1 met).
- ✅ Amber **text** on light → use `amberText` `#7A5C00` (~6:1).
- ✅ Body/long text → `primaryColor` / `onSurface`, never gray-on-gray.

---

## 2. Spacing / radius / sizing (already defined — use these, no magic numbers)
- Spacing: `spacingXS 4 / S 8 / M 16 / L 24 / XL 32 / XXL 48` (8pt rhythm).
- Radius: `radiusXS 4 / S 8 / M 12 / L 16 / XL 20 / XXL 24`.
- Icon: `iconSizeS 16 / M 24 / L 32 / XL 48`.
- Elevation: `elevationS 2 / M 4 / L 8 / XL 12`.
- **Touch targets ≥ 44×44** (use `hitSlop`/padding when the glyph is smaller).

## 3. Typography
- Family: Poppins (`GoogleFonts.poppinsTextTheme`). Full M3 scale defined in `lightTheme`.
- Weight hierarchy: headings 600–700, labels 500, body 400. Body ≥ 16px on mobile.

## 4. Motion
- Micro-interactions 150–300ms; transitions ≤ 400ms. `easeOut` enter, `easeIn` exit.
- Motion must convey cause→effect, not decoration. **Respect reduced-motion** (gate the
  gradient/animation flourishes behind `MediaQuery.disableAnimations`).

---

## 5. Component rules (from flutter-ai-ui-skill + ui-ux-pro-max)
- **Loading:** shimmer/skeleton when > 300ms — never a bare spinner in a card or an empty box.
- **Error states:** icon + cause + recovery action (retry). Errors announced (`Semantics`/`role:alert`), not color-only.
- **Empty states:** helpful message + next action, never a blank region.
- **Navigation:** prefer M3 `NavigationBar`; bottom nav ≤ 5 top-level items; highlight active item; predictable back (`PopScope`).
- **Forms:** `Form` + `GlobalKey`; visible labels (not placeholder-only); error below the field; validate on blur.
- **Icons:** one family, consistent stroke; no emoji as structural icons; ≥3:1 contrast.
- **Lists:** `ListView.builder` for >10 items.
- **State:** check `mounted` before using `BuildContext` after `await`. `const` constructors everywhere possible. Extract build methods > ~80 lines.

## 6. Verdict color semantics (trust-critical — scanner)
- **Scam / threat** → `errorColor`. **Caution / low-confidence** → `warningColor`.
  **Safe / not-a-scam** → `successColor`. **Informational** → `infoColor`.
- Verdict must not rely on color alone — pair with icon + text label.

## 7. Anti-patterns to avoid
- Raw hex in widgets · amber text on white · gray-on-gray body · emoji icons ·
  decorative-only motion · bare spinners · placeholder-only labels · touch targets < 44 ·
  color-only meaning · blocking input during animation.
