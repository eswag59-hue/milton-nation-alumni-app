# Promo Asset Brief — Milton Nation Alumni App

**Hand this whole file to a fresh Claude Code session.** It contains everything needed to build promotional material for the app: brand, logos, app icon, color palette, where screenshots live (and how to get the missing ones), the source marketing copy, and a pointer to the originating chat. All paths are absolute so it works from any working directory.

---

## 1. What you're promoting

**Milton Nation** — a SwiftUI iOS app (App Store category: Health & Fitness) for **alumni of Milton Recovery Centers (FL) and Milton Jefferson (OH)**, two substance-use-disorder treatment facilities under parent **Milton Health Group LLC**. It's a peer recovery community: sobriety tracking, a community feed, an "I'm Struggling" crisis-support flow, peer chat, meetings, and care-team messaging.

**Tone:** warm, calm, hopeful, dignified. This is a recovery app — promo must be **tasteful and non-exploitative**. No stock "addiction" clichés, no real patient imagery, nothing stigmatizing.

**Brand naming nuance (important):**
- The **app** is branded **"Milton Nation"** — deliberately understated/brand-anonymous (a HIPAA-conscious choice: it avoids "Recovery"/SUD-program wording in public-facing surfaces like SMS).
- The **parent recovery brand** is **"Milton / Jefferson Recovery"** — that's what the logo SVGs in the brand kit say. Use the app icon + in-app "Milton Nation" wordmark as the **primary** app identity; the Jefferson Recovery wordmarks are the **parent** brand, fine for "by Milton Health Group" context.

---

## 2. Asset inventory (absolute paths)

### App icon
- `/Users/ezrabarishansky/Developer/Milton Nation Alumni App/Milton Nation Alumni App/Milton Nation Alumni App/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- (source variant) `/Users/ezrabarishansky/Developer/Milton Nation Alumni App/Milton Nation Alumni App/Milton Nation Alumni App/Assets.xcassets/AppIcon.icon/Assets/app 123.png`

### In-app logo / wordmark (use as primary app identity)
- Light: `/Users/ezrabarishansky/Developer/Milton Nation Alumni App/Milton Nation Alumni App/Milton Nation Alumni App/Assets.xcassets/MiltonLogo.imageset/milton_logo.png`
- Dark: `/Users/ezrabarishansky/Developer/Milton Nation Alumni App/Milton Nation Alumni App/Milton Nation Alumni App/Assets.xcassets/MiltonLogo.imageset/milton_logo_dark.png`

### Brand kit — the good stuff (vector logos + brand sheet + palettes)
Folder: `/Users/ezrabarishansky/Downloads/Milton-WarChest/00_BRAND/`
- `BRAND_SHEET.png` — one-look brand sheet
- `MILTON COLOR PALLATE.png`, `MILTON JEFF COLOR PALLATE.png` — color palettes
- `Milton - Jefferson Recovery Logo - RGB.svg` (vector logo)
- `Milton - Jefferson Recovery Logo - White Text - RGB.svg`
- `Milton - Jefferson Recovery Wordmark - RGB.svg`
- `Milton - Jefferson Recovery Wordmark - White - RGB.svg`
- Also: `/Users/ezrabarishansky/Downloads/Milton-WarChest/Milton-Social-Media-Handoff.pdf` (existing social handoff), `00_BRAND/_templates/` (templates)

### Loose logo exports (PNG wordmarks + zipped logo packs) in `~/Downloads/`
- `Milton - Jefferson Recovery Wordmark - RGB.ai (Logo).png` (and copies `(1)`–`(5)`)
- `Milton - Logos-20260617T184857Z-3-001.zip` (full logo pack — unzip for more formats)
- `Milton - Jefferson Recovery Wordmark - RGB.ai (Logo).zip`

### Existing motion asset (reference for style/pacing)
- `/Users/ezrabarishansky/Downloads/Milton-WarChest/02_WEEK-1/renders/WK1_TUE_brand-wall-reel.mp4`

---

## 3. Brand color palette (pulled from the live app code — these are exact)

**Primary**
- `#007396` — Milton teal-blue (signature / primary)
- `#165C7D` — deep teal · `#0093B2` — bright cyan · `#369DA0` — teal · `#56B093` — green

**Accent / neutral**
- `#D4EB8E` — lime accent
- `#101820` — ink / near-black · `#6B7280` — secondary gray
- `#F2F5F5` / `#E0E5E5` — light backgrounds

**Semantic**
- `#E74C3C` — alert red (crisis/error) · `#E8A838` — amber (warning/highlight)

Full color sets also live in the asset catalog: `…/Milton Nation Alumni App/Assets.xcassets/*.colorset/Contents.json` (AccentColor, AppBackground, CardBackground, TextPrimary/Secondary, etc.).

---

## 4. App Store screenshots — a finished set exists on iCloud Drive

A polished, captioned App Store screenshot set already exists (iCloud Drive):

**Base set (7 screens):**
`/Users/ezrabarishansky/Library/Mobile Documents/com~apple~CloudDocs/05_Projects/Milton/AppStoreScreenshots/MiltonAppStoreScreenshots/`
- `01_login.png` · `02_home.png` · `03_community.png` · `03_admin_dashboard.png` · `04_meetings.png` · `05_chat.png` · `06_profile.png`
- (`Dashboard` is a stray alias file — ignore it.)

**Device-sized sets (the App Store's two required sizes):**
`/Users/ezrabarishansky/Library/Mobile Documents/com~apple~CloudDocs/05_Projects/Milton/AppStoreScreenshots/AppStore-Screenshots-additional/`
- `6.9"/` — 6.9-inch (Pro Max class): `01_login` · `02_home` · `03_community` · `04_meetings` · `05_chat` · `06_profile`
- `6.1"/` — 6.1-inch: same six

**⚠️ Quality caveats before you use these — read this:**
- They were shot from the **ADMIN account in "User View"** — they say *"Welcome back, admin," "Admin User," "admin@milton.com," "0 Days of Recovery,"* and several show a floating **"Back to Admin"** pill. That's staging-looking; don't use as-is for hero marketing.
- The in-app **logo currently has the brand color-palette swatches baked into it** (a brand-sheet export shipped as the logo), so it appears in every header. A clean-logo fix + re-shoot is planned.
- They're dated **April** (older build) and don't include the **"I'm Struggling" crisis sheet** or **sobriety tracker**.

**Preferred source:** fresh captures from Build 13 logged in as **Alex Demo** (`appreviewer@miltonrecovery.com`, a real FL alumni with 90 days sobriety) in normal user mode (no "Back to Admin" pill, real name, real streak). Build is on Ezra's iPhone — he can re-shoot on request. Until then, the April set is usable for layout/structure reference only.

(Ignore the loose `Screenshot 20xx-…png` files in `~/Downloads/` — those are Twilio/console captures, not app screens.)

---

## 5. Marketing copy & positioning (source material)

In the repo at `/Users/ezrabarishansky/Developer/Milton Nation Alumni App/Milton Nation Alumni App/launch-kit/`:
- `04-app-store-connect-content.md` — App Store listing copy (name, subtitle, description, keywords)
- `09-copy-bank.md` — reusable copy / taglines
- `APP-PRIVACY-POLICY-SPEC.md`, `TERMS-OF-SERVICE-SPEC.md` — for legal footers if needed

---

## 6. "Link to this chat" — read this honestly

There is **no shareable web URL** for the originating Claude Code conversation — it's a local CLI session, not a hosted chat, so I won't hand you a link that doesn't exist. What *does* exist is the on-disk transcript, which a local Claude Code session can read directly:

- Session transcript folder: `/Users/ezrabarishansky/.claude/projects/-Users-ezrabarishansky-aaa/`
- The **most recently modified `.jsonl`** in that folder is the originating conversation (at time of writing: `addbb3e8-b9b6-4044-bb3a-efee3fb7b7f9.jsonl`). If unsure, sort by modified time and take the newest.

Other authoritative context to "find whatever you want":
- **App repo:** `/Users/ezrabarishansky/Developer/Milton Nation Alumni App/Milton Nation Alumni App/` (GitHub `eswag59-hue/milton-nation-alumni-app`)
- **Project handoff:** `…/launch-kit/HANDOFF-2026-06-16.md`
- **Persistent project memory:** `/Users/ezrabarishansky/.claude/projects/-Users-ezrabarishansky-aaa/memory/project_milton_nation.md`

---

## 7. Suggested deliverables (pick with Ezra — don't assume)

A "promo" could mean several things. Confirm scope, then build:
- **App Store screenshots** (6.7" + 6.1" sizes) with caption overlays on-brand
- **Social launch cards** (square + story) — "Now on the App Store"
- **Short promo video / reel** (15–30s) — match the pacing of the existing `WK1_TUE_brand-wall-reel.mp4`
- **One-pager / landing hero** for a marketing page

**Guardrails:** Milton Nation app identity primary; tasteful recovery tone; provide light + dark variants; use exact hex palette above; vector logos for any scaling.

---

*Brief generated 2026-06-22 from the live repo + brand kit. If an asset path 404s, the file may have moved — search `~/Downloads/Milton-WarChest/`, the repo's `Assets.xcassets/`, and `~/Downloads/` for `Milton`/`logo`/`brand`.*
