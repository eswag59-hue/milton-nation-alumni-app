#!/usr/bin/env python3
"""Repaints the old-build artefacts out of the App Store screenshots.

The live listing screenshots were captured from an admin account on an older
build, so Home reads "Welcome back, admin" with a 0-day streak and Profile
reads "Admin User". Re-shooting on the member demo account is the real fix;
this makes the existing captures usable for the film in the meantime.

Only text the current build already renders differently is touched — the
numbers match the staged demo profile (1,096 days = 156 weeks / 36 months /
3 years), so nothing here invents a claim the app would not show.
"""
from PIL import Image, ImageDraw, ImageFont
import numpy as np, pathlib

HERE = pathlib.Path(__file__).parent
SCR  = HERE.parent / "build" / "screens"
# Arial-metric; the closest match on this box to the app's SF Pro UI text.
BOLD = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
REG  = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"

def bgcolor(a, box, pad=6):
    """Median colour just outside a box — the flat card behind the text."""
    l,t,r,b = box
    strip = np.concatenate([a[max(t-pad,0):t, l:r].reshape(-1,3),
                            a[b:b+pad,        l:r].reshape(-1,3)])
    return tuple(int(v) for v in np.median(strip, axis=0))

def repaint(img, box, text, font, fill, align='left', pad=6):
    a = np.array(img.convert('RGB'))
    bg = bgcolor(a, box, pad)
    d = ImageDraw.Draw(img)
    d.rectangle(box, fill=bg)
    l,t,r,b = box
    tw = d.textlength(text, font=font)
    asc, desc = font.getmetrics()
    y = t + ((b-t) - (asc+desc))//2
    x = l if align=='left' else l + ((r-l)-tw)//2
    d.text((x,y), text, font=font, fill=fill)

def home():
    """Coordinates measured off the capture, not estimated: text rows were
    located by scanning for dark-pixel runs, so the boxes sit on the glyphs."""
    p = SCR/"02_home.png"; img = Image.open(p).convert('RGB')
    # "Welcome back, admin"  (measured y 517-578, x 50-714)
    repaint(img, (46, 508, 780, 588), "Welcome back, Alex",
            ImageFont.truetype(BOLD, 76), (13,26,33))
    # the streak numeral (measured y 893-1017, centred on x 660)
    repaint(img, (360, 885, 960, 1025), "1,096",
            ImageFont.truetype(BOLD, 150), (13,26,33), align='center')
    # weeks / months / years (measured y 1245-1293; centres x 283 / 660 / 1037)
    for cx, val in [(283,"156"), (660,"36"), (1037,"3")]:
        repaint(img, (cx-130, 1238, cx+130, 1300), val,
                ImageFont.truetype(BOLD, 60), (13,26,33), align='center')
    img.save(p); print("restaged", p.name)

def profile():
    """Measured rows: name y 886-937, handle y 998-1037, email y 1086-1116,
    all centred on x 660. (An earlier pass was one row low and hit the avatar's
    edit badge instead of the name.)"""
    p = SCR/"06_profile.png"; img = Image.open(p).convert('RGB')
    repaint(img, (360, 878, 960, 946), "Alex Demo",
            ImageFont.truetype(BOLD, 66), (13,26,33), align='center')
    repaint(img, (400, 990, 920, 1046), "@alexdemo",
            ImageFont.truetype(REG, 48), (58,120,150), align='center')
    repaint(img, (380, 1078, 940, 1124), "alex@miltonrecovery.com",
            ImageFont.truetype(REG, 38), (118,140,152), align='center')
    img.save(p); print("restaged", p.name)

if __name__ == "__main__":
    home(); profile()
