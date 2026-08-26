"""Three 9:16 shorts, ~12s each. Silent masters."""
import sys, os
from PIL import Image, ImageDraw
from engine import *
import screens, film
from film import (LAYOUT, PLATE, bgp, CEN, title, sub, keyline, device_at,
                  glass_card, paste_a, home_screen, sc, dimmed, POST, CHAT, RESET)

FPS = 30
L9 = dict(LAYOUT['9x16'])
L9.update(dev_h=0.50, dev_cy=0.735, tcy=0.150, title_sz=0.050, card_w=0.86, card_cx=0.5)

def endcard(fr, t, d, compact=True):
    W, H = fr.size
    icon = Image.open('brand/appicon.png').convert('RGBA')
    ih = int(H*0.105); icon = icon.resize((ih, ih), Image.LANCZOS)
    icon.putalpha(rrect_mask((ih, ih), ih*0.225))
    ia = out3(seg(t, 0.15, 1.0)); k = 0.90+0.10*out3(seg(t, 0.15, 1.3))
    iw = int(ih*k); ic = icon.resize((iw, iw), Image.LANCZOS)
    y = H*0.335
    paste_a(fr, ic, (W/2-iw/2, y-iw/2), ia)
    y += ih*0.62
    lg = Image.open('brand/logo_dark_trim.png').convert('RGBA')
    lw = int(W*0.50); lh = int(lw*lg.height/lg.width); lg = lg.resize((lw, lh), Image.LANCZOS)
    paste_a(fr, lg, (W/2-lw/2, y), fade(t, 0.6, 1.4, 99, 99))
    y += lh + H*0.048
    ba = fade(t, 1.5, 2.2, 99, 99)
    if ba > 0:
        ap = Image.open('brand/appstore_trim.png').convert('RGBA')
        gp = Image.open('brand/gplay_trim.png').convert('RGBA')
        bh = int(H*0.046)
        ap = ap.resize((int(bh*ap.width/ap.height), bh), Image.LANCZOS)
        gh = int(bh*0.90); gp = gp.resize((int(gh*gp.width/gp.height), gh), Image.LANCZOS)
        gap = int(W*0.026); tot = ap.width+gp.width+gap
        paste_a(fr, ap, (W/2-tot/2, y), ba)
        paste_a(fr, gp, (W/2-tot/2+ap.width+gap, y+(ap.height-gp.height)/2), ba)
        y += ap.height + H*0.046
        fa = fade(t, 2.1, 2.8, 99, 99)
        if fa > 0:
            sub(fr, CEN(L9), 'For verified alumni  ·  Demo data shown', fa*0.66, y-H*0.5,
                color=(116, 130, 140), weight='Regular', size=L9['sub_sz']*0.74)
    return fr

def hook(fr, lines, t, a0, b0, c0, d0, accent=None):
    C = {**CEN(L9), 'tcy': 0.42}
    a = fade(t, a0, b0, c0, d0)
    if a <= 0: return fr
    dy0 = -14*(1-out3(seg(t, a0, b0)))
    for i, ln in enumerate(lines):
        col = accent if (accent and i == len(lines)-1) else (238, 244, 246)
        title(fr, C, ln, a, dy=dy0+(i-(len(lines)-1)/2)*L9['H']*0.072, size=L9['title_sz']*1.20, color=col)
    return fr

# ---------------- A: the counter ----------------
def short_A(t):
    if t < 3.0:
        fr = bgp(L9, '9x16', 'bg', t/3.0, 1.16, 1.04, dim=0.10+0.26*inout(seg(t, 0, 2.6)))
        return hook(fr, ['Day one', 'was the easy part.'], t, 0.5, 1.3, 2.2, 3.0, accent=LIME)
    if t < 9.4:
        u = t-3.0; d = 6.4
        fr = bgp(L9, '9x16', 'bg', seg(u, 0, d), 1.02, 1.10, dim=0.85)
        wake = out3(seg(u, 0.1, 1.0))
        p = out5(seg(u, 0.5, 4.0)); val = f'{int(round(1+1096*p)):,}'
        scr = dimmed(home_screen(0, val, out3(seg(u, 0.4, 0.9))), 0.15+0.85*wake)
        fr = device_at(fr, L9, scr, scale=1.0+0.035*inout(seg(u, 0, d)), glow=0.30+0.35*wake)
        a = fade(u, 3.9, 4.6, d-0.7, d-0.15)
        if a > 0:
            C = {**CEN(L9), 'tcy': 0.145}
            title(fr, C, 'every day.', a, dy=-L9['H']*0.030, size=L9['title_sz']*1.12)
            title(fr, C, 'counted.', a, dy=L9['H']*0.038, color=LIME, size=L9['title_sz']*1.12)
        return fr
    u = t-9.4
    return endcard(bgp(L9, '9x16', 'bg', seg(u, 0, 3.0), 1.10, 1.0, dim=0.32+0.20*inout(seg(u, 0, 2.4))), u, 3.0)

# ---------------- B: three years is something ----------------
def short_B(t):
    if t < 3.0:
        fr = bgp(L9, '9x16', 'bg', t/3.0, 1.16, 1.04, dim=0.10+0.26*inout(seg(t, 0, 2.6)))
        return hook(fr, ['Discharge day', 'is not goodbye.'], t, 0.5, 1.3, 2.2, 3.0, accent=CYAN)
    if t < 9.4:
        u = t-3.0; d = 6.4
        fr = bgp(L9, '9x16', 'bg', seg(u, 0, d), 1.02, 1.10, dim=0.85)
        fr = device_at(fr, L9, sc('0357'), scale=1.0+0.03*inout(seg(u, 0, d)), glow=0.45)
        ca = fade(u, 0.7, 1.6, d-0.7, d-0.15)
        if ca > 0:
            card = glass_card(sc('0357'), CHAT, L9['card_w']*L9['W'])
            W, H = fr.size
            paste_a(fr, card, (W/2-card.width/2, H*0.335+24*(1-out3(seg(u, 0.7, 1.9)))), ca)
        a = fade(u, 2.6, 3.4, d-0.7, d-0.15)
        if a > 0:
            C = {**CEN(L9), 'tcy': 0.145}
            title(fr, C, 'your care team.', a, dy=-L9['H']*0.030, size=L9['title_sz']*1.12)
            title(fr, C, 'one tap.', a, dy=L9['H']*0.038, color=CYAN, size=L9['title_sz']*1.12)
        return fr
    u = t-9.4
    return endcard(bgp(L9, '9x16', 'bg', seg(u, 0, 3.0), 1.10, 1.0, dim=0.32+0.20*inout(seg(u, 0, 2.4))), u, 3.0)

# ---------------- C: no shame in starting over ----------------
def short_C(t):
    if t < 3.2:
        fr = bgp(L9, '9x16', 'bg', t/3.2, 1.16, 1.04, dim=0.10+0.26*inout(seg(t, 0, 2.8)))
        return hook(fr, ['A reset', 'is not a failure.'], t, 0.5, 1.4, 2.4, 3.2, accent=SAGE)
    if t < 9.4:
        u = t-3.2; d = 6.2
        fr = bgp(L9, '9x16', 'bg', seg(u, 0, d), 1.02, 1.10, dim=0.85)
        fr = device_at(fr, L9, sc('0316'), scale=1.0+0.03*inout(seg(u, 0, d)), glow=0.45)
        ca = fade(u, 0.7, 1.6, d-0.7, d-0.15)
        if ca > 0:
            card = glass_card(sc('0316'), RESET, L9['card_w']*L9['W'])
            W, H = fr.size
            paste_a(fr, card, (W/2-card.width/2, H*0.325+24*(1-out3(seg(u, 0.7, 1.9)))), ca)
        a = fade(u, 2.6, 3.4, d-0.7, d-0.15)
        if a > 0:
            C = {**CEN(L9), 'tcy': 0.140}
            title(fr, C, 'no shame', a, dy=-L9['H']*0.030, size=L9['title_sz']*1.12)
            title(fr, C, 'in starting over.', a, dy=L9['H']*0.038, color=SAGE, size=L9['title_sz']*1.12)
        return fr
    u = t-9.4
    return endcard(bgp(L9, '9x16', 'bg', seg(u, 0, 3.0), 1.10, 1.0, dim=0.32+0.20*inout(seg(u, 0, 2.4))), u, 3.0)

SHORTS = {'A_counted': (short_A, 12.4), 'B_careteam': (short_B, 12.4), 'C_startover': (short_C, 12.4)}

if __name__ == '__main__':
    which = sys.argv[1]
    fn, dur = SHORTS[which]
    if sys.argv[2:] and sys.argv[2] == 'proof':
        os.makedirs('proof', exist_ok=True)
        for t in [1.6, 4.2, 6.0, 8.6, 10.4, 12.0]:
            fn(t).convert('RGB').save(f'proof/{which}_{t:04.1f}.jpg', quality=90)
        print('proofs done')
    else:
        out = f'frames_{which}'; os.makedirs(out, exist_ok=True)
        n = int(dur*FPS)
        for i in range(n):
            fn(i/FPS).convert('RGB').save(f'{out}/{i:05d}.jpg', quality=94, subsampling=0)
        print('DONE', which, n, flush=True)
