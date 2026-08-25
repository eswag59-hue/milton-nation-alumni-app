/* Shared helpers: timing, dips, phone chrome, tab bar, waves. */
const T0 = performance.now();
const now = () => (performance.now() - T0) / 1000;
function at(sec, fn) { setTimeout(fn, Math.max(0, sec * 1000)); }
function dipIn(el, dur = 0.35) { // fade the black dip away at start
  el.style.transition = `opacity ${dur}s ease`; requestAnimationFrame(() => requestAnimationFrame(() => el.style.opacity = '0'));
}
function dipOut(el, sec, dur = 0.3) { at(sec, () => { el.style.transition = `opacity ${dur}s ease`; el.style.opacity = '1'; }); }

/* status bar right cluster: signal, wifi, battery */
const SB_RIGHT = `
<svg width="196" height="38" viewBox="0 0 196 38">
 <g fill="currentColor">
  <rect x="0" y="22" width="8" height="12" rx="2"/><rect x="13" y="16" width="8" height="18" rx="2"/>
  <rect x="26" y="10" width="8" height="24" rx="2"/><rect x="39" y="4" width="8" height="30" rx="2"/>
  <path d="M78 14a26 26 0 0 1 34 0l-5 6a19 19 0 0 0-24 0zM86 22a15 15 0 0 1 18 0l-5 6a8 8 0 0 0-8 0zM95 31l4 4 4-4a6 6 0 0 0-8 0z" transform="translate(-8,-2) scale(.92)"/>
  <rect x="138" y="8" width="48" height="24" rx="8" fill="none" stroke="currentColor" stroke-width="3"/>
  <rect x="142" y="12" width="40" height="16" rx="5"/>
  <rect x="189" y="15" width="5" height="10" rx="2.5"/>
 </g></svg>`;

const ICONS = {
  home: '<svg viewBox="0 0 24 24"><path d="M12 3 2.7 11h2.6v9.3h5.2v-6h3v6h5.2V11h2.6z"/></svg>',
  people: '<svg viewBox="0 0 24 24"><circle cx="8.2" cy="7.6" r="3.4"/><path d="M1.6 19.4c0-3.4 3-5.6 6.6-5.6s6.6 2.2 6.6 5.6v1H1.6z"/><circle cx="17" cy="8.4" r="2.7"/><path d="M15.4 13.7c2.9.2 7 1.7 7 5.7v1h-5.5v-1c0-2.3-.9-4.2-2.4-5.5z"/></svg>',
  cal: '<svg viewBox="0 0 24 24"><path d="M4 4h16a1.6 1.6 0 0 1 1.6 1.6V20A1.6 1.6 0 0 1 20 21.6H4A1.6 1.6 0 0 1 2.4 20V5.6A1.6 1.6 0 0 1 4 4zm.4 5.4v10h15.2v-10zM7 2h2.4v3H7zm7.6 0H17v3h-2.4z"/></svg>',
  msg: '<svg viewBox="0 0 24 24"><path d="M12 2.8c5.7 0 10.3 3.8 10.3 8.6S17.7 20 12 20c-1 0-2-.1-3-.35L4 21.6l1.3-3.8c-2.2-1.6-3.6-3.9-3.6-6.4C1.7 6.6 6.3 2.8 12 2.8z"/></svg>',
  person: '<svg viewBox="0 0 24 24"><path d="M12 1.8A10.2 10.2 0 1 0 22.2 12 10.2 10.2 0 0 0 12 1.8zm0 4.4a3.5 3.5 0 1 1-3.5 3.5A3.5 3.5 0 0 1 12 6.2zm0 13.8a8 8 0 0 1-5.9-2.6c.6-2 3-3.2 5.9-3.2s5.3 1.2 5.9 3.2A8 8 0 0 1 12 20z"/></svg>'
};

/* Build phone with app scaffold. opts: {theme:'light'|'dark', active:'Home'|..., logoInvert:bool} */
function mkPhone(opts = {}) {
  const dark = opts.theme === 'dark';
  const wrap = document.createElement('div');
  wrap.className = 'phwrap';
  const ph = document.createElement('div');
  ph.className = 'phone' + (dark ? ' dark' : '');
  const logoFilter = dark ? '' : 'filter:invert(1) hue-rotate(180deg);';
  const tabs = [['Home', 'home'], ['Community', 'people'], ['Meetings', 'cal'], ['Chat', 'msg'], ['Profile', 'person']]
    .map(([n, i]) => `<div class="tab${n === (opts.active || 'Home') ? ' on' : ''}" data-tab="${n}">${ICONS[i]}<span>${n}</span></div>`).join('');
  ph.innerHTML = `
    <div class="screen${dark ? ' dark' : ''}">
      <div class="app${dark ? ' dark' : ''}">
        <div class="apphead"><img src="logo_dark.png" style="${logoFilter}"></div>
        <div class="gradbar"></div>
        <div class="content" id="content"></div>
        <div class="tabbar">${tabs}</div>
      </div>
      <div class="status"><span>9:41</span>${SB_RIGHT}</div>
      <div class="island"></div>
      <div class="homebar"></div>
    </div>`;
  const p3 = document.createElement('div');
  p3.className = 'ph3d';
  p3.appendChild(ph);
  wrap.appendChild(p3);
  document.querySelector('.stage').appendChild(wrap);
  /* 2026 treatment: slow 3D drift + a passing glass sheen */
  if (!opts.static3d) {
    p3.animate(
      [{ transform: 'rotateY(-3.4deg) rotateX(1.1deg)' },
       { transform: 'rotateY(2.6deg) rotateX(-0.8deg)' }],
      { duration: 11000, direction: 'alternate', iterations: Infinity, easing: 'ease-in-out' });
  }
  const sheen = document.createElement('div');
  sheen.className = 'sheen';
  ph.querySelector('.screen').appendChild(sheen);
  const sweep = () => sheen.animate([{ left: '-70%' }, { left: '135%' }],
    { duration: 2600, easing: 'cubic-bezier(.4,.2,.3,1)' });
  at(1.2, sweep); at(6.4, sweep);
  return ph;
}

/* Full Home screen content, matching HomeScreen.swift top to bottom.
   prefix keeps ids unique when a page holds two copies (light+dark). */
function homeHTML(px, dark) {
  return `
  <div class="greet">Welcome back, alex</div>
  <div class="sub">Your recovery journey continues today</div>
  <div class="mcard sob ${dark ? 'dark-sob' : 'light-sob'}">
    <div class="day" id="${px}day" style="color:${dark ? '#F2F5F5' : '#101820'}">365</div>
    <div class="dlab">days</div>
    <div class="tag">Living proof that recovery works</div>
    <div class="trio">
      <div><b id="${px}wk" style="color:${dark ? '#F2F5F5' : '#101820'}">52</b><span>weeks</span></div>
      <div><b id="${px}mo" style="color:${dark ? '#F2F5F5' : '#101820'}">12</b><span>months</span></div>
      <div><b style="color:${dark ? '#F2F5F5' : '#101820'}">1</b><span>year</span></div>
    </div>
    <div class="upd">&#8635;&nbsp; Update recovery date</div>
  </div>
  <div class="mcard refl">
    <div class="rhead">&#10077; Daily Reflection</div>
    <div class="quote">&#8220;Courage isn't the absence of fear. It's one more sunrise, met sober.&#8221;</div>
    <div class="attr">&mdash; Daily Reflections</div>
  </div>
  <div class="mcard pbx">
    <div class="pbh">&#11088; Points &amp; Badges <span class="pts">1,240 pts</span></div>
    <div class="pbsub">Earn points by logging in daily, posting, and hitting milestones!</div>
  </div>
  <div class="mcard news">
    <div class="rhead" style="color:${dark ? '#0093B2' : '#007396'}">&#128488; Updates &amp; News</div>
    <div class="arow"><b>Alumni BBQ &mdash; Saturday 2pm</b><span>Bring your people. Food's on us.</span><i>Aug 22</i></div>
    <div class="arow"><b>New: telehealth sessions</b><span>Request a session with your care team, right from the app.</span><i>Aug 18</i></div>
  </div>
  <div class="strug">&#10084;&#65039;&nbsp; I'm struggling today</div>
  <div style="height:40px"></div>`;
}

/* ambient background waves (behind phone / standalone) */
function startWaves(canvas, o = {}) {
  const x = canvas.getContext('2d');
  const W = canvas.width = 1080, H = canvas.height = 1920;
  const bands = o.bands || [
    { c: 'rgba(22,92,125,',  a: .50, amp: 90,  len: 720, sp: .22, y: .80, th: 340 },
    { c: 'rgba(0,115,150,',  a: .55, amp: 70,  len: 560, sp: .32, y: .87, th: 300 },
    { c: 'rgba(0,147,178,',  a: .50, amp: 55,  len: 440, sp: .45, y: .93, th: 280 },
  ];
  const glow = o.glow !== false;
  (function frame() {
    const t = now();
    x.clearRect(0, 0, W, H);
    if (o.sky) { const g = x.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#0a1117'); g.addColorStop(.62, '#0f2230'); g.addColorStop(1, '#123243'); x.fillStyle = g; x.fillRect(0, 0, W, H); }
    for (const b of bands) {
      x.beginPath();
      const base = H * b.y + (o.rise ? Math.max(0, (o.rise - t)) * 260 : 0);
      x.moveTo(-20, H + 20);
      for (let px = -20; px <= W + 20; px += 8) {
        const yy = base + Math.sin((px / b.len) * Math.PI * 2 + t * b.sp * Math.PI * 2) * b.amp
                        + Math.sin((px / (b.len * .53)) * Math.PI * 2 - t * b.sp * 1.7) * b.amp * .35;
        x.lineTo(px, yy);
      }
      x.lineTo(W + 20, H + 20); x.closePath();
      const g2 = x.createLinearGradient(0, H * b.y - b.th, 0, H);
      g2.addColorStop(0, b.c + (b.a) + ')'); g2.addColorStop(1, b.c + '0)');
      x.fillStyle = g2;
      if (glow) { x.shadowColor = b.c + '.8)'; x.shadowBlur = 30; }
      x.fill(); x.shadowBlur = 0;
    }
    requestAnimationFrame(frame);
  })();
}
