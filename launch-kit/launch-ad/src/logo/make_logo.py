#!/usr/bin/env python3
"""Rebuilds the Milton logotype as a vector-ish asset so the swirl can be
animated through it. Chat attachments never reach the filesystem, so this is a
reconstruction from the supplied artwork — compare and correct.

Bodoni Moda is a very close match for the didone logotype: high stroke
contrast, ball terminal on the 't', geometric 'o'. The gradient runs the brand
ramp left to right across the word, and the swirl is a translucent ribbon that
crosses the letterforms.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np, pathlib, math

HERE = pathlib.Path(__file__).parent
OUT  = HERE.parent.parent / "build" / "logo"
OUT.mkdir(parents=True, exist_ok=True)
BODONI = str(HERE.parent / "fonts" / "BodoniModa.ttf")

W, H = 2000, 900
# Sampled off the supplied logo, left to right across the word.
RAMP = ["#17607F", "#0A7E9C", "#0C93B2", "#2FA1A6", "#57B295", "#8CC77F", "#C9E77E"]

def hexrgb(c): return tuple(int(c[i:i+2], 16) for i in (1, 3, 5))

def ramp_img(w, h, stops=RAMP):
    im = Image.new("RGB", (w, h)); d = ImageDraw.Draw(im)
    S = [hexrgb(c) for c in stops]
    for x in range(w):
        t = x/(w-1)*(len(S)-1); i = min(int(t), len(S)-2); f = t-i
        d.line([(x,0),(x,h)], fill=tuple(int(S[i][k]*(1-f)+S[i+1][k]*f) for k in range(3)))
    return im

def wordmark_mask(size=560):
    """Alpha mask of the word, trimmed tight."""
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    f = ImageFont.truetype(BODONI, size)
    d.text((W//2, H//2), "milton", font=f, fill=255, anchor="mm")
    a = np.array(m); ys, xs = np.nonzero(a > 8)
    return m.crop((xs.min()-6, ys.min()-6, xs.max()+7, ys.max()+7))

def swirl_mask(w, h, phase=0.0, thickness=0.30):
    """A ribbon sweeping through the word — a sine band, feathered."""
    yy, xx = np.mgrid[0:h, 0:w]
    u = xx/w
    centre = 0.46 + 0.30*np.sin(u*2.6*math.pi + phase) + 0.16*np.sin(u*1.1*math.pi + phase*0.6)
    dist = np.abs(yy/h - centre)
    band = np.clip(1.0 - dist/thickness, 0, 1)**1.6
    return Image.fromarray((band*255).astype("uint8"), "L").filter(ImageFilter.GaussianBlur(w*0.006))

def build(phase=0.0, swirl_strength=0.55, out="logo.png"):
    wm = wordmark_mask()
    w, h = wm.size
    base = ramp_img(w, h)
    # the swirl lightens the ramp where it crosses
    sw = swirl_mask(w, h, phase)
    light = Image.new("RGB", (w, h), (255, 255, 255))
    base = Image.composite(Image.blend(base, light, swirl_strength), base, sw)
    base.putalpha(wm)
    canvas = Image.new("RGBA", (w+80, h+80), (0,0,0,0))
    canvas.alpha_composite(base, (40, 40))
    canvas.save(OUT/out)
    return canvas.size

if __name__ == "__main__":
    print("logo.png", build(0.0, 0.55, "logo.png"))
    # a flat version with no swirl, for the end card
    print("logo_flat.png", build(0.0, 0.0, "logo_flat.png"))
