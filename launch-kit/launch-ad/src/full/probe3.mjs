/* Contact sheet across the film so every beat is eyeballed before it ships. */
import { chromium } from 'playwright';
import { resolve } from 'path';
const name = process.argv[2] || 'film3';
const times = (process.argv[3] || '').length
  ? process.argv[3].split(',').map(Number) : null;
const b = await chromium.launch({ executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
  args:['--no-sandbox','--disable-gpu','--font-render-hinting=none'] });
const p = await b.newPage({ viewport:{width:1080,height:1920}, deviceScaleFactor:1 });
p.on('pageerror', e => console.error('PAGEERROR:', e.message));
p.on('console', m => { if (m.type()==='error') console.error('PAGE:', m.text()); });
await p.goto('file://' + resolve(`${name}.html`));
await p.waitForFunction(() => window.READY === true, { timeout: 90000 });
const dur = await p.evaluate(() => window.DURATION);
const TS = times || Array.from({length:24}, (_,i) => +(dur*(i+0.5)/24).toFixed(2));
const el = await p.$('#c');
for (let i=0;i<TS.length;i++){
  await p.evaluate(t => window.SEEK(t), TS[i]);
  await el.screenshot({ path:`_pb3_${String(i).padStart(2,'0')}.png` });
}
await b.close();
console.log('DUR', dur, '\nTIMES', TS.join(' '));
