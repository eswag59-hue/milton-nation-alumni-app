import { chromium } from 'playwright';
import { resolve } from 'path';
const page_file = process.argv[2] || 'intro.html';
const ts = (process.argv[3] || '0.7,1.1,1.5,1.9,2.4,3.0,3.6,4.2,4.8,5.4,5.9,6.2')
  .split(',').map(Number);
const b = await chromium.launch({
  executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
  args: ['--no-sandbox','--disable-gpu','--font-render-hinting=none'] });
const p = await b.newPage({ viewport:{width:1080,height:1920}, deviceScaleFactor:1 });
p.on('pageerror', e => console.error('PAGEERROR:', e.message));
p.on('console', m => { if (m.type()==='error') console.error('PAGE:', m.text()); });
await p.goto('file://' + resolve(page_file));
await p.waitForFunction(() => window.READY === true, { timeout: 60000 });
const el = await p.$('#c');
for (let i=0;i<ts.length;i++){
  await p.evaluate(t => window.SEEK(t), ts[i]);
  await el.screenshot({ path:`pb_${String(i).padStart(2,'0')}.png` });
}
await b.close();
console.log(`probed ${ts.length} @ ${page_file}`);
