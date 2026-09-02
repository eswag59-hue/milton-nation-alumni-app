/* An iPhone 17, drawn AROUND the screen.

   The screen stays ground truth — generated hardware is never a symmetric
   rectangle, so a fitted screenshot always overran one rail, and deriving the
   body from the screen makes the bezel uniform by construction.

   The earlier version was geometrically an iPhone 11: measured against a real
   17 Pro (71.9mm body, 66.6mm display, 402x874pt) the black bezel was 1.7x too
   thick and the screen corner radius was 8.8% of screen width against a true
   13.7%, which left a fat mismatched corner where the two radii disagreed.
   Everything below is that measurement:

     black bezel   1.2mm / 66.6mm  = 0.018 of screen width
     titanium rail 1.4mm / 66.6mm  = 0.021
     screen radius 55.2pt / 402pt  = 0.137
     island        125 x 36.7pt    = 0.311 x 0.0913, 11pt down
     home bar      139 x 5pt       = 0.346 x 0.0057 of height, 8pt up          */

/* Screen light spilling onto the bezel and rail is the cue that sells a lit
   display. Blurring the source once per texture keeps it to one draw a frame. */
const _spillCache = new Map();
function spillTex(im) {
  let c = _spillCache.get(im);
  if (!c) {
    c = document.createElement('canvas');
    c.width = 128; c.height = Math.max(1, Math.round(128 * im.height / im.width));
    const g2 = c.getContext('2d');
    g2.filter = 'blur(6px)';
    g2.drawImage(im, 0, 0, c.width, c.height);
    g2.filter = 'none';
    _spillCache.set(im, c);
  }
  return c;
}

function drawDevice(ctx, tex, sx, sy, sw, sh, opts) {
  opts = opts || {};
  const bez  = opts.bezel !== undefined ? opts.bezel : sw * 0.018;
  const rail = opts.rail  !== undefined ? opts.rail  : sw * 0.021;
  const rS   = sw * 0.137;
  const rB   = rS + bez + rail;
  const bx = sx - bez - rail, by = sy - bez - rail;
  const bw = sw + 2 * (bez + rail), bh = sh + 2 * (bez + rail);

  ctx.save();

  // contact shadow — the phone has to sit in the shot, not float over it
  ctx.save();
  ctx.shadowColor = 'rgba(0,0,0,.80)'; ctx.shadowBlur = sw * 0.30;
  ctx.shadowOffsetY = sh * 0.028;
  ctx.fillStyle = '#05080B';
  ctx.beginPath(); ctx.roundRect(bx, by, bw, bh, rB); ctx.fill();
  ctx.restore();

  // titanium: bright chamfer at the outer edge, darker flank, warm bounce
  const rg = ctx.createLinearGradient(bx, by, bx + bw, by + bh);
  rg.addColorStop(0.00, '#DCE3E8');
  rg.addColorStop(0.04, '#7C8790');
  rg.addColorStop(0.14, '#262E34');
  rg.addColorStop(0.34, '#525C64');
  rg.addColorStop(0.52, '#252D33');
  rg.addColorStop(0.70, '#5E6971');
  rg.addColorStop(0.88, '#1E262B');
  rg.addColorStop(0.96, '#8E99A1');
  rg.addColorStop(1.00, '#E4EAEE');
  ctx.fillStyle = rg;
  ctx.beginPath(); ctx.roundRect(bx, by, bw, bh, rB); ctx.fill();

  // the black glass border inside the rail
  ctx.fillStyle = '#05070A';
  ctx.beginPath();
  ctx.roundRect(bx + rail, by + rail, bw - 2 * rail, bh - 2 * rail, rB - rail);
  ctx.fill();

  // screen light spilling outward across bezel and rail
  const sp = opts.spill;
  if (sp) {
    ctx.save();
    ctx.beginPath();
    ctx.roundRect(bx, by, bw, bh, rB);
    ctx.roundRect(sx - bez, sy - bez, sw + 2 * bez, sh + 2 * bez, rS + bez);
    ctx.clip('evenodd');
    ctx.globalCompositeOperation = 'lighter';
    ctx.globalAlpha = 0.22;
    const g2 = bez + rail;
    ctx.drawImage(spillTex(sp), sx - g2 * 1.8, sy - g2 * 1.8,
                  sw + g2 * 3.6, sh + g2 * 3.6);
    ctx.restore();
  }

  // the screen
  ctx.save();
  ctx.beginPath(); ctx.roundRect(sx, sy, sw, sh, rS); ctx.clip();
  ctx.fillStyle = '#000'; ctx.fillRect(sx, sy, sw, sh);
  if (typeof tex === 'function') tex(sx, sy, sw, sh);
  else if (tex) ctx.drawImage(tex, sx, sy, sw, sh);

  if (opts.island !== false) {
    const iw = sw * 0.311, ih = sw * 0.0913;
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.roundRect(sx + sw / 2 - iw / 2, sy + sw * 0.027, iw, ih, ih / 2);
    ctx.fill();
    // the lens, just visible in the island
    ctx.fillStyle = 'rgba(28,38,48,.9)';
    ctx.beginPath();
    ctx.arc(sx + sw / 2 + iw * 0.30, sy + sw * 0.027 + ih / 2, ih * 0.27, 0, 7);
    ctx.fill();
  }
  if (opts.homebar !== false) {
    const hw = sw * 0.346, hh = sh * 0.0057;
    ctx.fillStyle = 'rgba(0,0,0,.34)';
    ctx.beginPath();
    ctx.roundRect(sx + sw / 2 - hw / 2, sy + sh - sh * 0.0092 - hh, hw, hh, hh / 2);
    ctx.fill();
  }
  // one soft raking highlight, not a wash
  const gl = ctx.createLinearGradient(sx, sy, sx + sw * 0.75, sy + sh * 0.42);
  gl.addColorStop(0.00, 'rgba(255,255,255,.085)');
  gl.addColorStop(0.30, 'rgba(255,255,255,.022)');
  gl.addColorStop(0.55, 'rgba(255,255,255,0)');
  ctx.fillStyle = gl; ctx.fillRect(sx, sy, sw, sh);
  ctx.restore();

  // hairline where glass meets metal
  ctx.strokeStyle = 'rgba(226,240,248,.34)';
  ctx.lineWidth = Math.max(sw * 0.0022, 1);
  ctx.beginPath();
  ctx.roundRect(bx + rail * 0.5, by + rail * 0.5, bw - rail, bh - rail, rB - rail * 0.5);
  ctx.stroke();

  // buttons, in their real places: action + volume left, power + camera right
  const bwd = rail * 0.92;
  ctx.fillStyle = '#414B53';
  [[0.148, 0.032], [0.212, 0.070], [0.300, 0.070]].forEach(([p, l]) => {
    ctx.beginPath();
    ctx.roundRect(bx - bwd * 0.42, by + bh * p, bwd, bh * l, bwd * 0.42);
    ctx.fill();
  });
  ctx.beginPath();
  ctx.roundRect(bx + bw - bwd * 0.58, by + bh * 0.232, bwd, bh * 0.098, bwd * 0.42);
  ctx.fill();
  ctx.fillStyle = '#4A555D';
  ctx.beginPath();
  ctx.roundRect(bx + bw - bwd * 0.58, by + bh * 0.372, bwd, bh * 0.052, bwd * 0.42);
  ctx.fill();

  ctx.restore();
  return { bx, by, bw, bh, rB, rS };
}
