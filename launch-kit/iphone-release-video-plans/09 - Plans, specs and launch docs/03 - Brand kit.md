# Milton Nation — Brand Kit for Video Production

Everything Higgsfield (or any video/design tool) needs to stay on-brand. All values are pulled from the live app code (`Theme/AppTheme.swift`, `Assets.xcassets`) — they are exact, not approximations.

---

## 1. Identity & naming (get this right in every video)

| Thing | Name | Notes |
|---|---|---|
| The app (public identity) | **Milton Nation** | Deliberately understated — a HIPAA-conscious choice. Never say "Milton Recovery app" in public-facing ads. |
| App Store listing name | **Milton Nation Alumni** | Subtitle: "Recovery support for alumni" |
| Parent recovery brand | **Milton / Jefferson Recovery** | Fine for "by …" context, not the app's identity |
| Legal entity | **Milton Health Group LLC** | Legal footers only |
| Florida facility | **Milton Recovery Centers** 🌴 | Team name in-app: "Milton Team Florida" |
| Ohio facility | **Milton Jefferson** 🌻 | Team name in-app: "Milton Team Ohio" |

**Audience gate (say it in every announcement):** the app is exclusively for **verified alumni** of Milton Recovery Centers (FL) and Milton Jefferson (OH). Accounts require admin approval. It is free.

---

## 2. Color palette

### Brand palette (the 7-swatch Milton ribbon, in order)

| # | Hex | Pantone | Name / use |
|---|---|---|---|
| 1 | `#101820` | Black 6 C | Ink — primary dark, headlines, dark backgrounds |
| 2 | `#165C7D` | 7700 C | Deep Teal — header gradients, depth |
| 3 | `#007396` | 633 C | **Milton Teal — THE signature color.** Accent, buttons, links, tab tint |
| 4 | `#0093B2` | 632 C | Bright Cyan — "Support" category, energy |
| 5 | `#369DA0` | 6137 C | Sea Teal — secondary accents |
| 6 | `#56B093` | 2459 C | Sage Green — "Wins" category, growth |
| 7 | `#D4EB8E` | 372 C | Lime — "Gratitude" category, the pop/highlight color |

### Semantic colors

| Hex | Use |
|---|---|
| `#E74C3C` | Crisis / "I'm Struggling" red — use ONLY for crisis UI, never decoration |
| `#E8A838` | Amber — "Struggles" category, warnings |
| `#F2F5F5` | Light app background |
| `#FFFFFF` | Card background (light) |
| `#E0E5E5` | Dividers (light) |
| `#101820` / `#6B7280` | Text primary / secondary (light) |

### Dark mode (the app fully supports it — shoot both)

| Token | Dark value |
|---|---|
| Background | `#101820` |
| Card | `#1C242D` |
| Sheet surface | `#162633` (teal-tinted, never pure black) |
| Divider | `#333840` |
| Text primary / secondary | `#F2F5F5` / `#999EA8` |
| Crisis surface | `#4A1C19` |

### Gradients (used in the app — reuse in motion graphics)

- **Header gradient:** `#101820 → #165C7D`, top-left → bottom-right
- **Brand ribbon:** all 7 brand colors, left → right (the signature Milton stripe)
- **Sobriety glow:** `#0093B2` @ 15% → `#369DA0` @ 15%

### Category color-coding (feed)

Wins `#56B093` · Struggles `#E8A838` · Support `#0093B2` · Gratitude `#D4EB8E` · General `#6B7280`

---

## 3. Typography

- **In-app font: SF Pro** (Apple's system font — the app uses it exclusively; there is no custom font in the code). For video overlays on iOS-style content, use **SF Pro Display** (headlines) / **SF Pro Text** (body).
- **Cross-platform / Higgsfield stand-in:** **Inter** is the closest freely-licensed match if SF Pro isn't available in the tool.
- **The wordmark is custom lettering** (elegant, high-contrast, lowercase "milton"). **Never re-typeset it — always place the logo file.** The sub-line "Milton Nation Alumni" under the wordmark is a clean, wide-tracked geometric sans.
- The authoritative brand-font spec lives in `BRAND_SHEET.png` in Ezra's brand kit (`~/Downloads/Milton-WarChest/00_BRAND/` on Ezra's Mac) — check it before buying/licensing any display font.

**Type hierarchy for videos:** big statements in SF Pro Display Bold, tight leading, sentence case (the app's voice is sentence-case, not SHOUTING); body/captions SF Pro Text Regular; numbers (day counts) get the hero treatment — huge, Milton Teal or white.

---

## 4. Logos & marks (files + rules)

### In this repo (`Milton Nation Alumni App/Assets.xcassets/`)

| File | What it is | Use on |
|---|---|---|
| `MiltonLogo.imageset/milton_logo.png` | Black "milton" wordmark + "Milton Nation Alumni" sub-line (2000×1320, clean — swatch bar removed) | Light backgrounds |
| `MiltonLogo.imageset/milton_logo_dark.png` | Same wordmark in white | Dark backgrounds |
| `AppIcon.appiconset/AppIcon.png` | App icon: white "m" on layered teal waves (1024×1024) | Icon moments, end-cards, avatar |
| `AppIcon.icon/Assets/app 123.png` | Icon source variant | Backup |

### On Ezra's Mac (vector masters — parent brand)

`~/Downloads/Milton-WarChest/00_BRAND/`: `Milton - Jefferson Recovery Logo - RGB.svg` (+ white-text variant), wordmark SVGs (+ white), `BRAND_SHEET.png`, palette PNGs, and `Milton-Social-Media-Handoff.pdf`. Existing motion reference: `~/Downloads/Milton-WarChest/02_WEEK-1/renders/WK1_TUE_brand-wall-reel.mp4` (match its pacing).

### Rules

1. App identity = **"milton" wordmark + app icon**. Jefferson Recovery marks = parent-brand context only ("from the team at Milton / Jefferson Recovery").
2. Clear space around the wordmark ≥ the height of the "m". Don't stretch, recolor, outline, or add effects.
3. On photos/video, put the white wordmark over a `#101820` or deep-teal scrim — never raw over busy footage.
4. The app icon's layered-wave motif (organic overlapping teal curves) is a **usable background pattern** for motion graphics — it's the brand's visual signature.

---

## 5. Voice & tone (from the app's copy bank)

Warm, calm, hopeful, dignified. This is a recovery app — promo must be tasteful and non-exploitative.

- **Direct, never clinical.** "You're approved" not "your application has been processed."
- **Recovery-first.** "Days sober," "streak" — not "abstinence period."
- **Warm, not saccharine.** "Welcome" beats "welcome to your healing journey."
- **Crisis copy is short + warm.** "Help is here. Tap to call."
- **Never** medical claims ("treatment," "cure," "diagnose") except naming licensed staff roles.

### Hard guardrails for ads

- No stock "addiction" clichés (no needles, bottles, dark alleys, head-in-hands).
- No real patient imagery, ever. AI-generated people are fine but must read as dignified everyday life, not "patients." If a person portrays a recovery story, add a small "Dramatization" disclaimer.
- Only **demo accounts** on screen (Alex Demo, Dana Case, Dr. Robin Nova, Jordan Test…). Zero real names, numbers, or PHI.
- Crisis resources shown in-app (988, 741741, SAMHSA) may appear in footage — treat those frames with respect, no fast-cut glitch effects over them.
- Age rating is 17+; keep ad placements consistent with that.

---

## 6. The facts (for announcement/hype scripts — all true, all verifiable in-repo)

- The official alumni app of Milton Recovery Centers (Florida) and Milton Jefferson (Ohio).
- **Sobriety tracker** with milestone badges (tiers Seedling → Legend).
- **Private, moderated community feed** — Wins, Struggles, Support, Gratitude.
- **Secure 1-on-1 care-team chat** with your assigned counselor, therapist, or case manager.
- **Meeting finder** — AA, NA, SMART Recovery via a live meetings database, plus Milton's own meetings, RSVP included.
- **"I'm Struggling"** — one tap to 988, Crisis Text Line 741741, SAMHSA 1-800-662-4357, Milton FL (844) 406-4325 / OH (740) 715-4673, and a "notify my care team" option; the app can lock into a focused, chat-only mode.
- **Daily reflections** — a curated quote to start each day.
- **Built HIPAA-aware:** encrypted in transit and at rest, Face ID lock, screenshot & screen-recording protection, session timeout, audit logging, facility data isolation (Florida and Ohio never mix), and content moderation with automatic crisis escalation.
- Admin-approved membership — a private community of people who actually walked the same halls.
- Free. iOS first (App Store); Android is a roadmap item, not a current build.
- 249 automated tests pass on every change.

**Sensitive-claim rule:** say "HIPAA-aware" / "built to HIPAA standards," never "HIPAA-certified" (no such certification exists). Never promise 24/7 crisis response by Milton staff — the app itself says "not an emergency service; call 988/911."
