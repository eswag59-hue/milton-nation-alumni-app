# Ezra's Checklist — Video Portfolio Production

Your personal to-do list, in order. Everything Claude could do from the repo is done; this is the part that needs your hands (your Mac, your Higgsfield account, your sign-off).

---

## Step 1 — Get the kit (5 min)

- [ ] Merge (or check out) branch `claude/app-launch-video-portfolio-p00gsx` — it contains this whole `launch-kit/video-portfolio/` folder **and the new DEBUG staff logins** you'll need for recording (`therapist@milton.com`, `case@milton.com`, `counselor@milton.com`).
- [ ] Skim `01-BRAND-KIT.md` once so the palette/voice is in your head.

## Step 2 — Gather the files Claude can't reach (10 min — they're on your Mac, not in the repo)

- [ ] From the repo: `Assets.xcassets/MiltonLogo.imageset/milton_logo.png` + `milton_logo_dark.png`, `Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- [ ] From `~/Downloads/Milton-WarChest/00_BRAND/`: `BRAND_SHEET.png`, both color-palette PNGs, and the 4 `Milton - Jefferson Recovery … RGB.svg` vector logos
- [ ] `~/Downloads/Milton-WarChest/02_WEEK-1/renders/WK1_TUE_brand-wall-reel.mp4` (pacing reference — upload to Higgsfield as a style reference)
- [ ] Apple's official **"Download on the App Store"** badge from developer.apple.com (App Store marketing resources page) — don't redraw it
- [ ] Drop everything in one folder: `~/Milton-Video-Kit/`

## Step 3 — Record (one focused session, ~2–3 hours)

Open `02-RECORDING-SHOT-LISTS.md` and go top to bottom:

- [ ] Part 0 setup: simulator + status-bar override + recording command
- [ ] Part 1 — Alumni clips (ALUM-01…10) · light mode
- [ ] Re-run ALUM-02 and ALUM-04 in dark mode
- [ ] Part 2 — Staff clips (as therapist, then quick re-takes as case manager + counselor)
- [ ] Part 3 — Admin clips (don't skip ADMIN-05, the announcement→home cut)
- [ ] Part 4 — Super admin clips (SUPER-01 facility switch is the money shot)
- [ ] Part 5 — Stills, light + dark
- [ ] Everything lands in `~/Milton-Video-Kit/recordings/`, named as in the shot list

## Step 4 — Higgsfield (the fun part)

- [ ] Upload the Step-2 assets + Step-3 clips
- [ ] Generate the brand motion library first (P-01 → P-06 in `04-HIGGSFIELD-PROMPTS.md`) — these get reused everywhere
- [ ] Generate b-roll (P-07 → P-12) and the type cards (P-13)
- [ ] Build the end-card once; save as a template
- [ ] Assemble per the recipes table (Section 4), scripts + VO lines from `03-VIDEO-SCRIPTS.md`
- [ ] Order to build in: **H-4 (15s) first** — it's the fastest full test of the pipeline — then H-1 anthem, A-2, A-1, H-2, H-3, then the six onboarding videos
- [ ] Export every ad in 9:16 AND 16:9 (+1:1 for feed); onboarding videos 16:9 + 9:16

## Step 5 — Before anything goes public

- [ ] Run the compliance checklist at the bottom of `04-HIGGSFIELD-PROMPTS.md` on every export
- [ ] Music: use Higgsfield/platform-licensed tracks only (no commercial songs without a license)
- [ ] Get clinical/leadership eyes on A-1 and anything showing the crisis flow
- [ ] Once the App Store listing is live, drop the real link into every caption + end-card QR (until then: "coming soon")

---

## ❓ Questions for you (answer whenever — the kit works either way)

1. **Store links (answered "live on both stores" 2026-08-25 — thank you):** send the App Store URL and the Google Play URL so captions, end-cards, and QR codes can carry real links — and point Claude at where the Android project lives for the Android recording set.
2. **Demo bypass:** since the app is live, is `DEMO_BYPASS_ENABLED` off in prod? (It should be.) If so, Path B recording uses real staff test accounts instead of code `000000`.
3. **Tagline:** the app's login screen says **"Driven by purpose. Committed to care."** Want that as the official campaign tagline, or should the videos lead with "Recovery is stronger together"? (Scripts currently use both, in different spots.)
4. **The brand display font:** the "milton" wordmark is custom lettering. If you know the font name (check `BRAND_SHEET.png`), tell Claude and it goes in the brand kit; until then videos use the logo files + SF Pro and never re-typeset the wordmark.
5. **Want a real on-device capture path?** If you'd rather record on your physical iPhone, Claude can add a DEBUG-only "marketing capture" toggle that disables the screen-recording block (mock data only, so no PHI exposure). Say the word.
