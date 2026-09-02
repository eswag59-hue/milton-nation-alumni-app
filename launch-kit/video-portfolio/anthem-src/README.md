# Anthem video — production source

The complete pipeline that renders the "Welcome to the Nation" launch anthem (60s master + 30s/15s cutdowns, 1080×1920) from code: every app screen is an HTML/CSS/JS replica built from the real app source (exact tokens from `AppTheme.swift`), animated, recorded headlessly, scored procedurally, and assembled with ffmpeg. No Mac, no simulator, no editing suite required.

## Regenerate from scratch

```bash
cd launch-kit/video-portfolio/anthem-src
npm i playwright && npx playwright install chromium   # or use a preinstalled chromium
pip install pillow imageio-ffmpeg

# assets into seg/ (from the repo + official sources)
cp "../../../Milton Nation Alumni App/Assets.xcassets/AppIcon.appiconset/AppIcon.png" seg/appicon.png
cp "../../../Milton Nation Alumni App/Assets.xcassets/MiltonLogo.imageset/milton_logo_dark.png" seg/logo_dark.png
python3 -c "from PIL import Image; im=Image.open('seg/logo_dark.png').convert('RGBA'); im.crop(im.getchannel('A').getbbox()).save('seg/wordmark_tight.png')"
curl -sL -o seg/apple-badge.svg "https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us"
curl -sL -o seg/play-badge.png "https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png"
python3 -c "from PIL import Image; im=Image.open('seg/play-badge.png').convert('RGBA'); im.crop(im.getchannel('A').getbbox()).save('seg/play-badge.png')"
mkdir -p fonts && for w in 400 500 600 800; do curl -s -o fonts/inter-$w.ttf "$(curl -s "https://fonts.googleapis.com/css2?family=Inter:wght@$w" -A curl | grep -o 'https://[^)]*\.ttf' | head -1)"; done

mkdir -p rec out
node record.mjs shot     # QA stills into out/ — check them
node record.mjs rec      # record all segments (webm) into rec/
python3 score2.py        # three synced score WAVs into out/
bash assemble.sh         # final MP4s into out/
```

## Anatomy

- `seg/base.css` + `seg/lib.js` — design tokens (the exact Milton palette), phone chrome (Dynamic Island, status bar, blurred tab bar, 3D drift + glass sheen), the shared full Home screen builder, canvas wave renderer.
- `seg/seg01…seg10.html` — one self-driving animation per beat: light-trace opener, icon reveal, springboard app-launch → Home scroll with the day counter rolling, milestone counter, community feed, iOS care-team chat, meetings map, dark-mode sweep, profile scroll with badge earn, end-card with the official store badges.
- `record.mjs` — Playwright headless recorder (`shot` = QA stills, `rec` = video). Durations live at the top; each page runs on its own clock with dip-to-black edges so plain concatenation cuts cleanly.
- `score2.py` — procedural temp score (felt-piano plucks, sub thumps on every cut, one lift at the end), generated per-timeline so the cutdowns stay in sync. **Swap for a licensed track before public use.**
- `assemble.sh` — trims, concats, muxes; outputs `Milton-Nation-Anthem-{60s,30s,15s}-v2.mp4`.

## House rules baked in

Demo identities only · crisis content excluded from hype cuts · "Demo data shown" on the end-card · official store badge artwork only (the app is live on both stores per Ezra, 2026-08-25).
