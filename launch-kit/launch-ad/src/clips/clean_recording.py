#!/usr/bin/env python3
"""Removes the screen-recording indicator from stills grabbed out of an iOS
screen recording, and normalises them to the 1320x2868 screen size the rest of
the pipeline composites at.

While recording, iOS replaces the clock with a red pill. Everything else in the
status bar is genuine, so only that pill is repainted — from the wallpaper
either side of it, which is what sits behind it.
"""
from PIL import Image
import numpy as np, pathlib, sys

OUT_W, OUT_H = 1320, 2868

def kill_indicator(im):
    a = np.array(im.convert('RGB')).astype(float)
    H, W, _ = a.shape
    # The pill lives in the top-left of the status bar. Find strongly red pixels.
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    red = (r > 120) & (r > g*1.8) & (r > b*1.8)
    red[int(H*0.06):, :] = False                  # status bar only
    ys, xs = np.nonzero(red)
    if len(ys) == 0:
        return im
    y0, y1 = max(ys.min()-10, 0), min(ys.max()+10, H-1)
    x0, x1 = max(xs.min()-14, 0), min(xs.max()+14, W-1)
    # repaint by interpolating across the pill from clean columns either side
    pad = 26
    for y in range(y0, y1+1):
        left  = a[y, max(x0-pad,0):max(x0-4,1)].mean(axis=0)
        right = a[y, min(x1+4,W-2):min(x1+pad,W-1)].mean(axis=0)
        t = np.linspace(0, 1, x1-x0+1)[:, None]
        a[y, x0:x1+1] = left[None,:]*(1-t) + right[None,:]*t
    print(f"  removed indicator at x{x0}-{x1} y{y0}-{y1}")
    return Image.fromarray(a.round().clip(0,255).astype('uint8'))

def normalise(src, dst):
    im = kill_indicator(Image.open(src))
    im = im.resize((OUT_W, OUT_H), Image.LANCZOS)
    im.save(dst)
    print(f"  {src} -> {dst}")

if __name__ == "__main__":
    normalise(sys.argv[1], sys.argv[2])
