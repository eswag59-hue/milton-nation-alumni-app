# Launch ad — the pipeline that produced it

`assets/milton-launch-9s.mp4` — 9.6s, 1080×1920, 30fps. `-1x1.mp4` is the feed cut.

The point of this directory is that the ad is **reproducible**. Every frame of
the app on screen is a real screenshot, not a redraw — that was the recurring
failure of earlier attempts, and it is the one thing not to regress on.

## The cut

| Time | What |
|---|---|
| 0.0–1.5s | Black lifts to the phone in a dark teal void, brand ribbon drifting behind |
| 1.5–5.4s | *"Recovery doesn't happen alone."* in Bodoni Moda; one slow motion-control push-in |
| 6.6–9.6s | Cut to the milton wordmark, brand gradient hairline, NOW ON THE APP STORE |

No audio. Deliberate — a clean silent cut beats a bad temp score, and the
earlier attempt was rejected on its sound. Higgsfield `generate_audio` can lay
a bed under this without touching the picture.

## How it was built

### 1. Start from a real screen

`assets/screen-community-clean.png` is a genuine App Store screenshot with the
`Back to Admin` debug pill patched out by `src/clean_screenshot.py`.

That pill is a UIKit overlay shown only when an **admin** account is in "View as
User" mode. It is in every screenshot currently on the App Store listing.
Screenshots taken on the member demo account (`role = alumni`) cannot show it at
all, so re-shot captures need no patching — prefer them.

### 2. Higgsfield builds the environment around the screen

Upload the screenshot (`media_upload` → PUT → `media_confirm`), then pass its
`media_id` as an `image_references` media to `nano_banana_pro`. The role is
declared as `image` and the backend coerces it.

The prompt has to be emphatic that the screen is not to be reinterpreted —
without that, the model redesigns the UI into something generically app-shaped:

> THE PHONE SCREEN MUST DISPLAY THE PROVIDED REFERENCE INTERFACE EXACTLY AS
> GIVEN — same layout, same text, same colours, same cards, pixel-accurate…
> Do not redesign, reinterpret, translate, or invent any interface element.

Environment brief: deep charcoal-teal void, volumetric haze, softbox upper-left,
cyan rim light, an out-of-focus teal→cyan→lime ribbon echoing the brand ramp,
faint reflection below, generous negative space top and bottom for titles.

Reference render: `assets/hero-still.png` (job `569225bd`).

### 3. Animate, guarding against UI warp

`minimax_h3`, 6s, 9:16, with the still as `start_image`. The failure mode is the
interface scrolling, rippling or re-rendering mid-shot, so the prompt pins it:

> THE SCREEN CONTENT MUST REMAIN COMPLETELY STATIC, SHARP AND UNCHANGED
> throughout … Treat the screen as a still photograph rigidly attached to the
> device.

Only the environment moves — ribbon drift, haze roll, the specular travelling a
few millimetres along the titanium edge.

Higgsfield offers its **IN THE DARK** preset for this prompt
(`24bae836-2c4a-48e0-89b6-49fcc0b21612`). It was declined: a preset overrides the
screen-stability instruction, which is the whole ballgame. Worth trying once the
fundamentals are locked.

**Render two takes and check every second before editing.** `ffmpeg -vf fps=1`
into a contact sheet makes warping obvious in one glance.

### 4. Type and assembly

```bash
src/fetch_fonts.sh        # Bodoni Moda + Jost from gstatic
python3 src/make_titles.py                       # -> build/title.png, build/endcard.png
src/assemble.sh hero-clip.mp4 ../assets/milton-launch-9s.mp4
```

The wordmark is not re-typeset — `src/wordmark_alpha.png` is the app's own
wordmark lifted from a screenshot at 8×, ink recoloured white, alpha preserved.
The gradient hairline uses the brand ramp
`#101820 → #165C7D → #007396 → #0093B2 → #369DA0 → #56B093 → #D4EB8E`.

## Two ffmpeg traps this hit

**A still PNG input is one frame.** `-i title.png` with a fade at `st=1.1`
produces a title that never appears — the fade has no frames to act on and fails
silently. Needs `-loop 1 -framerate 30 -t <duration>`.

**`zoompan` multiplies frames.** `d=90` expands *each input frame* into 90
output frames, so a 3s still became 3m45s. Use `d=1` with the input already at
the output rate and drive the zoom off `on`.

## Next

- Re-cut the hero from the **Home screen at 1,096 days** — a stronger frame than
  a feed, and free of the empty "Photo" placeholder.
- 15s and 30s versions off the same look.
- Stills from `hero-still.png` for Canva, email and the App Store set.
