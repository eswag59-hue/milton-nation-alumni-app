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
let HOLE=null;                 // screen rect to keep out of the bloom
const SASP=2868/1320;

const B={HOOK:[0,5.4],ICON:[5.4,12.0],OPEN:[12.0,15.6],HOME:[15.6,21.2],
         COMM:[21.2,27.6],MEET:[27.6,34.6],CHAT:[34.6,39.6],PROF:[39.6,43.6],
         END:[43.6,52.0]};
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
const BAND_TOP=0.048, BAND_BOT=0.925, ZK=1.045;
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
function markScreen(S){ HOLE={x:S.x,y:S.y,w:S.w,h:S.h,r:S.w*0.137}; }
/* the Milton icon's slot on Ezra's own home screen, measured off his capture:
   centre 0.3827 / 0.5806 of the screen, 0.1553 of its width */
/* Ezra: "when it disappears onto the iPhone you could still see a dark spot on
   the emblem. Lower the icon just a tiny bit." His installed build has the dim
   teal artwork; the bright one has to sit slightly proud of it to cover it, and
   about a millimetre lower — 0.6% of screen height on a 6.3in display. */
const SLOT={cx:0.3878,cy:0.5805,s:0.1536}, SLOT_COVER=1.05;
function slot(S){return {x:S.x+S.w*SLOT.cx, y:S.y+S.h*SLOT.cy, s:S.w*SLOT.s*SLOT_COVER}}

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
function kinetic(t,t0,words,y,size,limeFrom,face,cols){
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
      g.fillStyle=cols?cols[i%cols.length]
                      :((limeFrom!==undefined&&limeFrom>=0&&i>=limeFrom)?LIME:'#FFFFFF');
      g.fillText(words[i], -ws[i]/2, 0);
      g.restore();
    }
    x+=ws[i]+gap;
  }
  g.restore();
}

/* ── beat 1 · paint out of a can ────────────────────────────────────────────
   Ezra: "paint to look real, like paint dripping out of a can, coming all over
   the entire screen. To fill in those words, they should be white at first and
   then it fills in with the paint. The paint should look creamy and matte."

   The previous version was additive light — 'lighter' blending, glowing edges —
   which is the exact opposite of matte paint, and is most of why it read as
   slop. This is opaque source-over colour on its own canvas, with rounded drip
   heads that only ever grow. The words are drawn white on top and filled by
   whatever paint has arrived behind them, so the fill happens by coverage
   rather than by a timer. When the paint drains, the fill stays. */
const RAMP=['#165C7D','#007396','#0093B2','#369DA0','#56B093','#D4EB8E'];
const CREAM='#F2F0E6';
const POUR=[0.00,1.70], LAND=1.80, DRAIN=[1.90,2.85];

const pc=document.createElement('canvas'); pc.width=W; pc.height=H;
const pg=pc.getContext('2d');

/* Uniform bands at even spacing read as a barcode, not paint. Real paint has an
   irregular front edge, drips of wildly different widths that overlap into one
   mass, and only two or three tones layered for body — not a stripe per colour. */
const DRIPS=(function(){
  const spec=[[0.04,0.150],[0.13,0.230],[0.24,0.110],[0.34,0.265],
              [0.45,0.135],[0.55,0.210],[0.65,0.120],[0.74,0.245],
              [0.85,0.145],[0.95,0.200],[0.19,0.090],[0.60,0.085]];
  return spec.map(([x,w],i)=>({
    x, w,
    lag:((i*29)%13)/13*0.26,
    rate:0.70+((i*17)%9)/9*0.70,
    tone:(i%3)
  }));
})();
/* one paint, three tones — under, body, and the cream that rides on top */
const COAT=['#0B4256','#0C7EA0','#F2F0E6'];

function frontY(x,base,t){
  return base
       + Math.sin(x*0.0062+t*0.5)*H*0.028
       + Math.sin(x*0.0131-t*0.8)*H*0.017
       + Math.sin(x*0.0233+t*1.3)*H*0.009;
}

function sheet(base,col,t){
  if(base<=-H*0.04) return;
  pg.fillStyle=col;
  pg.beginPath();
  pg.moveTo(-W*0.05,-H*0.06);
  pg.lineTo(W*1.05,-H*0.06);
  for(let x=W*1.05;x>=-W*0.05;x-=W*0.02) pg.lineTo(x, frontY(x,base,t));
  pg.closePath(); pg.fill();
}

function drip(d,head,t){
  const x=d.x*W, w=d.w*W, tip=w*0.30;
  pg.fillStyle=COAT[d.tone];
  pg.beginPath();
  pg.moveTo(x-w/2,-H*0.06);
  pg.lineTo(x+w/2,-H*0.06);
  pg.quadraticCurveTo(x+w*0.46, head-w*0.9, x+tip, head);
  pg.arc(x, head, tip, 0, Math.PI);
  pg.quadraticCurveTo(x-w*0.46, head-w*0.9, x-w/2, -H*0.06);
  pg.closePath(); pg.fill();
}

function paintTo(t){
  pg.clearRect(0,0,W,H);
  const p=eIO(seg(t,POUR[0],POUR[1]));
  const lip=cl(p*1.42,0,1);
  for(const d of DRIPS){
    const run=cl((p-d.lag)*d.rate*2.20,0,1);
    if(run>0) drip(d, lip*H*0.20 + run*H*1.30, t);
  }
  sheet(mix(-H*0.08, H*0.720, lip),       COAT[0], t);
  sheet(mix(-H*0.10, H*0.600, lip*1.05),  COAT[1], t+2.1);
  sheet(mix(-H*0.12, H*0.115, lip*1.20),  COAT[2], t+4.7);
}

/* white letterform, filled by whatever paint has reached it */
function paintedArt(draw,alpha,edge){
  if(alpha<=0.003)return;
  og.clearRect(0,0,W,H);
  og.globalCompositeOperation='source-over'; og.globalAlpha=1;
  draw(og);
  og.globalCompositeOperation='source-in';
  og.fillStyle='#FFFFFF'; og.fillRect(0,0,W,H);
  og.globalCompositeOperation='source-atop';
  og.drawImage(pc,0,0);
  og.globalCompositeOperation='source-over';
  g.save(); g.globalAlpha=cl(alpha,0,1);
  if(edge!==false){
    g.save();
    g.shadowColor='rgba(4,20,28,.85)'; g.shadowBlur=0;
    for(const [dx,dy] of [[-2,0],[2,0],[0,-2],[0,2],[-2,-2],[2,2],[-2,2],[2,-2]]){
      g.shadowOffsetX=dx; g.shadowOffsetY=dy; g.drawImage(oc,0,0);
    }
    g.restore();
  }
  g.drawImage(oc,0,0); g.restore();
}

function boldLogo(ctx,lg,x,y,w,h,spread){
  for(let a=0;a<8;a++)
    ctx.drawImage(lg, x+Math.cos(a*0.785)*spread, y+Math.sin(a*0.785)*spread, w, h);
  ctx.drawImage(lg,x,y,w,h);
}

function hook(t){
  g.fillStyle='#07090C'; g.fillRect(0,0,W,H);
  const lg=T.logo; if(!lg)return;
  const lw=W*0.82, lh=lg.height*(lw/lg.width);
  const wy=CY-H*0.060;

  paintTo(t);
  const vis=1-eIO(seg(t,DRAIN[0],DRAIN[1]));
  if(vis>0.003){ g.save(); g.globalAlpha=vis; g.drawImage(pc,0,0); g.restore(); }

  const wa=cl(seg(t,0.48,0.86),0,1)*(1-seg(t,5.05,5.4));
  if(wa>0){
    const b=t>=LAND?Math.exp(-(t-LAND)*8.0)*Math.sin((t-LAND)*22.0):0;
    const sc=1+b*0.055;
    g.save(); g.translate(CX,wy); g.scale(sc,sc); g.translate(-CX,-wy);
    paintedArt(ctx=>boldLogo(ctx,lg,CX-lw/2,wy-lh/2,lw,lh,Math.max(2.0,lw*0.0030)), wa);
    g.restore();
  }

  const la=cl(seg(t,1.15,1.60),0,1)*(1-seg(t,5.05,5.4));
  if(la>0){
    paintedArt(ctx=>{
      ctx.font='600 72px Jost, system-ui, sans-serif';
      ctx.textAlign='center'; ctx.textBaseline='alphabetic';
      ctx.fillStyle='#fff';
      ctx.fillText('Nobody can recover alone.', CX, CY+H*0.120);
    }, la);
  }
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
const DETACH=7.05, LANDED=10.65;

function iconBeat(t){
  const S=box(), sl=slot(S);
  const tp=seg(t,5.4,8.4);
  const toNation=seg(t,7.20,8.40);

  plate(g,T,'tile_icon',W,H,tp,1-toNation,TILE_P);
  plate(g,T,'nation',W,H,seg(t,7.2,12.0),toNation,{push:0.10,dy:0.016});

  /* the phone arrives under the shrinking icon and takes it */
  const ph=eO(seg(t,9.05,10.25));
  if(ph>0){
    g.save(); g.globalAlpha=ph;
    const hs=T.ezra_home2||T.ezra_home;
    drawDevice(g,(x,y,w,h)=>{ if(hs) g.drawImage(hs,x,y,w,h); },
      S.x,S.y,S.w,S.h,{spill:hs});
    g.restore();
    if(ph>0.85) markScreen(S);
  }

  /* the free icon, handed off from the emblem's own face */
  if(t>=DETACH&&T.icon){
    const m=plateMap(W,H,seg(DETACH,5.4,8.4),TILE_P,FACE_C[0],FACE_C[1]);
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

  /* Ezra: "I don't know what those sparkles are. Get rid of that shit... it
     should change transition." So the beat ends on the icon itself waking —
     a short bloom out of the slot that hands straight to the app opening. */
  const wake=seg(t,11.30,11.75)-seg(t,11.90,12.00);
  if(wake>0){
    g.save(); g.globalCompositeOperation='lighter'; g.globalAlpha=wake*0.85;
    const r=g.createRadialGradient(sl.x,sl.y,0,sl.x,sl.y,S.w*0.60);
    r.addColorStop(0,'rgba(150,236,250,.95)');
    r.addColorStop(0.30,'rgba(40,150,180,.32)');
    r.addColorStop(1,'rgba(0,0,0,0)');
    g.fillStyle=r; g.fillRect(0,0,W,H); g.restore();
  }

  kinetic(t,8.05,['so','we','built','a','nation'],H*0.885,74,4,
    `500 74px 'Bodoni Moda', Georgia, serif`);
}

/* ── beat 3 · the app opens the way iOS opens it ────────────────────────────
   Lifted from Ezra's own 26 Aug screen recording: the icon's rounded square
   expands out of its slot into the full display, and what is behind it is the
   "Welcome Back! / Are you still on track? / 1,097 days of recovery" screen —
   the app's real first beat, which no earlier cut had because no screenshot of
   it existed. Then the tap on "Yes, still going strong!" hands to Home. */
function openBeat(t){
  const b=B.OPEN, S=box(), sl=slot(S);
  plate(g,T,'nation',W,H,seg(t,7.2,b[1]),1-seg(t,b[0]+0.5,b[0]+1.4),{push:0.10,dy:0.016});
  plate(g,T,'home',W,H,seg(t,b[0]+0.5,B.HOME[1]),seg(t,b[0]+0.5,b[0]+1.4),
        {push:0.085,dy:-0.012});

  const k=eIO(seg(t,b[0]+0.10,b[0]+0.95));
  const home=T.ezra_home2||T.ezra_home, wel=T['00_welcome'];

  drawDevice(g,(x,y,w,h)=>{
    if(home) g.drawImage(home,x,y,w,h);
    /* the expanding card: icon corner radius to screen corner radius, exactly
       as the real animation does it */
    const cx=mix(sl.x,x+w/2,k), cy=mix(sl.y,y+h/2,k);
    const cw=mix(sl.s,w,k),     ch=mix(sl.s,h,k);
    /* radius follows the card, not the icon, or it reads square mid-expansion */
    const rr=cw*mix(0.225,0.137,k);
    g.save();
    g.beginPath(); g.roundRect(cx-cw/2,cy-ch/2,cw,ch,rr); g.clip();
    /* the icon stays square inside the growing card — stretching it to the card
       height elongated the m into a smear as the rect went tall */
    const ia=1-cl(seg(t,b[0]+0.42,b[0]+0.86),0,1);
    if(T.icon&&ia>0.004){ g.globalAlpha=ia; g.drawImage(T.icon,cx-cw/2,cy-cw/2,cw,cw); }
    if(wel){
      g.globalAlpha=cl(seg(t,b[0]+0.42,b[0]+0.95),0,1);
      const s2=cw/wel.width;
      g.drawImage(wel,cx-cw/2,cy-ch/2,cw,wel.height*s2);
    }
    g.restore();

    /* the tap that answers it */
    const tp=seg(t,b[1]-1.05,b[1]-0.55);
    if(k>0.98&&tp>0&&tp<1){
      const rx=x+w*0.50, ry=y+h*0.822;      // the "Yes, still going strong!" bar
      g.save(); g.globalAlpha=(1-tp)*0.85;
      g.strokeStyle='rgba(255,255,255,.95)'; g.lineWidth=w*0.010;
      g.beginPath(); g.arc(rx,ry,w*0.05+tp*w*0.11,0,7); g.stroke();
      g.fillStyle='rgba(255,255,255,.22)';
      g.beginPath(); g.arc(rx,ry,w*0.045,0,7); g.fill();
      g.restore();
    }
  },S.x,S.y,S.w,S.h,{spill:k>0.5?(wel||home):home});
  markScreen(S);

  cap(t,b[0]+1.15,b[1],['1,097 days.',''],['','Still going strong.']);
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
  markScreen(S);
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
  const val=Math.round(1+eIO(cl(seg(tq,win[0],win[1]),0,1))*1096);   // to 1,097, his live count
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
  /* 1.15 read as a funnel and 0.40 barely tipped; 0.78 is a phone lying on a
     table seen from a standing eye line. */
  const N=56, k=tilt*0.78;
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
  /* Ezra: "the phone should be lying flat, like it's on a table, and then
     coming out of the phone... and then it should turn vertically, and you can
     see how that page looks." So the tilt goes down and comes back, rather than
     laying back and staying there. */
  const tilt=eIO(seg(t,b[0]+1.10,b[0]+2.20))*(1-eIO(seg(t,b[1]-2.40,b[1]-1.30)));
  const S=box(FILL, SCY+(1-rise)*H*0.045);
  const im=T['03_community'];
  const off=eIO(seg(t,b[0]+0.85,b[1]-0.55))*1.0;
  const A=rise*(1-fall);

  /* Ezra: "a vertical phone with the comments coming out of the phone, and then
     the phone turns horizontal. The horizontal phone turns vertical and then
     shows this entire comment page and scrolls through it." So it is a rotation,
     not a tilt — composed offscreen and turned as one piece, with a squeeze
     through the quarter turn so it reads as a physical object rather than a
     sprite being spun. */
  const bz=S.w*0.018+S.w*0.021;
  const BX=S.x-bz, BY=S.y-bz, BW=S.w+2*bz, BH=S.h+2*bz;
  og.clearRect(0,0,W,H);
  og.globalCompositeOperation='source-over'; og.globalAlpha=1;
  drawDevice(og,(x,y,w,h)=>screenScroll(im,x,y,w,h,off,og),
    S.x,S.y,S.w,S.h,{spill:im});

  const turn=eIO(seg(t,b[0]+2.20,b[0]+3.20))-eIO(seg(t,b[0]+4.00,b[0]+5.00));
  const ang=-turn*Math.PI/2;
  const sq=1-Math.sin(Math.abs(ang))*0.06;      // a little foreshortening mid-turn
  if(Math.abs(turn)<0.004){
    g.save(); g.globalAlpha=A; g.drawImage(oc,0,0); g.restore();
    markScreen(S);
  } else {
    const fit=mix(1, (H*0.86)/BH, Math.sin(Math.abs(ang)));   // keep it in frame
    /* a display turned edge-on to the room is dimmer, and at full brightness the
       landscape phase blew out to a white slab */
    g.save(); g.globalAlpha=A*(1-Math.sin(Math.abs(ang))*0.22);
    g.translate(CX, S.y+S.h/2);
    g.rotate(ang); g.scale(fit*sq, fit);
    g.translate(-CX, -(S.y+S.h/2));
    g.drawImage(oc,0,0);
    g.restore();
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
  markScreen(S);
  /* the constellation feeding the phone */
  const into=seg(t,NEAR_T+0.35,NEAR_T+1.1)-seg(t,b[1]-1.0,b[1]-0.3);
  if(into>0) light(g,T.plume_in,CX,S.y+S.h*0.10,W*1.05,into*0.55,0);
  cap(t,b[0]+0.9,NEAR_T-0.30,["We're there with you",''],['every step of the way.','']);
  cap(t,NEAR_T+0.50,b[1],['Real AA & NA meetings',''],['','near you, right now.']);
  return S;
}

/* ── beat 7 · the phone steps off centre and the line sits beside it ────────
   Every reference Ezra sent varies its composition — phones off centre, at an
   angle, with type set beside them rather than pinned under. Holding one phone
   dead centre at one size for forty seconds is most of what reads as flat. */
function profBeat(t){
  const b=B.PROF, p=pB(t,'PROF');
  plate(g,T,'prof',W,H,p,1,{push:0.085,dy:-0.012});
  const rise=eO(seg(t,b[0],b[0]+0.75)), fall=seg(t,b[1]-0.42,b[1]);
  const shift=eIO(seg(t,b[0]+0.30,b[0]+1.50));
  const sh2=H*0.560;
  const sw2=sh2/SASP;
  const S={x:mix(CX-sw2/2, CX+W*0.185-sw2/2, shift),
           y:SCY-sh2/2+(1-rise)*H*0.045+H*0.010, w:sw2, h:sh2};
  const off=eIO(seg(t,b[0]+0.85,b[1]-0.55))*1.0;
  g.save(); g.globalAlpha=rise*(1-fall);
  g.translate(S.x+S.w/2, S.y+S.h/2); g.rotate(mix(0,-0.052,shift));
  g.translate(-(S.x+S.w/2), -(S.y+S.h/2));
  drawDevice(g,(x,y,w,h)=>screenScroll(T['06_profile'],x,y,w,h,off),
    S.x,S.y,S.w,S.h,{spill:T['06_profile']});
  g.restore();
  markScreen(S);

  const ta=seg(t,b[0]+1.20,b[0]+1.95)-seg(t,b[1]-0.45,b[1]);
  if(ta>0.004){
    g.save(); g.globalAlpha=cl(ta,0,1);
    g.textAlign='left'; g.textBaseline='alphabetic';
    g.shadowColor='rgba(0,0,0,.65)'; g.shadowBlur=26;
    const x=W*0.070;
    /* Ezra: "the font of Driven by Purpose, Committed to Care is terrible."
       Set in the wordmark's own didone, which is the brand's actual voice. */
    g.font="500 86px 'Bodoni Moda', Georgia, serif"; g.fillStyle='#FFFFFF';
    g.fillText('Driven by', x, CY-H*0.048);
    g.fillText('purpose.',  x, CY+H*0.024);
    g.font="500 66px 'Bodoni Moda', Georgia, serif"; g.fillStyle=LIME;
    g.fillText('Committed', x, CY+H*0.112);
    g.fillText('to care.',  x, CY+H*0.172);
    g.textAlign='center'; g.restore();
  }
}

/* ── beat 8 · close the app, then the card ────────────────────────────────── */
function endBeat(t){
  const b=B.END, S=box(), sl=slot(S);
  const home=T.ezra_home2||T.ezra_home;

  /* Ezra: "the way you close the app looks so unsmooth. Close the app
     normally." So it is the open run backwards, using the same card maths —
     the screen contracts into its own icon and the home screen is behind it. */
  const k=1-eIO(seg(t,b[0],b[0]+0.90));
  const pull=eIO(seg(t,b[0]+1.15,b[0]+2.35));

  plate(g,T,'nation',W,H,seg(t,b[0],b[0]+2.6),1-seg(t,b[0]+1.3,b[0]+2.4),
        {push:0.05,dy:0.01});
  plate(g,T,'end',W,H,seg(t,b[0]+1.3,DUR),seg(t,b[0]+1.3,b[0]+2.4),
        {push:0.075,dy:-0.012});

  if(pull<1){
    g.save(); g.globalAlpha=1-pull;
    g.translate(CX,CY); g.scale(mix(1,0.80,pull),mix(1,0.80,pull));
    g.translate(-CX,-CY+pull*H*0.16);
    drawDevice(g,(x,y,w,h)=>{
      if(home) g.drawImage(home,x,y,w,h);
      const cx=mix(sl.x,x+w/2,k), cy=mix(sl.y,y+h/2,k);
      const cw=mix(sl.s,w,k),     ch=mix(sl.s,h,k);
      const rr=cw*mix(0.225,0.137,k);
      g.save();
      g.beginPath(); g.roundRect(cx-cw/2,cy-ch/2,cw,ch,rr); g.clip();
      if(T['06_profile']&&k>0.02){
        g.globalAlpha=cl(k*2.2,0,1);
        const im=T['06_profile'], q=cw/im.width;
        g.drawImage(im,cx-cw/2,cy-ch/2,cw,im.height*q);
      }
      g.globalAlpha=1-cl(k*2.2,0,1);
      if(T.icon) g.drawImage(T.icon,cx-cw/2,cy-cw/2,cw,cw);
      g.restore();
    },S.x,S.y,S.w,S.h,{spill:home});
    g.restore();
    if(k>0.55) markScreen(S);
  }

  /* and then the same pour that opened the film closes it */
  const t0=b[0]+2.30;
  const lg=T.logo;
  /* "the ending should have the same paint idea" */
  const wy=CY-H*0.190;
  paintTo(t-t0+0.10);
  const vis=1-eIO(seg(t,t0+1.55,t0+2.35));
  if(vis>0.003){ g.save(); g.globalAlpha=vis; g.drawImage(pc,0,0); g.restore(); }
  const la=cl(seg(t,t0+0.50,t0+1.00),0,1);
  if(lg&&la>0){
    const LAND2=t0+1.42;
    const bb=t>=LAND2?Math.exp(-(t-LAND2)*8.0)*Math.sin((t-LAND2)*22.0):0;
    const lw=W*0.74, lh=lg.height*(lw/lg.width);
    g.save(); g.translate(CX,wy); g.scale(1+bb*0.05,1+bb*0.05); g.translate(-CX,-wy);
    paintedArt(ctx=>boldLogo(ctx,lg,CX-lw/2,wy-lh/2,lw,lh,Math.max(2.0,lw*0.0030)), la);
    g.restore();
  }

  line(CY-H*0.075,'The official alumni app of','',eO(seg(t,t0+1.95,t0+2.65)),42,400);
  line(CY-H*0.025,'Milton Recovery Centers','',eO(seg(t,t0+2.10,t0+2.80)),58,600);
  line(CY+H*0.042,'','Free for verified alumni',eO(seg(t,t0+2.45,t0+3.15)),48,600);
  line(CY+H*0.104,'Now live on the App Store and Google Play','',
       eO(seg(t,t0+2.85,t0+3.55)),36,400);
  const ba=eO(seg(t,t0+3.15,t0+3.95));
  if(T.badges&&ba>0){
    const bw=W*0.72, bh=T.badges.height*(bw/T.badges.width);
    g.save(); g.globalAlpha=ba;
    g.drawImage(T.badges,CX-bw/2,CY+H*0.158,bw,bh); g.restore();
  }
  line(H*0.930,'Demo data shown','',eO(seg(t,t0+3.7,t0+4.4))*0.55,26,400);
}

/* ── frame ────────────────────────────────────────────────────────────────── */
let FRAME_T=0;
function drawAt(t){
  g.globalCompositeOperation='source-over'; g.globalAlpha=1;
  g.fillStyle='#05070A'; g.fillRect(0,0,W,H);

  if(inB(t,'HOOK')) hook(t);
  else if(inB(t,'ICON')) iconBeat(t);
  else if(inB(t,'OPEN')) openBeat(t);
  else if(inB(t,'HOME')){
    screenBeat(t,'HOME','home','02_home',0.95,
      ['Yes, every day counts,',''],['','one day at a time.'],
      (x,y,w,h,tt,off,fh)=>counter(tt,{x,y,w,h},off,fh));
  }
  else if(inB(t,'COMM')) commBeat(t);
  else if(inB(t,'MEET')) meetBeat(t);
  else if(inB(t,'CHAT')) screenBeat(t,'CHAT','chat','05_chat',0.90,
      ["We're there for you",''],['','when it counts.']);
  else if(inB(t,'PROF')) profBeat(t);
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
  HOLE=null;
  for(let i=0;i<SUB;i++){
    drawAt(cl(t+(i/SUB-.5)*DT,0,DUR));
    ag.globalAlpha=1/(i+1); ag.drawImage(c,0,0); ag.globalAlpha=1;
  }
  const fin=grade(acc,FRAME,{hole:HOLE});
  g.globalCompositeOperation='source-over'; g.globalAlpha=1;
  g.clearRect(0,0,W,H); g.drawImage(fin,0,0);
  return true;
};
window.DURATION=DUR;

const SRC={
  logo:'assets/logo.png', icon:'assets/icon_bright.png',
  ezra_home:'assets/ezra_home.png', ezra_home2:'assets/ezra_home2.png',
  ezra_lock2:'assets/ezra_lock2.png', '00_welcome':'assets/00_welcome.png', badges:'assets/badges.png',
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
