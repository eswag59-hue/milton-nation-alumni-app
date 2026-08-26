/* Photographic finish.  Without this the plate layer and the drawn layer sit in
   two different worlds and the composite reads as a mock-up: bloom and grain are
   what put the crisp UI and the shot environment on the same piece of film. */
function Grade(W, H){
  const BW = W>>2, BH = H>>2;                       // bloom at quarter res
  const mk = (w,h) => { const c=document.createElement('canvas'); c.width=w; c.height=h;
                        return [c, c.getContext('2d')]; };
  const [b1,g1] = mk(BW,BH), [b2,g2] = mk(BW,BH), [b3,g3] = mk(BW,BH);
  const [tmp,tg] = mk(W,H), [out,og] = mk(W,H);

  /* Deterministic grain: four tiles built once from a seeded PRNG, cycled by
     frame index.  Generating per frame would make the render non-repeatable. */
  const GT = [], GW = W>>1, GH = H>>1;
  let s = 0x9E3779B9;
  const rnd = () => { s|=0; s=s+0x6D2B79F5|0; let t=Math.imul(s^s>>>15,1|s);
                      t=t+Math.imul(t^t>>>7,61|t)^t; return ((t^t>>>14)>>>0)/4294967296; };
  for (let k=0;k<4;k++){
    const [c,cg] = mk(GW,GH); const d = cg.createImageData(GW,GH);
    for (let i=0;i<d.data.length;i+=4){
      const v = 128 + (rnd()-0.5)*84;
      d.data[i]=d.data[i+1]=d.data[i+2]=v; d.data[i+3]=255;
    }
    cg.putImageData(d,0,0); GT.push(c);
  }

  return function apply(src, frame, o){
    o = o || {};
    const bloomAmt = o.bloom !== undefined ? o.bloom : 0.24;
    const grainAmt = o.grain !== undefined ? o.grain : 0.055;
    const caAmt    = o.ca    !== undefined ? o.ca    : 0.0022;
    const vig      = o.vig   !== undefined ? o.vig   : 0.34;

    // ── chromatic aberration: isolate each channel, then re-add at its own scale
    og.globalCompositeOperation='source-over'; og.globalAlpha=1;
    og.clearRect(0,0,W,H); og.fillStyle='#000'; og.fillRect(0,0,W,H);
    const CH = [['#FF0000', 1+caAmt], ['#00FF00', 1], ['#0000FF', 1-caAmt]];
    for (const [mask, k] of CH){
      tg.globalCompositeOperation='source-over'; tg.globalAlpha=1;
      tg.drawImage(src,0,0);
      tg.globalCompositeOperation='multiply'; tg.fillStyle=mask; tg.fillRect(0,0,W,H);
      og.globalCompositeOperation='lighter';
      og.drawImage(tmp, W/2-(W*k)/2, H/2-(H*k)/2, W*k, H*k);
    }

    // ── bloom: square the frame to crush everything but the highlights
    g1.globalCompositeOperation='source-over'; g1.globalAlpha=1;
    g1.clearRect(0,0,BW,BH); g1.drawImage(out,0,0,BW,BH);
    g2.globalCompositeOperation='source-over'; g2.globalAlpha=1;
    g2.clearRect(0,0,BW,BH); g2.drawImage(b1,0,0);
    g2.globalCompositeOperation='multiply'; g2.drawImage(b1,0,0);
    g2.globalCompositeOperation='multiply'; g2.drawImage(b1,0,0);
    /* Blur the quarter-res bright pass, not the delivery frame.  A 46px blur
       over 1080x1920 was costing ~45 minutes a render for a result that is
       indistinguishable from the same blur applied before the upscale. */
    og.globalCompositeOperation='lighter';
    g3.globalCompositeOperation='source-over'; g3.globalAlpha=1;
    g3.clearRect(0,0,BW,BH); g3.filter='blur(3.5px)'; g3.drawImage(b2,0,0);
    g3.filter='none';
    og.globalAlpha=bloomAmt; og.drawImage(b3,0,0,W,H);
    g3.clearRect(0,0,BW,BH); g3.filter='blur(11.5px)'; g3.drawImage(b2,0,0);
    g3.filter='none';
    og.globalAlpha=bloomAmt*0.55; og.drawImage(b3,0,0,W,H);
    og.globalAlpha=1;

    // ── vignette
    og.globalCompositeOperation='source-over';
    const rg = og.createRadialGradient(W/2,H*0.47,H*0.18, W/2,H*0.47,H*0.70);
    rg.addColorStop(0,'rgba(0,0,0,0)'); rg.addColorStop(1,`rgba(0,0,0,${vig})`);
    og.fillStyle=rg; og.fillRect(0,0,W,H);

    // ── grain
    og.globalCompositeOperation='overlay'; og.globalAlpha=grainAmt;
    og.drawImage(GT[frame & 3], 0, 0, W, H);
    og.globalCompositeOperation='source-over'; og.globalAlpha=1;
    return out;
  };
}
