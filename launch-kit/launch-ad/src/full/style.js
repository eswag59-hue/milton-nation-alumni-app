/* Style lifted from the reference cut Ezra supplied — matched deliberately,
   not invented. Measured off its frames:
     ground   near-black #090909, not a teal gradient
     waves    layered deep teal, bottom third only
     phone    thin dark bezel, light UI — NOT photoreal metal, which is why the
              reference never suffers the screen-overruns-the-rail problem
     caption  bottom centre, lowercase, two beats: white then lime           */
const INK   = '#080A0C';
const LIME  = '#C8E572';
const WAVES = ['#002933','#003D4C','#0A5163','#12657C'];

function refGround(g,W,H){ g.fillStyle=INK; g.fillRect(0,0,W,H); }

function refWaves(g,W,H,t,alpha){
  if(alpha<=0.002) return;
  g.save(); g.globalAlpha=alpha;
  for(let k=0;k<WAVES.length;k++){
    const base = H*(0.80 + k*0.055);
    const amp  = H*(0.030 - k*0.004);
    const drift= t*(16 + k*9);
    g.beginPath(); g.moveTo(-40,H);
    for(let x=-40;x<=W+40;x+=10){
      const y = base
              + Math.sin((x+drift)/300 + k*1.1)*amp
              + Math.sin((x+drift)/118 + k*2.3)*amp*0.42;
      g.lineTo(x,y);
    }
    g.lineTo(W+40,H); g.closePath();
    g.fillStyle = WAVES[k]; g.globalAlpha = alpha*(0.95 - k*0.13);
    g.fill();
  }
  g.restore();
}

/* the phone: thin dark bezel derived from the screen, so it cannot misfit */
function refPhone(g, tex, sx, sy, sw, sh){
  const bez = sw*0.021, r = sw*0.082, rB = r+bez;
  g.save();
  g.shadowColor='rgba(0,0,0,.65)'; g.shadowBlur=sw*0.14; g.shadowOffsetY=sh*0.012;
  g.fillStyle='#14181C';
  g.beginPath(); g.roundRect(sx-bez, sy-bez, sw+2*bez, sh+2*bez, rB); g.fill();
  g.shadowBlur=0; g.shadowOffsetY=0;
  g.save();
  g.beginPath(); g.roundRect(sx,sy,sw,sh,r); g.clip();
  g.fillStyle='#fff'; g.fillRect(sx,sy,sw,sh);
  if(typeof tex==='function') tex(sx,sy,sw,sh); else if(tex) g.drawImage(tex,sx,sy,sw,sh);
  const iw=sw*0.30, ih=sw*0.079;
  g.fillStyle='#000';
  g.beginPath(); g.roundRect(sx+sw/2-iw/2, sy+sh*0.014, iw, ih, ih/2); g.fill();
  g.restore();
  g.strokeStyle='rgba(255,255,255,.10)'; g.lineWidth=Math.max(sw*0.002,1);
  g.beginPath(); g.roundRect(sx-bez,sy-bez,sw+2*bez,sh+2*bez,rB); g.stroke();
  g.restore();
}

/* "every day. counted." — white beat, lime beat, bottom centre */
function refCaption(g, W, H, white, lime, alpha, size){
  if(alpha<=0.002) return;
  size = size || 54;
  g.save(); g.globalAlpha=Math.min(alpha,1);
  g.font=`600 ${size}px Jost, system-ui, sans-serif`;
  g.textBaseline='alphabetic';
  const w1=g.measureText(white).width, gap=size*0.28;
  const w2=lime? g.measureText(lime).width : 0;
  let x=(W-(w1+(lime?gap+w2:0)))/2;
  const y=H*0.905;
  g.shadowColor='rgba(0,0,0,.6)'; g.shadowBlur=18;
  g.textAlign='left';
  g.fillStyle='#FFFFFF'; g.fillText(white,x,y);
  if(lime){ g.fillStyle=LIME; g.fillText(lime, x+w1+gap, y); }
  g.textAlign='center';
  g.restore();
}
