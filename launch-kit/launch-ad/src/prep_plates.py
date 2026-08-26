"""Turn the raw Higgsfield plates into graded, correctly-sized film assets.

Two products come out of here:

  plates/*.jpg   full-frame environments, rendered at PAD x the delivery size so
                 the film can push in on them without going soft.
  plates/*.png   screen-blend light layers: the bright ribbons and shards lifted
                 off their plate so they can be laid over the drawn phone.

The light layers are a high-pass on luminance, not a threshold.  A hard
threshold left a visible cut edge where the ribbon met the haze; ramping
between lo and hi keeps the falloff the plate already had.
"""
import numpy as np, os
from PIL import Image, ImageFilter

SRC = 'build/plates'
DST = 'src/full/plates'
os.makedirs(DST, exist_ok=True)

OUT_W, OUT_H = 1080, 1920
PAD = 1.25                                   # headroom for the push-in
PW, PH = int(OUT_W*PAD), int(OUT_H*PAD)


def fit(im, w, h, anchor=0.5):
    """Cover-fit, cropping the long axis around `anchor` (0=top, 1=bottom)."""
    s = max(w/im.width, h/im.height)
    im = im.resize((max(w,int(im.width*s+.5)), max(h,int(im.height*s+.5))), Image.LANCZOS)
    x = int((im.width - w) * 0.5)
    y = int((im.height - h) * anchor)
    return im.crop((x, y, x+w, y+h))


def grade(im, lift=0.0, gain=1.0, gamma=1.0, teal=0.0, sat=1.0):
    a = np.asarray(im.convert('RGB')).astype(np.float32)/255.0
    a = np.clip(a*gain + lift, 0, 1) ** gamma
    if sat != 1.0:
        l = a @ np.array([.2126,.7152,.0722], np.float32)
        a = np.clip(l[...,None] + (a-l[...,None])*sat, 0, 1)
    if teal:                                  # pull shadows toward the house ink
        sh = (1.0 - a.mean(2, keepdims=True))**2
        a = np.clip(a + sh*teal*np.array([-0.05, 0.02, 0.06], np.float32), 0, 1)
    return Image.fromarray((a*255+.5).astype(np.uint8))


def light_layer(path, lo, hi, gamma=1.0, gain=1.0, box=None, blur=0.0, flip=False, foot=None, maxw=1400):
    """Lift the luminous part of a plate onto black for a screen blend."""
    im = Image.open(os.path.join(SRC, path)).convert('RGB')
    if box:
        W, H = im.size
        im = im.crop((int(W*box[0]), int(H*box[1]), int(W*box[2]), int(H*box[3])))
    if flip:
        im = im.transpose(Image.FLIP_TOP_BOTTOM)
    if maxw and im.width != maxw:
        im = im.resize((maxw, max(1, round(im.height*maxw/im.width))), Image.LANCZOS)
    if blur:
        im = im.filter(ImageFilter.GaussianBlur(blur))
    a = np.asarray(im).astype(np.float32)/255.0
    l = a @ np.array([.2126,.7152,.0722], np.float32)
    m = np.clip((l-lo)/(hi-lo), 0, 1) ** gamma
    if foot:
        H, Wd = m.shape
        v = np.clip((np.arange(H)/H - foot[0]) / (foot[1]-foot[0]), 0, 1)
        if foot[2]: v = 1.0 - v
        m *= v[:, None]
        u = np.abs(np.arange(Wd)/Wd - .5)*2
        m *= np.clip((0.94-u)/0.14, 0, 1)[None, :]
    return Image.fromarray((np.clip(a*m[...,None]*gain,0,1)*255+.5).astype(np.uint8))


PLATES = [
    # name        source          anchor  grade
    ('hook',     's1_hook.png',   0.50, dict(gain=1.30, gamma=0.94, teal=0.6, sat=1.05)),
    ('nation',   'q2_nation.png', 0.55, dict(gain=0.92, gamma=1.05, teal=0.5, sat=1.06)),
    ('tile',     'p2_tile.png',   0.50, dict(gain=0.88, gamma=1.05, teal=0.7, sat=1.05)),
    ('home',     'p1_title.png',  0.50, dict(gain=0.80, gamma=1.06, teal=0.9, sat=1.00)),
    ('comm',     'q3_panes.png',  0.50, dict(gain=0.84, gamma=1.04, teal=0.9, sat=1.00)),
    ('chat',     'q4_bubbles.png',0.50, dict(gain=1.00, gamma=0.98, teal=1.0, sat=0.98)),
    ('meet',     'p5_map.png',    0.50, dict(gain=0.95, gamma=1.02, teal=0.6, sat=1.08)),
    ('prof',     'q5_dawn.png',   0.24, dict(gain=0.94, gamma=1.02, teal=2.4, sat=0.62)),
    ('end',      's2_end.png',    0.46, dict(gain=0.86, gamma=1.06, teal=1.4, sat=0.92)),
]

for name, src, anchor, gr in PLATES:
    im = Image.open(os.path.join(SRC, src)).convert('RGB')
    im = fit(im, PW, PH, anchor)
    grade(im, **gr).save(f'{DST}/{name}.jpg', quality=93, subsampling=0)
    print('plate', name, src)

# ── screen-blend light layers ────────────────────────────────────────────────
# r1/r2 came back as pure light on pure black, so they need no isolation at all
# — a low lo/hi here only shapes contrast.  They carry the beat: r1 is what
# leaves the screen, r2 is what pours back into it.
light_layer('r1_burst.png',    0.04, 0.40, gamma=1.05, gain=1.15, maxw=1600,
            box=(0.00,0.00,1.00,0.72)).save(f'{DST}/plume_out.png')
light_layer('r2_converge.png', 0.04, 0.40, gamma=1.05, gain=1.15, maxw=1600,
            box=(0.00,0.00,1.00,1.00)).save(f'{DST}/plume_in.png')
# p4's ribbons are softer and wider — they sit behind the phone as ambient bloom.
# Measured: its own phone starts at y 0.245, so the crop stops short of it.
light_layer('p4_in.png', 0.22, 0.70, gamma=1.15, gain=1.00, foot=(0.88, 1.00, True),
            box=(0.00,0.00,1.00,0.235)).save(f'{DST}/plume_soft.png')
# p3's shards sit off the lower-right corner of its phone; starting at x 0.60
# clears the phone's own right edge, which read as a hard vertical streak.
light_layer('p3_out.png', 0.18, 0.64, gamma=1.15, gain=1.40,
            box=(0.60,0.26,1.00,0.60)).save(f'{DST}/shards.png')
print('light layers done')

# ── home screen with the numeral removed ─────────────────────────────────────
# The counter used to paint over the baked-in 1,096 at draw time, but that patch
# inherited the beat's fade-in alpha and so could not hide anything until the
# phone was fully opaque — the screenshot's own value showed through and then
# snapped.  Erasing it once, here, means the film only ever draws one number.
home = Image.open('build/screens/02_home.png').convert('RGB')
hw, hh = home.size
from PIL import ImageDraw as _ID
_ID.Draw(home).rectangle(
    [hw*0.24, hh*0.3020, hw*0.76, hh*0.3700], fill=(222, 240, 243))
home.save('src/full/assets/02_home_blank.png')
print('02_home_blank.png', home.size)

# ── the app icon, set into the glass emblem ──────────────────────────────────
# Ezra: "the logo of the icon you have there doesn't fit in that emblem. Tilt it
# and make it fit" and "you have it on top, but it's not fully on top."  The
# earlier pass drew the icon flat and square over a slab that sits at a 3/4
# angle, so it floated. The face quad below is measured off tile.jpg; the icon
# is warped into it, then the slab's own speculars are put back over the top so
# it reads as printed inside the glass rather than pasted on the front.
from PIL import ImageFilter as _IF

FACE = [(0.211, 0.317), (0.820, 0.308), (0.829, 0.681), (0.217, 0.672)]  # TL TR BR BL
INSET = 0.055                       # the glass has a bevel; hold off the edge


def _coeffs(dst, src):
    m = []
    for (dx, dy), (sx_, sy_) in zip(dst, src):
        m.append([dx, dy, 1, 0, 0, 0, -sx_ * dx, -sx_ * dy])
        m.append([0, 0, 0, dx, dy, 1, -sy_ * dx, -sy_ * dy])
    A = np.array(m, dtype=np.float64)
    B = np.array(src, dtype=np.float64).reshape(8)
    return np.linalg.solve(A.T @ A, A.T @ B)


tile = Image.open(f'{DST}/tile.jpg').convert('RGB')
TW_, TH_ = tile.size
quad = [(fx * TW_, fy * TH_) for fx, fy in FACE]
cx_ = sum(p[0] for p in quad) / 4.0
cy_ = sum(p[1] for p in quad) / 4.0
quad = [(cx_ + (x - cx_) * (1 - INSET), cy_ + (y - cy_) * (1 - INSET)) for x, y in quad]

icon = Image.open('src/full/assets/icon_bright.png').convert('RGB')
# round the icon's own corners so it sits in the slab's radius, not as a square
ic_m = Image.new('L', icon.size, 0)
_ID.Draw(ic_m).rounded_rectangle([0, 0, icon.width - 1, icon.height - 1],
                                 radius=int(icon.width * 0.225), fill=255)
icon.putalpha(ic_m)

src_pts = [(0, 0), (icon.width, 0), (icon.width, icon.height), (0, icon.height)]
warped = icon.transform((TW_, TH_), Image.PERSPECTIVE, _coeffs(quad, src_pts),
                        Image.BICUBIC)

out = tile.copy()
out.paste(warped, (0, 0), warped.split()[3].point(lambda v: int(v * 0.90)))

# put the slab's speculars back over the icon so the glass reads in front of it
base = np.asarray(tile).astype(np.float32)
soft = np.asarray(tile.filter(_IF.GaussianBlur(26))).astype(np.float32)
spec = np.clip((base - soft) * 1.7, 0, 255)
res = np.asarray(out).astype(np.float32)
res = 255.0 - (255.0 - res) * (255.0 - spec) / 255.0          # screen blend
Image.fromarray(np.clip(res, 0, 255).astype(np.uint8)).save(
    f'{DST}/tile_icon.jpg', quality=94, subsampling=0)
print('tile_icon.jpg  face quad', [(round(x), round(y)) for x, y in quad])
