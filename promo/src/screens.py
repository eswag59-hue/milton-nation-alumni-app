"""Build app screens for the film: real header/tabbar pixels + native counter card."""
from PIL import Image, ImageDraw
from engine import (font, rrect_mask, vgrad, text_layer, text_width,
                    INK, TEAL, CYAN, GREY, PAPER, WHITE, SAGE, LIME, AMBER, RED)

SW, SH = 1170, 2352           # status-bar-stripped screen
HEADER_H = 186
TABBAR_H = 252
BG = (239, 242, 242)
_src = lambda n: Image.open(f'ui/{n}.png').convert('RGB')

def header():   return _src('0349').crop((0, 0, SW, HEADER_H))
def tabbar():   return _src('0349').crop((0, SH-TABBAR_H, SW, SH))

def _card(dr, box, radius, fill):
    dr.rounded_rectangle(box, radius=radius, fill=fill)

def counter_card(img, y0, value_text, num_alpha=1.0):
    """The hero sobriety card, drawn natively at Milton's exact palette."""
    d = ImageDraw.Draw(img)
    L, R = 48, 1122
    _card(d, [L, y0, R, y0+814], 46, (219, 237, 239))
    cx = (L+R)//2
    # big number
    if value_text:
        f = font('InterDisplay-Bold', 196)
        img.alpha_composite(text_layer(img.size, (cx, y0+178), value_text, f, INK,
                                       tracking=-6, anchor='mm', alpha=num_alpha))
    img.alpha_composite(text_layer(img.size, (cx, y0+338), 'days', font('InterDisplay-Regular', 50),
                                   GREY, anchor='mm'))
    img.alpha_composite(text_layer(img.size, (cx, y0+418), 'Living proof that recovery works',
                                   font('InterDisplay-MediumItalic', 46), TEAL, anchor='mm'))
    # stat strip
    _card(d, [L+48, y0+468, R-48, y0+630], 28, (232, 244, 245))
    cells = [('156', 'weeks'), ('36', 'months'), ('3', 'years')]
    span = (R-48)-(L+48)
    for i, (n, lab) in enumerate(cells):
        ccx = L+48 + span*(i+0.5)/3
        if i: d.line([(L+48+span*i/3, y0+498), (L+48+span*i/3, y0+600)], fill=(206, 224, 226), width=3)
        img.alpha_composite(text_layer(img.size, (ccx, y0+528), n, font('InterDisplay-Bold', 62), INK, anchor='mm'))
        img.alpha_composite(text_layer(img.size, (ccx, y0+590), lab, font('InterDisplay-Regular', 40), GREY, anchor='mm'))
    # pill
    _card(d, [L+48, y0+672, R-48, y0+770], 42, (198, 226, 231))
    img.alpha_composite(text_layer(img.size, (cx, y0+721), '↺  Update recovery date',
                                   font('InterDisplay-SemiBold', 46), TEAL, anchor='mm'))
    return y0+814

def reflection_card(img, y0):
    d = ImageDraw.Draw(img)
    L, R = 48, 1122
    _card(d, [L, y0, R, y0+470], 46, WHITE)
    img.alpha_composite(text_layer(img.size, (L+56, y0+64), '“',
                                   font('InterDisplay-Bold', 96), TEAL, anchor='lm'))
    img.alpha_composite(text_layer(img.size, (L+128, y0+74), 'Daily Reflection',
                                   font('InterDisplay-Bold', 52), INK, anchor='lm'))
    quote = ['Addiction begins with the hope that', 'something out there can instantly fill up',
             'the emptiness inside.']
    for i, ln in enumerate(quote):
        img.alpha_composite(text_layer(img.size, (L+56, y0+186+i*62), ln,
                                       font('InterDisplay-Italic', 50), INK, anchor='lm'))
    img.alpha_composite(text_layer(img.size, (L+56, y0+408), '— Jean Kilbourne',
                                   font('InterDisplay-Regular', 46), TEAL, anchor='lm'))
    return y0+470

def home_body(value_text='1,097', num_alpha=1.0):
    """Tall scrollable body: native welcome + counter + reflection, then the real 0349 body."""
    real = _src('0349').crop((0, 486, SW, SH-TABBAR_H))   # start after the reflection card
    native_h = 1580
    body = Image.new('RGBA', (SW, native_h+real.height), BG+(255,))
    body.alpha_composite(text_layer(body.size, (48, 92), 'Welcome back, alex',
                                    font('InterDisplay-Bold', 68), INK, anchor='lm'))
    body.alpha_composite(text_layer(body.size, (48, 172), 'Your recovery journey continues today',
                                    font('InterDisplay-Regular', 48), TEAL, anchor='lm'))
    y = counter_card(body, 232, value_text, num_alpha)
    reflection_card(body, y+56)
    body.paste(real, (0, native_h))
    return body.convert('RGB')

def screen(body, scroll=0):
    """Compose a full 1170x2352 screen from a tall body at a scroll offset."""
    out = Image.new('RGB', (SW, SH), BG)
    view_h = SH - HEADER_H - TABBAR_H
    s = max(0, min(int(scroll), body.height - view_h))
    out.paste(body.crop((0, s, SW, s+view_h)), (0, HEADER_H))
    out.paste(header(), (0, 0))
    out.paste(tabbar(), (0, SH-TABBAR_H))
    return out

def full(name):
    """A real screenshot, unmodified (already status-bar stripped)."""
    return _src(name)
