/* Deterministic frame renderer: steps window.SEEK(t) and screenshots each
   frame. Never screen-records — realtime capture drops frames, which is what
   made the first attempts glitch. */
import { chromium } from 'playwright';
import { mkdirSync } from 'fs';
import { resolve } from 'path';

const FPS = 30;
const OUT = 'frames';
mkdirSync(OUT, { recursive: true });

const browser = await chromium.launch({
  executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
  args: ['--no-sandbox', '--disable-gpu', '--font-render-hinting=none'],
});
const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
page.on('console', m => { if (m.type() === 'error') console.error('PAGE:', m.text()); });
await page.goto('file://' + resolve('act3.html'));
await page.waitForFunction(() => window.READY === true, { timeout: 60000 });

const dur = await page.evaluate(() => window.DURATION);
const total = Math.round(dur * FPS);
console.log(`rendering ${total} frames (${dur}s @ ${FPS}fps)`);

const el = await page.$('#c');
for (let i = 0; i < total; i++) {
  await page.evaluate(t => window.SEEK(t), i / FPS);
  await el.screenshot({ path: `${OUT}/f${String(i).padStart(4, '0')}.png` });
  if (i % 60 === 0) console.log(`  ${i}/${total}`);
}
await browser.close();
console.log('done');
