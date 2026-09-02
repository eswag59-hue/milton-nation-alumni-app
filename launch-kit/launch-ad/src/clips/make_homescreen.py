#!/usr/bin/env python3
"""An iOS-style home screen with the REAL Milton icon sitting among ordinary apps.

The surrounding icons are generic originals — plain glyphs on brand-neutral
gradients in the right visual language. Apple's actual icon artwork is not
reproduced; the point is only that Milton reads as one app among many on a
real phone, which is what sells the shot.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np, pathlib, math

W, H = 1320, 2868                     # matches the real screenshots
HERE = pathlib.Path(__file__).parent
BUILD = HERE.parent.parent / "build"
OUT = BUILD / "clip03"; OUT.mkdir(parents=True, exist_ok=True)
JOST = str(HERE.parent / "fonts" / "Jost.ttf")

COLS, ROWS = 4, 6
ICON = 236
GAP_X = (W - COLS*ICON) // (COLS + 1)
TOP = 430
ROW_PITCH = ICON + 132

def superellipse(size, r=0.28, n=5.0):
    """iOS-style squircle mask."""
    s = size*4
    m = Image.new("L", (s, s), 0)
    px = m.load()
    a = s/2
    for y in range(s):
        for x in range(s):
            u = (x - a + .5)/a; v = (y - a + .5)/a
            if abs(u)**n + abs(v)**n <= 1.0: px[x, y] = 255
    return m.resize((size, size), Image.LANCZOS)

MASK = superellipse(ICON)

def _mark(d, kind, col):
    """Simple original glyphs drawn as geometry — always renders, no font
    dependency, and nothing here reproduces another vendor's icon artwork."""
    C = ICON/2; U = ICON/100.0          # convenience unit
    def rr(x0,y0,x1,y1,r,**kw): d.rounded_rectangle([x0,y0,x1,y1], r, **kw)
    if kind == "handset":
        d.line([(C-16*U,C-18*U),(C-4*U,C-4*U)], fill=col, width=int(11*U))
        d.line([(C-4*U,C-4*U),(C+16*U,C+16*U)], fill=col, width=int(11*U))
        d.ellipse([C-24*U,C-26*U,C-8*U,C-10*U], fill=col)
        d.ellipse([C+8*U,C+8*U,C+24*U,C+24*U], fill=col)
    elif kind == "bubble":
        rr(C-24*U,C-20*U,C+24*U,C+12*U, int(14*U), fill=col)
        d.polygon([(C-10*U,C+10*U),(C-2*U,C+24*U),(C+6*U,C+10*U)], fill=col)
    elif kind == "envelope":
        rr(C-26*U,C-18*U,C+26*U,C+18*U, int(6*U), fill=col)
        d.line([(C-26*U,C-18*U),(C,C+3*U),(C+26*U,C-18*U)], fill=(0,0,0,90), width=int(5*U))
    elif kind == "flower":
        for a in range(6):
            import math as _m
            ang = a*_m.pi/3
            d.ellipse([C+_m.cos(ang)*14*U-11*U, C+_m.sin(ang)*14*U-11*U,
                       C+_m.cos(ang)*14*U+11*U, C+_m.sin(ang)*14*U+11*U], fill=col)
    elif kind == "lens":
        d.ellipse([C-25*U,C-25*U,C+25*U,C+25*U], outline=col, width=int(7*U))
        d.ellipse([C-11*U,C-11*U,C+11*U,C+11*U], fill=col)
    elif kind == "arrow":
        d.polygon([(C+24*U,C-22*U),(C-22*U,C+2*U),(C-2*U,C+6*U),(C+2*U,C+24*U)], fill=col)
    elif kind == "cloud":
        d.ellipse([C-26*U,C-6*U,C+2*U,C+18*U], fill=col)
        d.ellipse([C-8*U,C-20*U,C+20*U,C+12*U], fill=col)
        rr(C-22*U,C+4*U,C+22*U,C+18*U, int(9*U), fill=col)
    elif kind == "dial":
        d.ellipse([C-25*U,C-25*U,C+25*U,C+25*U], outline=col, width=int(6*U))
        d.line([(C,C),(C,C-16*U)], fill=col, width=int(5*U))
        d.line([(C,C),(C+12*U,C+4*U)], fill=col, width=int(5*U))
    elif kind == "lines":
        for i,(w) in enumerate((34,26,30)):
            y = C-16*U+i*15*U
            rr(C-w*U/1.6, y-3*U, C+w*U/1.6, y+3*U, int(3*U), fill=col)
    elif kind == "heart":
        d.pieslice([C-26*U,C-22*U,C+2*U,C+6*U], 180, 360, fill=col)
        d.pieslice([C-2*U,C-22*U,C+26*U,C+6*U], 180, 360, fill=col)
        d.polygon([(C-26*U,C-8*U),(C,C+26*U),(C+26*U,C-8*U)], fill=col)
    elif kind == "card":
        rr(C-26*U,C-17*U,C+26*U,C+17*U, int(6*U), fill=col)
        rr(C-26*U,C-6*U,C+26*U,C+2*U, 0, fill=(0,0,0,80))
    elif kind == "note":
        d.ellipse([C-22*U,C+6*U,C-6*U,C+22*U], fill=col)
        d.ellipse([C+4*U,C-2*U,C+20*U,C+14*U], fill=col)
        rr(C-9*U,C-22*U,C-4*U,C+14*U, int(2*U), fill=col)
        rr(C+17*U,C-26*U,C+22*U,C+6*U, int(2*U), fill=col)
        rr(C-9*U,C-24*U,C+22*U,C-16*U, int(3*U), fill=col)
    elif kind == "play":
        d.polygon([(C-14*U,C-22*U),(C+22*U,C),(C-14*U,C+22*U)], fill=col)
    elif kind == "gear":
        import math as _m
        for a in range(8):
            ang = a*_m.pi/4
            d.line([(C+_m.cos(ang)*12*U, C+_m.sin(ang)*12*U),
                    (C+_m.cos(ang)*26*U, C+_m.sin(ang)*26*U)], fill=col, width=int(10*U))
        d.ellipse([C-18*U,C-18*U,C+18*U,C+18*U], fill=col)
        d.ellipse([C-7*U,C-7*U,C+7*U,C+7*U], fill=(0,0,0,120))
    elif kind == "folder":
        rr(C-26*U,C-14*U,C+26*U,C+20*U, int(6*U), fill=col)
        rr(C-26*U,C-21*U,C-2*U,C-10*U, int(4*U), fill=col)
    elif kind == "ring":
        d.ellipse([C-24*U,C-24*U,C+24*U,C+24*U], outline=col, width=int(11*U))
    elif kind == "check":
        d.line([(C-18*U,C+1*U),(C-5*U,C+15*U)], fill=col, width=int(9*U))
        d.line([(C-5*U,C+15*U),(C+19*U,C-16*U)], fill=col, width=int(9*U))
    elif kind == "compass":
        d.ellipse([C-26*U,C-26*U,C+26*U,C+26*U], outline=col, width=int(6*U))
        d.polygon([(C+13*U,C-13*U),(C+3*U,C+3*U),(C-13*U,C+13*U),(C-3*U,C-3*U)], fill=col)
    elif kind == "num":
        f = ImageFont.truetype(JOST, int(ICON*0.42))
        d.text((C, C+4*U), "17", font=f, fill=col, anchor="mm")
    elif kind == "letter":
        f = ImageFont.truetype(JOST, int(ICON*0.50))
        d.text((C, C), "A", font=f, fill=col, anchor="mm")

def grad_icon(c0, c1, glyph=None, gcol=(255,255,255)):
    im = Image.new("RGBA", (ICON, ICON))
    d = ImageDraw.Draw(im, "RGBA")
    for y in range(ICON):
        t = y/(ICON-1)
        d.line([(0,y),(ICON,y)], fill=tuple(int(c0[k]*(1-t)+c1[k]*t) for k in range(3))+(255,))
    if glyph:
        dark = (c0[0]+c0[1]+c0[2]) > 600          # light chip -> dark mark
        _mark(d, glyph, (40,46,54,255) if dark else gcol+(255,))
    im.putalpha(MASK)
    return im

# Generic apps — glyph + palette only, no reproduced artwork.
APPS = [
    ("Phone",    (46,190,90),  (24,150,66),  "handset"),
    ("Messages", (58,205,110), (30,165,80),  "bubble"),
    ("Mail",     (60,150,240), (30,110,205), "envelope"),
    ("Calendar", (255,255,255),(232,236,240),"num"),
    ("Photos",   (250,215,80), (240,120,90), "flower"),
    ("Camera",   (120,126,134),(78,84,92),   "lens"),
    ("Maps",     (86,196,140), (48,150,110), "arrow"),
    ("Weather",  (66,150,235), (40,105,190), "cloud"),
    ("Clock",    (28,32,38),   (12,14,18),   "dial"),
    ("Notes",    (255,222,110),(242,196,70), "lines"),
    ("Health",   (255,255,255),(240,242,246),"heart"),
    ("Wallet",   (40,44,50),   (18,20,24),   "card"),
    ("MILTON",   None,         None,         None),          # the real icon
    ("Music",    (250,90,110), (225,50,80),  "note"),
    ("Podcasts", (170,120,240),(130,80,215), "play"),
    ("App Store",(70,160,245), (40,115,210), "letter"),
    ("Settings", (150,156,164),(105,112,120),"gear"),
    ("Files",    (80,170,240), (48,125,205), "folder"),
    ("Fitness",  (36,40,46),   (16,18,22),   "ring"),
    ("Reminders",(255,255,255),(238,240,244),"check"),
]
DOCK = [
    ("Phone",   (46,190,90),  (24,150,66),  "handset"),
    ("Safari",  (70,175,250), (35,120,215), "compass"),
    ("Messages",(58,205,110), (30,165,80),  "bubble"),
    ("Camera",  (120,126,134),(78,84,92),   "lens"),
]

def wallpaper():
    """Deep teal brand wallpaper with a soft liquid ribbon."""
    im = Image.new("RGB", (W, H), (8, 22, 30))
    g = Image.new("RGB", (W, H), (0,0,0)); d = ImageDraw.Draw(g)
    ramp = [(23,96,127),(10,126,156),(12,147,178),(47,161,166),(87,178,149),(201,231,126)]
    for k in range(3):
        yb, amp = H*(0.34 + k*0.20), H*0.10
        for x in range(-60, W+60, 8):
            t = (x+60)/(W+120)*(len(ramp)-1); i = min(int(t), len(ramp)-2); f = t-i
            col = tuple(int(ramp[i][j]*(1-f)+ramp[i+1][j]*f) for j in range(3))
            y = yb + math.sin(x/430 + k*1.4)*amp
            d.ellipse([x-150, y-150, x+150, y+150], fill=col)
    g = g.filter(ImageFilter.GaussianBlur(170))
    return Image.blend(im, Image.blend(im, g, 0.82), 0.92)

def label(d, text, cx, y):
    f = ImageFont.truetype(JOST, 34)
    for dx, dy in ((0,1),(1,0),(-1,0),(0,-1)):
        d.text((cx+dx, y+dy), text, font=f, fill=(0,0,0,110), anchor="ma")
    d.text((cx, y), text, font=f, fill=(255,255,255,242), anchor="ma")

ICON_URL = ("https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/fc/47/85/"
            "fc47853e-53cb-8491-5ac3-4e997929ee01/"
            "AppIcon-0-0-1x_U007ephone-0-1-85-220.png/512x512bb.jpg")

def fetch_icon():
    """The real App Store icon, so Milton on this home screen is the actual
    shipped artwork rather than a redraw. Cached after the first fetch."""
    dst = OUT/"milton_icon.png"
    if dst.exists(): return dst
    import urllib.request
    with urllib.request.urlopen(ICON_URL, timeout=30) as r:
        dst.write_bytes(r.read())
    print("fetched", dst.name)
    return dst

def build():
    fetch_icon()
    bg = wallpaper().convert("RGBA")
    d = ImageDraw.Draw(bg)

    # status bar
    f = ImageFont.truetype(JOST, 46)
    d.text((104, 74), "9:41", font=f, fill=(255,255,255), anchor="lm")
    for i, h in enumerate((16, 24, 32, 40)):
        x = W-300+i*22
        d.rounded_rectangle([x, 88-h, x+13, 88], 4, fill=(255,255,255,235 if i < 3 else 120))
    d.rounded_rectangle([W-196, 62, W-120, 96], 12, outline=(255,255,255,190), width=3)
    d.rounded_rectangle([W-192, 66, W-146, 92], 9, fill=(255,255,255,235))

    milton = Image.open(OUT/"milton_icon.png").convert("RGBA").resize((ICON, ICON), Image.LANCZOS)
    milton.putalpha(MASK)

    for idx, (name, c0, c1, gl) in enumerate(APPS):
        r, c = divmod(idx, COLS)
        x = GAP_X + c*(ICON+GAP_X)
        y = TOP + r*ROW_PITCH
        ic = milton if name == "MILTON" else grad_icon(c0, c1, gl)
        sh = Image.new("RGBA", (W, H), (0,0,0,0))
        sh.paste(Image.new("RGBA", (ICON, ICON), (0,0,0,120)), (x, y+10), MASK)
        bg.alpha_composite(sh.filter(ImageFilter.GaussianBlur(16)))
        bg.alpha_composite(ic, (x, y))
        label(d, "Milton" if name == "MILTON" else name, x+ICON/2, y+ICON+18)

    # page dots
    for i in range(3):
        cx = W/2 + (i-1)*34
        d.ellipse([cx-8, 2360-8, cx+8, 2360+8],
                  fill=(255,255,255,255 if i == 0 else 110))

    # dock — a frosted glass slab
    dx0, dy0, dx1, dy1 = 44, 2430, W-44, 2740
    region = bg.crop((dx0, dy0, dx1, dy1)).filter(ImageFilter.GaussianBlur(38))
    glass = Image.new("RGBA", region.size, (255,255,255,34))
    region = Image.alpha_composite(region.convert("RGBA"), glass)
    m = Image.new("L", region.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0,0,region.width-1,region.height-1], 76, fill=255)
    bg.paste(region, (dx0, dy0), m)
    for i, (name, c0, c1, gl) in enumerate(DOCK):
        x = dx0 + 52 + i*((dx1-dx0-104-ICON)//3)
        bg.alpha_composite(grad_icon(c0, c1, gl), (x, dy0+38))

    # home indicator
    d.rounded_rectangle([W/2-134, 2800, W/2+134, 2812], 6, fill=(255,255,255,225))

    bg.convert("RGB").save(OUT/"homescreen.png")
    print("wrote", OUT/"homescreen.png")

def lockscreen():
    """Same wallpaper as the home screen, so the unlock reads as one continuous
    surface rather than a cut between two different pictures."""
    bg = wallpaper().convert("RGBA")
    d = ImageDraw.Draw(bg)

    # status bar
    f = ImageFont.truetype(JOST, 46)
    d.text((104, 74), "9:41", font=f, fill=(255,255,255), anchor="lm")
    for i, h in enumerate((16, 24, 32, 40)):
        x = W-300+i*22
        d.rounded_rectangle([x, 88-h, x+13, 88], 4, fill=(255,255,255,235 if i < 3 else 120))
    d.rounded_rectangle([W-196, 62, W-120, 96], 12, outline=(255,255,255,190), width=3)
    d.rounded_rectangle([W-192, 66, W-146, 92], 9, fill=(255,255,255,235))

    # padlock
    cx, cy = W/2, 470
    d.rounded_rectangle([cx-30, cy-6, cx+30, cy+40], 10, fill=(255,255,255,235))
    d.arc([cx-20, cy-40, cx+20, cy+6], 180, 360, fill=(255,255,255,235), width=9)

    # the time — light weight, very large, the way a lock screen carries it
    ft = ImageFont.truetype(JOST, 430)
    d.text((cx, 900), "9:41", font=ft, fill=(255,255,255,252), anchor="mm")
    fd = ImageFont.truetype(JOST, 64)
    d.text((cx, 630), "Tuesday, August 25", font=fd, fill=(255,255,255,215), anchor="mm")

    # frosted quick-action buttons
    for dx in (-1, 1):
        bx, by, r = int(cx + dx*230), 2560, 86
        reg = bg.crop((bx-r, by-r, bx+r, by+r)).filter(ImageFilter.GaussianBlur(30))
        reg = Image.alpha_composite(reg.convert("RGBA"),
                                    Image.new("RGBA", reg.size, (255,255,255,42)))
        m = Image.new("L", reg.size, 0)
        ImageDraw.Draw(m).ellipse([0,0,reg.width-1,reg.height-1], fill=255)
        bg.paste(reg, (bx-r, by-r), m)
        if dx < 0:                                   # torch
            d.rounded_rectangle([bx-16, by-26, bx+16, by+8], 8, fill=(255,255,255,240))
            d.polygon([(bx-10, by+8),(bx+10, by+8),(bx+6, by+30),(bx-6, by+30)],
                      fill=(255,255,255,240))
        else:                                        # camera
            d.ellipse([bx-30, by-22, bx+30, by+30], outline=(255,255,255,240), width=8)
            d.ellipse([bx-13, by-5, bx+13, by+21], fill=(255,255,255,240))

    d.text((cx, 2726), "swipe up to open", font=ImageFont.truetype(JOST, 38),
           fill=(255,255,255,190), anchor="mm")
    d.rounded_rectangle([W/2-134, 2800, W/2+134, 2812], 6, fill=(255,255,255,225))
    bg.convert("RGB").save(OUT/"lockscreen.png")
    print("wrote", OUT/"lockscreen.png")

if __name__ == "__main__":
    build()
    lockscreen()
