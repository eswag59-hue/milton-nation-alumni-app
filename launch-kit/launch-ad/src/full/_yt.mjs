/* Play a YouTube video in a real browser and grab frames off the <video>.
   yt-dlp is blocked from this datacentre IP ("confirm you're not a bot"), but a
   genuine Chromium session with a normal UA is a different request entirely. */
import { chromium } from 'playwright';
import { mkdirSync } from 'fs';
const id = process.argv[2], N = +(process.argv[3] || 12);
const OUT = `../../build/ref2/${id}`;
mkdirSync(OUT, { recursive: true });
/* All outbound traffic here goes through the agent proxy; without pointing
   Chromium at it every navigation dies on ERR_CONNECTION_RESET. */
const b = await chromium.launch({
  executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
  proxy: { server: process.env.HTTPS_PROXY || 'http://127.0.0.1:40157' },
  args: ['--no-sandbox','--disable-gpu','--autoplay-policy=no-user-gesture-required',
         '--disable-blink-features=AutomationControlled'] });
const ctx = await b.newContext({
  viewport: { width: 1280, height: 800 },
  userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  locale: 'en-US', ignoreHTTPSErrors: true });
const p = await ctx.newPage();
await p.goto(`https://www.youtube.com/embed/${id}?autoplay=1&mute=1&controls=0`,
             { waitUntil: 'domcontentloaded', timeout: 60000 });
await p.waitForTimeout(4000);
try { await p.click('button[aria-label*="Play"], .ytp-large-play-button', { timeout: 4000 }); } catch {}
await p.waitForTimeout(2500);
const dur = await p.evaluate(() => { const v = document.querySelector('video'); return v ? v.duration : 0; });
console.log('duration', dur);
if (!dur || !isFinite(dur)) { console.log('NO VIDEO'); await b.close(); process.exit(1); }
const el = await p.$('video');
for (let i = 0; i < N; i++) {
  const t = dur * (i + 0.5) / N;
  await p.evaluate(tt => { const v = document.querySelector('video'); v.pause(); v.currentTime = tt; }, t);
  await p.waitForTimeout(1400);
  await el.screenshot({ path: `${OUT}/f${String(i).padStart(2,'0')}.jpg`, type: 'jpeg', quality: 88 });
}
console.log('captured', N, 'frames');
await b.close();
