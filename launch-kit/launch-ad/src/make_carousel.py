#!/usr/bin/env python3
"""Five-slide Instagram carousel (1080x1350) for the launch.

Built from the app's own assets — the real wordmark, real screenshots, the
Higgsfield hero still, and the brand ramp — so nothing on screen is invented.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np, pathlib

W, H = 1080, 1350
HERE  = pathlib.Path(__file__).parent
ROOT  = HERE.parent
OUT   = ROOT / "build" / "carousel"; OUT.mkdir(parents=True, exist_ok=True)
BODONI, JOST = str(HERE/"fonts"/"BodoniModa.ttf"), str(HERE/"fonts"/"Jost.ttf")
BRAND = ['#101820','#165C7D','#007396','#0093B2','#369DA0','#56B093','#D4EB8E']
LIME, INK = (212,235,142), (7,13,17)

def hexrgb(c): return tuple(int(c[i:i+2],16) for i in (1,3,5))

def tracked(d, xy, text, font, fill, track=0.0, anchor='c'):
    ws=[d.textlength(ch,font=font) for ch in text]
    total=sum(ws)+track*(len(text)-1); x,y=xy
    if anchor=='c': x-=total/2
    for ch,w in zip(text,ws): d.text((x,y),ch,font=font,fill=fill); x+=w+track
    return total

def ground():
    """Dark base with the brand ribbon drifting through it, heavily blurred."""
    img = Image.new('RGB',(W,H),INK)
    g = Image.new('RGB',(W,H),(0,0,0)); d=ImageDraw.Draw(g)
    stops=[hexrgb(c) for c in BRAND]
    for k in range(3):
        yb, amp = H*0.62 + k*110, 150 - k*40
        for x in range(-40, W+40, 6):
            t=(x+40)/(W+80)*(len(stops)-1); i=min(int(t),len(stops)-2); f=t-i
            col=tuple(int(stops[i][j]*(1-f)+stops[i+1][j]*f) for j in range(3))
            y=yb+np.sin(x/430+k*1.2)*amp+np.sin(x/165+k*2.0)*amp*0.3
            d.ellipse([x-46,y-46,x+46,y+46], fill=col)
    g = g.filter(ImageFilter.GaussianBlur(72))
    img = Image.blend(img, Image.blend(img, g, 0.85), 0.55)
    # vignette
    v=Image.new('L',(W,H),0); vd=ImageDraw.Draw(v)
    vd.ellipse([-W*0.35,-H*0.28,W*1.35,H*1.28],fill=255)
    v=v.filter(ImageFilter.GaussianBlur(190))
    return Image.composite(img, Image.new('RGB',(W,H),INK), v)

def gradbar(w,h=3):
    bar=Image.new('RGB',(w,h)); d=ImageDraw.Draw(bar); stops=[hexrgb(c) for c in BRAND]
    for x in range(w):
        t=x/(w-1)*(len(stops)-1); i=min(int(t),len(stops)-2); f=t-i
        d.line([(x,0),(x,h)],fill=tuple(int(stops[i][j]*(1-f)+stops[i+1][j]*f) for j in range(3)))
    return bar

def wordmark(width):
    wm=Image.open(HERE/"wordmark_alpha.png").convert('RGBA')
    a=np.array(wm); a[:,:,0:3]=255
    wm=Image.fromarray(a,'RGBA')
    return wm.resize((width,int(wm.height*width/wm.width)), Image.LANCZOS)

def headline(img, lines, size=88, y=170, colour=(255,255,255)):
    lay=Image.new('RGBA',(W,H),(0,0,0,0)); d=ImageDraw.Draw(lay)
    f=ImageFont.truetype(BODONI,size); step=int(size*1.2)
    for i,l in enumerate(lines): tracked(d,(W/2,y+i*step),l,f,colour+(255,),track=1.4)
    sh=lay.filter(ImageFilter.GaussianBlur(16)); sa=np.array(sh)
    sh=Image.fromarray(np.dstack([np.zeros_like(sa[:,:,0])]*3+[(sa[:,:,3]*0.5).astype('uint8')]),'RGBA')
    img.paste(sh,(0,0),sh); img.paste(lay,(0,0),lay)

def kicker(img, text, y, colour=LIME, size=27, track=7.0):
    d=ImageDraw.Draw(img); tracked(d,(W/2,y),text,ImageFont.truetype(JOST,size),colour+(255,),track=track)

def paste_fit(img, src, box, radius=26, shadow=True):
    """Fit src inside box (l,t,r,b), rounded, with a soft drop shadow."""
    l,t,r,b = box; bw,bh = r-l, b-t
    s = min(bw/src.width, bh/src.height)
    im = src.resize((int(src.width*s), int(src.height*s)), Image.LANCZOS).convert('RGBA')
    m = Image.new('L', im.size, 0); ImageDraw.Draw(m).rounded_rectangle([0,0,im.width-1,im.height-1], radius, fill=255)
    im.putalpha(m)
    x, y = l+(bw-im.width)//2, t+(bh-im.height)//2
    if shadow:
        sh=Image.new('RGBA',(W,H),(0,0,0,0)); sh.paste(Image.new('RGBA',im.size,(0,0,0,190)),(x,y+16),m)
        img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(34)))
    img.alpha_composite(im,(x,y))

def slide(n, build):
    img = ground().convert('RGBA'); build(img)
    bar = gradbar(int(W*0.42)); img.paste(bar, ((W-bar.width)//2, H-92))
    d=ImageDraw.Draw(img)
    tracked(d,(W/2,H-70),f"{n} / 5",ImageFont.truetype(JOST,21),(120,145,158,255),track=3)
    img.convert('RGB').save(OUT/f"slide{n}.png"); print("wrote", OUT/f"slide{n}.png")

# ── the five ──────────────────────────────────────────────────────────────
def s1(img):
    headline(img, ["Day one is", "the loneliest day."], 92, 430)
    kicker(img, "MILTON NATION ALUMNI", 300)
    kicker(img, "SWIPE", 900, (150,175,188))
    d = ImageDraw.Draw(img)                      # Jost ships no arrow glyph
    cx, cy = W/2 + 78, 913
    d.line([(cx,cy-9),(cx+11,cy),(cx,cy+9)], fill=(150,175,188,255), width=3)
    d.line([(cx-13,cy),(cx+10,cy)],          fill=(150,175,188,255), width=3)

def s2(img):
    hero = Image.open(ROOT/"assets"/"hero-still.png")
    hero = hero.crop((int(hero.width*0.16), int(hero.height*0.20),
                      int(hero.width*0.84), int(hero.height*0.86)))
    paste_fit(img, hero, (196, 285, 884, 1035), radius=18, shadow=False)
    headline(img, ["Now there's", "somewhere to go."], 74, 120)
    kicker(img, "LIVE ON THE APP STORE", 1075)

def s3(img):
    scr = Image.open(ROOT/"assets"/"screen-community-clean.png")
    paste_fit(img, scr.crop((0,0,scr.width,int(scr.height*0.72))), (330, 330, 750, 1035), radius=30)
    headline(img, ["A community."], 70, 140)
    kicker(img, "REAL PEOPLE.  REAL DAYS.  REAL SUPPORT.", 240, (150,175,188), 22, 4.5)

def s4(img):
    d=ImageDraw.Draw(img)
    f=ImageFont.truetype(BODONI,300)
    tracked(d,(W/2,430),"1,096",f,(255,255,255,255),track=2)
    kicker(img, "D A Y S   O F   R E C O V E R Y", 880, (190,215,225), 26, 5)
    headline(img, ["Every day, counted."], 62, 1010)

def s5(img):
    wm = wordmark(560)
    wm = wm.crop((0, 0, wm.width, int(wm.height*0.62)))   # logotype only
    img.alpha_composite(wm, ((W-wm.width)//2, 400))
    kicker(img, "M I L T O N   N A T I O N   A L U M N I", 400+wm.height+28,
           (168,192,203), 24, 4)
    bar = gradbar(int(W*0.38)); img.paste(bar, ((W-bar.width)//2, 660))
    kicker(img, "NOW ON THE APP STORE", 725)
    kicker(img, "AND GOOGLE PLAY", 782, (150,175,188), 24, 6)
    headline(img, ["You're not doing", "this alone."], 54, 900, (205,225,232))

for i, fn in enumerate([s1,s2,s3,s4,s5], 1):
    slide(i, fn)
