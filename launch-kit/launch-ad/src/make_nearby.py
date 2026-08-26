"""Render the Meetings > Nearby tab at capture resolution.

Ezra called nearby AA/NA "a really big flex" and it is the one beat with no
screenshot behind it.  Rather than invent a screen, this follows the shipped
SwiftUI exactly — NearbyMeetingsView's map / section header / LazyVStack, and
NearbyMeetingCard's dark #101820 card, AA-blue / NA-sage fellowship pill,
accent distance pill, day+time, address, location, and Directions button.
The status bar, wordmark header and segmented control are lifted pixel-for-pixel
off the real 04_meetings.png capture; only the selected pill is repainted.
"""
from PIL import Image, ImageDraw, ImageFont
import math

W, H = 1320, 2868
PT = 3.0                                   # 440x956pt at 3x
ACCENT   = (0, 115, 150)                   # AppTheme.accent   #007396
SAGE     = (86, 176, 147)                  # AppTheme.accentSage #56B093
AA_BLUE  = (0, 122, 255)                   # SwiftUI Color.blue
CARD     = (16, 24, 32)                    # AppTheme.sheetBackground #101820
BG       = (242, 245, 245)                 # AppTheme.backgroundLight #F2F5F5
INK      = (16, 24, 32)
R16      = int(16*PT)

F = {w: {} for w in (400, 500, 600, 700)}
def font(w, px):
    px = int(px)
    if px not in F[w]:
        F[w][px] = ImageFont.truetype(f'src/fonts/Inter-{w}.ttf', px)
    return F[w][px]

MEETINGS = [
    ("Sunrise Serenity Group",   "AA", "0.4 mi", "Monday", "7:00 AM",
     "535 Canton Ave, Milton, MA 02186",  "St. Michael's Parish Hall"),
    ("Milton Steps & Traditions", "AA", "0.9 mi", "Monday", "12:15 PM",
     "197 Central Ave, Milton, MA 02186",  "Milton Community Center"),
    ("New Beginnings",           "NA", "1.6 mi", "Monday", "6:30 PM",
     "40 Highland St, Milton, MA 02186",   "Highland Congregational Church"),
    ("Just For Today",           "NA", "2.3 mi", "Monday", "8:00 PM",
     "1150 Blue Hill Ave, Milton, MA 02186", "Blue Hills Fellowship Hall"),
]

base = Image.open('build/screens/04_meetings.png').convert('RGB')
img  = Image.new('RGB', (W, H), BG)
img.paste(base.crop((0, 0, W, 736)), (0, 0))       # real chrome down to the toggle
d = ImageDraw.Draw(img)

# ── segmented control: swap the selection to Nearby ──────────────────────────
# Measured off the capture: accent pill x 48..326, white pill x 354..645, y 634..735.
def pill(x0, y0, x1, y1, fill, outline=None, wdt=3):
    d.rounded_rectangle([x0, y0, x1, y1], radius=(y1-y0)//2, fill=fill,
                        outline=outline, width=wdt)

d.rectangle([0, 630, W, 740], fill=BG)
pill(48, 634, 326, 735, (255, 255, 255), (225, 230, 230))
pill(354, 645, 645, 735, ACCENT)

def glyph_building(dd, cx, cy, s, col):
    dd.rectangle([cx-s*.42, cy-s*.5, cx+s*.06, cy+s*.5], fill=col)
    dd.rectangle([cx+s*.12, cy-s*.18, cx+s*.46, cy+s*.5], fill=col)
    for r in range(3):
        for c in range(2):
            dd.rectangle([cx-s*.34+c*s*.22, cy-s*.38+r*s*.26,
                          cx-s*.34+c*s*.22+s*.10, cy-s*.38+r*s*.26+s*.12],
                         fill=(255, 255, 255))

def glyph_location(dd, cx, cy, s, col):
    dd.polygon([(cx+s*.52, cy-s*.52), (cx-s*.52, cy+s*.02),
                (cx-s*.04, cy+s*.10), (cx+s*.06, cy+s*.54)], fill=col)

fs = font(600, 40)
glyph_building(d, 108, 685, 40, ACCENT)
d.text((140, 685), "Milton", font=fs, fill=INK, anchor="lm")
glyph_location(d, 410, 690, 40, (255, 255, 255))
d.text((442, 690), "Nearby", font=fs, fill=(255, 255, 255), anchor="lm")

# ── map ──────────────────────────────────────────────────────────────────────
MX, MY, MW, MH = int(16*PT), 736 + int(8*PT), W - int(32*PT), int(220*PT)
mp = Image.new('RGB', (MW, MH), (232, 236, 230))
md = ImageDraw.Draw(mp)
md.polygon([(0, MH*.62), (MW*.30, MH*.52), (MW*.58, MH*.72), (MW*.42, MH),
            (0, MH)], fill=(206, 226, 224))                       # water
for gx in range(-2, 9):                                            # roads
    md.line([(gx*MW/7 + MH*.18, 0), (gx*MW/7 - MH*.18, MH)], fill=(250, 250, 248), width=13)
for gy in range(0, 6):
    md.line([(0, gy*MH/4.4), (MW, gy*MH/4.4 - MW*.05)], fill=(250, 250, 248), width=11)
md.line([(MW*.02, MH*.30), (MW*.55, MH*.16), (MW, MH*.34)], fill=(255, 243, 214), width=22)
for cx, cy in ((.18,.26),(.36,.44),(.62,.30),(.78,.58)):           # parks
    md.ellipse([MW*cx-MW*.07, MH*cy-MH*.10, MW*cx+MW*.07, MH*cy+MH*.10], fill=(216, 231, 210))
PINS = [(.30,.38),(.52,.30),(.44,.60),(.72,.48)]
for i,(px, py) in enumerate(PINS):
    x, y, s = MW*px, MH*py, 34
    md.ellipse([x-s*.55, y+s*.62, x+s*.55, y+s*.92], fill=(0,0,0,40))
    md.polygon([(x, y+s*.85), (x-s*.62, y-s*.10), (x+s*.62, y-s*.10)],
               fill=AA_BLUE if i < 2 else SAGE)
    md.ellipse([x-s*.62, y-s*.72, x+s*.62, y+s*.14], fill=AA_BLUE if i < 2 else SAGE)
    md.ellipse([x-s*.24, y-s*.50, x+s*.24, y-s*.02], fill=(255, 255, 255))
x, y, s = MW*.50, MH*.52, 26                                       # you-are-here
md.ellipse([x-s*1.9, y-s*1.9, x+s*1.9, y+s*1.9], fill=(0, 115, 150, 30))
md.ellipse([x-s*.5, y-s*.5, x+s*.5, y+s*.5], fill=ACCENT,
           outline=(255, 255, 255), width=7)
mask = Image.new('L', (MW, MH), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, MW-1, MH-1], radius=R16, fill=255)
img.paste(mp, (MX, MY), mask)

# ── section header ───────────────────────────────────────────────────────────
y = MY + MH + int(12*PT)
glyph_location(d, MX + 20, y + 26, 38, ACCENT)
d.text((MX + 48, y + 26), f"Nearest {len(MEETINGS)} Meetings",
       font=font(600, 51), fill=INK, anchor="lm")
y += int(12*PT) + 52

# ── cards ────────────────────────────────────────────────────────────────────
def icon(dd, kind, cx, cy, s, col):
    if kind == 'cal':
        dd.rounded_rectangle([cx-s*.5, cy-s*.42, cx+s*.5, cy+s*.5], radius=s*.14,
                             outline=col, width=4)
        dd.line([(cx-s*.5, cy-s*.14), (cx+s*.5, cy-s*.14)], fill=col, width=4)
        dd.line([(cx-s*.26, cy-s*.62), (cx-s*.26, cy-s*.30)], fill=col, width=4)
        dd.line([(cx+s*.26, cy-s*.62), (cx+s*.26, cy-s*.30)], fill=col, width=4)
    elif kind == 'clock':
        dd.ellipse([cx-s*.5, cy-s*.5, cx+s*.5, cy+s*.5], outline=col, width=4)
        dd.line([(cx, cy), (cx, cy-s*.30)], fill=col, width=4)
        dd.line([(cx, cy), (cx+s*.22, cy+s*.10)], fill=col, width=4)
    elif kind == 'pin':
        dd.ellipse([cx-s*.34, cy-s*.56, cx+s*.34, cy+s*.12], outline=col, width=4)
        dd.polygon([(cx-s*.20, cy-s*.02), (cx+s*.20, cy-s*.02), (cx, cy+s*.34)], fill=col)
        dd.ellipse([cx-s*.11, cy-s*.36, cx+s*.11, cy-s*.14], fill=col)
        dd.arc([cx-s*.50, cy+s*.22, cx+s*.50, cy+s*.56], 200, 340, fill=col, width=4)
    elif kind == 'info':
        dd.ellipse([cx-s*.5, cy-s*.5, cx+s*.5, cy+s*.5], outline=col, width=4)
        dd.line([(cx, cy-s*.06), (cx, cy+s*.26)], fill=col, width=4)
        dd.ellipse([cx-s*.05, cy-s*.28, cx+s*.05, cy-s*.18], fill=col)
    elif kind == 'dir':
        # arrow.triangle.turn.up.right: an L-turn stroke topped with a solid head
        dd.line([(cx-s*.30, cy+s*.34), (cx-s*.30, cy-s*.12), (cx+s*.10, cy-s*.12)],
                fill=col, width=5, joint='curve')
        dd.polygon([(cx+s*.04, cy-s*.34), (cx+s*.36, cy-s*.12),
                    (cx+s*.04, cy+s*.10)], fill=col)

def wht(o):  return (255, 255, 255) if o >= 1 else tuple(int(255*o + CARD[i]*(1-o)) for i in range(3))

for name, fel, dist, day, time_, addr, loc in MEETINGS:
    pad = int(16*PT)
    ch  = pad*2 + 51 + int(10*PT) + 36 + int(10*PT) + 36 + int(10*PT) + 33 + int(10*PT) + 62
    d.rounded_rectangle([MX, y, W-MX, y+ch], radius=R16, fill=CARD)
    cy = y + pad

    # name + fellowship + distance
    d.text((MX+pad, cy+26), name, font=font(600, 51), fill=(255, 255, 255), anchor="lm")
    dw = d.textlength(dist, font=font(700, 36))
    px1 = W-MX-pad
    pill(px1-dw-int(8*PT)*2, cy+4, px1, cy+4+36+int(4*PT)*2, ACCENT, None, 0)
    d.text((px1-int(8*PT)-dw/2, cy+4+18+int(4*PT)), dist, font=font(700, 36),
           fill=(255, 255, 255), anchor="mm")
    fw = d.textlength(fel, font=font(700, 33))
    px0 = px1-dw-int(8*PT)*2-int(6*PT)
    pill(px0-fw-int(7*PT)*2, cy+9, px0, cy+9+33+int(3*PT)*2,
         AA_BLUE if fel == "AA" else SAGE, None, 0)
    d.text((px0-int(7*PT)-fw/2, cy+9+16+int(3*PT)), fel, font=font(700, 33),
           fill=(255, 255, 255), anchor="mm")
    cy += 51 + int(10*PT)

    # day + time
    icon(d, 'cal', MX+pad+18, cy+18, 36, wht(.9))
    d.text((MX+pad+46, cy+18), day, font=font(400, 36), fill=wht(.9), anchor="lm")
    tx = MX+pad+46 + d.textlength(day, font=font(400, 36)) + int(12*PT)
    icon(d, 'clock', tx+18, cy+18, 36, wht(.9))
    d.text((tx+46, cy+18), time_, font=font(400, 36), fill=wht(.9), anchor="lm")
    cy += 36 + int(10*PT)

    icon(d, 'pin', MX+pad+18, cy+18, 36, wht(.85))
    d.text((MX+pad+46, cy+18), addr, font=font(400, 36), fill=wht(.85), anchor="lm")
    cy += 36 + int(10*PT)

    d.text((MX+pad, cy+16), loc, font=font(400, 33), fill=wht(.7), anchor="lm")
    cy += 33 + int(10*PT)

    icon(d, 'info', MX+pad+16, cy+30, 33, wht(.55))
    d.text((MX+pad+40, cy+30), "Tap for details", font=font(400, 33),
           fill=wht(.55), anchor="lm")
    lbl, lf = "Directions", font(700, 36)
    lw = d.textlength(lbl, font=lf)
    bw = int(12*PT)*2 + 34 + 8 + lw
    bx1, by0 = W-MX-pad, cy+30-31
    pill(bx1-bw, by0, bx1, by0+62, ACCENT, None, 0)
    icon(d, 'dir', bx1-bw+int(12*PT)+17, by0+31, 34, (255, 255, 255))
    d.text((bx1-int(12*PT)-lw, by0+31), lbl, font=lf, fill=(255, 255, 255), anchor="lm")

    y += ch + int(12*PT)
    if y > H - 300:
        break

# ── real tab bar off the capture ─────────────────────────────────────────────
img.paste(base.crop((0, 2700, W, H)), (0, 2700))
img.save('build/screens/07_nearby.png')
print('build/screens/07_nearby.png', img.size, 'cards drawn to y', y)
