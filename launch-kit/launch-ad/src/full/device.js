/* A phone drawn AROUND the screen, not the other way round.

   Every earlier attempt fitted a real screenshot into a generated phone and
   estimated where its display sat. Generated hardware is never a perfect
   symmetric rectangle, so one side always overran the rail. Here the screen is
   the ground truth: the body is derived from it, the bezel is uniform by
   construction, and the screen cannot misfit.                              */
function drawDevice(ctx, tex, sx, sy, sw, sh, opts) {
  opts = opts || {};
  const bez  = opts.bezel  !== undefined ? opts.bezel  : sw*0.030;  // glass border
  const rail = opts.rail   !== undefined ? opts.rail   : sw*0.016;  // titanium
  const rS   = sw*0.088;                                            // screen radius
  const rB   = rS + bez + rail;
  const bx = sx - bez - rail, by = sy - bez - rail;
  const bw = sw + 2*(bez+rail), bh = sh + 2*(bez+rail);

  ctx.save();

  // drop shadow + brand bloom
  ctx.save();
  ctx.shadowColor = 'rgba(0,0,0,.72)'; ctx.shadowBlur = sw*0.20; ctx.shadowOffsetY = sh*0.020;
  ctx.fillStyle = '#0A1116';
  ctx.beginPath(); ctx.roundRect(bx, by, bw, bh, rB); ctx.fill();
  ctx.restore();
  ctx.save();
  ctx.shadowColor = 'rgba(0,150,190,.42)'; ctx.shadowBlur = sw*0.26;
  ctx.fillStyle = '#0A1116';
  ctx.beginPath(); ctx.roundRect(bx, by, bw, bh, rB); ctx.fill();
  ctx.restore();

  // titanium rail — a real metal ramp, bright at the edges, dark in the middle
  const rg = ctx.createLinearGradient(bx, by, bx+bw, by+bh);
  rg.addColorStop(0.00, '#D8DEE3');
  rg.addColorStop(0.06, '#7E8A93');
  rg.addColorStop(0.22, '#2C363D');
  rg.addColorStop(0.50, '#59656D');
  rg.addColorStop(0.78, '#232C32');
  rg.addColorStop(0.94, '#8A959D');
  rg.addColorStop(1.00, '#E2E7EB');
  ctx.fillStyle = rg;
  ctx.beginPath(); ctx.roundRect(bx, by, bw, bh, rB); ctx.fill();

  // black glass sitting inside the rail
  ctx.fillStyle = '#04070A';
  ctx.beginPath(); ctx.roundRect(bx+rail, by+rail, bw-2*rail, bh-2*rail, rB-rail); ctx.fill();

  // the screen
  ctx.save();
  ctx.beginPath(); ctx.roundRect(sx, sy, sw, sh, rS); ctx.clip();
  ctx.fillStyle = '#000'; ctx.fillRect(sx, sy, sw, sh);
  if (typeof tex === 'function') tex(sx, sy, sw, sh);
  else if (tex) ctx.drawImage(tex, sx, sy, sw, sh);

  // dynamic island rides inside the screen, as it does on the real device
  if (opts.island !== false) {
    const iw = sw*0.30, ih = sw*0.082;
    ctx.fillStyle = '#000';
    ctx.beginPath(); ctx.roundRect(sx+sw/2-iw/2, sy+sh*0.016, iw, ih, ih/2); ctx.fill();
  }
  // glass sheen across the top-left
  const gl = ctx.createLinearGradient(sx, sy, sx+sw*0.9, sy+sh*0.5);
  gl.addColorStop(0.00, 'rgba(255,255,255,.10)');
  gl.addColorStop(0.28, 'rgba(255,255,255,.032)');
  gl.addColorStop(0.55, 'rgba(255,255,255,0)');
  ctx.fillStyle = gl; ctx.fillRect(sx, sy, sw, sh);
  ctx.restore();

  // a crisp inner highlight where glass meets metal
  ctx.strokeStyle = 'rgba(215,232,240,.30)';
  ctx.lineWidth = Math.max(sw*0.0028, 1);
  ctx.beginPath(); ctx.roundRect(bx+rail*0.5, by+rail*0.5, bw-rail, bh-rail, rB-rail*0.5); ctx.stroke();

  // side buttons
  ctx.fillStyle = '#39434A';
  const bwd = rail*0.85;
  [[0.20,0.055],[0.30,0.085],[0.40,0.085]].forEach(([p,l])=>{      // left rail
    ctx.beginPath(); ctx.roundRect(bx-bwd*0.45, by+bh*p, bwd, bh*l, bwd*0.45); ctx.fill();
  });
  ctx.beginPath(); ctx.roundRect(bx+bw-bwd*0.55, by+bh*0.30, bwd, bh*0.115, bwd*0.45); ctx.fill();

  ctx.restore();
  return {bx, by, bw, bh, rB};
}
