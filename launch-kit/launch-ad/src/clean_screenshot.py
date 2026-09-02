#!/usr/bin/env python3
"""Removes the 'Back to Admin' debug pill from an App Store screenshot.

The pill is a UIKit overlay that only appears when an admin account is in
"View as User" mode. It is present in every screenshot currently on the App
Store listing. It sits over a horizontally uniform background, so filling the
band by interpolating between the clean columns either side is invisible.

Not needed for screenshots taken on a member account (role = alumni), which
cannot show the pill at all.

    python3 clean_screenshot.py in.png out.png
"""
import sys
from PIL import Image
import numpy as np

# Band covering the capsule and its drop shadow, for a 1320x2868 capture.
Y0, Y1 = 2450, 2605
X0, X1 = 380, 940
PAD = 45


def clean(src, dst):
    a = np.array(Image.open(src).convert('RGB')).astype(float)
    for y in range(Y0, Y1 + 1):
        left = a[y, X0 - PAD:X0 - 5].mean(axis=0)
        right = a[y, X1 + 5:X1 + PAD].mean(axis=0)
        t = np.linspace(0.0, 1.0, X1 - X0 + 1)[:, None]
        a[y, X0:X1 + 1] = left[None, :] * (1 - t) + right[None, :] * t
    Image.fromarray(a.round().clip(0, 255).astype('uint8')).save(dst)
    print(f"{src} -> {dst}")


if __name__ == "__main__":
    clean(sys.argv[1], sys.argv[2])
