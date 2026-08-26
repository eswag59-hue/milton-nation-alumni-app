/* Environment layer.  Every ground in this film is a Higgsfield plate, pushed
   and drifted in 2.5D — the flat drawn grounds are what read as cheap.
   Plates are authored at PAD x the delivery frame so the push never softens. */
const PAD = 1.25;

function plateDraw(g, im, W, H, z, dx, dy, alpha){
  if (!im || alpha <= 0.002) return;
  const dw = W*PAD*z, dh = H*PAD*z;
  g.save(); g.globalAlpha = Math.min(1, alpha);
  g.drawImage(im, W/2 - dw/2 + dx, H/2 - dh/2 + dy, dw, dh);
  g.restore();
}

/* p runs 0..1 across the beat; the push is slow and never reverses. */
function plate(g, T, key, W, H, p, alpha, opts){
  opts = opts || {};
  const z  = 1 + p*(opts.push !== undefined ? opts.push : 0.085);
  const dx = (opts.dx || 0) * p * W;
  const dy = (opts.dy !== undefined ? opts.dy : -0.012) * p * H;
  plateDraw(g, T[key], W, H, z, dx, dy, alpha);
}

/* Light layers are RGB-on-black, so 'screen' drops the black for free and no
   alpha channel is needed.  'lighter' is reserved for sparks that should clip. */
function light(g, im, cx, cy, w, alpha, rot, mode){
  if (!im || alpha <= 0.002) return;
  const h = im.height * (w/im.width);
  g.save();
  g.globalCompositeOperation = mode || 'screen';
  g.globalAlpha = Math.min(1, alpha);
  g.translate(cx, cy); if (rot) g.rotate(rot);
  g.drawImage(im, -w/2, -h/2, w, h);
  g.restore();
}

/* Where a point on a plate lands on screen, using the same transform plate()
   applies. Needed so an object composited into a plate — the icon set into the
   glass emblem — can be handed off to a free-floating copy without jumping. */
function plateMap(W, H, p, opts, fx, fy){
  opts = opts || {};
  const z  = 1 + p*(opts.push !== undefined ? opts.push : 0.085);
  const dx = (opts.dx || 0) * p * W;
  const dy = (opts.dy !== undefined ? opts.dy : -0.012) * p * H;
  const dw = W*PAD*z, dh = H*PAD*z;
  return { x: W/2 - dw/2 + dx + fx*dw, y: H/2 - dh/2 + dy + fy*dh, w: dw, h: dh };
}
