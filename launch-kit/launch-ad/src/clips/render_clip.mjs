/* Renders one clip HTML to frames + mp4.  node render_clip.mjs clip01_logo */
import { chromium } from 'playwright';
import { mkdirSync, rmSync } from 'fs';
import { resolve } from 'path';
const name = process.argv[2];
const FPS = 30, OUT = `frames_${name}`;
rmSync(OUT, { recursive: true, force: true }); mkdirSync(OUT, { recursive: true });
const b = await chromium.launch({ executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
  args:['--no-sandbox','--disable-gpu','--font-render-hinting=none'] });
const p = await b.newPage({ viewport:{width:1080,height:1920}, deviceScaleFactor:1 });
p.on('pageerror', e => console.error('PAGEERROR:', e.message));
p.on('console', m => { if (m.type()==='error') console.error('PAGE:', m.text()); });
await p.goto('file://' + resolve(`${name}.html`));
await p.waitForFunction(() => window.READY === true, { timeout: 60000 });
const dur = await p.evaluate(() => window.DURATION);
const total = Math.round(dur*FPS);
const el = await p.$('#c');
for (let i=0;i<total;i++){
  await p.evaluate(t => window.SEEK(t), i/FPS);
  await el.screenshot({ path:`${OUT}/f${String(i).padStart(4,'0')}.png` });
}
await b.close();
console.log(`${name}: ${total} frames (${dur}s)`);
