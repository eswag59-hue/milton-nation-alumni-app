"""Lift usable stills out of Ezra's 26 Aug screen recording.

The recording is 1170x2532 at 60fps and carries four things nothing else had:
his current lock screen, his current home screen, the real iOS app-open card
mid-expansion, and the "Welcome Back! / Are you still on track?" screen, which
is the app's actual first beat and was missing from every cut so far.

iOS stamps a red recording pill over the clock. It is repainted from the columns
either side rather than blurred, so the rest of the status bar stays genuine.
"""
import numpy as np
from PIL import Image

SRC = 'build/rec2'
DST = 'src/full/assets'
OUT_W, OUT_H = 1320, 2868                 # the size every other screen uses


def strip_pill(im):
    """Repaint the red recording pill from clean columns on either side."""
    a = np.asarray(im.convert('RGB')).astype(np.float32)
    H, W, _ = a.shape
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    red = (r > 120) & (r - g > 45) & (r - b > 45)
    red[int(H * 0.05):] = False           # the pill only ever sits in the status bar
    if not red.any():
        return im
    ys, xs = np.where(red)
    y0, y1 = max(0, ys.min() - 6), min(H, ys.max() + 7)
    x0, x1 = max(0, xs.min() - 8), min(W, xs.max() + 9)
    left = a[y0:y1, max(0, x0 - 5):x0].mean(1, keepdims=True)
    right = a[y0:y1, x1:min(W, x1 + 5)].mean(1, keepdims=True)
    w = np.linspace(0, 1, x1 - x0)[None, :, None]
    a[y0:y1, x0:x1] = left * (1 - w) + right * w
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def norm(im):
    """Match the 1320x2868 frame the rest of the pipeline is built around."""
    s = OUT_W / im.width
    im = im.resize((OUT_W, round(im.height * s)), Image.LANCZOS)
    if im.height == OUT_H:
        return im
    if im.height > OUT_H:                  # trim evenly, keep the centre
        d = im.height - OUT_H
        return im.crop((0, d // 2, OUT_W, im.height - (d - d // 2)))
    pad = Image.new('RGB', (OUT_W, OUT_H), tuple(np.asarray(im)[-1].mean(0).astype(int)))
    pad.paste(im, (0, (OUT_H - im.height) // 2))
    return pad


for name, out in [('lock', 'ezra_lock2.png'), ('home', 'ezra_home2.png'),
                  ('welcome', '00_welcome.png')]:
    im = Image.open(f'{SRC}/pick_{name}.png')
    norm(strip_pill(im)).save(f'{DST}/{out}')
    print(out, 'from', name)
