#!/usr/bin/env python3
"""Same five carousel slides, with every piece of TYPE removed.
Backgrounds, phone imagery, wordmark and gradient bars only — so the text
can be rebuilt as live, editable text in Canva on top of these."""
import importlib.util, pathlib, sys
from PIL import Image, ImageDraw

HERE = pathlib.Path(__file__).parent
spec = importlib.util.spec_from_file_location("mc", HERE/"make_carousel.py")
mc = importlib.util.module_from_spec(spec)

# stub out every type-drawing call before the module body runs its render loop
_orig_headline, _orig_kicker, _orig_tracked = None, None, None
sys.modules["mc"] = mc
import types
src = (HERE/"make_carousel.py").read_text().split("# ── the five")[0]
exec(compile(src, "make_carousel.py", "exec"), mc.__dict__)

W, H, ROOT = mc.W, mc.H, mc.ROOT
OUT = ROOT/"build"/"carousel_plates"; OUT.mkdir(parents=True, exist_ok=True)

def p1(img): pass
def p2(img):
    hero = Image.open(ROOT/"assets"/"hero-still.png")
    hero = hero.crop((int(hero.width*0.16), int(hero.height*0.20),
                      int(hero.width*0.84), int(hero.height*0.86)))
    mc.paste_fit(img, hero, (196,285,884,1035), radius=18, shadow=False)
def p3(img):
    scr = Image.open(ROOT/"assets"/"screen-community-clean.png")
    mc.paste_fit(img, scr.crop((0,0,scr.width,int(scr.height*0.72))), (330,330,750,1035), radius=30)
def p4(img): pass
def p5(img):
    wm = mc.wordmark(560); wm = wm.crop((0,0,wm.width,int(wm.height*0.62)))
    img.alpha_composite(wm, ((W-wm.width)//2, 400))
    bar = mc.gradbar(int(W*0.38)); img.paste(bar, ((W-bar.width)//2, 660))

for n, fn in enumerate([p1,p2,p3,p4,p5], 1):
    img = mc.ground().convert('RGBA'); fn(img)
    bar = mc.gradbar(int(W*0.42)); img.paste(bar, ((W-bar.width)//2, H-92))
    img.convert('RGB').save(OUT/f"plate{n}.png", optimize=True)
    print("wrote", OUT/f"plate{n}.png")
