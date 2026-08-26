/* MILTON NATION ALUMNI — launch film.
   Built to Ezra's eight beats.  The rule that decides every layer: Higgsfield
   renders the world (grounds, glass, the light that leaves and enters the
   screen), code renders anything with an edge a viewer can read — his real app
   screens, the wordmark, the type, the counter.  Generative video warps UI text,
   which is what sank every earlier cut. */
const W=1080,H=1920,CX=W/2,CY=H/2,DUR=52.0;
const c=document.getElementById('c'),g=c.getContext('2d');
const cl=(v,a,b)=>Math.max(a,Math.min(b,v));
const seg=(t,a,b)=>cl((t-a)/(b-a),0,1);
const eO=t=>1-Math.pow(1-t,3), eI=t=>t*t*t, eIO=t=>t<.5?4*t*t*t:1-Math.pow(-2*t+2,3)/2;
const back=(t,s)=>{s=s===undefined?1.90:s;return 1+(s+1)*Math.pow(t-1,3)+s*Math.pow(t-1,2)};
const mix=(a,b,k)=>a+(b-a)*k;
const T={};
const SASP=2868/1320;

const B={HOOK:[0,5.4],ICON:[5.4,12.8],HOME:[12.8,19.0],COMM:[19.0,25.6],
         MEET:[25.6,33.2],CHAT:[33.2,38.6],PROF:[38.6,42.8],END:[42.8,52.0]};
const inB=(t,k)=>t>=B[k][0]&&t<B[k][1], pB=(t,k)=>seg(t,B[k][0],B[k][1]);

/* Content motion inside the phone.

   Ezra asked to scroll through each screen.  The captures are single-viewport
   1320x2868 stills — exactly the phone's aspect — so there is no content below
   the fold to scroll to, and `off*(fh-h)` in the earlier cuts was always zero:
   nothing ever moved.  Panning the still instead drags its own baked-in tab bar
   up into frame, which reads as two tab bars.

   What is available honestly: draw the content a little larger than the screen
   and pan within that margin, with the status bar and tab bar pinned at their
   true size.  Travel works out to 0.877*(k-1) of the screen height — enough to
   see the content move without ever exposing the capture's own chrome.
   A full-length scroll needs scroll-recordings of each tab, which only Ezra can
   make; see launch-kit/EZRA-DO-THIS-NOW.md. */
const BAND_TOP=0.048, BAND_BOT=0.925, ZK=1.08;
const TRAVEL=(BAND_BOT-BAND_TOP)*(ZK-1);
function screenScroll(im,x,y,w,h,p,ctx){
  ctx=ctx||g;
  if(!im)return;
  const kw=w*ZK, kh=h*ZK, kx=x-(kw-w)/2;
  const o=BAND_TOP*(1-ZK)*h - cl(p,0,1)*TRAVEL*h;
  ctx.save();
  ctx.beginPath(); ctx.rect(x,y+h*BAND_TOP,w,h*(BAND_BOT-BAND_TOP)); ctx.clip();
  ctx.drawImage(im,kx,y+o,kw,kh);
  ctx.restore();
  ctx.save();                                   // status bar, pinned, true size
  ctx.beginPath(); ctx.rect(x,y,w,h*BAND_TOP); ctx.clip();
  ctx.drawImage(im,x,y,w,h); ctx.restore();
  ctx.save();                                   // tab bar, pinned, true size
  ctx.beginPath(); ctx.rect(x,y+h*BAND_BOT,w,h*(1-BAND_BOT)); ctx.clip();
  ctx.drawImage(im,x,y,w,h); ctx.restore();
}
/* where a point on the capture lands on screen once the content has panned */
function onScreenY(y,h,frac,p){
  return y + (BAND_TOP*(1-ZK)*h - cl(p,0,1)*TRAVEL*h) + frac*h*ZK;
}
function onScreenX(x,w,frac){ return x-(w*ZK-w)/2 + frac*w*ZK; }

/* the phone's screen rect — everything else is derived from it */
const FILL=0.660, SCY=CY-H*0.055;
function box(fillH,cy){const sh=H*(fillH||FILL), sw=sh/SASP;
  return {x:CX-sw/2,y:(cy===undefined?SCY:cy)-sh/2,w:sw,h:sh}}
/* the Milton icon's slot on Ezra's own home screen, measured off his capture:
   centre 0.3827 / 0.5806 of the screen, 0.1553 of its width */
const SLOT={cx:0.3827,cy:0.5806,s:0.1553};
function slot(S){return {x:S.x+S.w*SLOT.cx, y:S.y+S.h*SLOT.cy, s:S.w*SLOT.s}}

/* offscreen used for anything that needs its own alpha (logo sweep, cards) */
const oc=document.createElement('canvas'); oc.width=W; oc.height=H;
const og=oc.getContext('2d');

/* ── type ─────────────────────────────────────────────────────────────────── */
function line(y,white,lime,alpha,size,weight){
  if(alpha<=0.002)return;
  g.save(); g.globalAlpha=cl(alpha,0,1);
  g.font=`${weight||600} ${size}px Jost, system-ui, sans-serif`;
  g.textAlign='left'; g.textBaseline='alphabetic';
  const gap=lime?size*0.30:0;
  const w1=white?g.measureText(white).width:0, w2=lime?g.measureText(lime).width:0;
  let x=(W-(w1+gap+w2))/2;
  g.shadowColor='rgba(0,0,0,.62)'; g.shadowBlur=22;
  if(white){g.fillStyle='#FFFFFF'; g.fillText(white,x,y);}
  if(lime){g.fillStyle=LIME; g.fillText(lime,x+w1+gap,y);}
  g.textAlign='center'; g.restore();
}
/* two-line caption in the lower third; second line rises a beat after the first */
function cap(t,b0,b1,l1,l2,size){
  size=size||52;
  const a=seg(t,b0,b0+0.65)-seg(t,b1-0.45,b1);
  if(a<=0.002)return;
  const y=l2?H*0.868:H*0.900;
  line(y,l1[0],l1[1],a,size);
  if(l2) line(y+size*1.22, l2[0],l2[1], (seg(t,b0+0.35,b0+1.0)-seg(t,b1-0.45,b1)), size);
}
/* words arriving one at a time, each with its own overshoot */
function kinetic(t,t0,words,y,size,limeFrom,face){
  g.save(); g.textAlign='left'; g.textBaseline='alphabetic';
  g.font=face||`600 ${size}px Jost, system-ui, sans-serif`;
  const gap=size*0.30;
  const ws=words.map(w=>g.measureText(w).width);
  const total=ws.reduce((a,b)=>a+b,0)+gap*(words.length-1);
  let x=(W-total)/2;
  for(let i=0;i<words.length;i++){
    const k=seg(t,t0+i*0.115,t0+i*0.115+0.52);
    if(k>0){
      const e=back(k), a=cl(k*2.2,0,1);
      g.save(); g.globalAlpha=a;
      g.translate(x+ws[i]/2, y);
      g.scale(mix(0.72,1,e), mix(0.72,1,e));
      g.translate(0, (1-e)*size*0.55);
      g.shadowColor='rgba(0,0,0,.6)'; g.shadowBlur=24;
      g.fillStyle=(limeFrom!==undefined&&i>=limeFrom)?LIME:'#FFFFFF';
      g.fillText(words[i], -ws[i]/2, 0);
      g.restore();
    }
    x+=ws[i]+gap;
  }
  g.restore();
}

/* ── beat 1 · the colour wave, and the word it lands on ──────────────────────
   Ezra on the glass-shard version: "I don't like the glass. I like what you
   originally had. I want a wave of colors to kind of flow through that entire
   page and through the word, and then it lands on the word and it's like bop."

   So: no plate. A near-black ground, ribbons of the brand ramp sweeping in from
   the left, the wordmark painted in behind the wave front as it passes, then the
   ribbons collapsing onto the word's own line — the colour becomes the word —
   and a scale punch on the frame they land. */
const RAMP=['#165C7D','#007396','#0093B2','#369DA0','#56B093','#D4EB8E'];
const WAVE=[0.10,1.38], LAND=1.52, COLLAPSE=[1.30,1.74];

function ribbon(i,t,front,coll,alpha,wy){
  const spd=0.86+i*0.052;
  const k=(6.1+i*0.7)/W, ph=i*1.25 - t*1.15;
  /* the collapse pulls every ribbon onto the wordmark's line, so the field
     resolves into the word instead of just sliding off frame */
  const baseY=mix(CY+(i-3)*H*0.056+Math.sin(t*0.62+i*1.4)*H*0.010, wy, coll);
  const amp=mix(H*(0.052+(i%3)*0.020), H*0.004, coll);
  const th =mix(H*(0.034+(i%4)*0.014), H*0.006, coll);
  const x0=-W*0.30, x1=W*1.30, STEP=W*0.030;
  const grad=g.createLinearGradient(front*W-W*0.85,0,front*W+W*0.55,0);
  for(let q=0;q<=5;q++){
    const c=RAMP[(q+i)%RAMP.length];
    grad.addColorStop(q/5, c);
  }
  for(let pass=0;pass<3;pass++){
    const tk=th*(1+pass*0.85), a=alpha*[0.52,0.24,0.12][pass];
    if(a<=0.003) continue;
    g.globalAlpha=a; g.fillStyle=grad;
    g.beginPath();
    for(let x=x0;x<=x1;x+=STEP) g.lineTo(x, baseY+Math.sin(x*k+ph)*amp-tk/2);
    for(let x=x1;x>=x0;x-=STEP) g.lineTo(x, baseY+Math.sin(x*k+ph)*amp+tk/2);
    g.closePath(); g.fill();
  }
}

function hook(t){
  /* ground: near-black with one soft lift, not flat and not glass */
  g.fillStyle='#06080B'; g.fillRect(0,0,W,H);
  const bg=g.createRadialGradient(CX,CY-H*0.04,0,CX,CY-H*0.04,W*0.95);
  bg.addColorStop(0,'rgba(16,30,38,.85)'); bg.addColorStop(1,'rgba(4,6,9,0)');
  g.fillStyle=bg; g.fillRect(0,0,W,H);

  const lg=T.logo; if(!lg)return;
  const lw=W*0.76, lh=lg.height*(lw/lg.width);
  const wy=CY-H*0.055;

  const front=mix(-0.34,1.42,eIO(seg(t,WAVE[0],WAVE[1])));
  const coll=eIO(seg(t,COLLAPSE[0],COLLAPSE[1]));
  const env=cl(seg(t,0.06,0.42),0,1)*(1-seg(t,COLLAPSE[0],COLLAPSE[1]+0.10));
  if(env>0.003){
    g.save(); g.globalCompositeOperation='lighter';
    for(let i=0;i<7;i++) ribbon(i,t,front,coll,env,wy);
    g.restore();
  }

  /* the word, painted in behind the wave front */
  const rev=cl((front*W - (CX-lw/2) + W*0.16)/(lw+W*0.32),0,1);
  if(rev>0.004){
    /* the bop: a damped punch on the frame the wave lands, not a slow scale */
    const b=t>=LAND?Math.exp(-(t-LAND)*9.0)*Math.sin((t-LAND)*26.0):0;
    const sc=1+b*0.085;
    og.clearRect(0,0,W,H);
    og.globalCompositeOperation='source-over'; og.globalAlpha=1;
    og.drawImage(lg,CX-lw/2,wy-lh/2,lw,lh);
    const m=og.createLinearGradient(CX-lw/2-W*0.16,0,CX-lw/2-W*0.16+(lw+W*0.32)*rev,0);
    m.addColorStop(0,'rgba(0,0,0,1)');
    m.addColorStop(Math.max(0,1-0.16),'rgba(0,0,0,1)');
    m.addColorStop(1,'rgba(0,0,0,0)');
    og.globalCompositeOperation='destination-in';
    og.fillStyle=m; og.fillRect(CX-lw/2-W*0.16,0,(lw+W*0.32)*rev+2,H);
    og.globalCompositeOperation='source-over';
    g.save();
    g.translate(CX,wy); g.scale(sc,sc); g.translate(-CX,-wy);
    g.globalAlpha=1-seg(t,5.05,5.4);
    g.shadowColor='rgba(40,170,200,.55)'; g.shadowBlur=44;
    g.drawImage(oc,0,0);
    g.restore();
  }

  /* the flash on landing */
  const fl=Math.max(0,1-Math.abs(t-LAND)*4.2);
  if(fl>0){
    g.save(); g.globalCompositeOperation='lighter'; g.globalAlpha=fl*0.42;
    const rg=g.createRadialGradient(CX,wy,0,CX,wy,W*0.80);
    rg.addColorStop(0,'rgba(206,244,250,.95)');
    rg.addColorStop(0.40,'rgba(70,165,190,.26)');
    rg.addColorStop(1,'rgba(0,0,0,0)');
    g.fillStyle=rg; g.fillRect(0,0,W,H); g.restore();
  }

  /* and then the line, alone on the screen */
  kinetic(t,1.98,['Nobody','can','recover','alone.'],CY+H*0.115,68,3);
}

/* ── beat 2 · out of the emblem, onto his own home screen ───────────────────
   The emblem is a plate with the icon warped into its face (see prep_plates.py),
   so for the first stretch the icon IS the glass slab — no flat square floating
   in front of it. At the hand-off a free copy takes over from exactly the face's
   measured centre and size, comes FORWARD toward camera first — Ezra: "it should
   animate that entire app coming out of the screen onto the homepage" — and only
   then recedes into its slot on his own home screen. */
const TILE_P={push:0.13,dy:-0.010};
const FACE_C=[0.5193,0.4945], FACE_W=0.6105;     // measured off tile.jpg
const DETACH=7.05, LANDED=11.05;

function iconBeat(t){
  const S=box(), sl=slot(S);
  const tp=seg(t,5.4,8.6);
  const toNation=seg(t,7.30,8.60);

  plate(g,T,'tile_icon',W,H,tp,1-toNation,TILE_P);
  plate(g,T,'nation',W,H,seg(t,7.3,12.8),toNation,{push:0.10,dy:0.016});

  /* the phone arrives under the shrinking icon and takes it */
  const ph=eO(seg(t,9.05,10.25));
  if(ph>0){
    g.save(); g.globalAlpha=ph;
    drawDevice(g,(x,y,w,h)=>{ if(T.ezra_home) g.drawImage(T.ezra_home,x,y,w,h); },
      S.x,S.y,S.w,S.h,{spill:T.ezra_home});
    g.restore();
  }

  /* the free icon, handed off from the emblem's own face */
  if(t>=DETACH&&T.icon){
    const m=plateMap(W,H,seg(DETACH,5.4,8.6),TILE_P,FACE_C[0],FACE_C[1]);
    const sz0=FACE_W*m.w;
    /* forward first, then away: one eased travel with a scale bump on the front */
    const k=eIO(seg(t,DETACH,LANDED));
    const fwd=Math.sin(cl(seg(t,DETACH,DETACH+1.5),0,1)*Math.PI)*0.30;
    const sz=Math.exp(mix(Math.log(sz0),Math.log(sl.s),k))*(1+fwd);
    const ix=mix(m.x,sl.x,k), iy=mix(m.y,sl.y,k);
    const a=cl(seg(t,DETACH,DETACH+0.22),0,1);
    g.save(); g.globalAlpha=a;
    if(k<0.94){g.shadowColor='rgba(30,150,180,.8)'; g.shadowBlur=sz*0.34;}
    g.beginPath(); g.roundRect(ix-sz/2,iy-sz/2,sz,sz,sz*0.225); g.clip();
    g.drawImage(T.icon,ix-sz/2,iy-sz/2,sz,sz);
    g.restore();
  }

  /* light leaves the screen, then pours back into it */
  const out=seg(t,11.00,11.55)-seg(t,12.15,12.75);
  if(out>0) light(g,T.plume_out, CX, S.y-H*0.135, W*1.00, out*0.80, 0);
  const into=seg(t,11.85,12.35)-seg(t,12.60,12.80);
  if(into>0) light(g,T.plume_in, CX, S.y-H*0.055, W*0.86, into*0.62, 0);

  kinetic(t,8.05,['so','we','built','a','nation'],H*0.885,74,4,
    `500 74px 'Bodoni Moda', Georgia, serif`);
}

/* ── the five screen beats ────────────────────────────────────────────────── */
function screenBeat(t,beat,plateKey,tex,scroll,l1,l2,extra,popts){
  const b=B[beat], p=pB(t,beat);
  plate(g,T,plateKey,W,H,p,1,popts||{push:0.085,dy:-0.012});
  const rise=eO(seg(t,b[0],b[0]+0.75)), fall=seg(t,b[1]-0.42,b[1]);
  const S=box(FILL, SCY+(1-rise)*H*0.045);
  g.save(); g.globalAlpha=rise*(1-fall);
  drawDevice(g,(x,y,w,h)=>{
    const off=scroll?eIO(seg(t,b[0]+0.85,b[1]-0.55))*scroll:0;
    screenScroll(T[tex],x,y,w,h,off);
    if(extra) extra(x,y,w,h,t,off,h);
  },S.x,S.y,S.w,S.h,{spill:T[tex]});
  g.restore();
  cap(t,b[0]+1.0,b[1],l1,l2);
  return S;
}

/* the streak counting up, over the real Home card.
   Numeral position MEASURED off 02_home.png: y 0.3368 of screen height, cap
   height 0.0446, centred x 0.5011.  An earlier guess of 0.245 drew the animating
   value on top of the baked-in one and the two stacked. */
function counter(t,S,off,fh){
  const win=[B.HOME[0]+0.15,B.HOME[0]+3.9];
  if(t<B.HOME[0])return;
  const tq=FRAME_T;                                  // one value per output frame
  const val=Math.round(1+eIO(cl(seg(tq,win[0],win[1]),0,1))*1095);
  const cx=onScreenX(S.x,S.w,0.5011), cyy=onScreenY(S.y,S.h,0.3368,off);
  g.save();
  g.textAlign='center'; g.textBaseline='middle';
  g.font=`700 ${Math.round(S.h*ZK*0.0625)}px Jost, system-ui, sans-serif`;
  g.fillStyle='#12242C';
  g.fillText(val.toLocaleString('en-US'), cx, cyy);
  g.restore();
}


/* Ezra, on the community beat: "have the entire screen turn flat, with
   everything coming out of the screen, like comments and likes."

   Canvas2D has only affine transforms, so a real perspective tilt is done by
   sampling the plane in horizontal bands: under one-point perspective every
   band at depth v has scale 1/(1+k(1-v)), which is exactly a per-band width and
   height. At 56 bands the stepping is under a pixel and motion blur closes it. */
function tiltedPlane(im, sx0, sy0, sw0, sh0, cx, topY, w0, h0, tilt, alpha){
  if(!im||alpha<=0.003)return null;
  /* 1.15 laid the plane back so far the top was under half width and it read as
     a funnel rather than a screen. 0.40 is about a 30-degree tip — enough to see
     the surface, still unmistakably a phone. */
  const N=56, k=tilt*0.40;
  const sc=v=>1/(1+k*(1-v));
  let tot=0; for(let i=0;i<N;i++) tot+=sc((i+0.5)/N);
  const unit=h0/(tot/N);
  g.save(); g.globalAlpha=alpha;
  let y=topY;
  for(let i=0;i<N;i++){
    const v=(i+0.5)/N, ssc=sc(v);
    const bh=unit*ssc/N, bw=w0*ssc;
    g.drawImage(im, sx0, sy0+sh0*i/N, sw0, sh0/N,
                cx-bw/2, y, bw, bh+0.6);
    y+=bh;
  }
  g.restore();
  return {topW:w0*sc(0), botW:w0*sc(1), h:y-topY};
}

/* small live pieces of the real feed, lifting off the laid-back plane */
const CHIPS=[{x0:0.055,x1:0.300,y0:0.418,y1:0.455,dx:-0.32,dy:-0.26,t0:21.55},
             {x0:0.055,x1:0.760,y0:0.468,y1:0.514,dx: 0.30,dy:-0.20,t0:22.45},
             {x0:0.055,x1:0.300,y0:0.853,y1:0.891,dx: 0.30,dy:-0.40,t0:23.15}];

/* ── beat 4 · real posts leaving the screen ───────────────────────────────── */
const CARDS=[{y0:0.274,y1:0.532,t0:21.05,dx:-0.150,rot:-0.10},
             {y0:0.541,y1:0.918,t0:22.15,dx: 0.160,rot: 0.11}];
function liftCards(t,S,off,fh){
  const im=T['03_community']; if(!im)return;
  const sx0=Math.round(im.width*0.028), sx1=Math.round(im.width*0.972);
  for(const cd of CARDS){
    const k=seg(t,cd.t0,cd.t0+1.55);
    if(k<=0)continue;
    const a=(1-seg(t,cd.t0+0.85,cd.t0+1.55))*cl(k*4,0,1);
    if(a<=0.004)continue;
    const e=eO(k);
    const sy0=im.height*cd.y0, sy1=im.height*cd.y1;
    const scl=S.w*ZK/im.width;
    const dw=(sx1-sx0)*scl, dh=(sy1-sy0)*scl;
    const dx=onScreenX(S.x,S.w,(sx0+sx1)/2/im.width),
          dy=onScreenY(S.y,S.h,(cd.y0+cd.y1)/2,off);
    const z=1+e*0.26;
    g.save(); g.globalAlpha=a;
    g.translate(dx+cd.dx*W*e, dy-e*H*0.135);
    g.rotate(cd.rot*e); g.scale(z,z);
    g.fillStyle='#FFFFFF';
    g.shadowColor='rgba(0,0,0,.6)'; g.shadowBlur=54; g.shadowOffsetY=22;
    g.beginPath(); g.roundRect(-dw/2,-dh/2,dw,dh,dw*0.055); g.fill();
    g.shadowBlur=0; g.shadowOffsetY=0;
    g.beginPath(); g.roundRect(-dw/2,-dh/2,dw,dh,dw*0.055); g.clip();
    g.drawImage(im,sx0,sy0,sx1-sx0,sy1-sy0,-dw/2,-dh/2,dw,dh);
    g.restore();
  }
}

/* ── beat 4 · the screen lays flat and the feed comes off it ────────────────*/
function commBeat(t){
  const b=B.COMM, p=pB(t,'COMM');
  plate(g,T,'comm',W,H,p,1,{push:0.10,dy:-0.014});
  const rise=eO(seg(t,b[0],b[0]+0.75)), fall=seg(t,b[1]-0.42,b[1]);
  const tilt=eIO(seg(t,b[0]+1.15,b[0]+2.30));
  const S=box(FILL, SCY+(1-rise)*H*0.045);
  const im=T['03_community'];
  const off=eIO(seg(t,b[0]+0.85,b[1]-0.55))*1.0;
  const A=rise*(1-fall);

  /* Compose the device offscreen so the bezel, rail and screen all tip
     together — tilting the screen alone left a phone bent in a way phones are
     not, and dissolving the chrome lost the device entirely. */
  const bz=S.w*0.018+S.w*0.021;
  const BX=S.x-bz, BY=S.y-bz, BW=S.w+2*bz, BH=S.h+2*bz;
  og.clearRect(0,0,W,H);
  og.globalCompositeOperation='source-over'; og.globalAlpha=1;
  drawDevice(og,(x,y,w,h)=>screenScroll(im,x,y,w,h,off,og),
    S.x,S.y,S.w,S.h,{spill:im});

  if(tilt<0.02){
    g.save(); g.globalAlpha=A; g.drawImage(oc,0,0); g.restore();
  } else {
    tiltedPlane(oc, BX, BY, BW, BH, CX, BY+mix(0,H*0.045,tilt),
                BW, BH*mix(1,0.90,tilt), tilt, A);
    g.save(); g.globalAlpha=A*tilt*0.42;
    g.globalCompositeOperation='lighter';
    const gl=g.createRadialGradient(CX,S.y+S.h*0.45,0,CX,S.y+S.h*0.45,S.w*1.15);
    gl.addColorStop(0,'rgba(150,225,240,.28)'); gl.addColorStop(1,'rgba(0,0,0,0)');
    g.fillStyle=gl; g.fillRect(0,0,W,H); g.restore();
  }

  /* the posts, then the likes and comments, coming off the plane */
  liftCards(t,S,off,S.h);
  if(im) for(const c of CHIPS){
    const k=seg(t,c.t0,c.t0+1.6); if(k<=0)continue;
    const a=(1-seg(t,c.t0+0.85,c.t0+1.6))*cl(k*4,0,1);
    if(a<=0.004)continue;
    const e=eO(k), z=1+e*0.55;
    const sx0=im.width*c.x0, sx1=im.width*c.x1;
    const sy0=im.height*c.y0, sy1=im.height*c.y1;
    const scl=S.w*ZK/im.width, dw=(sx1-sx0)*scl, dh=(sy1-sy0)*scl;
    g.save(); g.globalAlpha=a;
    g.translate(onScreenX(S.x,S.w,(c.x0+c.x1)/2)+c.dx*W*e,
                onScreenY(S.y,S.h,(c.y0+c.y1)/2,off)+c.dy*H*e);
    g.scale(z,z);
    g.fillStyle='#FFFFFF';
    g.shadowColor='rgba(0,0,0,.55)'; g.shadowBlur=34; g.shadowOffsetY=12;
    g.beginPath(); g.roundRect(-dw/2-8,-dh/2-6,dw+16,dh+12,(dh+12)*0.42); g.fill();
    g.shadowBlur=0; g.shadowOffsetY=0;
    g.drawImage(im,sx0,sy0,sx1-sx0,sy1-sy0,-dw/2,-dh/2,dw,dh);
    g.restore();
  }

  const sh=seg(t,21.0,21.6)-seg(t,24.4,25.2);
  if(sh>0) light(g,T.shards,CX+W*0.20,SCY-H*0.06,W*0.95,sh*0.62,0);
  cap(t,b[0]+1.0,b[1],["That's why we built a community.",''],
      ['','Every win, witnessed together.']);
  return S;
}

/* ── beat 5 · the nearby flex ─────────────────────────────────────────────── */
const NEAR_T=29.65;
const ZOOM_T=27.85;
function meetBeat(t){
  const b=B.MEET, p=pB(t,'MEET');
  plate(g,T,'meet',W,H,p,1,{push:0.095,dy:-0.010});
  const rise=eO(seg(t,b[0],b[0]+0.75)), fall=seg(t,b[1]-0.42,b[1]);
  const S=box(FILL,SCY+(1-rise)*H*0.045);
  const swap=eIO(seg(t,NEAR_T,NEAR_T+0.44));
  g.save(); g.globalAlpha=rise*(1-fall);
  drawDevice(g,(x,y,w,h)=>{
    const a=T['04_meetings'], n=T['07_nearby']; if(!a)return;
    const o1=eIO(seg(t,b[0]+0.85,NEAR_T-0.15))*0.85;
    screenScroll(a,x-swap*w,y,w,h,o1);
    if(n&&swap>0){
      const o2=eIO(seg(t,NEAR_T+0.5,b[1]-0.55))*1.0;
      screenScroll(n,x+(1-swap)*w,y,w,h,o2);
    }
    /* the Virtual badge, tapped: one ring plus a chip naming what it does */
    const zp=seg(t,ZOOM_T,ZOOM_T+0.55);
    if(zp>0&&swap<0.02){
      const zx=onScreenX(x,w,0.8182), zy=onScreenY(y,h,0.3583,o1);
      if(zp<1){
        g.save(); g.globalAlpha=(1-zp)*0.9;
        g.strokeStyle='rgba(255,255,255,.95)'; g.lineWidth=w*0.009;
        g.beginPath(); g.arc(zx,zy,w*0.05+zp*w*0.09,0,Math.PI*2); g.stroke();
        g.restore();
      }
      const ca2=seg(t,ZOOM_T+0.30,ZOOM_T+0.70)-seg(t,NEAR_T-0.45,NEAR_T-0.05);
      if(ca2>0.004){
        g.save(); g.globalAlpha=cl(ca2,0,1);
        g.font=`600 ${Math.round(w*0.052)}px Jost, system-ui, sans-serif`;
        const lbl='Join by Zoom, one tap';
        const tw=g.measureText(lbl).width, ph=w*0.095, pw=tw+w*0.10;
        const px=cl(zx-pw*0.72, x+w*0.03, x+w-pw-w*0.03), py=zy-ph*1.55;
        g.fillStyle='rgba(6,12,16,.90)';
        g.beginPath(); g.roundRect(px,py,pw,ph,ph/2); g.fill();
        g.strokeStyle='rgba(200,229,114,.55)'; g.lineWidth=Math.max(w*0.004,1); g.stroke();
        g.fillStyle=LIME; g.textAlign='center'; g.textBaseline='middle';
        g.fillText(lbl, px+pw/2, py+ph/2+ph*0.03);
        g.restore();
      }
    }

    /* the tap on the Nearby pill, at its measured place on the real capture */
    const tp=seg(t,NEAR_T-0.42,NEAR_T+0.12);
    if(tp>0&&tp<1&&swap<0.5){
      const rx=onScreenX(x,w,0.3784), ry=onScreenY(y,h,0.2387,o1);
      g.save(); g.globalAlpha=(1-tp)*0.85;
      g.strokeStyle='rgba(255,255,255,.95)'; g.lineWidth=w*0.010;
      g.beginPath(); g.arc(rx,ry,w*0.055+tp*w*0.10,0,Math.PI*2); g.stroke();
      g.fillStyle='rgba(255,255,255,.28)';
      g.beginPath(); g.arc(rx,ry,w*0.048,0,Math.PI*2); g.fill();
      g.restore();
    }
  },S.x,S.y,S.w,S.h,{spill:swap<0.5?T['04_meetings']:T['07_nearby']});
  g.restore();
  /* the constellation feeding the phone */
  const into=seg(t,NEAR_T+0.35,NEAR_T+1.1)-seg(t,b[1]-1.0,b[1]-0.3);
  if(into>0) light(g,T.plume_in,CX,S.y+S.h*0.10,W*1.05,into*0.55,0);
  cap(t,b[0]+0.9,ZOOM_T+0.15,["We're there for you",''],['every step of the way.','']);
  cap(t,NEAR_T+0.50,b[1],['Real AA & NA meetings',''],['','near you, right now.']);
  return S;
}

/* ── beat 8 · close the app, then the card ────────────────────────────────── */
function endBeat(t){
  const b=B.END;
  const S=box();
  /* the app closing: the profile screen shrinks back into its own icon slot */
  const cls=eIO(seg(t,b[0],b[0]+1.35));
  const pull=eIO(seg(t,b[0]+1.45,b[0]+2.55));
  plate(g,T,'nation',W,H,seg(t,b[0],b[0]+2.6),1-seg(t,b[0]+1.6,b[0]+2.6),{push:0.05,dy:0.01});
  plate(g,T,'end',W,H,seg(t,b[0]+1.6,DUR),seg(t,b[0]+1.6,b[0]+2.6),{push:0.075,dy:-0.012});

  if(pull<1){
    const sl=slot(S);
    g.save(); g.globalAlpha=(1-pull);
    g.translate(0,pull*H*0.30); g.scale(mix(1,0.82,pull),mix(1,0.82,pull));
    g.translate(0,-pull*H*0.10);
    drawDevice(g,(x,y,w,h)=>{
      if(T.ezra_home) g.drawImage(T.ezra_home,x,y,w,h);
      const sz=mix(w,S.w*SLOT.s,cls);
      const cx=mix(x+w/2, x+w*SLOT.cx, cls), cy=mix(y+h/2, y+h*SLOT.cy, cls);
      g.save();
      g.beginPath(); g.roundRect(cx-sz/2,cy-sz/2,sz,sz,sz*(0.045+0.18*cls)); g.clip();
      if(cls<0.97&&T['06_profile']){
        const im=T['06_profile'], k=sz/im.width;
        g.drawImage(im,cx-sz/2,cy-sz/2,sz,im.height*k);
      }
      g.globalAlpha=cls; if(T.icon) g.drawImage(T.icon,cx-sz/2,cy-sz/2,sz,sz);
      g.restore();
    },S.x,S.y,S.w,S.h,{spill:T.ezra_home});
    g.restore();
  }
  const burst=seg(t,b[0]+1.05,b[0]+1.5)-seg(t,b[0]+2.4,b[0]+3.0);
  if(burst>0) light(g,T.plume_out,CX,S.y-H*0.115,W*1.15,burst*0.72,0);

  /* the card */
  const t0=b[0]+2.5;
  const lg=T.logo;
  const la=eO(seg(t,t0,t0+1.0));
  if(lg&&la>0){
    const e=back(seg(t,t0,t0+0.95),1.5);
    const lw=W*0.70*mix(0.88,1,e), lh=lg.height*(lw/lg.width);
    g.save(); g.globalAlpha=la;
    g.shadowColor='rgba(30,150,180,.5)'; g.shadowBlur=48;
    g.drawImage(lg,CX-lw/2,CY-H*0.190-lh/2+(1-e)*H*0.035,lw,lh);
    g.restore();
  }
  line(CY-H*0.080,'The official alumni app of','',eO(seg(t,t0+0.9,t0+1.7)),42,400);
  line(CY-H*0.030,'Milton Recovery Centers','',eO(seg(t,t0+1.05,t0+1.85)),58,600);
  line(CY+H*0.038,'','Free for verified alumni',eO(seg(t,t0+1.5,t0+2.3)),48,600);
  line(CY+H*0.100,'Now live on the App Store and Google Play','',
       eO(seg(t,t0+2.0,t0+2.8)),36,400);
  const ba=eO(seg(t,t0+2.35,t0+3.2));
  if(T.badges&&ba>0){
    const bw=W*0.72, bh=T.badges.height*(bw/T.badges.width);
    g.save(); g.globalAlpha=ba;
    g.drawImage(T.badges,CX-bw/2,CY+H*0.155,bw,bh); g.restore();
  }
  line(H*0.930,'Demo data shown','',eO(seg(t,t0+3.0,t0+3.8))*0.55,26,400);
}

/* ── frame ────────────────────────────────────────────────────────────────── */
let FRAME_T=0;
function drawAt(t){
  g.globalCompositeOperation='source-over'; g.globalAlpha=1;
  g.fillStyle='#05070A'; g.fillRect(0,0,W,H);

  if(inB(t,'HOOK')) hook(t);
  else if(inB(t,'ICON')) iconBeat(t);
  else if(inB(t,'HOME')){
    screenBeat(t,'HOME','home','02_home',0.95,
      ['Yes, every day counts,',''],['','one day at a time.'],
      (x,y,w,h,tt,off,fh)=>counter(tt,{x,y,w,h},off,fh));
  }
  else if(inB(t,'COMM')) commBeat(t);
  else if(inB(t,'MEET')) meetBeat(t);
  else if(inB(t,'CHAT')) screenBeat(t,'CHAT','chat','05_chat',0.90,
      ["We're there for you",''],['','when it counts.']);
  else if(inB(t,'PROF')) screenBeat(t,'PROF','prof','06_profile',1.0,
      ['Driven by purpose.',''],['','Committed to care.']);
  else endBeat(t);

  const bk=Math.max(1-seg(t,0,0.7),seg(t,DUR-0.9,DUR));
  if(bk>0){g.save();g.globalAlpha=bk;g.fillStyle='#05070A';g.fillRect(0,0,W,H);g.restore()}
}

/* motion blur, then the photographic finish */
const SUB=2,DT=1/30;
const acc=document.createElement('canvas');acc.width=W;acc.height=H;
const ag=acc.getContext('2d');
let grade=null, FRAME=0;
window.SEEK=function(t){
  FRAME=Math.round(t*30); FRAME_T=FRAME/30;
  ag.globalCompositeOperation='source-over'; ag.globalAlpha=1;
  ag.fillStyle='#000'; ag.fillRect(0,0,W,H);
  for(let i=0;i<SUB;i++){
    drawAt(cl(t+(i/SUB-.5)*DT,0,DUR));
    ag.globalAlpha=1/(i+1); ag.drawImage(c,0,0); ag.globalAlpha=1;
  }
  const fin=grade(acc,FRAME,{});
  g.globalCompositeOperation='source-over'; g.globalAlpha=1;
  g.clearRect(0,0,W,H); g.drawImage(fin,0,0);
  return true;
};
window.DURATION=DUR;

const SRC={
  logo:'assets/logo.png', icon:'assets/icon_bright.png',
  ezra_home:'assets/ezra_home.png', badges:'assets/badges.png',
  '02_home':'assets/02_home_blank.png','03_community':'assets/03_community.png',
  '04_meetings':'assets/04_meetings.png','05_chat':'assets/05_chat.png',
  '06_profile':'assets/06_profile.png','07_nearby':'assets/07_nearby.png',
  hook:'plates/hook.jpg', nation:'plates/nation.jpg', tile_icon:'plates/tile_icon.jpg',
  home:'plates/home.jpg', comm:'plates/comm.jpg', chat:'plates/chat.jpg',
  meet:'plates/meet.jpg', prof:'plates/prof.jpg', end:'plates/end.jpg',
  plume_out:'plates/plume_out.png', plume_in:'plates/plume_in.png',
  plume_soft:'plates/plume_soft.png', shards:'plates/shards.png',
};
Promise.all(Object.entries(SRC).map(([k,src])=>new Promise(r=>{
  const i=new Image(); i.onload=()=>{T[k]=i;r()};
  i.onerror=()=>{console.error('MISSING '+src);r()}; i.src=src;
}))).then(async()=>{
  if(document.fonts&&document.fonts.ready) await document.fonts.ready;
  grade=Grade(W,H);
  window.READY=true; SEEK(0);
});
