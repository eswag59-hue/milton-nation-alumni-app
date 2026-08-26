"""Milton Nation Alumni — 60s promo film. Silent master. Every frame = f(t)."""
import sys, os, math
from PIL import Image, ImageDraw, ImageFilter
from engine import *
import screens

FPS = 30
DUR = 60.0

LAYOUT = {
 '16x9': dict(W=1920, H=1080, dev_h=0.86, dev_cx=0.695, dev_cy=0.505,
              tx=0.088, tcy=0.47, talign='l', title_sz=0.062, sub_sz=0.024,
              card_cx=0.30, card_w=0.40),
 '9x16': dict(W=1080, H=1920, dev_h=0.605, dev_cx=0.50, dev_cy=0.655,
              tx=0.50, tcy=0.185, talign='m', title_sz=0.055, sub_sz=0.021,
              card_cx=0.50, card_w=0.78),
 '1x1':  dict(W=1080, H=1080, dev_h=0.72, dev_cx=0.760, dev_cy=0.520,
              tx=0.055, tcy=0.415, talign='l', title_sz=0.049, sub_sz=0.021,
              card_cx=0.285, card_w=0.44),
}
PLATE = {'16x9': dict(bg='plates/bg16.png',  hero='plates/t1_cinstudio_float.png',
                      glass='plates/t4_glasspanes.png', wide='plates/wide16.png',
                      hand='plates/hand16.png', shield='plates/shield16.png'),
         '9x16': dict(bg='plates/bg9.png',   hero='plates/hero9.png',
                      glass='plates/glass9.png', wide='plates/wide9.png',
                      hand='plates/hand9.png', shield='plates/glass9.png'),
         '1x1':  dict(bg='plates/bg16.png',  hero='plates/t1_cinstudio_float.png',
                      glass='plates/t4_glasspanes.png', wide='plates/wide16.png',
                      hand='plates/hand16.png', shield='plates/shield16.png')}

# hero crops out of the real app
POST  = (34,  876, 1136, 1232)
CHAT  = (34, 1440,  980, 1770)
HELP  = (34,  236, 1136,  664)
RESET = (34, 1640, 1136, 2196)

_S = {}
def sc(name):
    if name not in _S: _S[name] = screens.full(name)
    return _S[name]
_HB = None
def homebody(val='1,097'):
    global _HB
    if _HB is None or _HB[0] != val: _HB = (val, screens.home_body(val))
    return _HB[1]

def glass_card(src_img, box, width, radius=34):
    """Lift a region of the app UI onto a floating card with shadow."""
    c = src_img.crop(box)
    w = int(width); h = int(w*c.height/c.width)
    c = c.resize((w, h), Image.LANCZOS).convert('RGBA')
    c.putalpha(rrect_mask((w, h), radius))
    pad = int(w*0.16)
    out = Image.new('RGBA', (w+2*pad, h+2*pad), (0, 0, 0, 0))
    sh = Image.new('RGBA', (w, h), (0, 0, 0, 0)); sh.putalpha(rrect_mask((w, h), radius))
    sh = sh.filter(ImageFilter.GaussianBlur(pad*0.42))
    out.alpha_composite(Image.new('RGBA', sh.size, (0, 0, 0, 150)).copy().convert('RGBA'),
                        (pad, pad+int(pad*0.30)))
    out.putalpha(Image.new('L', out.size, 0))
    shadow = Image.new('RGBA', out.size, (0, 0, 0, 0))
    sm = Image.new('L', out.size, 0)
    ImageDraw.Draw(sm).rounded_rectangle([pad, pad+int(pad*0.3), pad+w, pad+h+int(pad*0.3)],
                                          radius=radius, fill=190)
    shadow.putalpha(sm.filter(ImageFilter.GaussianBlur(pad*0.40)))
    out = Image.alpha_composite(Image.new('RGBA', out.size, (0, 0, 0, 0)), shadow)
    out.alpha_composite(c, (pad, pad))
    return out

def paste_a(base, layer, xy, alpha=1.0):
    if alpha <= 0.002: return
    if alpha < 1.0:
        l = layer.copy(); l.putalpha(l.getchannel('A').point(lambda v: int(v*alpha)))
    else: l = layer
    base.alpha_composite(l, (int(xy[0]), int(xy[1])))

# ------------------------------------------------------------------ type
def title(frame, L, s, alpha, dy=0, size=None, color=(238, 244, 246), track=None):
    W, H = frame.size
    sz = int((size or L['title_sz'])*H)
    f = font('InterDisplay-Light', sz)
    tr = track if track is not None else -sz*0.012
    x = L['tx']*W; y = L['tcy']*H + dy
    frame.alpha_composite(text_layer((W, H), (x, y), s, f, color,
                          tracking=tr, anchor=('l' if L['talign'] == 'l' else 'm')+'m', alpha=alpha))

def sub(frame, L, s, alpha, dy, color=(122, 179, 196), size=None, weight='Medium', track=None):
    W, H = frame.size
    sz = int((size or L['sub_sz'])*H)
    f = font(f'InterDisplay-{weight}', sz)
    x = L['tx']*W; y = L['tcy']*H + dy
    frame.alpha_composite(text_layer((W, H), (x, y), s, f, color,
                          tracking=(track if track is not None else sz*0.02),
                          anchor=('l' if L['talign'] == 'l' else 'm')+'m', alpha=alpha))

def keyline(frame, L, alpha, dy, w_frac=0.055, color=(0, 147, 178)):
    W, H = frame.size
    if alpha <= 0.003: return
    lay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    x = L['tx']*W; y = L['tcy']*H + dy
    ww = w_frac*W*out3(alpha)
    x0 = x if L['talign'] == 'l' else x-ww/2
    ImageDraw.Draw(lay).rectangle([x0, y, x0+ww, y+max(2, H*0.0035)],
                                  fill=color+(int(255*c01(alpha)),))
    frame.alpha_composite(lay)

def title2(frame, L, s1, s2, alpha, dy=0, size=None, c1=(238, 244, 246), c2=None):
    """One line, two colours, correct for left OR centre alignment."""
    W, H = frame.size
    sz = int((size or L['title_sz'])*H); tr = -sz*0.012
    f = font('InterDisplay-Light', sz); f2 = font('InterDisplay-SemiBold', sz)
    w1 = text_width(s1, f, tr); w2 = text_width(s2, f2, tr)
    x0 = (W/2-(w1+w2)/2) if L['talign'] == 'm' else L['tx']*W
    y = L['tcy']*H+dy
    frame.alpha_composite(text_layer((W, H), (x0, y), s1, f, c1, tracking=tr, anchor='lm', alpha=alpha))
    frame.alpha_composite(text_layer((W, H), (x0+w1, y), s2, f2, c2 or LIME, tracking=tr, anchor='lm', alpha=alpha))


def title_block(frame, L, lines, alpha, cy=None, size=None, color=(238, 244, 246), lead=1.30, dy=0):
    """Multi-line centred/left block."""
    W, H = frame.size
    sz = (size or L['title_sz'])
    step = sz*H*lead
    LL = {**L, 'tcy': (cy if cy is not None else L['tcy'])}
    for i, ln in enumerate(lines):
        title(frame, LL, ln, alpha, dy=dy+(i-(len(lines)-1)/2)*step, size=sz, color=color)


def device_at(frame, L, screen_img, scale=1.0, dx=0, dy=0, on=True, glow=0.55):
    W, H = frame.size
    dw = (L['dev_h']*H/2.1036)*scale
    dev = device(screen_img, dw, screen_on=on)
    return place_device(frame, dev, L['dev_cx']*W+dx, L['dev_cy']*H+dy, glow=glow)

NUM_Y_BODY = 232+178          # counter numeral centre inside the tall home body
def CEN(L): return {**L, 'tx':0.5, 'talign':'m', 'tcy':0.5}
def bgp(L, fmt, key, p, z0=1.0, z1=1.06, ox=0.5, oy=0.5, dim=1.0):
    z = z0+(z1-z0)*inout(p)
    return bg_plate(PLATE[fmt][key], (L['W'], L['H']), zoom=z, ox=ox, oy=oy, dim=dim).convert('RGBA')
def dimmed(img, k):
    return img if k >= 0.999 else img.point(lambda v: int(v*k))

_hb_cache = {}
def home_screen(scroll, value=None, num_alpha=1.0):
    s = int(scroll)
    if s not in _hb_cache: _hb_cache[s] = screens.screen(homebody(''), s)
    img = _hb_cache[s]
    if not value: return img
    out = img.convert('RGBA')
    y = screens.HEADER_H + NUM_Y_BODY - s
    if screens.HEADER_H-100 < y < screens.SH:
        out.alpha_composite(text_layer(out.size, (585, y), value,
                            font('InterDisplay-Bold', 196), INK, tracking=-6,
                            anchor='mm', alpha=num_alpha))
    return out.convert('RGB')

# ---------------------------------------------------------------- beats
def b_cold(f_, L, fmt, t, d):
    dim = 0.06+0.30*inout(seg(t, 0, 6.5))
    fr = bgp(L, fmt, 'bg', seg(t, 0, d), 1.16, 1.02, dim=dim)
    C = CEN(L)
    narrow = fmt != '16x9'
    L1 = ['Treatment is', 'ninety days.'] if narrow else ['Treatment is ninety days.']
    L2 = ['Recovery is the', 'rest of your life.'] if narrow else ['Recovery is the rest of your life.']
    for lines, a0, b0, c0, d0 in [(L1, 2.1, 2.9, 4.5, 5.5), (L2, 5.5, 6.3, 8.3, 9.2)]:
        a = fade(t, a0, b0, c0, d0)
        if a > 0:
            title_block(fr, C, lines, a, size=L['title_sz']*1.16,
                        dy=-14*(1-out3(seg(t, a0, b0))))
    return fr

def b_title(f_, L, fmt, t, d):
    if fmt != '16x9':
        fr = bgp(L, fmt, 'bg', seg(t, 0, d), 1.14, 1.02, dim=0.40+0.45*inout(seg(t, 0, 2.2)))
        fr = device_at(fr, L, None, scale=0.96, on=False, glow=0.22+0.16*inout(seg(t, 0, d)))
        T = {**L, 'tx': 0.5, 'talign': 'm', 'tcy': (0.155 if fmt == '9x16' else 0.135)}
    else:
        fr = bgp(L, fmt, 'hero', seg(t, 0, d), 1.14, 1.0, dim=0.42+0.58*inout(seg(t, 0, 2.2)))
        T = {**L, 'tx': 0.575, 'talign': 'l', 'tcy': 0.47}
    a1 = fade(t, 0.9, 1.7, 2.5, 3.2)
    if a1 > 0: title(fr, T, 'nobody recovers alone', a1, dy=-10*(1-out3(seg(t, .9, 1.7))))
    a2 = fade(t, 3.2, 3.9, 4.6, 5.0)
    if a2 > 0: title2(fr, T, 'so we built a ', 'nation', a2)
    return fr


def b_counter(f_, L, fmt, t, d):
    fr = bgp(L, fmt, 'bg', seg(t, 0, d), 1.02, 1.09, dim=0.85)
    wake = out3(seg(t, 0.25, 1.35))
    p = out5(seg(t, 1.0, 4.3))
    val = f'{int(round(1+1096*p)):,}'
    na = out3(seg(t, 0.9, 1.4))
    scroll = 560*inout(seg(t, 5.8, 8.4))
    scr = dimmed(home_screen(scroll, val, na), 0.15+0.85*wake)
    fr = device_at(fr, L, scr, scale=1.0+0.03*inout(seg(t, 0, d)), glow=0.30+0.35*wake)
    a = fade(t, 2.5, 3.3, 7.6, 8.4)
    if a > 0:
        title(fr, L, 'every day.', a, dy=-L['H']*0.045)
        title(fr, L, 'counted.', a, dy=L['H']*0.028, color=LIME)
        keyline(fr, L, a, L['H']*0.085)
    return fr

def b_feature(f_, L, fmt, t, d, shot, line1, line2, box, accent=LIME, note=None):
    fr = bgp(L, fmt, 'bg', seg(t, 0, d), 1.04, 1.10, dim=0.82)
    fr = device_at(fr, L, sc(shot), scale=1.0+0.025*inout(seg(t, 0, d)), glow=0.45)
    a = fade(t, 0.5, 1.3, d-1.1, d-0.35)
    if a > 0:
        title(fr, L, line1, a, dy=-L['H']*0.045)
        title(fr, L, line2, a, dy=L['H']*0.028, color=accent)
        keyline(fr, L, a, L['H']*0.085, color=accent)
    ca = fade(t, 1.9, 2.8, d-1.0, d-0.3)
    if ca > 0:
        card = glass_card(sc(shot), box, L['card_w']*L['W'])
        W, H = fr.size
        rise = 26*(1-out3(seg(t, 1.9, 3.0)))
        ctop = (L['tcy']*H+H*0.125) if fmt != '9x16' else H*0.255
        maxh = H*0.96-ctop
        if card.height > maxh:
            k = maxh/card.height
            card = card.resize((max(1,int(card.width*k)), max(1,int(card.height*k))), Image.LANCZOS)
        paste_a(fr, card, (L['card_cx']*W-card.width/2, ctop+rise), ca)
    if note:
        na = fade(t, 3.4, 4.2, d-1.0, d-0.3)
        if na > 0: sub(fr, CEN(L), note, na*0.8, L['H']*0.415, color=(150, 165, 175),
                       weight='Regular', size=L['sub_sz']*0.80)
    return fr

def b_privacy(f_, L, fmt, t, d):
    fr = bgp(L, fmt, 'glass', seg(t, 0, d), 1.12, 1.0, dim=0.46)
    C = CEN(L); C = {**C, 'tcy': 0.44}
    a = fade(t, 0.5, 1.4, d-1.2, d-0.4)
    if a > 0:
        title(fr, C, 'private by design.', a, dy=-16*(1-out3(seg(t, .5, 1.4))), size=L['title_sz']*1.16)
        keyline(fr, C, a, L['H']*0.055, w_frac=0.05)
    b = fade(t, 1.7, 2.5, d-1.1, d-0.35)
    if b > 0:
        sub(fr, C, 'Face ID  ·  encrypted  ·  screen-capture protected', b, L['H']*0.105,
            color=(150, 200, 214), weight='Regular', size=L['sub_sz']*1.15)
    return fr

def b_end(f_, L, fmt, t, d):
    fr = bgp(L, fmt, 'bg', seg(t, 0, d), 1.12, 1.0, dim=0.30+0.22*inout(seg(t, 0, 3.2)))
    W, H = fr.size
    icon = Image.open('brand/appicon.png').convert('RGBA')
    ih = int(H*0.125); icon = icon.resize((ih, ih), Image.LANCZOS)
    icon.putalpha(rrect_mask((ih, ih), ih*0.225))
    ia = out3(seg(t, 0.3, 1.3)); k = 0.90+0.10*out3(seg(t, 0.3, 1.6))
    iw = int(ih*k); ic = icon.resize((iw, iw), Image.LANCZOS)
    y = H*(0.215 if fmt != '9x16' else 0.255)
    paste_a(fr, ic, (W/2-iw/2, y-iw/2), ia)
    y += ih*0.62
    lg = Image.open('brand/logo_dark_trim.png').convert('RGBA')
    lw = int(W*(0.215 if fmt != '9x16' else 0.52)); lh = int(lw*lg.height/lg.width)
    lg = lg.resize((lw, lh), Image.LANCZOS)
    paste_a(fr, lg, (W/2-lw/2, y), fade(t, 0.9, 1.8, 99, 99))
    y += lh + H*0.052
    ta = fade(t, 1.8, 2.6, 99, 99)
    if ta > 0:
        sub(fr, CEN(L), 'Driven by purpose. Committed to care.', ta, y-H*0.5,
            color=(152, 198, 212), weight='Regular', size=L['sub_sz']*1.02)
    y += H*0.062
    ba = fade(t, 2.7, 3.6, 99, 99)
    if ba > 0:
        ap = Image.open('brand/appstore_trim.png').convert('RGBA')
        gp = Image.open('brand/gplay_trim.png').convert('RGBA')
        bh = int(H*(0.058 if fmt != '9x16' else 0.046))
        ap = ap.resize((int(bh*ap.width/ap.height), bh), Image.LANCZOS)
        gh = int(bh*0.90); gp = gp.resize((int(gh*gp.width/gp.height), gh), Image.LANCZOS)
        gap = int(W*0.020); tot = ap.width+gp.width+gap
        paste_a(fr, ap, (W/2-tot/2, y), ba)
        paste_a(fr, gp, (W/2-tot/2+ap.width+gap, y+(ap.height-gp.height)/2), ba)
        y += ap.height + H*0.055
        fa = fade(t, 3.5, 4.3, 99, 99)
        if fa > 0:
            sub(fr, CEN(L), 'For verified alumni  ·  Demo data shown', fa*0.68, y-H*0.5,
                color=(116, 130, 140), weight='Regular', size=L['sub_sz']*0.72)
    return fr

TL = [
 (0.0,  9.2,  b_cold),
 (9.2, 14.2,  b_title),
 (14.2, 22.6, b_counter),
 (22.6, 28.6, lambda f, L, x, t, d: b_feature(f, L, x, t, d, '0327', 'every win.', 'witnessed.', POST, SAGE)),
 (28.6, 34.6, lambda f, L, x, t, d: b_feature(f, L, x, t, d, '0357', 'your care team.', 'one tap.', CHAT, CYAN)),
 (34.6, 40.6, lambda f, L, x, t, d: b_feature(f, L, x, t, d, '0355', 'meetings.', 'everywhere.', (34, 936, 1136, 1522), LIME)),
 (40.6, 46.6, lambda f, L, x, t, d: b_feature(f, L, x, t, d, '0323', 'and on the hard days,', 'one tap.', HELP, AMBER,
                                              note='A peer-support community — not an emergency service.')),
 (46.6, 52.4, b_privacy),
 (52.4, 60.0, b_end),
]

def render(t, fmt='16x9'):
    L = dict(LAYOUT[fmt])
    for t0, t1, fn in TL:
        if t0 <= t < t1 or (t >= 60.0 and t1 >= 60.0):
            return fn(None, L, fmt, t-t0, t1-t0).convert('RGB')
    return Image.new('RGB', (L['W'], L['H']), (0, 0, 0))

if __name__ == '__main__':
    fmt = sys.argv[1] if len(sys.argv) > 1 else '16x9'
    if sys.argv[2:] and sys.argv[2] == 'proof':
        os.makedirs('proof', exist_ok=True)
        for t in [1.0, 4.0, 7.5, 10.5, 13.5, 15.0, 17.0, 21.0, 25.5, 31.5, 37.5, 44.0, 49.5, 56.5, 59.0]:
            render(t, fmt).save(f'proof/{fmt}_{t:05.1f}.jpg', quality=90)
            print('proof', t, flush=True)
