# Promo Film Pipeline — Milton Nation Alumni

Deterministic renderer for the launch film set. Every frame is a pure function of
timeline time `t`, so a re-run reproduces the cut exactly.

## Deliverables

| File | Format | Duration | Use |
|---|---|---|---|
| `MiltonNation_60s_16x9.mp4` | 1920×1080 | 60.0s | YouTube, site hero, email, referral decks |
| `MiltonNation_60s_9x16.mp4` | 1080×1920 | 60.0s | Reels, TikTok, Stories |
| `MiltonNation_60s_1x1.mp4` | 1080×1080 | 60.0s | LinkedIn, in-feed |
| `MiltonNation_short_A_counted_9x16.mp4` | 1080×1920 | 12.4s | "Day one was the easy part" — the counter |
| `MiltonNation_short_B_careteam_9x16.mp4` | 1080×1920 | 12.4s | "Discharge day is not goodbye" — care team |
| `MiltonNation_short_C_startover_9x16.mp4` | 1080×1920 | 12.4s | "A reset is not a failure" — the reset screen |

All masters are **silent** by design — drop a licensed track over them. Each carries a
silent AAC stream so social uploaders don't choke on a missing audio track.

## The 60-second structure

| In | Out | Beat | On screen |
|---|---|---|---|
| 0:00 | 0:09 | Cold open | "Treatment is ninety days." / "Recovery is the rest of your life." |
| 0:09 | 0:14 | Title | "nobody recovers alone" / "so we built a **nation**" |
| 0:14 | 0:22 | Counter | Day count ticks 1 → 1,097 · "every day. **counted.**" |
| 0:22 | 0:28 | Community | Real Wins post · "every win. **witnessed.**" |
| 0:28 | 0:34 | Care team | Dana Case's real message · "your care team. **one tap.**" |
| 0:34 | 0:40 | Meetings | Nearby NA/AA card · "meetings. **everywhere.**" |
| 0:40 | 0:46 | Hard days | Get Help Now · "and on the hard days, **one tap.**" + peer-support disclaimer |
| 0:46 | 0:52 | Privacy | "private by design." · Face ID · encrypted · screen-capture protected |
| 0:52 | 1:00 | End card | Icon · wordmark · "Driven by purpose. Committed to care." · both store badges |

Cut points sit on whole/half seconds so any 60s track's downbeats line up without retiming.

## Why the film is built from screenshots, not screen recordings

`DeviceSecurityService` blocks screen capture: with a recording running the app renders
**"Screen Recording Blocked — Milton Nation protects your health information from screen
capture"** and shows "App Protected" in the app switcher. Recordings never get past the
Welcome Back gate. Motion is therefore synthesised from stills — which is how product
films are made anyway: 60fps, no capture indicator, no status-bar drift, full control of
pacing.

Status bars are cropped from every screenshot (the source set spans 2:02–9:34, which
would read as a continuity error).

## The counter is rebuilt, not screenshotted

No screenshot in the source set contains the hero day-counter card. `screens.py` rebuilds
it natively at the app's exact palette (`#101820` numerals, `#DBEDEF` card, the 156/36/3
strip, the "Update recovery date" pill) between the **real** header and **real** tab-bar
pixels, and stitches the real Points & Badges / Updates & News cards below it. The seam is
invisible and the numeral can animate, which a screenshot cannot.

## Content rules applied

- No faces, no depicted patients, no implied testimonials.
- Public naming is **Milton Nation Alumni** only — no treatment-centre naming.
- The crisis flow is present but not dwelt on, and carries the app's own honest line:
  *"A peer-support community — not an emergency service."*
- End card states **"For verified alumni · Demo data shown."**

## Re-rendering

```bash
pip install Pillow && apt-get install -y ffmpeg
# Inter Display is required (not vendored — 28MB):
curl -L -o inter.zip https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip
unzip -j inter.zip "*/InterDisplay-*.otf" "*/Inter-*.otf" -d src/fonts/

cd src
python3 render.py 16x9          # → frames_16x9/
python3 shorts.py A_counted     # → frames_A_counted/
ffmpeg -framerate 30 -i frames_16x9/%05d.jpg -f lavfi -i anullsrc=r=48000:cl=stereo \
  -shortest -c:v libx264 -pix_fmt yuv420p -crf 17 -c:a aac -movflags +faststart out.mp4
```

`src/` expects `ui/` (status-bar-stripped screenshots, named by their 4-digit IMG id) and
`plates/` (studio backgrounds). Regenerate plates from `prompts.md`.

## Editing the cut

- Timing: the `TL` table at the bottom of `film.py` — `(t_in, t_out, beat_fn)`.
- Copy: the lambda arguments in `TL`.
- Framing per format: the `LAYOUT` dict at the top of `film.py`.
- Which app moment floats as a card: the `POST` / `CHAT` / `HELP` / `RESET` crop boxes.
