#!/usr/bin/env python3
"""Renders the two type cards for the launch ad.

Both are built from the app's own assets rather than redrawn: the wordmark is
lifted straight out of a real screenshot at 8x, and the gradient hairline uses
the exact brand ramp. Run from this directory; writes into ../build/.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np
import pathlib

W, H = 1080, 1920
HERE  = pathlib.Path(__file__).parent
BUILD = HERE.parent / "build"
BUILD.mkdir(exist_ok=True)

BODONI = HERE / "fonts" / "BodoniModa.ttf"
JOST   = HERE / "fonts" / "Jost.ttf"

# Milton brand ramp, sampled from the app's own gradient bar.
BRAND = ['#101820', '#165C7D', '#007396', '#0093B2', '#369DA0', '#56B093', '#D4EB8E']

HEADLINE = ["Recovery doesn't", "happen alone."]
KICKER   = "NOW ON THE APP STORE"


def tracked(draw, xy, text, font, fill, track=0.0):
    """Centre-anchored text with manual letter-spacing."""
    widths = [draw.textlength(c, font=font) for c in text]
    x, y = xy
    x -= (sum(widths) + track * (len(text) - 1)) / 2
    for c, w in zip(text, widths):
        draw.text((x, y), c, font=font, fill=fill)
        x += w + track


def gradient_bar(w, h):
    bar = Image.new('RGB', (w, h))
    d = ImageDraw.Draw(bar)
    stops = [tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)) for c in BRAND]
    for x in range(w):
        t = x / (w - 1) * (len(stops) - 1)
        i = min(int(t), len(stops) - 2)
        f = t - i
        d.line([(x, 0), (x, h)],
               fill=tuple(int(stops[i][k] * (1 - f) + stops[i + 1][k] * f) for k in range(3)))
    return bar


def white_wordmark(target_w):
    """The app's own wordmark, ink recoloured white, alpha preserved."""
    wm = Image.open(HERE / "wordmark_alpha.png").convert('RGBA')
    a = np.array(wm)
    a[:, :, 0:3] = 255
    wm = Image.fromarray(a, 'RGBA')
    return wm.resize((target_w, int(wm.height * target_w / wm.width)), Image.LANCZOS)


def build_headline():
    card = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(card)
    f = ImageFont.truetype(str(BODONI), 78)
    for i, line in enumerate(HEADLINE):
        tracked(d, (W / 2, 205 + i * 95), line, f, (255, 255, 255, 255), track=1.5)
    # Soft shadow so the type holds over the volumetric haze.
    blur = card.filter(ImageFilter.GaussianBlur(18))
    ba = np.array(blur)
    shadow = np.dstack([np.zeros_like(ba[:, :, 0])] * 3 + [(ba[:, :, 3] * 0.55).astype('uint8')])
    card = Image.alpha_composite(Image.fromarray(shadow, 'RGBA'), card)
    card.save(BUILD / "title.png")


def build_endcard():
    card = Image.new('RGBA', (W, H), (8, 14, 18, 255))
    d = ImageDraw.Draw(card)

    wm = white_wordmark(640)
    wm_y = H // 2 - wm.height - 40          # optically centred lockup
    card.alpha_composite(wm, ((W - wm.width) // 2, wm_y))

    bar_w, bar_h = 460, 3
    bar_y = wm_y + wm.height + 58
    card.paste(gradient_bar(bar_w, bar_h), ((W - bar_w) // 2, bar_y))

    tracked(d, (W / 2, bar_y + 70), KICKER,
            ImageFont.truetype(str(JOST), 33), (214, 235, 142, 255), track=7.5)
    card.convert('RGB').save(BUILD / "endcard.png")


if __name__ == "__main__":
    build_headline()
    build_endcard()
    print(f"wrote {BUILD/'title.png'} and {BUILD/'endcard.png'}")
