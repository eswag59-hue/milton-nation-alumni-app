# Milton Nation — Higgsfield Prompt Pack

Ready-to-paste prompts for every generated segment in the slate. Written tool-agnostic (they work in Higgsfield, Runway, Pika, Veo, or any text/image-to-video tool). Real app footage always comes from your screen recordings (`02-RECORDING-SHOT-LISTS.md`) — generation is for **brand motion, b-roll, and transitions**, never for faking app UI.

---

## 0. One-time workspace setup

**Upload these as reusable assets/ingredients** (see `05-EZRA-CHECKLIST.md` for where each file lives):

1. `milton_logo.png` (black wordmark) + `milton_logo_dark.png` (white wordmark)
2. `AppIcon.png` (white "m" on teal waves — also your style reference image)
3. The 7 brand colors as a swatch/style reference: `#101820 #165C7D #007396 #0093B2 #369DA0 #56B093 #D4EB8E`
4. Your best 6–8 screenshots (light + dark) from Part 5 of the shot list
5. Your screen-recording clips
6. (From your Mac) `BRAND_SHEET.png` + the vector SVG logos from `~/Downloads/Milton-WarChest/00_BRAND/` — vectors scale clean at any resolution

### 🎨 MASTER STYLE BLOCK — paste at the end of every prompt

```
Style: premium healthcare-tech brand film. Palette strictly: deep ink #101820,
deep teal #165C7D, signature teal #007396, cyan #0093B2, sea teal #369DA0,
sage green #56B093, lime accent #D4EB8E. Soft diffused morning light, calm
confident pacing, organic flowing curved shapes like layered ocean waves,
matte textures, subtle film grain, shallow depth of field. Warm, hopeful,
dignified. NOT: neon, glitch, fast strobe, corporate stock-footage look,
hospital/clinical imagery, alcohol, drugs, needles, pills, darkness/despair
clichés, sad people, rain-on-window melancholy.
```

### Aspect ratios to render

Master everything 16:9 4K where possible, and re-generate (not crop) hero shots in 9:16 for Reels/TikTok/Stories and 1:1 for feed. Minimum deliverables per ad: 9:16 + 16:9.

---

## 1. Brand motion library (reusable across ALL videos)

**P-01 · Wave-motif background loop (the workhorse — generate 3–4 variants)**
> Abstract slow-motion background: layered translucent silk-like waves flowing diagonally, colors shifting between deep teal #165C7D, teal #007396 and cyan #0093B2 on a near-black #101820 field, gentle continuous motion, seamless loop, no text, no objects. + STYLE BLOCK

**P-02 · Logo reveal (image-to-video from `AppIcon.png`)**
> Animate this app icon: the white "m" letterform draws itself in with a liquid ink stroke, the layered teal wave background slowly drifts, a soft lime #D4EB8E light sweep passes across once, then all motion settles to stillness. Elegant, 4 seconds, dark background. + STYLE BLOCK

**P-03 · Wordmark reveal (image-to-video from `milton_logo_dark.png`)**
> Animate this wordmark on a #101820 background: letters fade up one by one with a soft blur-to-sharp resolve, then the sub-line "Milton Nation Alumni" tracks gently outward into place. Minimal, calm, 3 seconds. + STYLE BLOCK

**P-04 · Brand ribbon transition**
> A thin horizontal band of seven colors (#101820, #165C7D, #007396, #0093B2, #369DA0, #56B093, #D4EB8E) sweeps across a white frame left to right as a wipe transition, leaving clean white behind. Crisp, 1 second. + STYLE BLOCK

**P-05 · Streak-counter macro**
> Extreme close-up of large elegant rounded numerals on a soft teal gradient card, the number counting up 1, 7, 30, 90, 365 with a gentle tick animation and a faint glow pulse on each landing, sans-serif similar to SF Pro, background #F2F5F5. + STYLE BLOCK

**P-06 · Phone-in-hand composite shell**
> A hand holds a modern smartphone in soft morning window light, screen glowing plain bright white (for screen replacement in edit), shallow depth of field, warm neutral home interior, no identifiable face, slow subtle handheld drift. + STYLE BLOCK

*(Drop your screen recording onto the white screen with corner-pin tracking — Higgsfield/CapCut both do this. This is how you get "lifestyle" shots without faking UI.)*

---

## 2. B-roll scenes (dignified recovery-life imagery — for A-2, H-1, H-2)

Rules: everyday dignity, never "patient" imagery. No faces in identifiable close-up (avoids "real patient" implication) — favor hands, silhouettes, over-shoulder, wide shots. Add a "Dramatization" caption in edit if a person enacts a recovery story.

**P-07 · Morning door** *(A-2 opener)*
> A front door of a warm modest home opens from inside toward golden sunrise light, seen over the shoulder of a person in casual clothes stepping out, lens flare kept soft, hopeful new-beginning mood. + STYLE BLOCK

**P-08 · Coffee + phone morning ritual** *(daily reflection beats)*
> Overhead shot: hands cradling a warm mug beside a smartphone on a wooden kitchen table in morning light, steam rising, a journal and pen nearby, calm unhurried morning ritual. + STYLE BLOCK

**P-09 · Walking forward** *(progress metaphor)*
> Slow tracking shot from behind: a person in everyday clothes walking steadily along a tree-lined sidewalk at golden hour, confident unhurried pace, sun flaring gently through leaves. + STYLE BLOCK

**P-10 · Group warmth** *(community beats)*
> A small circle of diverse adults in a bright community room, mid-laughter, folding chairs, coffee cups, seen wide from doorway distance so faces stay soft, genuine warmth, natural light. + STYLE BLOCK

**P-11 · 2am glow** *(H-3 only — handle with care)*
> A dark quiet bedroom at night, a person sitting on the edge of the bed lit only by the soft glow of the phone in their hands, face turned away from camera, calm rather than distressed, a faint warm teal cast from the screen. + STYLE BLOCK

**P-12 · Sunrise water** *(anthem closer)*
> Wide serene shot of calm ocean water at sunrise, gentle overlapping waves in teal and gold tones, horizon line low in frame, expansive hopeful sky. + STYLE BLOCK
*(Echoes the app icon's wave motif — this is the brand's landscape.)*

---

## 3. Kinetic type cards (for OST beats in H-1 / H-2 / H-3)

**P-13 · Type card template**
> Minimal kinetic typography on #101820: the phrase "{INSERT LINE}" in a clean bold geometric sans-serif similar to SF Pro Display, white text with one word highlighted in lime #D4EB8E, letters assemble with a soft rise-and-settle, subtle wave-pattern texture at 5% opacity behind. + STYLE BLOCK

Lines to render (one card each): `nobody recovers alone` · `we built a nation` · `every win, witnessed` · `your people, one tap away` · `help is here` · `Day 1` · `a whole nation behind you` · `2:04 AM` · `Recovery is stronger together`

---

## 4. Per-video assembly recipes (what to feed Higgsfield for each)

| Video | Generated segments | Real footage (from shot lists) | End-card |
|---|---|---|---|
| O-1 Alumni onboarding | P-02 open | ALUM-01…10 | iOS |
| O-2/3/4 Staff onboarding | P-03 open | STAFF-01…05 (role's own login) | iOS |
| O-5 Admin onboarding | P-03 open | ADMIN-01…07 | iOS |
| O-6 Super admin | P-03 + P-04 | SUPER-01…04 | iOS |
| A-1 Org announcement | P-01 bg, P-04 wipes, P-13 cards | montage of ALUM + STAFF + ADMIN heroes | iOS + "by Milton Health Group" |
| A-2 Community announcement | P-07, P-08, P-09, P-10, P-12 | ALUM-02, 04, 05, 07 (respectful frames) | iOS |
| H-1 Anthem 60s | P-01, P-05, P-12, P-13 set | fast cuts of everything | iOS |
| H-2 Every day counts 30s | P-05, P-08, P-09 | ALUM-02 streak + ALUM-04 milestone post | iOS |
| H-3 2am 15s | P-11, P-13 ("2:04 AM", "help is here") | ALUM-07 (modal only, no dialer) | iOS |
| H-4 Pocket blitz 15s | P-02 slam open | 6 × 1.5s feature cuts | iOS |

**End-card build (make once, reuse):** `AppIcon.png` centered on P-01 wave loop → wordmark below → Apple's official "Download on the App Store" badge (download from Apple's marketing-resources page — never redraw it) → legal line "Free for verified alumni of Milton Recovery Centers & Milton Jefferson." Android variant: swap badge for "Android — coming soon" until a Play listing exists.

**Voiceover:** if using Higgsfield/ElevenLabs-style TTS, direct it: *"warm, mid-30s-to-40s, unhurried, quietly confident, speaks like a trusted friend, slight smile, never announcer-y."* Both a male and a female read; pick per platform. All VO lines are in `03-VIDEO-SCRIPTS.md`.

**Captions:** always burn in. SF Pro/Inter Semibold, white with 40% #101820 backing pill, max 2 lines.

---

## 5. Compliance checklist before exporting ANY ad

- [ ] Only demo names visible (Alex Demo, Dana Case, Dr. Robin Nova, Jordan Test)
- [ ] No real phone numbers except the public crisis/support lines the app itself shows
- [ ] "HIPAA-aware," never "HIPAA-certified" · no "treatment/cure" claims
- [ ] Crisis frames: slow pacing, no glitch/strobe effects, never imply Milton staff are 24/7
- [ ] AI-people scenes read as everyday life; "Dramatization" caption where a story is enacted
- [ ] Apple badge is the official artwork; no Play badge until the app is actually on Google Play
- [ ] 17+ rating respected in placement targeting
