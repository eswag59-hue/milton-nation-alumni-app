"""Milton Nation Alumni — promo film engine. Pure-function frame renderer."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, os

F = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'fonts')
_fc = {}
def font(name, size):
    k = (name, int(size))
    if k not in _fc: _fc[k] = ImageFont.truetype(f'{F}/{name}.otf', int(size))
    return _fc[k]

# ---------- brand ----------
INK       = (16, 24, 32)
TEAL      = (0, 115, 150)
TEAL_DEEP = (22, 92, 125)
CYAN      = (0, 147, 178)
SAGE      = (86, 176, 147)
LIME      = (212, 235, 142)
GREY      = (107, 114, 128)
AMBER     = (232, 168, 56)
RED       = (231, 76, 60)
PAPER     = (242, 245, 245)
WHITE     = (255, 255, 255)

# ---------- easing ----------
def c01(x): return 0.0 if x < 0 else (1.0 if x > 1 else x)
def lin(t): return c01(t)
def out3(t): return 1 - (1 - c01(t))**3
def out5(t): return 1 - (1 - c01(t))**5
def inout(t): t = c01(t); return t*t*(3 - 2*t)
def outexpo(t):
    t = c01(t); return 1.0 if t >= 1 else 1 - 2**(-10*t)
def seg(t, a, b):
    """normalised progress of t within [a,b]"""
    return 0.0 if b <= a else c01((t - a) / (b - a))
def fade(t, a, b, c, d):
    """0 before a, ramp a->b, 1 until c, ramp down c->d"""
    if t < a: return 0.0
    if t < b: return out3(seg(t, a, b))
    if t < c: return 1.0
    if t < d: return 1 - inout(seg(t, c, d))
    return 0.0

# ---------- primitives ----------
def rrect_mask(size, r, ss=4):
    w, h = size
    m = Image.new('L', (w*ss, h*ss), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w*ss-1, h*ss-1], radius=int(r*ss), fill=255)
    return m.resize((w, h), Image.LANCZOS)

def vgrad(size, top, bot):
    w, h = size
    g = Image.new('RGB', (1, h))
    px = g.load()
    for y in range(h):
        f = y/max(1, h-1)
        px[0, y] = tuple(int(top[i] + (bot[i]-top[i])*f) for i in range(3))
    return g.resize((w, h), Image.BILINEAR)

def radial_glow(size, cx, cy, rad, color, strength=1.0):
    """soft additive glow layer (RGB)"""
    w, h = size
    s = max(8, int(min(w, h)/12))
    small = Image.new('L', (s, s), 0)
    d = ImageDraw.Draw(small)
    for i in range(14, 0, -1):
        rr = rad*i/14 * s/max(w, h)
        a = int(255*strength*(1-i/14)**2.0)
        d.ellipse([cx*s/w-rr, cy*s/h-rr, cx*s/w+rr, cy*s/h+rr], fill=a)
    small = small.filter(ImageFilter.GaussianBlur(s/14))
    m = small.resize((w, h), Image.BICUBIC)
    layer = Image.new('RGB', (w, h), color)
    out = Image.new('RGB', (w, h), (0, 0, 0))
    out.paste(layer, (0, 0), m)
    return out

def screen_add(base, layer, amt=1.0):
    from PIL import ImageChops
    if amt >= 1.0: return ImageChops.add(base, layer)
    return ImageChops.add(base, layer.point(lambda v: int(v*amt)))

# ---------- text ----------
def text_layer(size, xy, s, fnt, fill, tracking=0, anchor='mm', alpha=1.0):
    """Render text with letter-spacing onto a transparent RGBA layer."""
    lay = Image.new('RGBA', size, (0, 0, 0, 0))
    if alpha <= 0.001 or not s: return lay
    d = ImageDraw.Draw(lay)
    chars, widths = list(s), []
    for ch in chars:
        widths.append(d.textlength(ch, font=fnt))
    total = sum(widths) + tracking*(len(chars)-1 if chars else 0)
    a = fnt.getbbox('Hxg')
    asc = a[1]; hgt = a[3]-a[1]
    x, y = xy
    if anchor[0] == 'm': x -= total/2
    elif anchor[0] == 'r': x -= total
    if anchor[1] == 'm': y -= hgt/2 + asc
    elif anchor[1] == 'b': y -= hgt + asc
    else: y -= asc
    col = fill + (int(255*c01(alpha)),)
    for ch, w in zip(chars, widths):
        d.text((x, y), ch, font=fnt, fill=col)
        x += w + tracking
    return lay

def text_width(s, fnt, tracking=0):
    d = ImageDraw.Draw(Image.new('L', (8, 8)))
    if not s: return 0
    return sum(d.textlength(c, font=fnt) for c in s) + tracking*(len(s)-1)

# ---------- device ----------
_dev_cache = {}
def device(screen_img, width, screen_on=True, corner=0.118, bezel=0.026):
    """Front-on phone. screen_img: PIL RGB at 1170x2532-ish (or None for off)."""
    W = int(width)
    SW = int(W*(1-2*bezel))
    SH = int(SW*2532/1170)
    H = int(SH + 2*bezel*W)
    body = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    r = corner*W
    mask = rrect_mask((W, H), r)
    frame = vgrad((W, H), (58, 64, 70), (12, 15, 18)).convert('RGBA')
    # specular rake down the left chamfer + top
    spec = Image.new('L', (W, H), 0)
    sd = ImageDraw.Draw(spec)
    sd.rounded_rectangle([0, 0, W-1, H-1], radius=int(r), outline=255, width=max(2, int(W*0.006)))
    spec = spec.filter(ImageFilter.GaussianBlur(W*0.004))
    hi = Image.new('RGBA', (W, H), (222, 236, 242, 0))
    hi.putalpha(spec.point(lambda v: int(v*0.85)))
    frame.alpha_composite(hi)
    body.paste(frame, (0, 0), mask)
    # screen
    sx, sy = int(bezel*W), int(bezel*W)
    sr = max(2, r - bezel*W*0.9)
    smask = rrect_mask((SW, SH), sr)
    if screen_on and screen_img is not None:
        sc = screen_img.convert('RGB').resize((SW, SH), Image.LANCZOS)
    else:
        sc = vgrad((SW, SH), (10, 13, 16), (4, 6, 8)).convert('RGB')
    body.paste(sc.convert('RGBA'), (sx, sy), smask)
    # glass sheen
    sheen = Image.new('L', (SW, SH), 0)
    ImageDraw.Draw(sheen).polygon([(0, 0), (SW*0.62, 0), (0, SH*0.42)], fill=26)
    sh = Image.new('RGBA', (SW, SH), (255, 255, 255, 0)); sh.putalpha(sheen)
    body.alpha_composite(sh.resize((SW, SH)), (sx, sy))
    return body

def place_device(frame, dev, cx, cy, glow=0.55, reflect=True):
    """Composite device centred at (cx,cy) with teal glow + floor reflection."""
    W, H = frame.size
    dw, dh = dev.size
    x, y = int(cx - dw/2), int(cy - dh/2)
    if glow > 0:
        g = radial_glow((W, H), cx, cy, dw*1.5, (0, 120, 155), strength=glow*0.5)
        rgb = screen_add(frame.convert('RGB'), g)
        frame = rgb.convert('RGBA') if frame.mode == 'RGBA' else rgb
    if reflect:
        rf = dev.transpose(Image.FLIP_TOP_BOTTOM)
        rw, rh = rf.size
        rh2 = int(rh*0.36)
        rf = rf.crop((0, 0, rw, rh2)).filter(ImageFilter.GaussianBlur(dw*0.02))
        ga = Image.new('L', (rw, rh2), 0)
        gd = ImageDraw.Draw(ga)
        for yy in range(rh2):
            gd.line([(0, yy), (rw, yy)], fill=int(52*(1-yy/rh2)**2.1))
        a = rf.getchannel('A').point(lambda v: v)
        from PIL import ImageChops
        rf.putalpha(ImageChops.multiply(a, ga))
        frame.paste(rf, (x, y+dh+int(dh*0.006)), rf)
    frame.paste(dev, (x, y), dev)
    return frame

# ---------- backgrounds ----------
_bg_cache = {}
def bg_plate(path, size, zoom=1.0, ox=0.5, oy=0.5, dim=1.0):
    """Ken-Burns crop of a plate."""
    key = (path, size)
    if key not in _bg_cache:
        im = Image.open(path).convert('RGB')
        W, H = size
        sc = max(W/im.width, H/im.height)*1.18
        _bg_cache[key] = im.resize((int(im.width*sc), int(im.height*sc)), Image.LANCZOS)
    src = _bg_cache[key]
    W, H = size
    cw, ch = W/zoom, H/zoom
    maxx, maxy = src.width-cw, src.height-ch
    x = maxx*c01(ox); y = maxy*c01(oy)
    out = src.crop((int(x), int(y), int(x+cw), int(y+ch))).resize((W, H), Image.LANCZOS)
    if dim != 1.0: out = out.point(lambda v: int(v*dim))
    return out
